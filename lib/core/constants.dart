import 'package:flutter/foundation.dart';

/// API configuration constants for Kinsu Health.
class ApiConstants {
  ApiConstants._();

  /// Backend base URL.
  ///
  /// Resolved in priority order:
  ///   1. `--dart-define=API_BASE_URL=<url>` (explicit override, any platform)
  ///   2. Web production default: deployed Railway API
  ///   3. Android emulator: 10.0.2.2:8000 (host loopback)
  ///   4. All other native: 127.0.0.1:8000
  ///
  /// Local dev web override:
  ///   `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000`
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Deployed Railway backend — used as the web default when no explicit URL is given.
  static const String _productionApiUrl =
      'https://independent-sparkle-production-03cf.up.railway.app';

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }

    if (kIsWeb) {
      return _productionApiUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

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
  static const String vitalSnapshot = '$apiV1/vitals/snapshot';

  static const String symptoms = '$apiV1/symptoms';
  static const String symptomsQuickLog = '$apiV1/symptoms/quick-log';
  static const String symptomsDailyCheckIn = '$apiV1/symptoms/daily-check-in';
  static const String symptomsDashboard = '$apiV1/symptoms/dashboard';

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
  static const String vaultConnectedServices =
      '$apiV1/vault/connected-services';
  static const String vaultLabParameterTrends =
      '$apiV1/vault/lab-parameters/trends';
}

/// Build-time feature flags.
class AppFlags {
  AppFlags._();

  /// Demo mode flag — skips Firebase auth for local development only.
  ///
  /// Enable with: `--dart-define=DISABLE_AUTH=true`
  ///
  /// Only takes effect in debug builds. The flag is silently ignored in
  /// profile/release builds even when the dart-define is present, so a
  /// misconfigured CI or production build can never ship with auth disabled.
  static final bool disableAuth =
      kDebugMode && const bool.fromEnvironment('DISABLE_AUTH', defaultValue: false);
}
