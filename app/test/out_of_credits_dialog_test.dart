import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/theme/app_feature_theme.dart';
import 'package:replywise/features/ads/data/ad_reward_repository.dart';
import 'package:replywise/features/ads/data/rewarded_ad_gateway.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/presentation/out_of_credits_dialog.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/polish_screen.dart';
import 'package:replywise/features/reply/explain_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';
import 'package:replywise/l10n/app_localizations.dart';

const _outOfCredits = EntitlementState(
  isPremium: false,
  freeUsesLimit: 3,
  freeUsesUsed: 5,
  freeUsesLeft: 0,
  paidCredits: 0,
  upgradeRequired: true,
);

const _withCredits = EntitlementState(
  isPremium: false,
  freeUsesLimit: 3,
  freeUsesUsed: 5,
  freeUsesLeft: 0,
  paidCredits: 1,
  upgradeRequired: false,
);

const _premium = EntitlementState(
  isPremium: true,
  freeUsesLimit: 3,
  freeUsesUsed: 5,
  freeUsesLeft: 0,
  paidCredits: 0,
  upgradeRequired: false,
);

class _ReadyRewardedGateway implements RewardedAdGateway {
  bool ready = true;
  int showCalls = 0;

  @override
  bool get isReady => ready;

  @override
  Future<bool> load(String adUnitId) async {
    ready = true;
    return true;
  }

  @override
  Future<bool> show() async {
    showCalls++;
    ready = false;
    return true;
  }

  @override
  void dispose() {}
}

class _RecordingAdRewardRepository implements AdRewardRepository {
  int claimCalls = 0;

  @override
  Future<AdRewardResult> claim({required String idempotencyKey}) async {
    claimCalls++;
    return const AdRewardResult(credits: 1, awarded: 1, dailyRemaining: 4);
  }
}

class _RewardedUsageRepository implements UsageRepository {
  int fetchCalls = 0;

  @override
  Future<EntitlementState> fetch() async {
    fetchCalls++;
    return _withCredits;
  }
}

class _AccessHarness extends ConsumerWidget {
  const _AccessHarness({this.feature = AppFeature.reply});

  final AppFeature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('launch-generation'),
          onPressed: () => ensureGenerationAccess(
            context: context,
            ref: ref,
            feature: feature,
          ),
          child: const Text('Launch'),
        ),
      ),
    );
  }
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 5600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

MaterialApp _localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<List<Override>> _baseOverrides(bool hasAccess) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    generationAccessProvider.overrideWithValue(hasAccess),
    sharedPreferencesProvider.overrideWithValue(prefs),
    guidanceLibraryRepositoryProvider.overrideWith(
      (ref) => GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
    ),
  ];
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required bool hasAccess,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: await _baseOverrides(hasAccess),
      child: _localizedApp(screen),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _editableIn(Key fieldKey) => find.descendant(
  of: find.byKey(fieldKey),
  matching: find.byType(EditableText),
);

Future<void> _expectDialogAfterTap(
  WidgetTester tester,
  Widget screen,
  Finder action, {
  required Key inputFieldKey,
  required AppFeature feature,
}) async {
  _useTallView(tester);
  await _pumpScreen(tester, screen, hasAccess: false);
  // The empty-input sheet takes priority over the credits gate, so give the
  // screen some input first.
  await tester.enterText(_editableIn(inputFieldKey), 'Some message text.');
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('out-of-credits-dialog')), findsOneWidget);
  expect(find.text("You're out of credits"), findsOneWidget);
  _expectDialogFeatureColor(tester, feature);
}

void _expectDialogFeatureColor(WidgetTester tester, AppFeature feature) {
  final watchAd = tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(const Key('out-of-credits-watch-ad')),
      matching: find.byType(FilledButton),
    ),
  );
  expect(
    watchAd.style?.backgroundColor?.resolve(<WidgetState>{}),
    feature.accentColor,
  );
  expect(
    watchAd.style?.foregroundColor?.resolve(<WidgetState>{}),
    Colors.white,
  );

  for (final key in const [
    Key('out-of-credits-upgrade'),
    Key('out-of-credits-buy-credits'),
  ]) {
    final button = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(
      button.style?.foregroundColor?.resolve(<WidgetState>{}),
      feature.accentColor,
    );
    expect(
      button.style?.side?.resolve(<WidgetState>{}),
      BorderSide(color: feature.accentColor, width: 1.4),
    );
  }
}

