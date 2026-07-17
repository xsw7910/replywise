import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/application/polish_page_controller.dart';
import 'package:replywise/features/polish/data/polish_repository.dart';
import 'package:replywise/features/polish/domain/polish_models.dart';
import 'package:replywise/features/polish/polish_screen.dart';
import 'package:replywise/features/reply/application/explain_page_controller.dart';
import 'package:replywise/features/reply/application/reply_page_controller.dart';
import 'package:replywise/features/reply/data/explain_repository.dart';
import 'package:replywise/features/reply/data/reply_repository.dart';
import 'package:replywise/features/reply/domain/reply_models.dart';
import 'package:replywise/features/reply/explain_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';

// ── Fakes ───────────────────────────────────────────────────────────────────

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

/// Counts how many times the model was actually asked to generate, so tests
/// can prove that returning to a page does not fire a second request.
class _CountingReplyRepository extends ReplyRepository {
  _CountingReplyRepository() : super(_DummyClient());

  int calls = 0;

  @override
  Future<ReplyResult> generate(ReplyRequest request) async {
    calls++;
    return const ReplyResult(
      versions: [
        ReplyVersion(label: 'Formal', text: 'Formal reply'),
        ReplyVersion(label: 'Casual', text: 'Casual reply'),
        ReplyVersion(label: 'Concise', text: 'Concise reply'),
      ],
      why: 'Because it works.',
    );
  }
}

class _CountingPolishRepository extends PolishRepository {
  _CountingPolishRepository() : super(_DummyClient());

  int calls = 0;

  @override
  Future<PolishResult> polish(PolishRequest request) async {
    calls++;
    return const PolishResult(
      polished: 'Polished text.',
      changes: 'Tightened wording.',
    );
  }
}

class _CountingExplainRepository extends ExplainRepository {
  _CountingExplainRepository() : super(_DummyClient());

  int calls = 0;

