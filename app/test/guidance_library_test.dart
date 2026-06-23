import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/features/guidance/application/guidance_library_controller.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/guidance/domain/guidance_template.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<ProviderContainer> _container({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final repo = GuidanceLibraryRepository(sharedPrefs);

  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    guidanceLibraryRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  c.read(guidanceLibraryControllerProvider); // trigger initial load
  return c;
}

GuidanceLibraryController _notifier(ProviderContainer c) =>
    c.read(guidanceLibraryControllerProvider.notifier);

GuidanceLibraryState _state(ProviderContainer c) =>
    c.read(guidanceLibraryControllerProvider);

Future<GuidanceLibraryRepository> _repo([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return GuidanceLibraryRepository(await SharedPreferences.getInstance());
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('Built-in templates', () {
    test('appear on first load', () async {
      final c = await _container();
      final state = _state(c);
      expect(state.builtInTemplates, hasLength(kBuiltInTemplates.length));
      expect(
        state.builtInTemplates.map((t) => t.id),
        containsAll(kBuiltInTemplates.map((t) => t.id)),
      );
    });

    test('repository refuses to delete a built-in (not found in customs)',
        () async {
      final repo = await _repo();
      expect(
        () => repo.deleteTemplate('builtin_be_polite'),
        throwsStateError,
      );
    });

    test('repository refuses to edit a built-in', () async {
      final repo = await _repo();
      final builtIn = kBuiltInTemplates.first;
      expect(
        () => repo.updateTemplate(builtIn.copyWith(title: 'Hacked')),
        throwsArgumentError,
      );
    });

    test('controller surfaces an error when editing a built-in fails',
        () async {
      final c = await _container();
      final builtIn = _state(c).builtInTemplates.first;
      final ok = await _notifier(c).update(builtIn.copyWith(title: 'Nope'));
      expect(ok, isFalse);
      expect(_state(c).error, isNotNull);
      // Built-in title is unchanged.
      expect(
        _state(c).builtInTemplates.first.title,
        builtIn.title,
      );
    });

    test('can be favorited', () async {
      final c = await _container();
      final builtIn = _state(c).builtInTemplates.first;
      expect(builtIn.isFavorite, isFalse);
      await _notifier(c).toggleFavorite(builtIn.id);
      expect(_state(c).favorites.any((t) => t.id == builtIn.id), isTrue);
    });
  });

  group('Custom guidance', () {
    test('can be added (await reports success)', () async {
      final c = await _container();
      final ok = await _notifier(c).add(
        title: 'Be brief',
        content: 'Keep it under two sentences.',
        category: GuidanceCategory.general,
      );
      expect(ok, isTrue);
      final custom = _state(c).customTemplates;
      expect(custom, hasLength(1));
      expect(custom.first.title, 'Be brief');
      expect(custom.first.isBuiltIn, isFalse);
    });

    test('can be edited', () async {
      final c = await _container();
      await _notifier(c).add(
        title: 'Old title',
        content: 'Old content.',
        category: GuidanceCategory.custom,
      );
      final added = _state(c).customTemplates.first;
      final ok = await _notifier(c).update(added.copyWith(title: 'New title'));
      expect(ok, isTrue);
      expect(_state(c).customTemplates.first.title, 'New title');
    });

    test('can be deleted', () async {
      final c = await _container();
      await _notifier(c).add(
          title: 'Gone', content: 'Soon.', category: GuidanceCategory.custom);
      final id = _state(c).customTemplates.first.id;
      final ok = await _notifier(c).delete(id);
      expect(ok, isTrue);
      expect(_state(c).customTemplates, isEmpty);
    });

    test('1000-character content can be created', () async {
      final c = await _container();
      final ok = await _notifier(c).add(
        title: 'Max length',
        content: 'x' * 1000,
        category: GuidanceCategory.custom,
      );
      expect(ok, isTrue);
      expect(_state(c).customTemplates.first.content.length, 1000);
    });

    test('favorite state persists across a fresh repository (reload)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final repo1 = GuidanceLibraryRepository(prefs);
      final added = await repo1.addTemplate(
        title: 'Persist me',
        content: 'Some content.',
        category: GuidanceCategory.custom,
      );
      await repo1.toggleFavorite(added.id);

      // Fresh repo over the same store simulates an app restart.
      final repo2 = GuidanceLibraryRepository(prefs);
      final loaded = repo2.loadTemplates();
      expect(
        loaded.firstWhere((t) => t.id == added.id).isFavorite,
        isTrue,
      );
    });

    test('persists after app restart simulation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final repo1 = GuidanceLibraryRepository(prefs);
      await repo1.addTemplate(
        title: 'Restart test',
        content: 'Should survive.',
        category: GuidanceCategory.general,
      );

      final repo2 = GuidanceLibraryRepository(prefs);
      final loaded = repo2.loadTemplates();
      expect(
        loaded.where((t) => !t.isBuiltIn).map((t) => t.title),
        contains('Restart test'),
      );
    });
  });

  group('Corrupted storage', () {
    test('invalid custom JSON falls back to built-ins only', () async {
      final repo = await _repo({'guidance_library_custom_v1': 'not-json{['});
      final loaded = repo.loadTemplates();
      expect(loaded.where((t) => t.isBuiltIn), hasLength(kBuiltInTemplates.length));
      expect(loaded.where((t) => !t.isBuiltIn), isEmpty);
    });

    test('controller loads without error despite corrupted JSON', () async {
      final c = await _container(prefs: {'guidance_library_custom_v1': '{{bad'});
      expect(_state(c).error, isNull);
      expect(_state(c).customTemplates, isEmpty);
      expect(_state(c).builtInTemplates, isNotEmpty);
    });
  });

  group('Quick templates', () {
    test('favorites appear before built-ins', () async {
      final c = await _container();
      final builtIn = _state(c).builtInTemplates.first;
      await _notifier(c).toggleFavorite(builtIn.id);
      final quick = _notifier(c).getQuickTemplates();
      expect(quick, isNotEmpty);
      expect(quick.first.isFavorite, isTrue);
    });

    test('limited to 8 items', () async {
      final c = await _container();
      final quick = _notifier(c).getQuickTemplates();
      expect(quick.length, lessThanOrEqualTo(8));
    });
  });
}
