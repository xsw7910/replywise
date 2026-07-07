import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/app.dart';
import 'package:replywise/core/theme/app_colors.dart';
import 'package:replywise/features/auth/data/auth_repository.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/paywall/paywall_screen.dart';
import 'package:replywise/features/recent/domain/recent_item.dart';
import 'package:replywise/features/reply/reply_screen.dart';
import 'package:replywise/features/settings/application/dev_tools_controller.dart';
import 'package:replywise/features/entitlement/subscription_repository.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';

// ── Auth fakes ─────────────────────────────────────────────────────────────
// Overriding the underlying providers keeps tests network-free without
// needing access to the private generated base class.

class _FakeStorage extends TokenStorage {
  _FakeStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getAppUserId() async => 'test-user-id';
  @override
  Future<String?> getDeviceId() async => 'test-device-id';
  @override
  Future<String?> getAccessToken() async => 'fake.access.token';
  @override
  Future<String?> getRefreshToken() async => 'fake.refresh.token';
  @override
  Future<void> saveAppUserId(String id) async {}
  @override
  Future<void> saveDeviceId(String id) async {}
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> clearTokens() async {}
}

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(Dio());

  @override
  Future<MeData> me({required String accessToken}) async =>
      const MeData(userId: 1, appUserId: 'test-user-id');
}

List<Override> get _authOverrides => [
  tokenStorageProvider.overrideWith((ref) => _FakeStorage()),
  authRepositoryProvider.overrideWith((ref) => _FakeAuthRepo()),
];

class _FakeSubscriptionRepo implements SubscriptionRepository {
  @override
  Future<SubscriptionOffer> load(String appUserId) async =>
      const SubscriptionOffer(
        packageIdentifier: r'$rc_annual',
        productIdentifier: 'premium_yearly:yearly',
        priceString: r'$4.99',
        hasTrial: true,
      );

  @override
  Future<EntitlementState> purchase(
    String appUserId,
    SubscriptionOffer offer,
  ) async => const EntitlementState(
    isPremium: true,
    freeUsesLimit: 5,
    freeUsesUsed: 0,
    freeUsesLeft: null,
    paidCredits: 0,
    upgradeRequired: false,
  );

  @override
  Future<EntitlementState> restore(String appUserId) => purchase(
    appUserId,
    const SubscriptionOffer(
      packageIdentifier: r'$rc_annual',
      productIdentifier: 'premium_yearly:yearly',
      priceString: r'$4.99',
      hasTrial: true,
    ),
  );

  @override
  Future<EntitlementState?> syncActivePremiumSilently(String appUserId) async =>
      null;
}

// ── Guidance fake ──────────────────────────────────────────────────────────

late SharedPreferences _prefs;

