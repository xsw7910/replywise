import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// sharedPreferencesProvider is declared alongside the guidance repository and is
// the app-wide SharedPreferences handle (overridden at startup and in tests).
import '../../guidance/data/guidance_library_repository.dart'
    show sharedPreferencesProvider;
import '../domain/recent_item.dart';

const _kRecentKey = 'replywise_recent_items_v1';
const _kMaxStored = 50;

/// Local-only recent activity store backed by SharedPreferences (JSON list).
///
/// Items are persisted newest-first and capped at the most recent
/// [_kMaxStored]. Adding an item removes any existing entry with the same id or
/// the same (type + input), so re-running/regenerating the same input updates
/// the existing entry (new output/timestamp, moved to the top) instead of
/// appending a near-duplicate. Corrupted storage never crashes the app — reads
/// skip malformed records and fall back to an empty list.
class RecentRepository {
  RecentRepository(this._prefs);

  final SharedPreferences _prefs;

  Future<List<RecentItem>> getAll() async => _load();

  Future<List<RecentItem>> getLatest({int limit = 2}) async =>
      _load().take(limit).toList();

  Future<void> add(RecentItem item) async {
    // Deduplicate by id and by (type + inputText): a regenerate of the same
    // input replaces the previous entry rather than creating a duplicate.
    final items = _load()
      ..removeWhere(
        (e) =>
            e.id == item.id ||
            (e.type == item.type && e.inputText == item.inputText),
      );
    items.insert(0, item); // newest first
    await _save(items.take(_kMaxStored).toList());
  }

  Future<void> delete(String id) async {
    final items = _load()..removeWhere((e) => e.id == id);
    await _save(items);
  }

  Future<void> clear() async {
    await _prefs.remove(_kRecentKey);
  }

  List<RecentItem> _load() {
    final raw = _prefs.getString(_kRecentKey);
    if (raw == null) return [];

    final List<dynamic> list;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      list = decoded;
    } catch (_) {
      // Whole payload is unparseable — fall back to empty, never crash.
      return [];
    }

    // Parse each record independently so one malformed entry never discards
    // the rest of the valid history.
    final items = <RecentItem>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        items.add(RecentItem.fromJson(entry));
      } catch (_) {
        // Skip only this malformed record.
      }
    }
    return items;
  }

  Future<void> _save(List<RecentItem> items) async {
    await _prefs.setString(
      _kRecentKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}

final recentRepositoryProvider = Provider<RecentRepository>((ref) {
  return RecentRepository(ref.watch(sharedPreferencesProvider));
});
