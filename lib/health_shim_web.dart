/// Web stub for the `health` package.
///
/// `health` is Android/iOS-only. This file re-exports identical type names as
/// no-op stubs so the app compiles on Chrome without `dart:io` / platform
/// channels. Every method returns false/empty — the real `isAvailable()` guard
/// in [HealthConnectService] ensures none of this code is ever reachable at
/// runtime on web.
library health_shim_web;

// ── Enums ────────────────────────────────────────────────────────────────────

enum HealthDataType {
  BLOOD_PRESSURE_SYSTOLIC,
  BLOOD_PRESSURE_DIASTOLIC,
  HEART_RATE,
  BLOOD_GLUCOSE,
  BLOOD_OXYGEN,
  WEIGHT,
  BODY_TEMPERATURE,
  STEPS,
  ACTIVE_ENERGY_BURNED,
  WORKOUT,
}

enum HealthDataAccess { READ_WRITE }

enum HealthConnectSdkStatus {
  sdkUnavailable,
  sdkAvailable,
  sdkUnavailableProviderUpdateRequired,
}

enum HealthWorkoutActivityType {
  WALKING,
  YOGA,
  BIKING,
  SWIMMING,
  STRENGTH_TRAINING,
  DANCING,
  SOFTBALL,
  HIGH_INTENSITY_INTERVAL_TRAINING,
  OTHER,
}

// ── Value types ───────────────────────────────────────────────────────────────

class NumericHealthValue {
  final num numericValue;
  const NumericHealthValue(this.numericValue);
}

class HealthDataPoint {
  final String uuid;
  final DateTime dateFrom;
  final HealthDataType type;
  final Object value;
  final String unitString;

  const HealthDataPoint({
    required this.uuid,
    required this.dateFrom,
    required this.type,
    required this.value,
    this.unitString = '',
  });
}

// ── Health singleton stub ─────────────────────────────────────────────────────

class Health {
  Future<void> configure() async {}

  bool isHealthConnectAvailable() => false;

  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async =>
      HealthConnectSdkStatus.sdkUnavailable;

  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      false;

  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      false;

  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      [];

  List<HealthDataPoint> removeDuplicates(List<HealthDataPoint> points) =>
      points;

  Future<bool> writeHealthData({
    required double value,
    required HealthDataType type,
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      false;

  Future<bool> writeBloodPressure({
    required int systolic,
    required int diastolic,
    required DateTime startTime,
  }) async =>
      false;

  Future<bool> writeWorkoutData({
    required HealthWorkoutActivityType activityType,
    required DateTime start,
    required DateTime end,
    int? totalEnergyBurned,
    int? totalDistance,
  }) async =>
      false;
}