Future<List<Override>> _guidanceOverrides() async => [
  sharedPreferencesProvider.overrideWithValue(_prefs),
  guidanceLibraryRepositoryProvider.overrideWith(
    (ref) => GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
  ),
];

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpReplyWiseApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._authOverrides,
          ...await _guidanceOverrides(),
          // Keep the startup/Settings silent premium reconciliation off the
          // real RevenueCat SDK: the fake reports no active entitlement.
          subscriptionRepositoryProvider.overrideWithValue(
            _FakeSubscriptionRepo(),
          ),
        ],
        child: const ReplyWiseApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapHomeCard(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('app defaults to Home and exposes main navigation', (
    WidgetTester tester,
  ) async {
    await pumpReplyWiseApp(tester);

    expect(find.text('ReplyWise'), findsOneWidget);
    expect(find.text('Your AI reply assistant'), findsOneWidget);
    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Reply'), findsAtLeastNWidgets(1));
    expect(find.text('Explain'), findsAtLeastNWidgets(1));
    expect(find.text('Polish'), findsAtLeastNWidgets(1));
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Polish').last);
    await tester.pumpAndSettle();

    expect(find.text('Text to polish'), findsOneWidget);
  });

  testWidgets('Home Reply feature card opens Reply page', (tester) async {
    await pumpReplyWiseApp(tester);

    await tapHomeCard(tester, const Key('home-feature-reply'));

    // The Reply page header no longer carries the subtitle; assert on a
    // stable element of the Reply page body instead.
    expect(find.text('Message received'), findsOneWidget);
  });

  testWidgets('Home Explain feature card opens Explain page', (tester) async {
    await pumpReplyWiseApp(tester);

    await tapHomeCard(tester, const Key('home-feature-explain'));

    expect(find.text('Message to understand'), findsOneWidget);
  });

  testWidgets('Home Polish feature card opens Polish page', (tester) async {
    await pumpReplyWiseApp(tester);

    await tapHomeCard(tester, const Key('home-feature-polish'));

    expect(find.text('Text to polish'), findsOneWidget);
  });

  testWidgets('Home Guidance Library feature card opens library page', (
    tester,
  ) async {
    await pumpReplyWiseApp(tester);

    await tapHomeCard(tester, const Key('home-feature-guidance'));

    expect(find.text('Built-in'), findsOneWidget);
  });

  testWidgets('Home Recent shows the empty state when there is no history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpReplyWiseApp(tester);

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Create your first reply'), findsOneWidget);
    final emptyIllustration = tester.widget<Image>(
      find.byKey(const Key('home-recent-empty-illustration')),
    );
    expect(emptyIllustration.width, 84);
    expect(emptyIllustration.height, 62);
    expect(find.text('View all'), findsNothing);
  });

  testWidgets('Home Recent shows the latest stored items', (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final items = [
      RecentItem(
        id: '1',
        type: RecentType.reply,
        title: 'Reply to: Late delivery',
        inputText: 'Where is my order?',
        outputText: 'It ships today.',
        createdAt: now,
      ),
      RecentItem(
        id: '2',
        type: RecentType.polish,
        title: 'Polish: My landlord email',
        inputText: 'hey can i pay rent late',
        outputText: 'Polished text.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
    SharedPreferences.setMockInitialValues({
      'replywise_recent_items_v1': jsonEncode(
        items.map((e) => e.toJson()).toList(),
      ),
    });
    _prefs = await SharedPreferences.getInstance();

    await pumpReplyWiseApp(tester);

    expect(find.text('Reply to: Late delivery'), findsOneWidget);
    expect(find.text('Polish: My landlord email'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsNothing);
    expect(
      find.byKey(const Key('home-recent-populated-illustration')),
      findsNothing,
    );
    final recentCardContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const Key('home-recent-populated-card')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (recentCardContainer.decoration as BoxDecoration).color,
      AppColors.recentCardBackground,
    );
  });

  testWidgets('Home tip uses a small right-side illustration', (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpReplyWiseApp(tester);

    final illustration = tester.widget<Image>(
      find.byKey(const Key('home-tip-illustration')),
    );
    expect(illustration.width, 88);
    expect(illustration.height, 66);
  });

  testWidgets('Create your first reply opens the Reply page', (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpReplyWiseApp(tester);

    await tester.tap(find.text('Create your first reply'));
    await tester.pumpAndSettle();

    expect(find.text('Message received'), findsOneWidget);
  });

  testWidgets('Developer Testing panel is visible in dev Settings', (
    tester,
  ) async {
    await pumpReplyWiseApp(tester);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Developer Testing'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Developer Testing'), findsOneWidget);
    expect(find.text('Reset free usage'), findsOneWidget);
    expect(find.text('Add 10 credits'), findsOneWidget);
    expect(find.text('Simulate Premium On'), findsOneWidget);
  });

  testWidgets('Developer Testing panel can be hidden for production', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._authOverrides,
          ...await _guidanceOverrides(),
          devToolsPanelVisibleProvider.overrideWithValue(false),
          subscriptionRepositoryProvider.overrideWithValue(
            _FakeSubscriptionRepo(),
          ),
        ],
        child: const ReplyWiseApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Developer Testing'), findsNothing);
    expect(find.text('Reset free usage'), findsNothing);
  });

  testWidgets('Settings redesign fits a phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpReplyWiseApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Credits'), findsOneWidget);
    expect(
      find.text('Manage your account and app preferences'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settings-credits-card')), findsOneWidget);
    expect(find.byKey(const Key('settings-options-group')), findsOneWidget);
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guidance chip fills the Reply guidance field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await _guidanceOverrides(),
        child: const MaterialApp(home: ReplyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Accept'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pump();

    final guidanceField = find.descendant(
      of: find.byKey(const Key('reply-guidance-field')),
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(guidanceField);
    // Chip inserts the guidance instruction, not the label.
    expect(field.controller?.text, 'Accept the request politely.');
  });

  testWidgets('paywall shows verified annual subscription terms', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._authOverrides,
          ...await _guidanceOverrides(),
          subscriptionRepositoryProvider.overrideWithValue(
            _FakeSubscriptionRepo(),
          ),
        ],
        child: const MaterialApp(home: PaywallScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start 3-day Free Trial'), findsOneWidget);
    expect(find.textContaining(r'$4.99/year'), findsOneWidget);

    // Scroll to reveal items below the Buy Credits card.
    await tester.scrollUntilVisible(
      find.text('Restore Premium subscription'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Restore Premium subscription'), findsOneWidget);
  });
}