  @override
  Future<ExplainResult> explain({
    required String text,
    required String explainLang,
    String? appLocale,
  }) async {
    calls++;
    return const ExplainResult(
      meaning: 'They agree in principle.',
      tone: 'Warm.',
      hiddenMeaning: 'Timing is uncertain.',
      suggestedReplies: ['Thanks!'],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

String _textOf(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(_editableIn(key)).controller.text;

TextEditingController _controllerOf(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(_editableIn(key)).controller;

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 6200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<ProviderContainer> _makeContainer(List<Override> extra) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      guidanceLibraryRepositoryProvider.overrideWith(
        (ref) =>
            GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
      ),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Mounts [child] under a single, persistent [container]. Because the
/// container outlives each `pumpWidget`, the kept-alive feature providers
/// survive when the page widget is disposed and later re-mounted — exactly the
/// navigation scenario we are fixing.
Future<void> _show(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// Simulates leaving the current page and coming back: mount a throwaway page
/// (disposing the current one), then mount [page] again as a fresh instance.
Future<void> _leaveAndReturn(
  WidgetTester tester,
  ProviderContainer container,
  Widget page,
) async {
  await _show(tester, container, const Scaffold(body: SizedBox.shrink()));
  await _show(tester, container, page);
}

void main() {
  testWidgets('Reply input survives navigating away and back', (tester) async {
    _useTallView(tester);
    final container = await _makeContainer([
      replyRepositoryProvider.overrideWith((ref) => _CountingReplyRepository()),
    ]);

    await _show(tester, container, const ReplyScreen());
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can you send the report?',
    );
    await tester.pump();

    await _leaveAndReturn(tester, container, const ReplyScreen());

    expect(
      _textOf(tester, const Key('reply-incoming-field')),
      'Can you send the report?',
    );
  });

  testWidgets('Reply guidance (and its expanded state) survives navigation', (
    tester,
  ) async {
    _useTallView(tester);
    final container = await _makeContainer([
      replyRepositoryProvider.overrideWith((ref) => _CountingReplyRepository()),
    ]);

    await _show(tester, container, const ReplyScreen());
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    await tester.enterText(
      _editableIn(const Key('reply-guidance-field')),
      'Keep it warm.',
    );
    await tester.pump();

    await _leaveAndReturn(tester, container, const ReplyScreen());

    // The guidance section is still expanded and the text is restored.
    expect(find.byKey(const Key('reply-guidance-field')), findsOneWidget);
    expect(_textOf(tester, const Key('reply-guidance-field')), 'Keep it warm.');
  });

  testWidgets('Reply results survive navigation without a second request', (
    tester,
  ) async {
    _useTallView(tester);
    final repo = _CountingReplyRepository();
    final container = await _makeContainer([
      replyRepositoryProvider.overrideWith((ref) => repo),
    ]);

    await _show(tester, container, const ReplyScreen());
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can you send the report?',
    );
    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();

    expect(find.text('Formal reply'), findsOneWidget);
    expect(repo.calls, 1);

    await _leaveAndReturn(tester, container, const ReplyScreen());

    // Result is still there, and no extra generation (hence no extra credit
    // deduction) was triggered by rebuilding the page.
    expect(find.text('Formal reply'), findsOneWidget);
    expect(repo.calls, 1);
  });

  testWidgets('Polish input and result survive navigation', (tester) async {
    _useTallView(tester);
    final repo = _CountingPolishRepository();
    final container = await _makeContainer([
      polishRepositoryProvider.overrideWith((ref) => repo),
    ]);

    await _show(tester, container, const PolishScreen());
    await tester.enterText(
      _editableIn(const Key('polish-draft-field')),
      'please review my draft',
    );
    await tester.tap(find.text('Polish Text'));
    await tester.pumpAndSettle();

    expect(find.text('Polished text.'), findsOneWidget);
    expect(repo.calls, 1);

    await _leaveAndReturn(tester, container, const PolishScreen());

    expect(
      _textOf(tester, const Key('polish-draft-field')),
      'please review my draft',
    );
    expect(find.text('Polished text.'), findsOneWidget);
    expect(repo.calls, 1);
  });

  testWidgets('Explain input and result survive navigation', (tester) async {
    _useTallView(tester);
    final repo = _CountingExplainRepository();
    final container = await _makeContainer([
      explainRepositoryProvider.overrideWith((ref) => repo),
    ]);

    await _show(tester, container, const ExplainScreen());
    await tester.enterText(
      _editableIn(const Key('explain-message-field')),
      'What do they mean?',
    );
    await tester.tap(find.byKey(const Key('explain-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('They agree in principle.'), findsOneWidget);
    expect(repo.calls, 1);

    await _leaveAndReturn(tester, container, const ExplainScreen());

    // Both the typed message and the generated explanation are restored, with
    // no second request.
    expect(
      _textOf(tester, const Key('explain-message-field')),
      'What do they mean?',
    );
    expect(find.text('They agree in principle.'), findsOneWidget);
    expect(repo.calls, 1);
  });

  testWidgets('typing does not force the cursor to the end on rebuild', (
    tester,
  ) async {
    _useTallView(tester);
    final container = await _makeContainer([
      replyRepositoryProvider.overrideWith((ref) => _CountingReplyRepository()),
    ]);

    await _show(tester, container, const ReplyScreen());
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Hello world',
    );
    await tester.pump();

    // Place the caret in the middle of the text.
    final controller = _controllerOf(tester, const Key('reply-incoming-field'));
    controller.selection = const TextSelection.collapsed(offset: 5);

    // Force an unrelated page rebuild (toggles a watched flag).
    container
        .read(replyPageControllerProvider.notifier)
        .toggleMoreOptionsExpanded();
    await tester.pump();

    // The caret stayed put; it was not yanked to the end of the field.
    expect(
      _controllerOf(tester, const Key('reply-incoming-field')).selection,
      const TextSelection.collapsed(offset: 5),
    );
  });

  testWidgets('Reply, Polish and Explain page state are independent', (
    tester,
  ) async {
    final container = await _makeContainer(const []);

    container.read(replyPageControllerProvider.notifier).setIncoming('reply');
    container.read(polishPageControllerProvider.notifier).setDraft('polish');
    container
        .read(explainPageControllerProvider.notifier)
        .setMessage('explain');

    expect(container.read(replyPageControllerProvider).incoming, 'reply');
    expect(container.read(polishPageControllerProvider).draft, 'polish');
    expect(container.read(explainPageControllerProvider).message, 'explain');

    // Mutating one feature leaves the others untouched.
    container.read(replyPageControllerProvider.notifier).setIncoming('changed');
    expect(container.read(polishPageControllerProvider).draft, 'polish');
    expect(container.read(explainPageControllerProvider).message, 'explain');
  });

  testWidgets('clearing the Reply field clears only Reply page state', (
    tester,
  ) async {
    _useTallView(tester);
    final container = await _makeContainer([
      replyRepositoryProvider.overrideWith((ref) => _CountingReplyRepository()),
    ]);
    // Give Polish some state to prove it is not touched by a Reply clear.
    container.read(polishPageControllerProvider.notifier).setDraft('keep me');

    await _show(tester, container, const ReplyScreen());
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'temporary',
    );
    await tester.pump();
    expect(container.read(replyPageControllerProvider).incoming, 'temporary');

    // The field's built-in clear button clears the controller, which must also
    // clear the mirrored provider state.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('reply-incoming-field')),
        matching: find.byTooltip('Clear'),
      ),
    );
    await tester.pump();

    expect(_textOf(tester, const Key('reply-incoming-field')), isEmpty);
    expect(container.read(replyPageControllerProvider).incoming, isEmpty);
    // Polish was not affected.
    expect(container.read(polishPageControllerProvider).draft, 'keep me');
  });

  test('page state holds only plain values, never widget objects', () async {
    final container = await _makeContainer(const []);
    final reply = container.read(replyPageControllerProvider);
    // A representative sample: everything the notifier exposes is a String or
    // bool — there is nowhere to stash a controller, FocusNode, or context.
    expect(reply.incoming, isA<String>());
    expect(reply.guidance, isA<String>());
    expect(reply.tone, isA<String>());
    expect(reply.guidanceExpanded, isA<bool>());
    expect(reply.moreOptionsExpanded, isA<bool>());

    final polish = container.read(polishPageControllerProvider);
    expect(polish.draft, isA<String>());
    expect(polish.length, isA<String>());

    final explain = container.read(explainPageControllerProvider);
    expect(explain.message, isA<String>());
  });
}
