import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Reusable Delta Sync + Local Cache helper backed by [SharedPreferences].
///
/// Stores each collection's cached JSON rows and `lastSyncedAt` timestamp so
/// subsequent fetches only query rows where `updated_at > lastSyncedAt`.
class DeltaSyncCache {
  DeltaSyncCache._();

  static const String _dataPrefix = 'ns_delta_data_v1_';
  static const String _syncPrefix = 'ns_delta_sync_v1_';

  static Future<({List<Map<String, dynamic>> rows, String? lastSyncedAt})> load(
    String cacheKey,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_dataPrefix$cacheKey');
      final syncAt = prefs.getString('$_syncPrefix$cacheKey');
      if (raw == null || raw.isEmpty) {
        return (rows: <Map<String, dynamic>>[], lastSyncedAt: syncAt);
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final rows = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return (rows: rows, lastSyncedAt: syncAt);
      }
    } catch (_) {}
    return (rows: <Map<String, dynamic>>[], lastSyncedAt: null);
  }

  /// Merges [deltaRows] into [existingRows] by [idField] (updating existing or
  /// prepending new rows) and persists both the merged list and new `lastSyncedAt`.
  static Future<List<Map<String, dynamic>>> mergeAndSave(
    String cacheKey,
    List<Map<String, dynamic>> existingRows,
    List<Map<String, dynamic>> deltaRows, {
    String idField = 'id',
    String updatedField = 'updated_at',
  }) async {
    final byId = <String, Map<String, dynamic>>{};
    final order = <String>[];

    // New/updated delta rows go first so recent items appear at the top
    for (final row in deltaRows) {
      final id = row[idField]?.toString() ?? '';
      if (id.isEmpty) continue;
      if (!byId.containsKey(id)) order.add(id);
      byId[id] = row;
    }

    for (final row in existingRows) {
      final id = row[idField]?.toString() ?? '';
      if (id.isEmpty) continue;
      if (!byId.containsKey(id)) {
        order.add(id);
        byId[id] = row;
      }
    }

    final merged = order.map((id) => byId[id]!).toList();

    String newSyncAt = DateTime.now().toUtc().toIso8601String();
    for (final row in merged) {
      final ts = row[updatedField]?.toString() ?? row['created_at']?.toString();
      if (ts != null && ts.compareTo(newSyncAt) > 0) {
        newSyncAt = ts;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_dataPrefix$cacheKey', jsonEncode(merged));
      await prefs.setString('$_syncPrefix$cacheKey', newSyncAt);
    } catch (_) {}

    return merged;
  }

  static Future<void> clear(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_dataPrefix$cacheKey');
      await prefs.remove('$_syncPrefix$cacheKey');
    } catch (_) {}
  }

  /// Convenience wrapper: loads cached rows, runs [fetchDelta] with `lastSyncedAt`
  /// (null on first load), merges the delta into the cache, and returns the full list.
  static Future<List<Map<String, dynamic>>> sync(
    String cacheKey,
    Future<List<Map<String, dynamic>>> Function(String? lastSyncedAt) fetchDelta, {
    String idField = 'id',
    String updatedField = 'updated_at',
  }) async {
    final cached = await load(cacheKey);
    final syncArg = (cached.lastSyncedAt != null && cached.rows.isNotEmpty)
        ? cached.lastSyncedAt
        : null;
    final delta = await fetchDelta(syncArg);
    return mergeAndSave(
      cacheKey,
      cached.rows,
      delta,
      idField: idField,
      updatedField: updatedField,
    );
  }
}

