import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/router/app_router.dart';
import 'package:replywise/core/widgets/app_shell.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/polish_screen.dart';
import 'package:replywise/features/reply/explain_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';
import 'package:replywise/l10n/app_localizations.dart';

/// Lifecycle behavior of the error bottom sheet: an open sheet must be
/// dismissed when the user switches bottom-navigation tabs, and dismissing it
/// must never pop the page route underneath.
///
/// Uses a minimal shell router (same ShellRoute + AppShell structure as the
/// real app router) so no auth/network providers are needed.
void main() {
  Future<GoRouter> pumpShellApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 5200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: AppRoutes.reply,
      routes: [
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: Scaffold(body: Text('HOME'))),
            ),
            GoRoute(
              path: AppRoutes.reply,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ReplyScreen()),
            ),
            GoRoute(
              path: AppRoutes.explain,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ExplainScreen()),
            ),
            GoRoute(
              path: AppRoutes.polish,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PolishScreen()),
            ),
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: Scaffold(body: Text('SETTINGS PAGE')),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          guidanceLibraryRepositoryProvider.overrideWith(
            (ref) =>
                GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> showEmptyInputSheetOnReply(WidgetTester tester) async {
    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-input-sheet')), findsOneWidget);
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    // The nav bar labels live inside AppShell's bottom bar; tapping the last
    // matching text targets the bar (pages may repeat the word elsewhere).
    await tester.tap(find.text(label).last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('switching Reply → Explain dismisses the open error sheet', (
    tester,
  ) async {
    await pumpShellApp(tester);
    await showEmptyInputSheetOnReply(tester);

    await tapTab(tester, 'Explain');

    expect(find.byKey(const Key('empty-input-sheet')), findsNothing);
    // The Explain page rendered normally.
    expect(find.text('Message to understand'), findsOneWidget);
  });

  testWidgets('switching Reply → Polish dismisses the open error sheet', (
    tester,
  ) async {
    await pumpShellApp(tester);
    await showEmptyInputSheetOnReply(tester);

    await tapTab(tester, 'Polish');

    expect(find.byKey(const Key('empty-input-sheet')), findsNothing);
    expect(find.text('Text to polish'), findsOneWidget);
  });

  testWidgets('empty input on Explain, then switching to Reply dismisses the '
      'sheet', (tester) async {
    final router = await pumpShellApp(tester);
    router.go(AppRoutes.explain);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('explain-submit-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-input-sheet')), findsOneWidget);

    await tapTab(tester, 'Reply');

    expect(find.byKey(const Key('empty-input-sheet')), findsNothing);
    expect(find.text('Message received'), findsOneWidget);
  });

  testWidgets('empty input on Polish, then switching to Settings dismisses '
      'the sheet', (tester) async {
    final router = await pumpShellApp(tester);
    router.go(AppRoutes.polish);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Polish Text'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-input-sheet')), findsOneWidget);

    await tapTab(tester, 'Settings');

    expect(find.byKey(const Key('empty-input-sheet')), findsNothing);
    expect(find.text('SETTINGS PAGE'), findsOneWidget);
  });

  testWidgets('tab tap with no open sheet still navigates and pops nothing', (
    tester,
  ) async {
    await pumpShellApp(tester);
    expect(find.text('Message received'), findsOneWidget);

    await tapTab(tester, 'Explain');

    expect(find.text('Message to understand'), findsOneWidget);
  });

  testWidgets('dismissing the sheet via its button keeps the page route', (
    tester,
  ) async {
    await pumpShellApp(tester);
    await showEmptyInputSheetOnReply(tester);

    await tester.tap(find.byKey(const Key('empty-input-got-it')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-input-sheet')), findsNothing);
    // The Reply page itself was not popped.
    expect(find.text('Message received'), findsOneWidget);
  });

  testWidgets('re-selecting the current tab with a sheet open dismisses it '
      'and keeps the page', (tester) async {
    await pumpShellApp(tester);
    await showEmptyInputSheetOnReply(tester);

    await tapTab(tester, 'Reply');

    expect(find.byKey(const Key('empty-input-sheet')), findsNothing);
    expect(find.text('Message received'), findsOneWidget);
  });
}
