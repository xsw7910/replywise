import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/core/theme/app_feature_theme.dart';
import 'package:replywise/features/app_status/application/app_status_controller.dart';
import 'package:replywise/features/app_status/data/app_status_service.dart';
import 'package:replywise/features/app_status/domain/app_status.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/data/polish_repository.dart';
import 'package:replywise/features/polish/domain/polish_models.dart';
import 'package:replywise/features/polish/polish_screen.dart';
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

/// Reply repository that fails with [error] until [failuresLeft] runs out,
/// then succeeds — used to verify that Retry re-runs the original action.
class _FlakyReplyRepository extends ReplyRepository {
  _FlakyReplyRepository({this.error, this.failuresLeft = -1})
    : super(_DummyClient());

  final ApiError? error;
  int failuresLeft; // -1 = always fail (when error != null)
  int calls = 0;

  @override
  Future<ReplyResult> generate(ReplyRequest request) async {
    calls++;
    final failure = error;
    if (failure != null && failuresLeft != 0) {
      if (failuresLeft > 0) failuresLeft--;
      throw failure;
    }
    return const ReplyResult(
      versions: [ReplyVersion(label: 'Friendly', text: 'A friendly reply')],
      why: 'Test result',
    );
  }
}

class _NeverPolishRepository extends PolishRepository {
  _NeverPolishRepository() : super(_DummyClient());

  @override
  Future<PolishResult> polish(PolishRequest request) =>
      Completer<PolishResult>().future;
}

class _FakeAppStatusService implements AppStatusService {
  _FakeAppStatusService(this._onFetch);

  final Future<AppStatus> Function() _onFetch;
  int callCount = 0;

  @override
  Future<AppStatus> fetch({
    String appName = 'replywise',
    String platform = 'android',
  }) {
    callCount++;
    return _onFetch();
  }
}

AppStatus _buildStatus({
  bool maintenance = false,
  String minSupportedVersion = '1.0.0',
  int minSupportedBuildNumber = 0,
  bool forceUpdate = false,
}) => AppStatus(
  appName: 'replywise',
  platform: 'android',
  maintenance: maintenance,
  maintenanceMessage: 'Scheduled maintenance in progress.',
  minSupportedVersion: minSupportedVersion,
  minSupportedBuildNumber: minSupportedBuildNumber,
  latestVersion: minSupportedVersion,
  latestBuildNumber: minSupportedBuildNumber,
  forceUpdate: forceUpdate,
  updateMessage: 'Please update ReplyWise.',
  disabledFeatures: const [],
  supportEmail: 'support@novaaistudio.ca',
  updatedAt: DateTime.utc(2026, 1, 1),
);

// ── Harness ─────────────────────────────────────────────────────────────────

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

void _expectErrorSheetFeatureColor(WidgetTester tester, AppFeature feature) {
  final icon = tester.widget<Icon>(
    find.byKey(const Key('app-error-sheet-icon')),
  );
  expect(icon.color, feature.accentColor);

  final iconContainer = tester.widget<Container>(
    find.byKey(const Key('app-error-sheet-icon-container')),
  );
  final decoration = iconContainer.decoration! as BoxDecoration;
  expect(decoration.color, feature.iconBackgroundColor);
  expect(decoration.border, Border.all(color: feature.selectedChipColor));

  final button = tester.widget<FilledButton>(
    find.byKey(const Key('empty-input-got-it')),
  );
  expect(
    button.style?.backgroundColor?.resolve(<WidgetState>{}),
    feature.accentColor,
  );
  expect(button.style?.foregroundColor?.resolve(<WidgetState>{}), Colors.white);
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 5200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        guidanceLibraryRepositoryProvider.overrideWith(
          (ref) =>
              GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
        ),
        ...overrides,
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byWidget(screen)));
}

