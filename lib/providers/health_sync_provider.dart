import 'package:flutter/widgets.dart';
import '../health_shim.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/health_connect_sync_registry.dart';
import '../models/vital.dart';
import '../services/exercise_service.dart';
import '../services/health_connect_service.dart';
import 'vitals_provider.dart';

/// The four possible states of Health Connect on this device / session.
enum HCSyncStatus {
  /// SDK not installed or Android version too old.
  unavailable,

  /// SDK available but one or more permissions have not been granted.
  noPermission,

  /// Ready — permissions granted, no operation in progress.
  idle,

  /// An import is currently in flight.
  syncing,

  /// The last import finished successfully.
  done,

  /// The last import ended with an error.
  error,
}

/// Central orchestrator for Android Health Connect.
///
/// Responsibilities:
///   • Tracks SDK availability and permission state.
///   • Owns the "write-back to HC" toggle (persisted in SharedPreferences).
///   • Runs the import flow: fetch raw HC points → deduplicate via
///     [HCSyncRegistry] → convert to [VitalLog] → POST to backend via
///     [VitalsProvider] with skipHCWrite=true (to prevent echo loops).
///   • Re-checks permissions whenever the app returns to the foreground.
///   • Propagates the write-back setting to [VitalsProvider] and
///     [ExerciseService] so they can fire-and-forget HC writes.
class HealthSyncProvider extends ChangeNotifier {
  final HealthConnectService _hc;
  final HCSyncRegistry _registry;
  final VitalsProvider _vitalsProvider;
  final ExerciseService _exerciseService;
  final SharedPreferences _prefs;

  // ── State ─────────────────────────────────────────────────────────────────
  HCSyncStatus _status = HCSyncStatus.idle;
  bool _isAvailable = false;
  bool _writeBackEnabled = false;
  DateTime? _lastSyncAt;
  int _lastImportCount = 0;
  String? _lastError;

  late final AppLifecycleListener _lifecycleListener;

  static const _prefWriteBack = 'hc_write_back';
  static const _prefLastSync = 'hc_last_sync';

  HealthSyncProvider({
    required HealthConnectService hcService,
    required HCSyncRegistry registry,
    required VitalsProvider vitalsProvider,
    required ExerciseService exerciseService,
    required SharedPreferences prefs,
  })  : _hc = hcService,
        _registry = registry,
        _vitalsProvider = vitalsProvider,
        _exerciseService = exerciseService,
        _prefs = prefs;

  // ── Getters ───────────────────────────────────────────────────────────────
  HCSyncStatus get status => _status;
  bool get isAvailable => _isAvailable;
  bool get writeBackEnabled => _writeBackEnabled;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get lastImportCount => _lastImportCount;
  String? get lastError => _lastError;
  int get registryCount => _registry.count;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Must be called once after construction (called from main.dart).
  ///
  /// Checks availability, loads persisted settings, and registers a
  /// lifecycle listener to re-check permissions on app resume.
  Future<void> init() async {
    _isAvailable = await _hc.isAvailable();

    if (!_isAvailable) {
      _status = HCSyncStatus.unavailable;
      notifyListeners();
      return;
    }

    // Load persisted settings.
    _writeBackEnabled = _prefs.getBool(_prefWriteBack) ?? false;
    final lastSyncStr = _prefs.getString(_prefLastSync);
    if (lastSyncStr != null) _lastSyncAt = DateTime.tryParse(lastSyncStr);

    // Check current permission state.
    final hasPerms = await _hc.hasPermissions();
    _status = hasPerms ? HCSyncStatus.idle : HCSyncStatus.noPermission;

    // Push current write-back state to both dependent services.
    if (hasPerms && _writeBackEnabled) {
      _configureWriteBack(enabled: true);
    }

    // Re-check permissions every time the app comes back to the foreground
    // (user may have revoked permissions via Android Settings).
    _lifecycleListener = AppLifecycleListener(
      onResume: _onAppResume,
    );

    notifyListeners();
  }

