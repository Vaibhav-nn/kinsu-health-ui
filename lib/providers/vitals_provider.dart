import 'package:flutter/foundation.dart';

import '../core/error_formatter.dart';
import '../models/vital.dart';
import '../services/health_connect_service.dart';
import '../services/vitals_service.dart';

class VitalsProvider extends ChangeNotifier {
  final VitalsService _service;

  VitalsProvider(this._service);

  // ── Health Connect write-back ─────────────────────────────────────────────

  HealthConnectService? _hcService;
  bool _hcWriteBack = false;

  /// Called by [HealthSyncProvider] to wire up (or disconnect) HC write-back.
  void configureHealthConnect(HealthConnectService hc, {required bool writeBack}) {
    _hcService = hc;
    _hcWriteBack = writeBack;
  }

  List<VitalLog> _vitals = [];
  List<VitalLog> get vitals => _vitals;

  VitalTrendResponse? _trendData;
  VitalTrendResponse? get trendData => _trendData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadVitals({String? vitalType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vitals = await _service.listVitals(vitalType: vitalType);
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTrends(String vitalType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trendData = await _service.getVitalTrends(vitalType: vitalType);
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Logs a vital to the backend with optimistic UI update.
  ///
  /// The vital is added to the local list immediately. If the POST fails,
  /// it is removed and [error] is set. Set [skipHCWrite] to true when the
  /// vital was imported *from* Health Connect to prevent echo loops.
  Future<bool> logVital(VitalLog vital, {bool skipHCWrite = false}) async {
    // Optimistic insert — user sees the new entry immediately.
    _vitals.insert(0, vital);
    notifyListeners();

    try {
      final created = await _service.logVital(vital);
      // Replace optimistic entry with server-assigned version (has real id).
      final idx = _vitals.indexOf(vital);
      if (idx >= 0) _vitals[idx] = created;
      notifyListeners();
      if (!skipHCWrite && _hcWriteBack && _hcService != null) {
        _hcService!.writeVitalFromLog(created);
      }
      return true;
    } catch (e) {
      // Rollback optimistic insert.
      _vitals.remove(vital);
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  /// Logs a multi-reading snapshot with optimistic UI update.
  ///
  /// Placeholder [VitalLog]s are built from the snapshot's non-null fields and
  /// prepended to the list immediately. On success they are replaced with the
  /// server-assigned records. On failure they are removed and [error] is set.
  Future<bool> logSnapshot(VitalSnapshot snapshot) async {
    final placeholders = _placeholdersFromSnapshot(snapshot);
    _vitals = [...placeholders, ..._vitals];
    notifyListeners();

    try {
      final created = await _service.logSnapshot(snapshot);
      for (final p in placeholders) {
        _vitals.remove(p);
      }
      _vitals = [...created, ..._vitals];
      notifyListeners();
      return true;
    } catch (e) {
      for (final p in placeholders) {
        _vitals.remove(p);
      }
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  /// Builds placeholder [VitalLog]s from each non-null field in [snapshot].
  List<VitalLog> _placeholdersFromSnapshot(VitalSnapshot snapshot) {
    final ps = <VitalLog>[];
    final t = snapshot.recordedAt;
    final n = snapshot.notes;

    if (snapshot.bloodPressureSystolic != null) {
      ps.add(VitalLog(
        vitalType: 'blood_pressure',
        value: snapshot.bloodPressureSystolic!,
        valueSecondary: snapshot.bloodPressureDiastolic,
        unit: 'mmHg',
        recordedAt: t,
        notes: n,
      ));
    }
    if (snapshot.heartRate != null) {
      ps.add(VitalLog(
          vitalType: 'heart_rate',
          value: snapshot.heartRate!,
          unit: 'bpm',
          recordedAt: t,
          notes: n));
    }
    if (snapshot.bloodSugar != null) {
      ps.add(VitalLog(
          vitalType: 'blood_sugar',
          value: snapshot.bloodSugar!,
          unit: 'mg/dL',
          recordedAt: t,
          notes: n));
    }
    if (snapshot.weight != null) {
      ps.add(VitalLog(
          vitalType: 'weight',
          value: snapshot.weight!,
          unit: 'kg',
          recordedAt: t,
          notes: n));
    }
    if (snapshot.temperature != null) {
      ps.add(VitalLog(
          vitalType: 'temperature',
          value: snapshot.temperature!,
          unit: '°C',
          recordedAt: t,
          notes: n));
    }
    if (snapshot.spo2 != null) {
      ps.add(VitalLog(
          vitalType: 'spo2',
          value: snapshot.spo2!,
          unit: '%',
          recordedAt: t,
          notes: n));
    }
    return ps;
  }

  Future<bool> deleteVital(int id) async {
    try {
      await _service.deleteVital(id);
      _vitals.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

}