Future<void> _typeReplyInputAndGenerate(WidgetTester tester) async {
  await tester.enterText(
    _editableIn(const Key('reply-incoming-field')),
    'Can we move the meeting?',
  );
  await tester.tap(find.text('Generate Reply'));
  await tester.pumpAndSettle();
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('empty input', () {
    testWidgets('Reply shows the empty-input bottom sheet', (tester) async {
      _useTallView(tester);
      final repo = _FlakyReplyRepository();
      await _pumpScreen(
        tester,
        const ReplyScreen(),
        overrides: [replyRepositoryProvider.overrideWith((ref) => repo)],
      );

      await tester.tap(find.text('Generate Reply'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-input-sheet')), findsOneWidget);
      expect(find.text('Add a message first'), findsOneWidget);
      _expectErrorSheetFeatureColor(tester, AppFeature.reply);
      expect(repo.calls, 0); // no API request for empty input

      // "Got it" only dismisses the sheet.
      await tester.tap(find.byKey(const Key('empty-input-got-it')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('empty-input-sheet')), findsNothing);
      expect(repo.calls, 0);
    });

    testWidgets('Explain shows the empty-input bottom sheet', (tester) async {
      _useTallView(tester);
      await _pumpScreen(tester, const ExplainScreen());

      await tester.tap(find.byKey(const Key('explain-submit-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-input-sheet')), findsOneWidget);
      expect(find.text('Add a message first'), findsOneWidget);
      _expectErrorSheetFeatureColor(tester, AppFeature.explain);
    });

    testWidgets('Polish shows the empty-input bottom sheet', (tester) async {
      _useTallView(tester);
      await _pumpScreen(
        tester,
        const PolishScreen(),
        overrides: [
          polishRepositoryProvider.overrideWith(
            (ref) => _NeverPolishRepository(),
          ),
        ],
      );

      await tester.tap(find.text('Polish Text'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-input-sheet')), findsOneWidget);
      expect(find.text('Add a message first'), findsOneWidget);
      _expectErrorSheetFeatureColor(tester, AppFeature.polish);
    });
  });

  testWidgets('network error shows the connection-problem bottom sheet', (
    tester,
  ) async {
    _useTallView(tester);
    final repo = _FlakyReplyRepository(
      error: const ApiError(message: 'offline'), // no code → NETWORK_ERROR
    );
    // App-status re-check also fails: server truly unreachable.
    final statusService = _FakeAppStatusService(
      () => Future<AppStatus>.error(const ApiError(message: 'offline')),
    );
    await _pumpScreen(
      tester,
      const ReplyScreen(),
      overrides: [
        replyRepositoryProvider.overrideWith((ref) => repo),
        appStatusServiceProvider.overrideWithValue(statusService),
      ],
    );

    await _typeReplyInputAndGenerate(tester);

    expect(find.byKey(const Key('server-unavailable-dialog')), findsOneWidget);
    expect(find.text('Connection problem'), findsOneWidget);
  });

  testWidgets('network error Try again retries the original action', (
    tester,
  ) async {
    _useTallView(tester);
    final repo = _FlakyReplyRepository(
      error: const ApiError(message: 'offline'),
      failuresLeft: 1, // fail once, then succeed
    );
    final statusService = _FakeAppStatusService(() async => _buildStatus());
    await _pumpScreen(
      tester,
      const ReplyScreen(),
      overrides: [
        replyRepositoryProvider.overrideWith((ref) => repo),
        appStatusServiceProvider.overrideWithValue(statusService),
      ],
    );

    await _typeReplyInputAndGenerate(tester);
    expect(find.byKey(const Key('server-unavailable-dialog')), findsOneWidget);
    expect(repo.calls, 1);

    await tester.tap(find.byKey(const Key('server-unavailable-retry')));
    await tester.pumpAndSettle();

    expect(repo.calls, 2); // the same action ran again
    expect(find.text('A friendly reply'), findsOneWidget); // and succeeded
  });

  testWidgets('maintenance shows the blocking maintenance bottom sheet', (
    tester,
  ) async {
    _useTallView(tester);
    final statusService = _FakeAppStatusService(
      () async => _buildStatus(maintenance: true),
    );
    final repo = _FlakyReplyRepository();
    final container = await _pumpScreen(
      tester,
      const ReplyScreen(),
      overrides: [
        replyRepositoryProvider.overrideWith((ref) => repo),
        appStatusServiceProvider.overrideWithValue(statusService),
      ],
    );
    await container.read(appStatusControllerProvider.notifier).refresh();

    await _typeReplyInputAndGenerate(tester);

    expect(find.byKey(const Key('maintenance-dialog')), findsOneWidget);
    expect(find.text('Scheduled maintenance in progress.'), findsOneWidget);
    expect(repo.calls, 0); // request never started

    // Not dismissible: tapping the barrier above the sheet does nothing.
    await tester.tapAt(const Offset(700, 100));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('maintenance-dialog')), findsOneWidget);
  });

  testWidgets('force update shows the blocking update bottom sheet', (
    tester,
  ) async {
    _useTallView(tester);
    final statusService = _FakeAppStatusService(
      () async => _buildStatus(
        forceUpdate: true,
        minSupportedVersion: '1.0.0',
        minSupportedBuildNumber: 99,
      ),
    );
    final repo = _FlakyReplyRepository();
    final container = await _pumpScreen(
      tester,
      const ReplyScreen(),
      overrides: [
        replyRepositoryProvider.overrideWith((ref) => repo),
        appStatusServiceProvider.overrideWithValue(statusService),
        currentAppVersionProvider.overrideWithValue('1.0.0'),
        currentAppBuildNumberProvider.overrideWithValue(33),
      ],
    );
    await container.read(appStatusControllerProvider.notifier).refresh();

    await _typeReplyInputAndGenerate(tester);

    expect(find.byKey(const Key('force-update-dialog')), findsOneWidget);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.byKey(const Key('force-update-now')), findsOneWidget);
    expect(repo.calls, 0);

    // Not dismissible while the update is still required.
    await tester.tapAt(const Offset(700, 100));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('force-update-dialog')), findsOneWidget);
  });

  testWidgets('paywall error shows the credits bottom sheet', (tester) async {
    _useTallView(tester);
    final repo = _FlakyReplyRepository(
      error: const ApiError(
        message: 'no credits',
        statusCode: 402,
        code: 'PAYWALL_REQUIRED',
      ),
    );
    await _pumpScreen(
      tester,
      const ReplyScreen(),
      overrides: [replyRepositoryProvider.overrideWith((ref) => repo)],
    );

    await _typeReplyInputAndGenerate(tester);

    expect(find.byKey(const Key('credits-error-sheet')), findsOneWidget);
    expect(find.text('No credits left'), findsOneWidget);
    expect(find.byKey(const Key('credits-error-get-credits')), findsOneWidget);
    expect(find.byKey(const Key('credits-error-watch-ad')), findsOneWidget);
  });

  testWidgets('rate-limited error shows the please-wait bottom sheet', (
    tester,
  ) async {
    _useTallView(tester);
    final repo = _FlakyReplyRepository(
      error: const ApiError(
        message: 'slow down',
        statusCode: 429,
        code: 'RATE_LIMITED',
      ),
    );
    await _pumpScreen(
      tester,
      const ReplyScreen(),
      overrides: [replyRepositoryProvider.overrideWith((ref) => repo)],
    );

    await _typeReplyInputAndGenerate(tester);

    expect(find.byKey(const Key('rate-limited-sheet')), findsOneWidget);
    expect(find.text('Please wait'), findsOneWidget);
  });

  testWidgets('retryable AI error Try again re-runs the original action', (
    tester,
  ) async {
    _useTallView(tester);
    final repo = _FlakyReplyRepository(
      error: const ApiError(
        message: 'busy',
        statusCode: 503,
        code: 'MODEL_UNAVAILABLE',
      ),
      failuresLeft: 1, // fail once, then succeed
    );
    await _pumpScreen(
      tester,
      const ReplyScreen(),
      overrides: [replyRepositoryProvider.overrideWith((ref) => repo)],
    );

    await _typeReplyInputAndGenerate(tester);
    expect(find.byKey(const Key('ai-busy-sheet')), findsOneWidget);
    expect(find.text('AI is busy'), findsOneWidget);
    expect(repo.calls, 1);

    await tester.tap(find.byKey(const Key('ai-busy-try-again')));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.text('A friendly reply'), findsOneWidget);
  });
}
