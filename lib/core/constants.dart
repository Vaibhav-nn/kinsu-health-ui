/// API configuration constants for Kinsu Health.
class ApiConstants {
  ApiConstants._();

  /// Backend base URL — change for production.
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// API version prefix.
  static const String apiV1 = '/api/v1';

  // ── Endpoint paths ─────────────────────────────────────
  static const String authLogin = '$apiV1/auth/login';

  // Vitals
  static const String vitals = '$apiV1/vitals';
  static const String vitalTrends = '$apiV1/vitals/trends';

  // Symptoms
  static const String symptoms = '$apiV1/symptoms';

  // Illness
  static const String illness = '$apiV1/illness';

  // Medications
  static const String medications = '$apiV1/medications';

  // Reminders
  static const String reminders = '$apiV1/reminders';
  static const String reminderTimeline = '$apiV1/reminders/timeline';
}
