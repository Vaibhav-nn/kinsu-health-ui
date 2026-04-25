# Kinsu Health App — Session Changelog

> Branch: `health-connect-test`  
> Period: 2026-04-25

---

## Health Connect Integration (4 UI Touchpoints)

### 1. Profile → "Connected apps" tile
**File:** `lib/screens/home/profile_screen.dart`

- `Connected apps` tile in the Account section navigates to `HealthConnectSettingsScreen`.
- Subtitle updated to `"Health Connect, wearables & devices"`.

### 2. Home hero card — HC sync badge
**File:** `lib/screens/home/home_screen.dart`

- Hero card is now tappable and opens `HealthConnectSettingsScreen` when HC is available.
- A sync status badge (icon + last-sync timestamp) is shown inside the hero card when HC is active.

### 3. Track Home — HC import prompt
**File:** `lib/screens/track/track_home.dart`

- When the sparkline chart has no data **and** HC is available, an inline "Import vitals from Health Connect" row is shown below the dashed placeholder.
- Pressing **Import** calls `HealthSyncProvider.importFromHC(days: 30)` and shows a spinner while syncing.
- A "Manage Health Connect settings →" link opens the settings screen.

### 4. Onboarding — HC bottom sheet
**File:** `lib/screens/auth/auth_gate.dart`

- After the profile setup flow completes, a modal bottom sheet (`_HCOnboardingSheet`) is shown if HC is available on the device.
- Bullet points list the benefits (steps, heart rate, workouts/sleep).
- Primary button navigates to `HealthConnectSettingsScreen`; secondary button dismisses.

---

## P0 — Critical Bug Fixes

### UUID mapping bug in `importFromHC`
**File:** `lib/providers/health_sync_provider.dart`

**Problem:** `_groupAndConvert` returned a flat `List<VitalLog>`. The import loop tried to map back to source HC point UUIDs using the list index `i`, which was wrong because BP vitals consume *two* source points (systolic + diastolic) while non-BP vitals consume one — the indices were never aligned after the separation.

**Fix:** Changed `_groupAndConvert` to return `List<({VitalLog vital, List<String> sourceUuids})>`. Each converted vital now carries its source UUID(s) directly. The import loop iterates the pairs, not indices:
```dart
for (final entry in vitalsToLog) {
  final ok = await _vitalsProvider.logVital(entry.vital, skipHCWrite: true);
  if (ok) successUuids.addAll(entry.sourceUuids);
}
```
BP pairs include both the systolic and diastolic UUIDs; all others carry exactly one UUID.

### Widget test — missing HealthSyncProvider
**File:** `test/widget_test.dart`

- Added `shared_preferences`, `HealthSyncProvider`, `HealthConnectService`, `HCSyncRegistry`, and `ExerciseService` imports.
- `SharedPreferences.setMockInitialValues({})` is called inside the *Home appointments* test so that `SharedPreferences.getInstance()` works in the test environment.
- A `HealthSyncProvider` (pre-constructed with real services backed by the fast-fail test Dio) is added to the `MultiProvider` for the `HomeScreen` test, preventing a `ProviderNotFoundException` crash.

---

## P1 — High-Priority Improvements

### Optimistic `logSnapshot`
**File:** `lib/providers/vitals_provider.dart`

- `logSnapshot` now builds placeholder `VitalLog`s from each non-null field in the snapshot (`bloodPressureSystolic`, `heartRate`, `bloodSugar`, `weight`, `temperature`, `spo2`) and prepends them to `_vitals` immediately.
- On success the placeholders are replaced with the server-assigned records.
- On failure the placeholders are removed and `error` is set.
- Extracted `_placeholdersFromSnapshot(VitalSnapshot)` as a private helper.

### Error banner + retry in Track Home
**File:** `lib/screens/track/track_home.dart`

- A `_TrackErrorBanner` widget is shown at the top of the page when either `VitalsProvider.error` or `MedicationsProvider.error` is non-null.
- The banner shows the error message and a **Retry** button that re-fires both `loadMedications` and `loadVitals` in a single tap.

### Vault screen already had an error state with retry; loading spinner replaced with shimmer
**File:** `lib/screens/vault_screen.dart`

- Replaced `Center(child: CircularProgressIndicator())` with `ShimmerCardList(count: 5)` for a polished skeleton loading experience.

### Lint cleanup — `shimmer_placeholders.dart`
**File:** `lib/widgets/shimmer_placeholders.dart`