  Future<void> _onAppResume() async {
    if (!_isAvailable) return;
    final stillGranted = await _hc.hasPermissions();
    if (!stillGranted && _status != HCSyncStatus.noPermission) {
      _status = HCSyncStatus.noPermission;
      // Disable write-back silently — the user will re-enable it after
      // granting permissions again.
      _configureWriteBack(enabled: false);
      notifyListeners();
    } else if (stillGranted && _status == HCSyncStatus.noPermission) {
      _status = HCSyncStatus.idle;
      notifyListeners();
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Launches the system HC permission dialog, then re-checks the result.
  Future<bool> requestPermissions() async {
    final granted = await _hc.requestPermissions();
    _status = granted ? HCSyncStatus.idle : HCSyncStatus.noPermission;
    if (granted && _writeBackEnabled) _configureWriteBack(enabled: true);
    notifyListeners();
    return granted;
  }

  // ── Write-back toggle ─────────────────────────────────────────────────────

  /// Persists the write-back preference and propagates it to both services.
  Future<void> toggleWriteBack(bool enabled) async {
    _writeBackEnabled = enabled;
    await _prefs.setBool(_prefWriteBack, enabled);
    _configureWriteBack(enabled: enabled);
    notifyListeners();
  }

  void _configureWriteBack({required bool enabled}) {
    _vitalsProvider.configureHealthConnect(_hc, writeBack: enabled);
    _exerciseService.configureHealthConnect(_hc, writeBack: enabled);
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Pulls HC data for the last [days] days and posts new records to the
  /// Kinsu backend.
  ///
  /// Deduplication: any HC [uuid] already in [HCSyncRegistry] is skipped.
  /// Echo-loop prevention: [VitalsProvider.logVital] is called with
  /// skipHCWrite=true so imported records are never written back to HC.
  Future<void> importFromHC({int days = 30}) async {
    if (_status == HCSyncStatus.syncing) return;
    _status = HCSyncStatus.syncing;
    _lastError = null;
    _lastImportCount = 0;
    notifyListeners();

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // Fetch everything (STEPS/WORKOUT included; we skip those below).
      final points = await _hc.fetchDataPoints(
        types: kHCReadWriteTypes,
        start: start,
        end: now,
      );

      // Filter to records we haven't seen before.
      final newPoints =
          points.where((p) => p.uuid.isNotEmpty && !_registry.isSynced(p.uuid)).toList();

      // Convert and group (handles BP pairing, unit conversion, etc.).
      final vitalsToLog = _groupAndConvert(newPoints);

      // Post each vital to the backend; count successes.
      for (final v in vitalsToLog) {
        final ok = await _vitalsProvider.logVital(v, skipHCWrite: true);
        if (ok) _lastImportCount++;
      }

      // Mark all new point UUIDs as processed.
      await _registry.markSynced(newPoints.map((p) => p.uuid));

      _lastSyncAt = DateTime.now();
      await _prefs.setString(_prefLastSync, _lastSyncAt!.toIso8601String());
      _status = HCSyncStatus.done;
    } catch (e) {
      _lastError = e.toString();
      _status = HCSyncStatus.error;
    }

    notifyListeners();
  }

  // ── Conversion helpers ────────────────────────────────────────────────────

  /// Groups BP systolic/diastolic pairs by timestamp (±1 s tolerance) and
  /// converts all other numeric vitals to [VitalLog] objects.
  ///
  /// STEPS, ACTIVE_ENERGY_BURNED, and WORKOUT are silently skipped — exercise
  /// import is handled separately via writeActivityLog (Phase 4).
  List<VitalLog> _groupAndConvert(List<HealthDataPoint> points) {
    // Bucket BP values by millisecond timestamp for fast matching.
    final bpSys = <int, double>{};
    final bpDia = <int, double>{};
    final others = <HealthDataPoint>[];

    for (final p in points) {
      final ms = p.dateFrom.millisecondsSinceEpoch;
      if (p.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
        bpSys[ms] = _numValue(p);
      } else if (p.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
        bpDia[ms] = _numValue(p);
      } else {
        others.add(p);
      }
    }

    final vitals = <VitalLog>[];

    // Match BP pairs within a ±1 000 ms window.
    for (final entry in bpSys.entries) {
      final matchMs = bpDia.keys.firstWhere(
        (t) => (t - entry.key).abs() <= 1000,
        orElse: () => entry.key,
      );
      vitals.add(VitalLog(
        vitalType: 'blood_pressure',
        value: entry.value,
        valueSecondary: bpDia[matchMs],
        unit: 'mmHg',
        recordedAt: DateTime.fromMillisecondsSinceEpoch(entry.key),
        notes: 'Imported from Health Connect',
      ));
    }

    // Convert remaining types.
    for (final p in others) {
      final v = _convertPoint(p);
      if (v != null) vitals.add(v);
    }

    return vitals;
  }

  /// Converts a single [HealthDataPoint] to a [VitalLog], or null if the
  /// type is not a tracked vital (e.g. STEPS, WORKOUT).
  VitalLog? _convertPoint(HealthDataPoint p) {
    final num = _numValue(p);
    const note = 'Imported from Health Connect';

    return switch (p.type) {
      HealthDataType.HEART_RATE => VitalLog(
          vitalType: 'heart_rate',
          value: num,
          unit: 'bpm',
          recordedAt: p.dateFrom,
          notes: note,
        ),
      HealthDataType.BLOOD_GLUCOSE => VitalLog(
          vitalType: 'blood_sugar',
          // Some devices return mmol/L — convert to mg/dL.
          value: p.unitString == 'MILLIMOLES_PER_LITER' ? num * 18.0182 : num,
          unit: 'mg/dL',
          recordedAt: p.dateFrom,
          notes: note,
        ),
      HealthDataType.BLOOD_OXYGEN => VitalLog(
          vitalType: 'spo2',
          value: num,
          unit: '%',
          recordedAt: p.dateFrom,
          notes: note,
        ),
      HealthDataType.WEIGHT => VitalLog(
          vitalType: 'weight',
          value: num,
          unit: 'kg',
          recordedAt: p.dateFrom,
          notes: note,
        ),
      HealthDataType.BODY_TEMPERATURE => VitalLog(
          vitalType: 'temperature',
          value: num,
          unit: '°C',
          recordedAt: p.dateFrom,
          notes: note,
        ),
      // STEPS, ACTIVE_ENERGY_BURNED, WORKOUT, and unknown types are skipped.
      _ => null,
    };
  }

  double _numValue(HealthDataPoint p) =>
      (p.value as NumericHealthValue).numericValue.toDouble();

  // ── Registry maintenance ──────────────────────────────────────────────────

  /// Clears the sync registry — forces all HC records to be re-evaluated on
  /// the next import. Exposed for the debug row in the settings screen.
  Future<void> clearRegistry() async {
    await _registry.clear();
    notifyListeners();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }
}
