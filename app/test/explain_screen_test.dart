import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/constants/input_limits.dart';
import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/core/router/app_router.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/reply/data/explain_repository.dart';
import 'package:replywise/features/reply/domain/reply_models.dart';
import 'package:replywise/features/reply/explain_screen.dart';

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

class _FakeExplainRepository extends ExplainRepository {
  _FakeExplainRepository({this.error, ExplainResult? result})
    : result =
          result ??
          const ExplainResult(
            meaning: 'They agree generally, but not yet.',
            tone: 'Positive but cautious.',
            hiddenMeaning: 'They may not have time until later.',
            suggestedReplies: [
              'Thanks, let’s revisit after Q3.',
              'Understood — I’ll follow up later.',
            ],
          ),
      super(_DummyClient());

  final ApiError? error;
  final ExplainResult result;
  int calls = 0;
  String? lastText;

  @override
  Future<ExplainResult> explain({
    required String text,
    required String explainLang,
    String? appLocale,
  }) async {
    calls++;
    lastText = text;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

String _textOf(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(_editableIn(key)).controller.text;

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 5200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpExplain(
  WidgetTester tester,
  _FakeExplainRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [explainRepositoryProvider.overrideWith((ref) => repo)],
      child: const MaterialApp(home: ExplainScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<List<Override>> _guidanceOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    guidanceLibraryRepositoryProvider.overrideWith(
      (ref) => GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
    ),
  ];
}

Future<void> _pumpRouterApp(
  WidgetTester tester,
  _FakeExplainRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        explainRepositoryProvider.overrideWith((ref) => repo),
        ...await _guidanceOverrides(),
      ],
      child: Consumer(
        builder: (context, ref, _) =>
            MaterialApp.router(routerConfig: ref.watch(appRouterProvider)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Explain page renders input and action button', (tester) async {
    _useTallView(tester);
    await _pumpExplain(tester, _FakeExplainRepository());

    expect(find.text('Message to understand'), findsOneWidget);
    expect(find.text('Explain this message'), findsOneWidget);
    expect(find.byKey(const Key('explain-message-field')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('explain-message-field')),
              matching: find.byType(TextField),
            ),
          )
          .maxLength,
      InputLimits.explainMessageMaxLength,
    );
  });

  testWidgets('empty input validates locally and does not call repository', (
    tester,
  ) async {
    _useTallView(tester);
    final repo = _FakeExplainRepository();
    await _pumpExplain(tester, repo);

    await tester.tap(find.byKey(const Key('explain-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a message to explain.'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets(
    'successful explain displays all sections and suggested replies',
    (tester) async {
      _useTallView(tester);
      final repo = _FakeExplainRepository();
      await _pumpExplain(tester, repo);

      await tester.enterText(
        _editableIn(const Key('explain-message-field')),
        'Sounds good in principle.',
      );
      await tester.tap(find.byKey(const Key('explain-submit-button')));
      await tester.pumpAndSettle();

      expect(repo.lastText, 'Sounds good in principle.');
      expect(find.text('Meaning'), findsOneWidget);
      expect(find.text('Tone'), findsOneWidget);
      expect(find.text('Hidden Meaning'), findsOneWidget);
      expect(find.text('Suggested Replies'), findsOneWidget);
      expect(find.text('They agree generally, but not yet.'), findsOneWidget);
      expect(find.text('Thanks, let’s revisit after Q3.'), findsOneWidget);
    },
  );

  testWidgets('copy suggested reply copies text and shows snackbar', (
    tester,
  ) async {
    _useTallView(tester);
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

    await _pumpExplain(tester, _FakeExplainRepository());
    await tester.enterText(
      _editableIn(const Key('explain-message-field')),
      'Sounds good in principle.',
    );
    await tester.tap(find.byKey(const Key('explain-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Copy').first);
    await tester.pumpAndSettle();

    expect(copied, ['Thanks, let’s revisit after Q3.']);
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('RATE_LIMITED shows a friendly explain-specific message', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpExplain(
      tester,
      _FakeExplainRepository(
        error: const ApiError(
          message: 'too many',
          statusCode: 429,
          code: 'RATE_LIMITED',
        ),
      ),
    );

    await tester.enterText(
      _editableIn(const Key('explain-message-field')),
      'Please explain this.',
    );
    await tester.tap(find.byKey(const Key('explain-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'You’ve reached the explain limit for now. Please try again later.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Continue to Reply passes the original message into Reply', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpRouterApp(tester, _FakeExplainRepository());

    await tester.tap(find.text('Explain').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      _editableIn(const Key('explain-message-field')),
      'Original message from Explain.',
    );
    await tester.tap(find.byKey(const Key('explain-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('explain-continue-reply-button')));
    await tester.pumpAndSettle();

    expect(find.text('Message received'), findsOneWidget);
    expect(
      _textOf(tester, const Key('reply-incoming-field')),
      'Original message from Explain.',
    );
  });
}
