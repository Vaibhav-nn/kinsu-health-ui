# Android Health Connect Integration Plan

## Overview

The integration uses the [`health`](https://pub.dev/packages/health) Flutter package (v12+), which wraps Android Health Connect (and iOS HealthKit) behind a single Dart API. Every vital type the app already tracks maps directly to a Health Connect record type. The work is split into 5 phases and touches ~12 files.

---

## Data Type Mapping

| Kinsu vital type | HC `HealthDataType` | Unit | Read | Write |
|---|---|---|---|---|
| `blood_pressure` (systolic) | `BLOOD_PRESSURE_SYSTOLIC` | mmHg | ✅ | ✅ |
| `blood_pressure` (diastolic) | `BLOOD_PRESSURE_DIASTOLIC` | mmHg | ✅ | ✅ |
| `heart_rate` | `HEART_RATE` | bpm | ✅ | ✅ |
| `blood_sugar` | `BLOOD_GLUCOSE` | mg/dL | ✅ | ✅ |
| `spo2` | `BLOOD_OXYGEN` | % | ✅ | ✅ |
| `weight` | `WEIGHT` | kg | ✅ | ✅ |
| `temperature` | `BODY_TEMPERATURE` | °C | ✅ | ✅ |
| Exercise → steps | `STEPS` | count | ✅ | ✅ |
| Exercise → calories | `ACTIVE_ENERGY_BURNED` | kcal | ✅ | ✅ |
| Exercise → workout | `WORKOUT` | — | ✅ | ✅ |

---

## Phase 1 — Foundation (Day 1–2)

### 1.1 `pubspec.yaml`

Add one dependency:

```yaml
health: ^12.0.0
```

`health` already depends on `permission_handler` transitively; no extra package needed for runtime permission dialogs.

---

### 1.2 `android/app/src/main/AndroidManifest.xml`

Three additions are needed inside `<manifest>`:

```xml
<!-- 1. Tell the Play Store this app uses Health Connect -->
<uses-permission android:name="android.permission.health.READ_HEALTH_DATA_HISTORY" />
<uses-permission android:name="android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND" />

<!-- 2. Fine-grained data-type permissions (read + write for each type) -->
<uses-permission android:name="android.permission.health.READ_BLOOD_PRESSURE" />
<uses-permission android:name="android.permission.health.WRITE_BLOOD_PRESSURE" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.WRITE_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_BLOOD_GLUCOSE" />
<uses-permission android:name="android.permission.health.WRITE_BLOOD_GLUCOSE" />
<uses-permission android:name="android.permission.health.READ_OXYGEN_SATURATION" />
<uses-permission android:name="android.permission.health.WRITE_OXYGEN_SATURATION" />
<uses-permission android:name="android.permission.health.READ_BODY_TEMPERATURE" />
<uses-permission android:name="android.permission.health.WRITE_BODY_TEMPERATURE" />
<uses-permission android:name="android.permission.health.READ_WEIGHT" />
<uses-permission android:name="android.permission.health.WRITE_WEIGHT" />
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.WRITE_STEPS" />
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.WRITE_ACTIVE_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_EXERCISE" />
<uses-permission android:name="android.permission.health.WRITE_EXERCISE" />

<!-- 3. Activity that handles the Health Connect permission intent -->
<activity
    android:name="androidx.health.connect.client.PermissionController$CreateRequestPermissionResultContract"
    android:exported="true" />
```

Also add inside `<application>`: a `<queries>` entry so the app can detect if Health Connect is installed:

```xml
<queries>
    <package android:name="com.google.android.apps.healthdata" />
</queries>
```

---

### 1.3 `android/app/src/main/res/xml/health_permissions.xml` *(new file)*

Health Connect on Android 13 and below requires a separate XML declaration of permissions read by the system:

```xml
<?xml version="1.0" encoding="utf-8"?>
<health-permissions>
    <uses-health-permission android:name="android.permission.health.READ_BLOOD_PRESSURE"/>
    <uses-health-permission android:name="android.permission.health.WRITE_BLOOD_PRESSURE"/>
    <uses-health-permission android:name="android.permission.health.READ_HEART_RATE"/>
    <uses-health-permission android:name="android.permission.health.WRITE_HEART_RATE"/>
    <uses-health-permission android:name="android.permission.health.READ_BLOOD_GLUCOSE"/>
    <uses-health-permission android:name="android.permission.health.WRITE_BLOOD_GLUCOSE"/>
    <uses-health-permission android:name="android.permission.health.READ_OXYGEN_SATURATION"/>
    <uses-health-permission android:name="android.permission.health.WRITE_OXYGEN_SATURATION"/>
    <uses-health-permission android:name="android.permission.health.READ_BODY_TEMPERATURE"/>
    <uses-health-permission android:name="android.permission.health.WRITE_BODY_TEMPERATURE"/>
    <uses-health-permission android:name="android.permission.health.READ_WEIGHT"/>
    <uses-health-permission android:name="android.permission.health.WRITE_WEIGHT"/>
    <uses-health-permission android:name="android.permission.health.READ_STEPS"/>
    <uses-health-permission android:name="android.permission.health.WRITE_STEPS"/>
    <uses-health-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED"/>
    <uses-health-permission android:name="android.permission.health.WRITE_ACTIVE_CALORIES_BURNED"/>
    <uses-health-permission android:name="android.permission.health.READ_EXERCISE"/>
    <uses-health-permission android:name="android.permission.health.WRITE_EXERCISE"/>
</health-permissions>
```

Then reference it on `<activity android:name=".MainActivity">` in `AndroidManifest.xml`:

```xml
<meta-data
    android:name="health_permissions"
    android:resource="@xml/health_permissions" />
```

---

### 1.4 `lib/core/health_connect_sync_registry.dart` *(new file)*

A lightweight local store (backed by `SharedPreferences`) that maps HC record UUIDs to entries already imported into the Kinsu backend. Prevents double-importing the same HC record.

```dart
/// Tracks which Health Connect record UUIDs have already been synced
/// into the Kinsu backend so we never import a duplicate.
class HCSyncRegistry {
  static const _prefKey = 'hc_synced_ids';

  final SharedPreferences _prefs;

  HCSyncRegistry(this._prefs);

  Set<String> get syncedIds =>
      _prefs.getStringList(_prefKey)?.toSet() ?? {};

  Future<void> markSynced(Iterable<String> hcUuids) async {
    final updated = {...syncedIds, ...hcUuids};
    await _prefs.setStringList(_prefKey, updated.toList());
  }

  bool isSynced(String hcUuid) => syncedIds.contains(hcUuid);

  Future<void> clear() async => _prefs.remove(_prefKey);
}
```

**Why this is needed:** When the user logs a vital in Kinsu it gets written to HC. Later, when they pull from HC, that same entry would be returned. Without the registry it would be imported again as a duplicate.

---

### 1.5 `lib/services/health_connect_service.dart` *(new file)*

Central wrapper around the `health` package. All HC calls go through here — nothing else in the app touches `Health` or `HealthDataPoint` directly.

```dart
class HealthConnectService {
  static final Health _health = Health();

  static const readableTypes = [
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

  // ── Platform check ────────────────────────────────────────────────────────

  /// Returns false on iOS or non-Health-Connect Android (< API 26).
  /// Use this as the feature gate before showing any HC UI.
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    return await Health().getHealthConnectSdkStatus() ==
        HealthConnectSdkStatus.sdkAvailable;
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> hasPermissions() async {
    return await _health.hasPermissions(
      readableTypes,
      permissions: List.filled(readableTypes.length, HealthDataAccess.READ_WRITE),
    ) ?? false;
  }

  /// Triggers the system Health Connect permission dialog.
  /// Returns true if all permissions were granted.
  Future<bool> requestPermissions() async {
    return await _health.requestAuthorization(
      readableTypes,
      permissions: List.filled(readableTypes.length, HealthDataAccess.READ_WRITE),
    );
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches all health data points of [types] between [start] and [end].
  /// Returns raw HealthDataPoint list — callers convert to VitalLog / ActivityLogItem.
  Future<List<HealthDataPoint>> fetchDataPoints({
    required List<HealthDataType> types,
    required DateTime start,
    required DateTime end,
  }) async {
    final points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );
    return Health.removeDuplicates(points);
  }

  // ── Write vitals ──────────────────────────────────────────────────────────

  /// Dispatches to the correct write method based on [vital.vitalType].
  Future<void> writeVitalFromLog(VitalLog vital) async {
    switch (vital.vitalType) {
      case 'blood_pressure':
        await writeBloodPressure(
          systolic: vital.value,
          diastolic: vital.valueSecondary ?? vital.value,
          recordedAt: vital.recordedAt,
        );
      case 'heart_rate':
        await _writeNumeric(HealthDataType.HEART_RATE, vital.value, vital.recordedAt);
      case 'blood_sugar':
        await _writeNumeric(HealthDataType.BLOOD_GLUCOSE, vital.value, vital.recordedAt);
      case 'spo2':
        await _writeNumeric(HealthDataType.BLOOD_OXYGEN, vital.value, vital.recordedAt);
      case 'weight':
        await _writeNumeric(HealthDataType.WEIGHT, vital.value, vital.recordedAt);
      case 'temperature':
        await _writeNumeric(HealthDataType.BODY_TEMPERATURE, vital.value, vital.recordedAt);
    }
  }

  /// Blood pressure requires two simultaneous writes (systolic + diastolic).
  Future<bool> writeBloodPressure({
    required double systolic,
    required double diastolic,
    required DateTime recordedAt,
  }) async {
    final s = await _writeNumeric(
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC, systolic, recordedAt);
    final d = await _writeNumeric(
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC, diastolic, recordedAt);
    return s && d;
  }

  Future<bool> _writeNumeric(
      HealthDataType type, double value, DateTime at) async {
    return _health.writeHealthData(
      value: value,
      type: type,
      startTime: at,
      endTime: at,
    );
  }

  // ── Write exercise ────────────────────────────────────────────────────────

  Future<bool> writeWorkout({required ActivityLogItem activity}) async {
    return _health.writeWorkoutData(
      activityType: _mapCategoryToHCExercise(activity.category),
      start: activity.loggedAt,
      end: activity.loggedAt.add(Duration(minutes: activity.durationMinutes)),
      totalEnergyBurned: activity.caloriesBurned,
      totalSteps: null,
    );
  }

  HealthWorkoutActivityType _mapCategoryToHCExercise(String category) {
    return switch (category) {
      'walk_run'  => HealthWorkoutActivityType.WALKING,
      'yoga'      => HealthWorkoutActivityType.YOGA,
      'cycling'   => HealthWorkoutActivityType.BIKING,
      'swimming'  => HealthWorkoutActivityType.SWIMMING,
      'strength'  => HealthWorkoutActivityType.STRENGTH_TRAINING,
      'dance'     => HealthWorkoutActivityType.DANCING,
      _           => HealthWorkoutActivityType.OTHER,
    };
  }
}
```

**Key design decisions:**
- `isAvailable()` is the universal feature gate — called before any HC UI is rendered.
- All reads return raw `HealthDataPoint`; conversion to app models happens in the provider layer.
- Blood pressure is always written as two separate records in HC (the platform has no combined type).

---

## Phase 2 — Write-Back: App → Health Connect (Day 3–4)

When the user logs a vital or exercise entry in Kinsu, the app simultaneously writes to HC. This is opt-in, controlled by a `syncToHealthConnect` boolean persisted in `SharedPreferences`.

### 2.1 `lib/providers/health_sync_provider.dart` *(new file)*

Single `ChangeNotifier` that owns all HC state: availability, permission status, toggle settings, and the import operation.

```dart
enum HCSyncStatus { unavailable, noPermission, idle, syncing, done, error }

class HealthSyncProvider extends ChangeNotifier {
  final HealthConnectService _hc;
  final HCSyncRegistry _registry;
  final VitalsProvider _vitalsProvider;
  final SharedPreferences _prefs;

  HCSyncStatus _status = HCSyncStatus.idle;
  bool _writeBackEnabled = false;
  bool _isAvailable = false;
  DateTime? _lastSyncAt;

  bool get isAvailable => _isAvailable;
  bool get writeBackEnabled => _writeBackEnabled;
  HCSyncStatus get status => _status;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Call once from main.dart after MultiProvider is set up.
  Future<void> init() async {
    _isAvailable = await _hc.isAvailable();
    if (!_isAvailable) {
      _status = HCSyncStatus.unavailable;
      notifyListeners();
      return;
    }
    _writeBackEnabled = _prefs.getBool('hc_write_back') ?? false;
    final lastSync = _prefs.getString('hc_last_sync');
    _lastSyncAt = lastSync != null ? DateTime.tryParse(lastSync) : null;

    final hasPerms = await _hc.hasPermissions();
    _status = hasPerms ? HCSyncStatus.idle : HCSyncStatus.noPermission;
    notifyListeners();
  }

  Future<void> toggleWriteBack(bool enabled) async {
    _writeBackEnabled = enabled;
    await _prefs.setBool('hc_write_back', enabled);
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    final granted = await _hc.requestPermissions();
    _status = granted ? HCSyncStatus.idle : HCSyncStatus.noPermission;
    notifyListeners();
    return granted;
  }

  /// Pulls HC data for the last [days] days and imports new entries into
  /// the backend. Skips any record UUID already in the sync registry.
  Future<void> importFromHC({int days = 30}) async {
    _status = HCSyncStatus.syncing;
    notifyListeners();

    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final points = await _hc.fetchDataPoints(
        types: HealthConnectService.readableTypes,
        start: start,
        end: now,
      );

      final newPoints = points.where((p) => !_registry.isSynced(p.sourceId)).toList();
      final vitalsToLog = _groupAndConvert(newPoints);

      for (final v in vitalsToLog) {
        await _vitalsProvider.logVital(v, skipHCWrite: true); // prevents echo loop
      }
      await _registry.markSynced(newPoints.map((p) => p.sourceId));

      _lastSyncAt = DateTime.now();
      await _prefs.setString('hc_last_sync', _lastSyncAt!.toIso8601String());
      _status = HCSyncStatus.done;
    } catch (_) {
      _status = HCSyncStatus.error;
    }
    notifyListeners();
  }

  /// Groups blood pressure pairs by timestamp and converts all points to VitalLog.
  List<VitalLog> _groupAndConvert(List<HealthDataPoint> points) {
    final bpSystolic = <DateTime, double>{};
    final bpDiastolic = <DateTime, double>{};
    final others = <HealthDataPoint>[];

    for (final p in points) {
      if (p.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
        bpSystolic[p.dateFrom] =
            (p.value as NumericHealthValue).numericValue.toDouble();
      } else if (p.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
        bpDiastolic[p.dateFrom] =
            (p.value as NumericHealthValue).numericValue.toDouble();
      } else {
        others.add(p);
      }
    }

    final vitals = <VitalLog>[];

    // Merge BP pairs (match within ±1 second)
    for (final entry in bpSystolic.entries) {
      final matchKey = bpDiastolic.keys.firstWhere(
        (t) => t.difference(entry.key).abs() < const Duration(seconds: 1),
        orElse: () => entry.key,
      );
      vitals.add(VitalLog(
        vitalType: 'blood_pressure',
        value: entry.value,
        valueSecondary: bpDiastolic[matchKey],
        unit: 'mmHg',
        recordedAt: entry.key,
        notes: 'Imported from Health Connect',
      ));
    }

    // Convert remaining types
    for (final p in others) {
      final v = _mapPoint(p);
      if (v != null) vitals.add(v);
    }

    return vitals;
  }

  VitalLog? _mapPoint(HealthDataPoint p) {
    final num = (p.value as NumericHealthValue).numericValue.toDouble();
    return switch (p.type) {
      HealthDataType.HEART_RATE => VitalLog(
          vitalType: 'heart_rate', value: num, unit: 'bpm',
          recordedAt: p.dateFrom, notes: 'Imported from Health Connect'),
      HealthDataType.BLOOD_GLUCOSE => VitalLog(
          vitalType: 'blood_sugar',
          // HC may return mmol/L on some devices — convert to mg/dL
          value: p.unitString == 'mmol/L' ? num * 18.0182 : num,
          unit: 'mg/dL',
          recordedAt: p.dateFrom, notes: 'Imported from Health Connect'),
      HealthDataType.BLOOD_OXYGEN => VitalLog(
          vitalType: 'spo2', value: num, unit: '%',
          recordedAt: p.dateFrom, notes: 'Imported from Health Connect'),
      HealthDataType.WEIGHT => VitalLog(
          vitalType: 'weight', value: num, unit: 'kg',
          recordedAt: p.dateFrom, notes: 'Imported from Health Connect'),
      HealthDataType.BODY_TEMPERATURE => VitalLog(
          vitalType: 'temperature', value: num, unit: '°C',
          recordedAt: p.dateFrom, notes: 'Imported from Health Connect'),
      _ => null,
    };
  }
}
```

---

### 2.2 Modify `lib/providers/vitals_provider.dart`

Add a `skipHCWrite` named parameter to `logVital` and `logSnapshot`, and fire-and-forget a HC write when write-back is enabled:

```dart
// Inject HealthConnectService at construction (or via locator):
final HealthConnectService _hcService;
final HealthSyncProvider _syncProvider; // read writeBackEnabled

Future<bool> logVital(VitalLog vital, {bool skipHCWrite = false}) async {
  // ── existing backend POST (unchanged) ──
  final success = await _service.logVital(vital);
  if (!success) return false;

  // ── NEW: mirror to Health Connect ──
  if (!skipHCWrite && _syncProvider.writeBackEnabled) {
    _hcService.writeVitalFromLog(vital).catchError((_) {}); // fire-and-forget
  }

  // ── existing local state update (unchanged) ──
  vitals.insert(0, vital.copyWith(id: ...));
  notifyListeners();
  return true;
}
```

The same `skipHCWrite` flag is added to `logSnapshot`.

---

### 2.3 Modify `lib/services/exercise_service.dart`

After `logActivity()` succeeds, mirror to HC:

```dart
Future<ActivityLogItem> logActivity({...}) async {
  final response = await _dio.post(ApiConstants.exerciseLogs, data: {...});
  final item = ActivityLogItem.fromJson(response.data as Map<String, dynamic>);

  // Mirror to Health Connect (fire-and-forget, never blocks the app)
  HealthConnectService().writeWorkout(activity: item).catchError((_) {});

  return item;
}
```

---

## Phase 3 — Read: Health Connect → App (Day 5)

### 3.1 `lib/screens/settings/health_connect_settings_screen.dart` *(new file)*

Reachable at `/health-connect`. Owns the full permission and sync management UI.

**Sections:**

1. **Availability banner** — device does not support HC → grey card with Play Store link.
2. **Permissions card** — list of 10 data types with individual grant status chips. "Grant Access" button triggers `HealthSyncProvider.requestPermissions()`.
3. **Write-back toggle** — `SwitchListTile`: "Automatically sync Kinsu entries to Health Connect". Calls `toggleWriteBack()`.
4. **Import section** — three buttons: "Last 30 days / 90 days / 180 days". Shows `LinearProgressIndicator` while `status == HCSyncStatus.syncing`. Shows "Last synced: Apr 22, 2026 at 14:30" when done.
5. **Debug row** (debug builds only) — "Clear sync registry" button to reset `HCSyncRegistry`.

**UI states:**

| `HCSyncStatus` | Shown |
|---|---|
| `unavailable` | "Health Connect not available" card, no other sections |
| `noPermission` | Permission card with prominent "Grant Access" CTA |
| `idle` | All sections enabled |
| `syncing` | Import buttons disabled, spinner shown |
| `done` | Success snackbar + last-synced timestamp updated |
| `error` | Error banner with retry button |

---

### 3.2 Add route to `lib/core/router.dart`

Inside the Home branch sub-routes (alongside `profile`, `exercise`, etc.):

```dart
GoRoute(
  path: 'health-connect',
  builder: (_, __) => const HealthConnectSettingsScreen(),
),
```

Add the constant to `KinsuRoutes`:

```dart
static const healthConnect = '/health-connect';
```

---

## Phase 4 — UI Touch-Points (Day 6)

Four small additions to surface the HC integration across existing screens.

### 4.1 `lib/screens/track/vitals/log_vital_screen.dart`

After a successful save, check write-back status and adjust the `SnackBar` message:

```dart
// After successful logVital:
final msg = syncProvider.writeBackEnabled
    ? 'Saved and synced to Health Connect'
    : 'Vital saved';
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
```

### 4.2 `lib/screens/track/vitals/vitals_trends_screen.dart`

Add a sync chip below the page header (only on Android when HC is available):

```dart
if (syncProvider.isAvailable)
  ActionChip(
    avatar: const Icon(Icons.download_rounded, size: 16),
    label: Text(syncProvider.lastSyncAt != null
        ? 'Last synced ${_formatDate(syncProvider.lastSyncAt!)}'
        : 'Import from Health Connect'),
    onPressed: () => syncProvider.importFromHC(days: 30),
  ),
```

### 4.3 `lib/screens/home/exercise_screen.dart`

Same pattern — a sync chip in the weekly summary header row:

```dart
if (syncProvider.isAvailable)
  OutlinedButton.icon(
    icon: const Icon(Icons.sync_rounded, size: 16),
    label: const Text('Sync workouts'),
    onPressed: () => syncProvider.importFromHC(days: 30),
  ),
```

### 4.4 `lib/screens/home/profile_screen.dart`

Add a `ListTile` entry pointing to the HC settings screen:

```dart
if (syncProvider.isAvailable)
  ListTile(
    leading: const Icon(Icons.favorite_border_rounded),
    title: const Text('Health Connect'),
    subtitle: Text(syncProvider.status == HCSyncStatus.noPermission
        ? 'Permissions required'
        : 'Connected'),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => context.push(KinsuRoutes.healthConnect),
  ),
```

---

## Phase 5 — Permission Lifecycle & Edge Cases (Day 7)

### 5.1 Permission revocation

HC permissions can be revoked by the user at any time via Android Settings. Re-check on every foreground resume:

```dart
// In HealthSyncProvider.init(), register a lifecycle listener:
AppLifecycleListener(
  onResume: () async {
    if (!_isAvailable) return;
    final stillGranted = await _hc.hasPermissions();
    if (!stillGranted && _status != HCSyncStatus.noPermission) {
      _status = HCSyncStatus.noPermission;
      notifyListeners();
    }
  },
);
```

### 5.2 HC not installed (Android < 9 or no HC app)

`isAvailable()` returns `false`. In this case:
- No HC UI is shown anywhere (no sync chips, no settings tile, no import buttons).
- Manifest permissions are declared but the OS ignores them on unsupported devices.
- `HealthConnectService` methods are never reached — every public call site is guarded by `if (!_isAvailable) return;`.

### 5.3 Blood pressure deduplication

Systolic and diastolic are two separate HC records but one `VitalLog` on the Kinsu side. During import in `_groupAndConvert`:
- Collect all `BLOOD_PRESSURE_SYSTOLIC` points keyed by timestamp.
- Match each to the closest `BLOOD_PRESSURE_DIASTOLIC` point within ±1 second.
- Create a single `VitalLog(value: systolic, valueSecondary: diastolic)`.
- Mark **both** HC UUIDs as synced in the registry.

### 5.4 Glucose unit conversion

HC stores blood glucose in `mmol/L` on some regional devices. The conversion is applied in `_mapPoint`:

```dart
// mmol/L × 18.0182 = mg/dL
value: p.unitString == 'mmol/L' ? num * 18.0182 : num,
unit: 'mg/dL',
```

### 5.5 `DISABLE_AUTH` demo builds

When `AppFlags.disableAuth = true` (APK testing), Firebase is not initialised but HC is platform-level and fully independent. No changes needed — HC integration works in demo mode without modification.

### 5.6 Echo loop prevention

Writing a vital to the backend → HC write-back → import from HC → would re-import the same record. Prevented by two mechanisms working together:
1. `skipHCWrite: true` flag passed during import so the provider never writes back to HC for imported entries.
2. `HCSyncRegistry` marks all HC UUIDs as synced after import, so a subsequent `importFromHC` call skips them.

---

## File Change Summary

| File | Action | Purpose |
|---|---|---|
| `pubspec.yaml` | Modify | Add `health: ^12.0.0` |
| `android/app/src/main/AndroidManifest.xml` | Modify | 20 permission tags + `<queries>` block |
| `android/app/src/main/res/xml/health_permissions.xml` | **New** | HC permission discovery (Android 13) |
| `lib/core/health_connect_sync_registry.dart` | **New** | UUID deduplication store (SharedPreferences) |
| `lib/services/health_connect_service.dart` | **New** | All HC reads / writes / permission handling |
| `lib/providers/health_sync_provider.dart` | **New** | Sync orchestration, state, import logic |
| `lib/providers/vitals_provider.dart` | Modify | Add `skipHCWrite` param + write-back trigger |
| `lib/services/exercise_service.dart` | Modify | Fire-and-forget HC workout write after log |
| `lib/screens/settings/health_connect_settings_screen.dart` | **New** | Permissions UI + manual import |
| `lib/core/router.dart` | Modify | Add `/health-connect` route + `KinsuRoutes` constant |
| `lib/screens/track/vitals/vitals_trends_screen.dart` | Modify | Import chip |
| `lib/screens/home/exercise_screen.dart` | Modify | Sync workouts chip |
| `lib/screens/home/profile_screen.dart` | Modify | HC settings entry tile |
| `lib/main.dart` | Modify | Add `HealthSyncProvider` to `MultiProvider` |

**14 files total — 6 new, 8 modified. No backend API changes required.**

---

## Testing Checklist

- [ ] Physical Android device with Health Connect installed: permission dialog appears, all 10 data types can be granted
- [ ] Log a vital in Kinsu → entry appears in HC Timeline app within 1–2 seconds
- [ ] Import from HC → correct count of records imported, no duplicates on a second import
- [ ] Revoke one HC permission in Android Settings → app shows "permissions required" state gracefully, no crash
- [ ] Non-HC device (default emulator API < 26) → zero HC UI elements visible anywhere in the app
- [ ] Blood pressure import → systolic + diastolic merged into a single `VitalLog` with both values
- [ ] Blood glucose import from a `mmol/L` device → correctly displayed as `mg/dL` in the trends screen
- [ ] `DISABLE_AUTH=true` APK build → HC still functional end-to-end
- [ ] Toggle write-back off → logging a vital does **not** write to HC (verify via HC Timeline)
- [ ] Echo loop: import from HC, check no duplicate entries appear in Kinsu after a second import
