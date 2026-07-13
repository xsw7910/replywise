import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/share/share_helper.dart';
import 'package:replywise/core/theme/app_colors.dart';
import 'package:replywise/core/theme/app_feature_theme.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/data/polish_repository.dart';
import 'package:replywise/features/polish/domain/polish_models.dart';
import 'package:replywise/features/polish/polish_screen.dart';

class _Storage extends TokenStorage {
  _Storage() : super(const FlutterSecureStorage());
}

class _DummyClient extends ApiClient {
  _DummyClient()
    : super(
        rawDio: Dio(),
        tokenStorage: _Storage(),
        recoverUnauthorized: () async => false,
      );
}

class _RecordingPolishRepository extends PolishRepository {
  _RecordingPolishRepository({this.result}) : super(_DummyClient());

  PolishRequest? lastRequest;
  final PolishResult? result;

  @override
  Future<PolishResult> polish(PolishRequest request) {
    lastRequest = request;
    final success = result;
    if (success != null) return Future.value(success);
    return Completer<PolishResult>().future;
  }
}

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

Finder _actionIn(Key key, String tooltip) =>
    find.descendant(of: find.byKey(key), matching: find.byTooltip(tooltip));

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 6200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<_RecordingPolishRepository> _pumpPolish(
  WidgetTester tester, {
  _RecordingPolishRepository? repository,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = repository ?? _RecordingPolishRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        guidanceLibraryRepositoryProvider.overrideWith(
          (ref) =>
              GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
        ),
        polishRepositoryProvider.overrideWith((ref) => repo),
        ...overrides,
      ],
      child: const MaterialApp(home: PolishScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _enterDraft(WidgetTester tester) =>
    tester.enterText(find.byType(TextField).first, 'Please review my draft.');

void main() {
  testWidgets('Polish result shows share before copy and copy still works', (
    tester,
  ) async {
    _useTallView(tester);
    final shared = <String>[];
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>;
          copied.add(args['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pumpPolish(
      tester,
      repository: _RecordingPolishRepository(
        result: const PolishResult(
          polished: 'Please review my draft.',
          changes: 'Improved clarity.',
        ),
      ),
      overrides: [
        generatedTextSharerProvider.overrideWithValue((
          text, {
          String? subject,
        }) async {
          shared.add(text);
        }),
      ],
    );
    await _enterDraft(tester);
    await tester.tap(find.text('Polish Text'));
    await tester.pumpAndSettle();

    final share = find.byTooltip('Share polished text');
    final copy = find.byKey(const Key('result-copy-button'));
    expect(share, findsOneWidget);
    expect(copy, findsOneWidget);
    expect(tester.getTopLeft(share).dx, lessThan(tester.getTopLeft(copy).dx));

    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(shared, ['Please review my draft.']);

    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, ['Please review my draft.']);
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('Polish mirrors the Reply compact hero and visual hierarchy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpPolish(tester);

    final hero = tester.widget<SliverAppBar>(
      find.byKey(const Key('polish-hero-header')),
    );
    expect(hero.expandedHeight, 112);
    // Title now shows the Polish feature icon before the accent-colored title.
    expect(
      find.descendant(
        of: find.byKey(const Key('polish-hero-header')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/icons/polish.png',
        ),
      ),
      findsOneWidget,
    );
    final polishTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('polish-hero-header')),
        matching: find.text('Polish'),
      ),
    );
    expect(polishTitle.style?.color, AppColors.polishColor);
    expect(
      AppFeature.polish.pageBackgroundImage,
      'assets/image/polish_page_backgroud.png',
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('polish-text-card'))).dy,
      closeTo(130, 1),
    );
    expect(find.text('Text to polish'), findsOneWidget);
    expect(find.text("Paste the text you'd like to improve"), findsOneWidget);
    expect(find.text('Paste your text here…'), findsOneWidget);
    expect(find.text('Help AI understand your intent'), findsOneWidget);
    expect(find.text('Adjust tone, length and format'), findsOneWidget);
    expect(find.text('Polish Text'), findsOneWidget);
    expect(find.text('Your polished text will appear here.'), findsOneWidget);

    final initialCardTop = tester
        .getTopLeft(find.byKey(const Key('polish-text-card')))
        .dy;
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(80);
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const Key('polish-text-card'))).dy,
      lessThan(initialCardTop),
    );
  });

  testWidgets('Polish shows Guidance and More options cards', (tester) async {
    _useTallView(tester);
    await _pumpPolish(tester);

    expect(find.text('Guidance'), findsOneWidget);
    expect(find.text('More options'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('polish-more-options-card'))).height,
      tester.getSize(find.byKey(const Key('polish-guidance-card'))).height,
    );
  });

  testWidgets('Polish Extra instruction header matches option styling', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpPolish(tester);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Extra instruction'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note_rounded), findsWidgets);
    expect(
      find.byKey(const Key('polish-extra-instruction-field')),
      findsOneWidget,
    );
  });

  testWidgets('selected guidance is sent in Polish request', (tester) async {
    _useTallView(tester);
    final repository = await _pumpPolish(tester);
    await _enterDraft(tester);

    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Improve grammar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Polish Text'));
    await tester.pump();

    expect(
      repository.lastRequest?.guidance,
      'Correct the grammar while preserving the meaning.',
    );
  });

  testWidgets(
    'Polish quick guidance starts with Use template and hides base items',
    (tester) async {
      _useTallView(tester);
      await _pumpPolish(tester);
      await tester.tap(find.text('Guidance'));
      await tester.pumpAndSettle();

      expect(find.text('Use template'), findsOneWidget);
      expect(find.text('Professional'), findsNothing);
      expect(find.text('Friendly'), findsNothing);
      expect(find.text('Concise'), findsNothing);
      expect(find.text('More natural'), findsNothing);
      expect(find.text('Improve grammar'), findsOneWidget);
      expect(find.text('Fix spelling'), findsOneWidget);
      expect(find.text('Shorter'), findsNothing);
      expect(find.text('Longer'), findsNothing);
    },
  );

  testWidgets('custom tone input is shown and sent in Polish request', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = await _pumpPolish(tester);
    await _enterDraft(tester);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').at(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('polish-custom-tone-field')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('polish-custom-tone-field')),
        matching: find.byIcon(Icons.menu_book_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('polish-custom-tone-field'))).height,
      lessThan(70),
    );
    await tester.enterText(
      _editableIn(const Key('polish-custom-tone-field')),
      ' warm but direct ',
    );
    await tester.tap(find.text('Polish Text'));
    await tester.pump();

    expect(repository.lastRequest?.tone, 'warm but direct');
  });

  testWidgets('Auto is the first and default Polish tone option', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = await _pumpPolish(tester);
    await _enterDraft(tester);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();

    final auto = find.text('Auto').first;
    final natural = find.text('Natural');
    expect(tester.getTopLeft(auto).dx, lessThan(tester.getTopLeft(natural).dx));

    await tester.tap(find.text('Polish Text'));
    await tester.pump();

    expect(repository.lastRequest?.tone, isNull);
  });

  testWidgets('custom audience input is shown and sent in Polish request', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = await _pumpPolish(tester);
    await _enterDraft(tester);

    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').at(1));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('polish-custom-audience-field')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('polish-custom-audience-field')),
        matching: find.byIcon(Icons.menu_book_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('polish-custom-audience-field')))
          .height,
      lessThan(70),
    );
    await tester.enterText(
      _editableIn(const Key('polish-custom-audience-field')),
      ' my customer ',
    );
    await tester.tap(find.text('Polish Text'));
    await tester.pump();

    expect(repository.lastRequest?.audience, 'my customer');
  });

  testWidgets(
    'Polish guidance shows Library, Paste, Clear and clears payload',
    (tester) async {
      _useTallView(tester);
      final repository = await _pumpPolish(tester);
      await _enterDraft(tester);
      await tester.tap(find.text('Guidance'));
      await tester.pumpAndSettle();

      const fieldKey = Key('polish-custom-guidance-field');
      expect(_actionIn(fieldKey, 'Templates'), findsOneWidget);
      expect(_actionIn(fieldKey, 'Paste'), findsOneWidget);
      // Clear only appears once the field has text.
      expect(_actionIn(fieldKey, 'Clear'), findsNothing);

      await tester.enterText(_editableIn(fieldKey), 'Old guidance');
      await tester.pump();
      expect(_actionIn(fieldKey, 'Clear'), findsOneWidget);
      await tester.tap(_actionIn(fieldKey, 'Clear'));
      await tester.pump();
      expect(
        tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
        isEmpty,
      );

      await tester.tap(find.text('Polish Text'));
      await tester.pump();
      expect(repository.lastRequest?.guidance, isNull);
    },
  );

  testWidgets('Polish quick Use template chip opens Guidance Library', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpPolish(tester);
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use template'));
    await tester.pumpAndSettle();

    expect(find.text('Choose guidance'), findsOneWidget);
  });

  testWidgets('Polish Guidance Library action inserts a selected template', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpPolish(tester);
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    const fieldKey = Key('polish-custom-guidance-field');
    await tester.tap(_actionIn(fieldKey, 'Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Choose guidance'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Use').first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
      isNotEmpty,
    );
  });

  testWidgets('Polish custom tone template icon fills the custom tone field', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpPolish(tester);
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').first);
    await tester.pumpAndSettle();

    const fieldKey = Key('polish-custom-tone-field');
    await tester.tap(_actionIn(fieldKey, 'Templates'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Use').first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
      isNotEmpty,
    );
  });

  testWidgets(
    'Polish custom audience template icon fills the custom audience field',
    (tester) async {
      _useTallView(tester);
      await _pumpPolish(tester);
      await tester.tap(find.text('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom').last);
      await tester.pumpAndSettle();

      const fieldKey = Key('polish-custom-audience-field');
      await tester.tap(_actionIn(fieldKey, 'Templates'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Use').first);
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
        isNotEmpty,
      );
    },
  );
}
