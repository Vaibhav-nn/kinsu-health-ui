import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import '../health_shim.dart';

import '../models/activity_models.dart';
import '../models/vital.dart';

/// All Health Connect data types that Kinsu reads **and** writes.
///
/// This is the single source of truth — keep it in sync with
/// AndroidManifest.xml and res/xml/health_permissions.xml.
const List<HealthDataType> kHCReadWriteTypes = [
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  HealthDataType.HEART_RATE,
  HealthDataType.BLOOD_GLUCOSE,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.WEIGHT,
  HealthDataType.BODY_TEMPERATURE,
  HealthDataType.STEPS,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.WORKOUT,
];

/// READ_WRITE access for every entry in [kHCReadWriteTypes].
final List<HealthDataAccess> kHCReadWriteAccess =
    List.filled(kHCReadWriteTypes.length, HealthDataAccess.READ_WRITE);

/// Thin wrapper around the `health` Flutter package for Android Health Connect.
///
/// Responsibilities (Phase 1 — Foundation):
///   • Platform availability check
///   • Permission request / status query
///   • Raw data fetch (returns [HealthDataPoint] — callers map to app models)
///   • Primitive numeric + blood-pressure + workout writes
///
/// Domain-model coupling (writeVitalFromLog, writeWorkout(ActivityLogItem))
/// is added in Phase 2, keeping this class free of app-layer imports.
///
/// Usage pattern:
/// ```dart
/// final hc = HealthConnectService();
/// if (!await hc.isAvailable()) return;          // feature gate
/// if (!await hc.hasPermissions()) {
///   await hc.requestPermissions();
/// }
/// final points = await hc.fetchDataPoints(...); // raw read
/// await hc.writeNumeric(...);                   // raw write
/// ```
class HealthConnectService {
  // The health package uses a shared singleton; we call methods on it directly.
  static final Health _health = Health();

  // configure() fetches the device ID and must be awaited once before any
  // other call. We track its Future so concurrent callers all await the same
  // operation instead of calling configure() multiple times.
  static Future<void>? _configureFuture;

  Future<void> _ensureConfigured() async {
    _configureFuture ??= _health.configure();
    await _configureFuture;
  }

  // ── Platform / availability ───────────────────────────────────────────────