Future<GoRouter> _pumpRouterHarness(
  WidgetTester tester, {
  List<Override> overrides = const [],
  Locale? locale,
  AppFeature feature = AppFeature.reply,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => _AccessHarness(feature: feature),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, _) => const Scaffold(key: Key('paywall-destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        generationAccessProvider.overrideWithValue(false),
        ...overrides,
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Reply shows dialog when out of credits', (tester) async {
    await _expectDialogAfterTap(
      tester,
      const ReplyScreen(),
      find.text('Generate Reply'),
      inputFieldKey: const Key('reply-incoming-field'),
      feature: AppFeature.reply,
    );
  });

  testWidgets('Explain shows dialog when out of credits', (tester) async {
    await _expectDialogAfterTap(
      tester,
      const ExplainScreen(),
      find.byKey(const Key('explain-submit-button')),
      inputFieldKey: const Key('explain-message-field'),
      feature: AppFeature.explain,
    );
  });

  testWidgets('Polish shows dialog when out of credits', (tester) async {
    await _expectDialogAfterTap(
      tester,
      const PolishScreen(),
      find.text('Polish Text'),
      inputFieldKey: const Key('polish-draft-field'),
      feature: AppFeature.polish,
    );
  });

  testWidgets('user with credits does not see dialog', (tester) async {
    _useTallView(tester);
    await _pumpScreen(
      tester,
      const ReplyScreen(),
      hasAccess: hasGenerationAccess(_withCredits),
    );
    await tester.tap(find.text('Generate Reply'));
    await tester.pump();
    expect(find.byKey(const Key('out-of-credits-dialog')), findsNothing);
  });

  testWidgets('premium user does not see dialog', (tester) async {
    _useTallView(tester);
    await _pumpScreen(
      tester,
      const ReplyScreen(),
      hasAccess: hasGenerationAccess(_premium),
    );
    await tester.tap(find.text('Generate Reply'));
    await tester.pump();
    expect(find.byKey(const Key('out-of-credits-dialog')), findsNothing);
  });

  testWidgets('Watch Ad triggers existing reward controller', (tester) async {
    final gateway = _ReadyRewardedGateway();
    final rewardRepository = _RecordingAdRewardRepository();
    final usageRepository = _RewardedUsageRepository();
    await _pumpRouterHarness(
      tester,
      overrides: [
        rewardedAdGatewayProvider.overrideWith((ref) => gateway),
        adRewardRepositoryProvider.overrideWith((ref) => rewardRepository),
        usageRepositoryProvider.overrideWith((ref) => usageRepository),
      ],
    );

    await tester.tap(find.byKey(const Key('launch-generation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('out-of-credits-watch-ad')));
    await tester.pumpAndSettle();

    expect(gateway.showCalls, 1);
    expect(rewardRepository.claimCalls, 1);
    expect(usageRepository.fetchCalls, 1);
    expect(find.text('Credit added. Tap Generate again.'), findsOneWidget);
  });

  testWidgets('Upgrade navigates to paywall', (tester) async {
    await _pumpRouterHarness(tester);
    await tester.tap(find.byKey(const Key('launch-generation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('out-of-credits-upgrade')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('paywall-destination')), findsOneWidget);
  });

  testWidgets('Buy Credits navigates to paywall', (tester) async {
    await _pumpRouterHarness(tester);
    await tester.tap(find.byKey(const Key('launch-generation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('out-of-credits-buy-credits')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('paywall-destination')), findsOneWidget);
  });

  testWidgets('dialog fits a small viewport with a long translation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpRouterHarness(tester, locale: const Locale('fr'));
    await tester.tap(find.byKey(const Key('launch-generation')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('out-of-credits-dialog')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('out-of-credit access predicate matches entitlement rules', () {
    expect(hasGenerationAccess(_outOfCredits), isFalse);
    expect(hasGenerationAccess(_withCredits), isTrue);
    expect(hasGenerationAccess(_premium), isTrue);
    expect(
      hasGenerationAccess(
        const EntitlementState(
          isPremium: false,
          freeUsesLimit: 3,
          freeUsesUsed: 4,
          freeUsesLeft: 1,
          paidCredits: 0,
          upgradeRequired: false,
        ),
      ),
      isTrue,
    );
  });
}
