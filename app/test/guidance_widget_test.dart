import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/guidance/domain/guidance_template.dart';
import 'package:replywise/features/guidance/presentation/guidance_library_screen.dart';
import 'package:replywise/features/polish/polish_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

late SharedPreferences _prefs;
late GuidanceLibraryRepository _repo;

Future<void> _initStorage() async {
  SharedPreferences.setMockInitialValues({});
  _prefs = await SharedPreferences.getInstance();
  _repo = GuidanceLibraryRepository(_prefs);
}

List<Override> get _overrides => [
  sharedPreferencesProvider.overrideWithValue(_prefs),
  guidanceLibraryRepositoryProvider.overrideWith(
    (ref) => GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
  ),
];

/// A tall viewport so the whole ListView renders without lazy culling, keeping
/// chip/card finders and taps reliable.
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

String _textOf(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(_editableIn(key)).controller.text;

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(_initStorage);

  group('Reply guidance append', () {
    testWidgets('appends selected guidance without overwriting existing text', (
      tester,
    ) async {
      _useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides,
          child: const MaterialApp(home: ReplyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Guidance is collapsed by default; reveal the field first.
      await tester.tap(find.text('Guidance'));
      await tester.pump();

      await tester.enterText(
        _editableIn(const Key('reply-guidance-field')),
        'My own note',
      );
      await tester.pump();

      await tester.tap(find.text('Professional'));
      await tester.pump();

      expect(
        _textOf(tester, const Key('reply-guidance-field')),
        'My own note\n'
        'Make the reply sound professional and appropriate for work.',
      );
    });
  });

  group('Polish guidance append', () {
    testWidgets('fills, then appends in the Guidance card', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides,
          child: const MaterialApp(home: PolishScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guidance'));
      await tester.pumpAndSettle();

      // First selection fills the dedicated guidance field.
      await tester.tap(find.text('Professional'));
      await tester.pumpAndSettle();

      expect(
        _textOf(tester, const Key('polish-custom-guidance-field')),
        'Make the writing sound professional.',
      );

      // Second selection appends without overwriting.
      await tester.tap(find.text('Friendly'));
      await tester.pumpAndSettle();

      expect(
        _textOf(tester, const Key('polish-custom-guidance-field')),
        'Make the writing sound professional.\n'
        'Make the writing warmer and friendlier.',
      );
      // The guidance field remains available for further edits.
      expect(
        find.byKey(const Key('polish-custom-guidance-field')),
        findsOneWidget,
      );
    });
  });

  group('Guidance Library screen', () {
    testWidgets(
      'built-in cards expose Use; only custom has an edit/delete menu',
      (tester) async {
        _useTallView(tester);
        await _repo.addTemplate(
          title: 'My custom one',
          content: 'A reusable note.',
          category: GuidanceCategory.custom,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides,
            child: const MaterialApp(home: GuidanceLibraryScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // One Use action per card (built-ins + the one custom).
        expect(
          find.widgetWithText(TextButton, 'Use'),
          findsNWidgets(kBuiltInTemplates.length + 1),
        );
        // Exactly one more-menu — only the single custom item has it.
        expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      },
    );

    testWidgets('standalone Use opens an in-Reply / in-Polish chooser', (
      tester,
    ) async {
      _useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides,
          child: const MaterialApp(home: GuidanceLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Use').first);
      await tester.pumpAndSettle();

      expect(find.text('Use in Reply'), findsOneWidget);
      expect(find.text('Use in Polish'), findsOneWidget);
    });

    testWidgets(
      'deleting a custom item asks for confirmation; Cancel keeps it',
      (tester) async {
        _useTallView(tester);
        await _repo.addTemplate(
          title: 'Deletable',
          content: 'Will be kept after cancel.',
          category: GuidanceCategory.custom,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides,
            child: const MaterialApp(home: GuidanceLibraryScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete this guidance?'), findsOneWidget);
        expect(find.text('This cannot be undone.'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Deletable'), findsOneWidget);
      },
    );
  });
}
