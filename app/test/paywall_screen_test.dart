import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/features/auth/data/auth_repository.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/paywall/paywall_screen.dart';
import 'package:replywise/features/entitlement/subscription_repository.dart';

// ── Auth fakes ─────────────────────────────────────────────────────────────────

class _FakeStorage extends TokenStorage {
  _FakeStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getAppUserId() async => 'paywall-test-user';
  @override
  Future<String?> getDeviceId() async => 'paywall-test-device';
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
      const MeData(userId: 1, appUserId: 'paywall-test-user');
}

List<Override> get _authOverrides => [
  tokenStorageProvider.overrideWith((ref) => _FakeStorage()),
  authRepositoryProvider.overrideWith((ref) => _FakeAuthRepo()),
];

// ── RevenueCat gateway fake ────────────────────────────────────────────────────

class _FakeGateway implements RevenueCatGateway {
  const _FakeGateway({
    this.creditPackages = const [],
    this.failSubscription = false,
  });

  final List<CreditPackage> creditPackages;
  final bool failSubscription;

  @override
  Future<void> configure({
    required String apiKey,
    required String appUserId,
  }) async {}

  @override
  Future<SubscriptionOffer> loadAnnualOffer() async {
    if (failSubscription) {
      throw const SubscriptionException(
        'The annual subscription is currently unavailable.',
      );
    }
    return const SubscriptionOffer(
      packageIdentifier: r'$rc_annual',
      productIdentifier: 'premium_yearly:yearly',
      priceString: r'$59.99',
      hasTrial: true,
    );
  }

  @override
  Future<void> purchase(SubscriptionOffer offer) async {}

  @override
  Future<void> restore() async {}

  @override
  Future<List<CreditPackage>> loadCreditPackages() async => creditPackages;

  @override
  Future<void> purchaseCredit(CreditPackage creditPackage) async {}

  // The Paywall's silent premium reconciliation must stay a no-op in these UI
  // tests: no active entitlement → no backend call.
  @override
  Future<bool> isEntitlementActive(String entitlementId) async => false;
}

// ── Credit packages used across tests ─────────────────────────────────────────

const _allCreditPackages = [
  CreditPackage(
    packageIdentifier: 'credits_10',
    productIdentifier: 'credits_10',
    credits: 10,
    priceString: r'$1.99',
  ),
  CreditPackage(
    packageIdentifier: 'credits_50',
    productIdentifier: 'credits_50',
    credits: 50,
    priceString: r'$6.99',
  ),
  CreditPackage(
    packageIdentifier: 'credits_100',
    productIdentifier: 'credits_100',
    credits: 100,
    priceString: r'$11.99',
  ),
];

// ── Test helper ────────────────────────────────────────────────────────────────

Future<void> _pumpPaywall(
  WidgetTester tester, {
  List<CreditPackage> creditPackages = const [],
  bool failSubscription = false,
}) async {
  tester.view.physicalSize = const Size(1080, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._authOverrides,
        revenueCatGatewayProvider.overrideWith(
          (ref) => _FakeGateway(
            creditPackages: creditPackages,
            failSubscription: failSubscription,
          ),
        ),
      ],
      child: const MaterialApp(home: PaywallScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('paywall uses Premium background and has no header', (
    tester,
  ) async {
    await _pumpPaywall(tester);

    expect(find.byType(AppBar), findsNothing);
    final background = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/image/premium_page_backgroud.png',
      ),
    );
    expect(background.fit, BoxFit.fitWidth);
    expect(background.alignment, Alignment.topCenter);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('Write with confidence'), findsNothing);
    expect(
      find.text(
        'Unlimited Reply and Polish generations while Premium is active.',
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('premium-intro-spacer')), findsOneWidget);
  });

  testWidgets('paywall shows yearly premium wording', (tester) async {
    await _pumpPaywall(tester);

    expect(find.text('ReplyWise Premium'), findsWidgets);
    expect(find.text('Start 3-day Free Trial'), findsOneWidget);
    expect(find.text('3 days free'), findsOneWidget);
    expect(find.textContaining(r'$59.99/year'), findsOneWidget);
  });

  testWidgets('paywall does not contain Monthly Premium or /month wording', (
    tester,
  ) async {
    await _pumpPaywall(tester);

    expect(find.text('Monthly Premium'), findsNothing);
    expect(find.textContaining('/month'), findsNothing);
  });

  testWidgets(r'annual package $rc_annual loads and shows offer', (
    tester,
  ) async {
    await _pumpPaywall(tester);

    // Offer loaded successfully — no error message and the CTA is shown.
    expect(
      find.text('The annual subscription is currently unavailable.'),
      findsNothing,
    );
    expect(find.text('Start 3-day Free Trial'), findsOneWidget);
    expect(find.text('3 days free'), findsOneWidget);
    expect(find.textContaining(r'$59.99/year'), findsOneWidget);
  });

  testWidgets(
    'credit packages credits_10/50/100 render as Buy N Credits buttons',
    (tester) async {
      await _pumpPaywall(tester, creditPackages: _allCreditPackages);

      expect(find.textContaining('Buy 10 Credits'), findsOneWidget);
      expect(find.textContaining('Buy 50 Credits'), findsOneWidget);
      expect(find.textContaining('Buy 100 Credits'), findsOneWidget);
      expect(find.textContaining(r'$1.99'), findsOneWidget);
      expect(find.textContaining(r'$6.99'), findsOneWidget);
      expect(find.textContaining(r'$11.99'), findsOneWidget);
    },
  );

  testWidgets('unavailable credit products show friendly retry UI', (
    tester,
  ) async {
    await _pumpPaywall(tester); // empty creditPackages by default

    expect(
      find.text('Credit packages are unavailable right now.'),
      findsOneWidget,
    );
    expect(find.text('Refresh packages'), findsOneWidget);
  });

  testWidgets('failed subscription load shows Try again retry', (tester) async {
    await _pumpPaywall(tester, failSubscription: true);

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Start 3-day Free Trial'), findsNothing);
  });
}