- Added `const` to all `Row`, `Column`, `Expanded`, and `_ShimmerBox` constructors inside each shimmer widget's build method, eliminating all `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` lint infos.

### Lint cleanup — `recent_prescriptions.dart`
**File:** `lib/widgets/recent_prescriptions.dart`

- Replaced all `.withOpacity(x)` calls with `.withValues(alpha: x)` per the `deprecated_member_use` lint rule.

---

## P2 — Quality & Polish

### Optimistic `addMedication`
**File:** `lib/providers/medications_provider.dart`

- `addMedication` now inserts the medication into the local list immediately (no loading spinner shown).
- On success the placeholder is replaced with the server-assigned version (which has a real `id`).
- On failure the placeholder is removed and `error` is set.
- Removed the `_isLoading = true / false` dance that was blocking UI for no reason.

### HC onboarding sheet — replace hardcoded hex colours
**File:** `lib/screens/auth/auth_gate.dart`

- Replaced all `Color(0xFFnnnnnn)` literals in `_HCOnboardingSheet` and `_HCBullet` with `KinsuTheme` and `KinsuSpacing` constants:
  - `Color(0xFFEFF6FF)` → `KinsuTheme.primaryLight`
  - `Color(0xFF3B82F6)` → `KinsuTheme.primary`
  - `Color(0xFF1A1A2E)` → `KinsuTheme.textPrimary`
  - `Color(0xFF6B7280)` → `KinsuTheme.textSecondary`
  - `Colors.grey.shade300` → `KinsuTheme.divider`
  - Spacing literals → `KinsuSpacing.xl / lg / md / sm`

### Dark mode toggle subtitle
**File:** `lib/screens/home/profile_screen.dart`

- Changed subtitle from `"Appearance setting (coming soon)"` to `"Switch between light and dark theme"` — the toggle has been working for the entire session; the "coming soon" copy was misleading.

### `KinsuSpacing` introduced
**File:** `lib/core/theme.dart`

- Added `class KinsuSpacing` with named constants: `xs(4)`, `sm(8)`, `md(12)`, `lg(16)`, `xl(20)`, `xxl(24)`, `xxxl(32)`.

---

## P3 — Nice-to-Have

### DPDP Act 2023 — Export & Delete account
**File:** `lib/screens/home/profile_screen.dart`

- Added **Export my data** tile (green icon, Account section) that shows a dialog explaining the DPDP Act 2023 data portability request flow.
- Added **Delete my account** tile (red icon, Account section) that shows a destructive-action confirmation dialog.
- Both tiles call `ScaffoldMessenger.showSnackBar` as a placeholder pending the backend API endpoints.
- The "Connected apps" tile icon colours were migrated from raw hex to `KinsuTheme` constants in the same pass.

### Emergency contacts sheet (replaces SOS stub)
**File:** `lib/screens/home/home_screen.dart`

- Renamed the SOS quick-action tile to **Emergency** (`Icons.emergency_outlined`).
- Instead of showing a "coming soon" snack bar, tapping it opens `_showEmergencySheet()` — a bottom sheet listing three dial-able emergency numbers (112 / 108 / 1091) with tappable `tel:` links via `url_launcher`.
- Added `_EmergencyContactTile` widget for each contact row.

---

## Infrastructure / Networking

### `RetryInterceptor`
**File:** `lib/core/network/retry_interceptor.dart` *(new)*

- Automatically retries idempotent requests (GET / HEAD / DELETE) on transient failures.
- Exponential back-off: 500 ms → 1 s, capped at 4 s.
- Retries on: connection errors, timeouts, 429 Too Many Requests (honours `Retry-After` header), 502 / 503 / 504.
- Non-idempotent methods (POST / PATCH / PUT) are **not** retried unless the caller sets `extra['retryOnPost'] = true`.

### `DioClient` updated
**File:** `lib/core/network/dio_client.dart`

- Wired `RetryInterceptor` as the third interceptor in the chain.
- Replaced `print(` with `debugPrint(` in the log interceptor.

### `ProfileContextInterceptor` debug logging
**File:** `lib/core/network/profile_context_interceptor.dart`

- Added a `debugPrint` statement when a request goes out without an active `X-Profile-Id` header, making it easier to diagnose profile scope issues during development.

### Vault search — cancellable requests
**File:** `lib/providers/vault_provider.dart`, `lib/services/vault_service.dart`

