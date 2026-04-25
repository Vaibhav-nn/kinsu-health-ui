import 'package:shared_preferences/shared_preferences.dart';

/// Persistent registry of Health Connect record UUIDs that have already been
/// imported into the Kinsu backend.
///
/// Purpose: prevents the same HC record from being imported twice.
/// When the user logs a vital in Kinsu and we write it to HC, a subsequent
/// "import from HC" call would otherwise re-create that entry as a duplicate.
/// Every HC UUID we have already synced is stored here; incoming records are
/// filtered against it before being submitted to the backend.
///
/// Storage: a flat string list in SharedPreferences — simple and zero-latency.
/// The list grows slowly (one entry per imported record) and never needs
/// structured queries, so a proper database would be overkill.
class HCSyncRegistry {
  static const _prefKey = 'hc_synced_uuids';

  final SharedPreferences _prefs;

  HCSyncRegistry(this._prefs);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// All HC UUIDs that have been synced into the backend.
  Set<String> get syncedIds =>
      (_prefs.getStringList(_prefKey) ?? []).toSet();

  /// Returns true if [hcUuid] has already been imported.
  bool isSynced(String hcUuid) => syncedIds.contains(hcUuid);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Marks [hcUuids] as synced so they will be skipped on future imports.
  Future<void> markSynced(Iterable<String> hcUuids) async {
    final updated = {...syncedIds, ...hcUuids};
    await _prefs.setStringList(_prefKey, updated.toList());
  }

  // ── Maintenance ───────────────────────────────────────────────────────────

  /// Total number of HC records tracked.
  int get count => syncedIds.length;

  /// Wipes the registry. All subsequent imports will re-evaluate every HC
  /// record — use only in debug / settings screen "reset sync" flow.
  Future<void> clear() async => _prefs.remove(_prefKey);
}
