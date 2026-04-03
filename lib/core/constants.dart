/// API configuration constants for Kinsu Health.
class ApiConstants {
  ApiConstants._();

  /// Backend base URL.
  ///
  /// Local default targets FastAPI on port 8000.
  /// Override at run time using:
  /// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// API version prefix.
  static const String apiV1 = '/api/v1';

  static const String authLogin = '$apiV1/auth/login';
  static const String authProfile = '$apiV1/auth/profile';
  static const String authConsent = '$apiV1/auth/consent';

  static const String homescreenOverview = '$apiV1/homescreen/overview';
  static const String homescreenDashboard = '$apiV1/homescreen/dashboard';
  static const String homescreenNotifications =
      '$apiV1/homescreen/notifications';
  static const String homescreenSearch = '$apiV1/homescreen/search';

  static const String appointments = '$apiV1/appointments';

  static const String vitals = '$apiV1/vitals';
  static const String vitalTrends = '$apiV1/vitals/trends';

  static const String symptoms = '$apiV1/symptoms';

  static const String illness = '$apiV1/illness';

  static const String medications = '$apiV1/medications';
  static const String medicationsDashboard = '$apiV1/medications/dashboard';
  static const String medicationsAdherence = '$apiV1/medications/adherence';

  static const String reminders = '$apiV1/reminders';
  static const String reminderTimeline = '$apiV1/reminders/timeline';

  static const String exerciseCatalog = '$apiV1/exercise/catalog';
  static const String exerciseLogs = '$apiV1/exercise/logs';
  static const String exerciseSummary = '$apiV1/exercise/summary';
  static const String exerciseHistory = '$apiV1/exercise/history';
  static const String exerciseRecommendations =
      '$apiV1/exercise/recommendations';

  static const String familyMembers = '$apiV1/family/members';
  static const String familyProfiles = '$apiV1/family/profiles';
  static const String familyDashboard = '$apiV1/family/dashboard';

  static const String vaultRecords = '$apiV1/vault/records';
  static const String vaultUploadUrl = '$apiV1/vault/records/upload-url';
  static const String vaultConfirmUpload =
      '$apiV1/vault/records/confirm-upload';
}