- `loadRecords` cancels any in-flight search via a `CancelToken` before starting a new one, so stale results from a superseded query can never overwrite newer ones.
- `DioExceptionType.cancel` is silently discarded; all other errors surface normally.
- Added `finally` block so `_isLoading` always resets.

---

## Health Connect — Foundation Layer

### `HealthConnectService`
**File:** `lib/services/health_connect_service.dart` *(pre-existing, updated)*

- Switched `package:health/health.dart` import to the conditional shim.

### Web shim for `package:health`
**Files:** `lib/health_shim.dart`, `lib/health_shim_web.dart` *(new)*

- `lib/health_shim.dart` re-exports the real `package:health/health.dart` on Android and the no-op stub `health_shim_web.dart` on web (Chrome/WASM).
- Stub covers: `HealthDataType`, `HealthDataAccess`, `HealthConnectSdkStatus`, `HealthWorkoutActivityType`, `NumericHealthValue`, `HealthDataPoint`, `Health`.
- Enables `flutter run -d chrome` without `package:health` compilation errors.

### `HCSyncRegistry`
**File:** `lib/core/health_connect_sync_registry.dart` *(new)*

- Persists a flat list of already-imported HC UUIDs in `SharedPreferences`.
- Exposes `isSynced(uuid)`, `markSynced(uuids)`, `count`, and `clear()`.

### `HealthSyncProvider`
**File:** `lib/providers/health_sync_provider.dart` *(new/major)*

- Central orchestrator: availability check, permission management, write-back toggle (persisted), import loop, foreground re-check.
- `HCSyncStatus` enum: `unavailable | noPermission | idle | syncing | done | error`.
- `importFromHC(days)`: fetches, deduplicates, converts, POSTs to backend.
- `configureHealthConnect` propagates write-back setting to `VitalsProvider` and `ExerciseService`.
- `AppLifecycleListener` is skipped on web (`kIsWeb` guard).

### HC write-back wired into VitalsProvider
**File:** `lib/providers/vitals_provider.dart`

- `configureHealthConnect(HealthConnectService hc, {required bool writeBack})` method added.
- `logVital(VitalLog, {bool skipHCWrite = false})`: when `skipHCWrite` is false and write-back is enabled, calls `hcService.writeVitalFromLog(created)` after a successful POST.
- `skipHCWrite = true` is used by `importFromHC` to prevent echo loops.

### HC write-back wired into ExerciseService
**File:** `lib/services/exercise_service.dart`

- Same `configureHealthConnect` pattern as `VitalsProvider`.
- `logActivity` calls `hcService.writeActivityLog(item)` when write-back is enabled.

### AndroidManifest — HC SDK discovery
**File:** `android/app/src/main/AndroidManifest.xml`

- Added `<queries>` block with `com.google.android.apps.healthdata` package and `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` intent so the app can detect Health Connect on Android 11+.

---

## Models

### `VitalLog.toJson` — null-field stripping
**File:** `lib/models/vital.dart`

- `toJson()` no longer sends `null` fields (`valueSecondary`, `notes`) to the backend.
- Same treatment applied to `VitalSnapshot.toJson()`.

### `Medication.toJson` — null-field stripping + `_dateOnly()` helper
**File:** `lib/models/medication.dart`

- `toJson()` strips `prescribingDoctor`, `endDate`, and `notes` when null.
- Added `static String _dateOnly(DateTime d)` helper to replace repetitive date string interpolation.

---

## Error Handling Consolidation

### `formatProviderError` — shared utility
**File:** `lib/core/error_formatter.dart` *(new)*

- Extracted from the various providers' inline `_formatError()` methods.
- Returns a user-friendly string for `DioException`, `SocketException`, `TimeoutException`, and generic errors.

### Providers migrated to shared formatter
- `MedicationsProvider` — replaced private `_formatError` with `formatProviderError`.
- `VaultProvider` — same.
- `VitalsProvider` — already used the shared formatter.

---

## Pubspec Changes

| Change | Detail |
|--------|--------|
| **Added** `health: ^12.2.0` | Android Health Connect integration |
| **Removed** `go_router: ^14.8.1` | App uses `IndexedStack` shell, router was unused |

---

## Theme System

### `KinsuSpacing` constants
**File:** `lib/core/theme.dart`

```dart
class KinsuSpacing {
  static const double xs   =  4.0;
  static const double sm   =  8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
}
```

---

*Generated 2026-04-25*
