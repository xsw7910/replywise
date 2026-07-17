import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/guidance_template.dart';

const _kCustomKey = 'guidance_library_custom_v1';
const _kFavoritesKey = 'guidance_library_favorites_v1';

class GuidanceLibraryRepository {
  GuidanceLibraryRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  // ── Read ───────────────────────────────────────────────────────────────────

  List<GuidanceTemplate> loadTemplates() {
    final favoriteIds = _loadFavoriteIds();
    final builtIns = kBuiltInTemplates
        .map((t) => t.copyWith(isFavorite: favoriteIds.contains(t.id)))
        .toList();
    final customs = _loadCustomTemplates()
        .map((t) => t.copyWith(isFavorite: favoriteIds.contains(t.id)))
        .toList();
    return [...builtIns, ...customs];
  }

  List<GuidanceTemplate> getQuickTemplates() {
    final all = loadTemplates();
    final favorites = all.where((t) => t.isFavorite).toList();
    final builtIns = all.where((t) => t.isBuiltIn && !t.isFavorite).toList();
    return [...favorites, ...builtIns].take(8).toList();
  }

  // ── Write (all persistence is awaited) ──────────────────────────────────────

  Future<GuidanceTemplate> addTemplate({
    required String title,
    required String content,
    required GuidanceCategory category,
  }) async {
    final now = DateTime.now();
    final template = GuidanceTemplate(
      id: _uuid.v4(),
      title: title,
      content: content,
      category: category,
      isBuiltIn: false,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
    );
    final customs = _loadCustomTemplates()..add(template);
    await _saveCustomTemplates(customs);
    return template;
  }

  Future<GuidanceTemplate> updateTemplate(GuidanceTemplate updated) async {
    if (updated.isBuiltIn) {
      throw ArgumentError('Built-in templates cannot be edited');
    }
    final customs = _loadCustomTemplates();
    final idx = customs.indexWhere((t) => t.id == updated.id);
    if (idx == -1) throw StateError('Template ${updated.id} not found');
    customs[idx] = updated.copyWith(updatedAt: DateTime.now());
    await _saveCustomTemplates(customs);
    return customs[idx];
  }

  Future<void> deleteTemplate(String id) async {
    final customs = _loadCustomTemplates();
    final before = customs.length;
    customs.removeWhere((t) => t.id == id);
    if (customs.length == before) throw StateError('Template $id not found');
    await _saveCustomTemplates(customs);
    // Also remove from favorites so a deleted item never lingers as a favorite.
    final favs = _loadFavoriteIds()..remove(id);
    await _saveFavoriteIds(favs);
  }

  Future<void> toggleFavorite(String id) async {
    final favs = _loadFavoriteIds();
    if (favs.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }
    await _saveFavoriteIds(favs);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  List<GuidanceTemplate> _loadCustomTemplates() {
    final raw = _prefs.getString(_kCustomKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(GuidanceTemplate.fromJson)
          .toList();
    } catch (_) {
      // Corrupted JSON should never crash the library — fall back to empty.
      return [];
    }
  }

  Future<void> _saveCustomTemplates(List<GuidanceTemplate> templates) async {
    await _prefs.setString(
      _kCustomKey,
      jsonEncode(templates.map((t) => t.toJson()).toList()),
    );
  }

  Set<String> _loadFavoriteIds() {
    return (_prefs.getStringList(_kFavoritesKey) ?? []).toSet();
  }

  Future<void> _saveFavoriteIds(Set<String> ids) async {
    await _prefs.setStringList(_kFavoritesKey, ids.toList());
  }
}

final guidanceLibraryRepositoryProvider = Provider<GuidanceLibraryRepository>((
  ref,
) {
  throw UnimplementedError(
    'Override guidanceLibraryRepositoryProvider with a SharedPreferences instance',
  );
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided at startup');
});
