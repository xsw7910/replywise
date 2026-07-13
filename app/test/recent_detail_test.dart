import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/router/app_router.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/application/pending_polish_input_provider.dart';
import 'package:replywise/features/polish/polish_screen.dart';
import 'package:replywise/features/recent/domain/recent_item.dart';
import 'package:replywise/features/recent/presentation/history_screen.dart';
import 'package:replywise/features/recent/presentation/recent_detail_screen.dart';
import 'package:replywise/features/reply/application/pending_explain_input_provider.dart';
import 'package:replywise/features/reply/application/pending_reply_input_provider.dart';
import 'package:replywise/features/reply/explain_screen.dart';
import 'package:replywise/l10n/app_localizations.dart';

RecentItem _item({
  String id = '1',
  RecentType type = RecentType.reply,
  String input = 'Where is my order?',
  String output = 'It ships today.',
  String? guidance,
  String? tone,
  String? formalText,
  String? casualText,
  String? conciseText,
}) => RecentItem(
  id: id,
  type: type,
  title: buildRecentTitle(type, input),
  inputText: input,
  outputText: output,
  createdAt: DateTime(2026, 7, 4, 14, 30),
  guidance: guidance,
  tone: tone,
  formalText: formalText,
  casualText: casualText,
  conciseText: conciseText,
);

Widget _localized(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

/// A stub destination route that echoes the value handed to a pending-input
/// provider, so a test can assert both the navigation target and the handoff.
class _Echo extends ConsumerWidget {
  const _Echo(this.provider);
  final ProviderListenable<String?> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Scaffold(body: Text('echo:${ref.watch(provider) ?? ''}'));
}

void main() {
  testWidgets('detail shows the saved input, result, and metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localized(
        RecentDetailScreen(
          id: '1',
          initialItem: _item(guidance: 'Be warm', tone: 'Friendly'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Where is my order?'), findsOneWidget); // input
    expect(find.text('It ships today.'), findsOneWidget); // result
    expect(find.text('Be warm'), findsOneWidget); // guidance metadata
    expect(find.text('Friendly'), findsOneWidget); // tone metadata
    expect(find.text('Use again'), findsOneWidget);
  });

  testWidgets('copy button copies the result and confirms with a snackbar', (
    tester,
  ) async {
    final copied = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      _localized(RecentDetailScreen(id: '1', initialItem: _item())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('result-copy-button')));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect((copied.single.arguments as Map)['text'], 'It ships today.');
    expect(find.text('Copied'), findsOneWidget); // snackbar confirmation
  });

  testWidgets('Reply detail displays all three saved versions', (tester) async {
    await tester.pumpWidget(
      _localized(
        RecentDetailScreen(
          id: 'three',
          initialItem: _item(
            output: 'Formal reply',
            formalText: 'Formal reply',
            casualText: 'Casual reply',
            conciseText: 'Concise reply',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Formal reply'), findsOneWidget);
    expect(find.text('Casual reply'), findsOneWidget);
    expect(find.text('Concise reply'), findsOneWidget);
    expect(find.byKey(const Key('result-copy-button')), findsNWidgets(3));
    expect(find.byTooltip('Share reply'), findsNWidgets(3));
  });

  testWidgets('Polish and Explain details retain single-output layout', (
    tester,
  ) async {
    for (final type in [RecentType.polish, RecentType.explain]) {
      await tester.pumpWidget(
        _localized(
          RecentDetailScreen(
            id: type.name,
            initialItem: _item(type: type, output: '${type.name} output'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('${type.name} output'), findsOneWidget);
      expect(find.text('Copy result'), findsOneWidget);
      expect(find.byTooltip('Share reply'), findsNothing);
    }
  });

  testWidgets('tapping a recent item opens its detail page', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final item = _item(id: 'abc');
    SharedPreferences.setMockInitialValues({
      'replywise_recent_items_v1': jsonEncode([item.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: AppRoutes.history,
      routes: [
        GoRoute(
          path: AppRoutes.history,
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.recentDetail}/:id',
          builder: (context, state) {
            final extra = state.extra;
            return RecentDetailScreen(
              id: state.pathParameters['id']!,
              initialItem: extra is RecentItem ? extra : null,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // History shows the row (title), not the result.
    expect(find.text(item.title), findsOneWidget);
    expect(find.text('It ships today.'), findsNothing);

    await tester.tap(find.text(item.title));
    await tester.pumpAndSettle();

    // The detail page is now visible with the saved result.
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('It ships today.'), findsOneWidget);
  });

  group(
    'Use again navigates to the feature page with the input handed off',
    () {
      Future<void> pumpHandoff(WidgetTester tester, RecentItem item) async {
        final router = GoRouter(
          initialLocation: '${AppRoutes.recentDetail}/${item.id}',
          routes: [
            GoRoute(
              path: '${AppRoutes.recentDetail}/:id',
              builder: (context, state) =>
                  RecentDetailScreen(id: item.id, initialItem: item),
            ),
            GoRoute(
              path: AppRoutes.reply,
              builder: (_, _) => _Echo(pendingReplyInputProvider),
            ),
            GoRoute(
              path: AppRoutes.polish,
              builder: (_, _) => _Echo(pendingPolishInputProvider),
            ),
            GoRoute(
              path: AppRoutes.explain,
              builder: (_, _) => _Echo(pendingExplainInputProvider),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      for (final type in RecentType.values) {
        testWidgets('for a ${type.name} item', (tester) async {
          final item = _item(
            id: type.name,
            type: type,
            input: 'saved ${type.name} input',
          );
          await pumpHandoff(tester, item);

          await tester.tap(find.byKey(const Key('recent-detail-use-again')));
          await tester.pumpAndSettle();

          // Landed on the matching feature route with the input handed off.
          expect(find.text('echo:saved ${type.name} input'), findsOneWidget);
        });
      }
    },
  );

  testWidgets('Polish screen prefills its draft from the pending input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
          pendingPolishInputProvider.overrideWith(_PresetPolish.new),
        ],
        child: _localized(const PolishScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('draft to polish again'), findsOneWidget);
  });

  testWidgets('Explain screen prefills its message from the pending input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pendingExplainInputProvider.overrideWith(_PresetExplain.new),
        ],
        child: _localized(const ExplainScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('message to explain again'), findsOneWidget);
  });
}

class _PresetPolish extends PendingPolishInputController {
  @override
  String? build() => 'draft to polish again';
}

class _PresetExplain extends PendingExplainInputController {
  @override
  String? build() => 'message to explain again';
}