  /// Returns true only on Android devices where Health Connect is installed
  /// and ready (sdkAvailable).
  ///
  /// Always returns false on iOS (HealthKit is separate) and on Flutter Web.
  /// Call this first — all other methods are safe no-ops when this is false.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;
    await _ensureConfigured();
    return _health.isHealthConnectAvailable();
  }

  /// Returns the raw [HealthConnectSdkStatus] for user-facing messaging:
  ///   sdkAvailable                  → connected
  ///   sdkUnavailableProviderUpdateRequired → "update Health Connect"
  ///   sdkUnavailable                → "install Health Connect"
  Future<HealthConnectSdkStatus?> sdkStatus() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    await _ensureConfigured();
    return _health.getHealthConnectSdkStatus();
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Returns true if all [kHCReadWriteTypes] are granted at READ_WRITE level.
  ///
  /// Note: on Android, HC permissions can be revoked at any time via
  /// Android Settings → Privacy → Health Connect. Re-check on every app
  /// foreground event (HealthSyncProvider in Phase 2).
  Future<bool> hasPermissions() async {
    await _ensureConfigured();
    final result = await _health.hasPermissions(
      kHCReadWriteTypes,
      permissions: kHCReadWriteAccess,
    );
    // hasPermissions returns null when the SDK is not ready — treat as false.
    return result ?? false;
  }

  /// Launches the system Health Connect permission dialog and returns true if
  /// all permissions are subsequently confirmed via a follow-up check.
  ///
  /// Background: Android does not guarantee requestAuthorization's own return
  /// value reflects what the user actually granted, so we re-query with
  /// hasPermissions() after the dialog dismisses.
  Future<bool> requestPermissions() async {
    await _ensureConfigured();
    await _health.requestAuthorization(
      kHCReadWriteTypes,
      permissions: kHCReadWriteAccess,
    );
    // Authoritative check — dialog may have been partially dismissed.
    return hasPermissions();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches raw Health Connect data points for [types] between [start] and
  /// [end], with package-level deduplication applied.
  ///
  /// Returns an empty list (never throws) on permission denial or SDK errors
  /// so callers don't need try/catch for the happy path.
  Future<List<HealthDataPoint>> fetchDataPoints({
    required List<HealthDataType> types,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      );
      // removeDuplicates deduplicates by the underlying HC record UUID.
      return _health.removeDuplicates(points);
    } catch (_) {
      return [];
    }
  }

  // ── Write: single numeric ─────────────────────────────────────────────────

  /// Writes a single numeric Health Connect record.
  ///
  /// [type]       — target HealthDataType (must not be WORKOUT or BLOOD_PRESSURE_*;
  ///                use [writeBloodPressure] for blood pressure).
  /// [value]      — measurement in the type's canonical unit.
  /// [recordedAt] — observation time; used as both start and end time since
  ///                these are instantaneous point measurements.
  ///
  /// Returns true on success. Failures are swallowed — HC write-back is
  /// best-effort and must never block the user's primary logging flow.
  Future<bool> writeNumeric({
    required HealthDataType type,
    required double value,
    required DateTime recordedAt,
  }) async {
    try {
      await _ensureConfigured();
      return await _health.writeHealthData(
        value: value,
        type: type,
        startTime: recordedAt,
        endTime: recordedAt,
      );
    } catch (_) {
      return false;
    }
  }

  // ── Write: blood pressure ─────────────────────────────────────────────────

  /// Writes a blood pressure reading using the package's dedicated
  /// writeBloodPressure method (systolic + diastolic in a single call).
  ///
  /// [systolic] and [diastolic] are provided as doubles (matching VitalLog)
  /// and truncated to int here, as the HC API expects integer mmHg values.
  ///
  /// During import, the two separate HC records are matched by their shared
  /// [recordedAt] timestamp and merged into one VitalLog (Phase 2).
  Future<bool> writeBloodPressure({
    required double systolic,
    required double diastolic,
    required DateTime recordedAt,
  }) async {
    try {
      await _ensureConfigured();
      return await _health.writeBloodPressure(
        systolic: systolic.round(),
        diastolic: diastolic.round(),
        startTime: recordedAt,
      );
    } catch (_) {
      return false;
    }
  }

  // ── Write: workout ────────────────────────────────────────────────────────

  /// Writes a workout session to Health Connect.
  ///
  /// [activityType]    — HC exercise type (use [categoryToHCType] to convert
  ///                     from a Kinsu category string).
  /// [start]           — session start time (= loggedAt in ActivityLogItem).
  /// [durationMinutes] — session length; end time = start + duration.
  /// [caloriesBurned]  — total active energy in kcal (optional).
  /// [distanceMeters]  — total distance in metres (optional; pass for
  ///                     walk_run and cycling activities).
  Future<bool> writeWorkoutRaw({
    required HealthWorkoutActivityType activityType,
    required DateTime start,
    required int durationMinutes,
    int? caloriesBurned,
    int? distanceMeters,
  }) async {
    try {
      await _ensureConfigured();
      return await _health.writeWorkoutData(
        activityType: activityType,
        start: start,
        end: start.add(Duration(minutes: durationMinutes)),
        totalEnergyBurned: caloriesBurned,
        totalDistance: distanceMeters,
      );
    } catch (_) {
      return false;
    }
  }

  // ── Category → HC type mapping ────────────────────────────────────────────

  /// Maps a Kinsu exercise category string to the closest
  /// [HealthWorkoutActivityType] for Health Connect.
  ///
  /// Used in Phase 2 when [writeWorkoutRaw] is called with an ActivityLogItem.
  static HealthWorkoutActivityType categoryToHCType(String category) {
    return switch (category) {
      'walk_run' => HealthWorkoutActivityType.WALKING,
      'yoga'     => HealthWorkoutActivityType.YOGA,
      'cycling'  => HealthWorkoutActivityType.BIKING,
      'swimming' => HealthWorkoutActivityType.SWIMMING,
      'strength' => HealthWorkoutActivityType.STRENGTH_TRAINING,
      'dance'    => HealthWorkoutActivityType.DANCING,
      'sports'   => HealthWorkoutActivityType.SOFTBALL,
      'cardio'   => HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING,
      _          => HealthWorkoutActivityType.OTHER,
    };
  }

  // ── Phase 2: domain-model convenience methods ─────────────────────────────

  /// Dispatches to the correct primitive write based on [vital.vitalType].
  ///
  /// Called by [VitalsProvider] after a successful backend POST when
  /// write-back is enabled. All failures are silently swallowed — HC
  /// write-back is best-effort and must never block the logging flow.
  Future<void> writeVitalFromLog(VitalLog vital) async {
    switch (vital.vitalType) {
      case 'blood_pressure':
        await writeBloodPressure(
          systolic: vital.value,
          diastolic: vital.valueSecondary ?? vital.value,
          recordedAt: vital.recordedAt,
        );
      case 'heart_rate':
        await writeNumeric(
          type: HealthDataType.HEART_RATE,
          value: vital.value,
          recordedAt: vital.recordedAt,
        );
      case 'blood_sugar':
        await writeNumeric(
          type: HealthDataType.BLOOD_GLUCOSE,
          value: vital.value,
          recordedAt: vital.recordedAt,
        );
      case 'spo2':
        await writeNumeric(
          type: HealthDataType.BLOOD_OXYGEN,
          value: vital.value,
          recordedAt: vital.recordedAt,
        );
      case 'weight':
        await writeNumeric(
          type: HealthDataType.WEIGHT,
          value: vital.value,
          recordedAt: vital.recordedAt,
        );
      case 'temperature':
        await writeNumeric(
          type: HealthDataType.BODY_TEMPERATURE,
          value: vital.value,
          recordedAt: vital.recordedAt,
        );
    }
  }

  /// Writes an [ActivityLogItem] to Health Connect as a WORKOUT record.
  ///
  /// Called by [ExerciseService] after a successful backend POST when
  /// write-back is enabled. Failures are silently swallowed.
  Future<void> writeActivityLog(ActivityLogItem activity) async {
    final distanceMeters = activity.distanceKm != null
        ? (activity.distanceKm! * 1000).round()
        : null;
    await writeWorkoutRaw(
      activityType: categoryToHCType(activity.category),
      start: activity.loggedAt,
      durationMinutes: activity.durationMinutes,
      caloriesBurned: activity.caloriesBurned,
      distanceMeters: distanceMeters,
    );
  }

  /// Writes a VitalSnapshot to Health Connect — one HC record per non-null field.
  Future<void> writeSnapshotToHC(VitalSnapshot snapshot) async {
    final at = snapshot.recordedAt;
    if (snapshot.bloodPressureSystolic != null &&
        snapshot.bloodPressureDiastolic != null) {
      await writeBloodPressure(
        systolic: snapshot.bloodPressureSystolic!,
        diastolic: snapshot.bloodPressureDiastolic!,
        recordedAt: at,
      );
    }
    if (snapshot.heartRate != null) {
      await writeNumeric(
          type: HealthDataType.HEART_RATE,
          value: snapshot.heartRate!,
          recordedAt: at);
    }
    if (snapshot.bloodSugar != null) {
      await writeNumeric(
          type: HealthDataType.BLOOD_GLUCOSE,
          value: snapshot.bloodSugar!,
          recordedAt: at);
    }
    if (snapshot.spo2 != null) {
      await writeNumeric(
          type: HealthDataType.BLOOD_OXYGEN,
          value: snapshot.spo2!,
          recordedAt: at);
    }
    if (snapshot.weight != null) {
      await writeNumeric(
          type: HealthDataType.WEIGHT,
          value: snapshot.weight!,
          recordedAt: at);
    }
    if (snapshot.temperature != null) {
      await writeNumeric(
          type: HealthDataType.BODY_TEMPERATURE,
          value: snapshot.temperature!,
          recordedAt: at);
    }
  }
}
