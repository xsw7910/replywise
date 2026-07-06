import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/data/polish_repository.dart';
import 'package:replywise/features/polish/domain/polish_models.dart';
import 'package:replywise/features/polish/polish_screen.dart';
import 'package:replywise/features/reply/data/explain_repository.dart';
import 'package:replywise/features/reply/data/reply_repository.dart';
import 'package:replywise/features/reply/domain/reply_models.dart';
import 'package:replywise/features/reply/explain_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';
import 'package:replywise/features/recent/data/recent_repository.dart';
import 'package:replywise/features/recent/domain/recent_item.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

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

class _OkReplyRepo extends ReplyRepository {
  _OkReplyRepo() : super(_DummyClient());

  @override
  Future<ReplyResult> generate(ReplyRequest request) async => const ReplyResult(
    versions: [
      ReplyVersion(label: 'Professional', text: 'Pro reply'),
      ReplyVersion(label: 'Friendly', text: 'Friendly reply'),
      ReplyVersion(label: 'Short', text: 'Short reply'),
    ],
    why: 'because it reads naturally',
  );
}

class _FailReplyRepo extends ReplyRepository {
  _FailReplyRepo(this.code, this.status) : super(_DummyClient());

  final String code;
  final int status;

  @override
  Future<ReplyResult> generate(ReplyRequest request) async =>
      throw ApiError(message: 'nope', code: code, statusCode: status);
}

class _OkPolishRepo extends PolishRepository {
  _OkPolishRepo() : super(_DummyClient());

  @override
  Future<PolishResult> polish(PolishRequest request) async =>
      const PolishResult(polished: 'Polished text', changes: 'Tidied it up.');
}

class _OkExplainRepo extends ExplainRepository {
  _OkExplainRepo() : super(_DummyClient());

  @override
  Future<ExplainResult> explain({
    required String text,
    required String explainLang,
    String? appLocale,
  }) async => const ExplainResult(
    meaning: 'They are agreeing.',
    tone: 'Warm.',
    hiddenMeaning: '',
    suggestedReplies: ['Sounds good!'],
  );
}

/// Returns usage instantly so the controllers' post-success `refresh()` does not
/// stall on a real network call (which would run the save after the assertion).
class _FakeUsageRepo extends UsageRepository {
  _FakeUsageRepo() : super(_DummyClient());

  @override
  Future<EntitlementState> fetch() async => const EntitlementState.initial();
}

// ── Harness ──────────────────────────────────────────────────────────────────

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 6200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<SharedPreferences> _freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

List<Override> _baseOverrides(SharedPreferences prefs) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  guidanceLibraryRepositoryProvider.overrideWith(
    (ref) => GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
  ),
  usageRepositoryProvider.overrideWith((ref) => _FakeUsageRepo()),
];

Future<void> _pumpReply(
  WidgetTester tester,
  SharedPreferences prefs,
  ReplyRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._baseOverrides(prefs),
        replyRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: const MaterialApp(home: ReplyScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPolish(
  WidgetTester tester,
  SharedPreferences prefs,
  PolishRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._baseOverrides(prefs),
        polishRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: const MaterialApp(home: PolishScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpExplain(
  WidgetTester tester,
  SharedPreferences prefs,
  ExplainRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._baseOverrides(prefs),
        explainRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: const MaterialApp(home: ExplainScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Reply', () {
    testWidgets('success saves a recent item', (tester) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpReply(tester, prefs, _OkReplyRepo());

      await tester.enterText(
        _editableIn(const Key('reply-incoming-field')),
        'Can we meet Friday?',
      );
      await tester.tap(find.text('Generate Reply'));
      await tester.pumpAndSettle();

      final items = await RecentRepository(prefs).getAll();
      expect(items.length, 1);
      expect(items.single.type, RecentType.reply);
      expect(items.single.inputText, 'Can we meet Friday?');
      expect(items.single.outputText, 'Pro reply');
    });

    testWidgets('failure does NOT save a recent item', (tester) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpReply(tester, prefs, _FailReplyRepo('MODEL_UNAVAILABLE', 503));

      await tester.enterText(
        _editableIn(const Key('reply-incoming-field')),
        'Hello there',
      );
      await tester.tap(find.text('Generate Reply'));
      await tester.pumpAndSettle();

      expect(await RecentRepository(prefs).getAll(), isEmpty);
    });

    testWidgets('validation failure (empty input) does NOT save', (
      tester,
    ) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpReply(tester, prefs, _OkReplyRepo());

      await tester.tap(find.text('Generate Reply'));
      await tester.pumpAndSettle();

      expect(await RecentRepository(prefs).getAll(), isEmpty);
    });

    testWidgets('paywall block does NOT save', (tester) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpReply(tester, prefs, _FailReplyRepo('PAYWALL_REQUIRED', 402));

      await tester.enterText(
        _editableIn(const Key('reply-incoming-field')),
        'Hi',
      );
      await tester.tap(find.text('Generate Reply'));
      await tester.pumpAndSettle();

      expect(await RecentRepository(prefs).getAll(), isEmpty);
    });

    testWidgets('rate limit does NOT save', (tester) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpReply(tester, prefs, _FailReplyRepo('RATE_LIMITED', 429));

      await tester.enterText(
        _editableIn(const Key('reply-incoming-field')),
        'Hi again',
      );
      await tester.tap(find.text('Generate Reply'));
      await tester.pumpAndSettle();

      expect(await RecentRepository(prefs).getAll(), isEmpty);
    });

    testWidgets('regenerating the same input does not create a duplicate', (
      tester,
    ) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpReply(tester, prefs, _OkReplyRepo());

      await tester.enterText(
        _editableIn(const Key('reply-incoming-field')),
        'Same message',
      );
      await tester.tap(find.text('Generate Reply'));
      await tester.pumpAndSettle();
      // Regenerate (result area button) with the same input.
      await tester.tap(find.text('Regenerate replies'));
      await tester.pumpAndSettle();

      final items = await RecentRepository(prefs).getAll();
      expect(items.length, 1, reason: 'regenerate must update, not append');
    });
  });

  group('Polish', () {
    testWidgets('success saves a recent item', (tester) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpPolish(tester, prefs, _OkPolishRepo());

      await tester.enterText(find.byType(TextField).first, 'plz fix my txt');
      await tester.tap(find.text('Polish Text'));
      await tester.pumpAndSettle();

      final items = await RecentRepository(prefs).getAll();
      expect(items.length, 1);
      expect(items.single.type, RecentType.polish);
      expect(items.single.inputText, 'plz fix my txt');
      expect(items.single.outputText, 'Polished text');
    });
  });

  group('Explain', () {
    testWidgets('success saves a recent item', (tester) async {
      _useTallView(tester);
      final prefs = await _freshPrefs();
      await _pumpExplain(tester, prefs, _OkExplainRepo());

      await tester.enterText(
        _editableIn(const Key('explain-message-field')),
        'See you then.',
      );
      await tester.tap(find.text('Explain this message'));
      await tester.pumpAndSettle();

      final items = await RecentRepository(prefs).getAll();
      expect(items.length, 1);
      expect(items.single.type, RecentType.explain);
      expect(items.single.inputText, 'See you then.');
      expect(items.single.outputText, 'They are agreeing.');
    });
  });
}
