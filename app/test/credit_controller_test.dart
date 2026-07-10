import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/credit_controller.dart';
import 'package:replywise/features/entitlement/credit_repository.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/subscription_repository.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';

// ── Infrastructure fakes ─────────────────────────────────────────────────────

class _DummyStorage extends TokenStorage {
  _DummyStorage() : super(const FlutterSecureStorage());
}

ApiClient _dummyClient() => ApiClient(
  rawDio: Dio(),
  tokenStorage: _DummyStorage(),
  recoverUnauthorized: () async => false,
);

// ── Fake repositories ─────────────────────────────────────────────────────────

class _FakeCreditRepo extends CreditRepository {
  _FakeCreditRepo({this.error}) : super(_dummyClient());

  final ApiError? error;
  int callCount = 0;

  @override
  Future<CreditSyncResult> sync() async {
    callCount++;
    if (error != null) throw error!;
    return const CreditSyncResult(
      isPremium: false,
      freeUsesLeft: 4,
      paidCredits: 10,
      upgradeRequired: false,
      grantedThisSync: 10,
    );
  }
}

class _FakeUsageRepo extends UsageRepository {
  _FakeUsageRepo() : super(_dummyClient());
  int fetchCount = 0;

  @override
  Future<EntitlementState> fetch() async {
    fetchCount++;
    return const EntitlementState(
      isPremium: false,
      freeUsesLimit: 3,
      freeUsesUsed: 1,
      freeUsesLeft: 4,
      paidCredits: 10,
      upgradeRequired: false,
    );
  }
}

// ── Fake gateway ──────────────────────────────────────────────────────────────

class _FakeGateway implements RevenueCatGateway {
  _FakeGateway({
    this.creditPackages = const [],
    this.loadError,
    this.purchaseError,
  });

  final List<CreditPackage> creditPackages;
  final Object? loadError;
  final Object? purchaseError;
  int loadCallCount = 0;
  int purchaseCallCount = 0;

  @override
  Future<void> configure({
    required String apiKey,
    required String appUserId,
  }) async {}

  @override
  Future<SubscriptionOffer> loadAnnualOffer() => throw UnimplementedError();

  @override
  Future<void> purchase(SubscriptionOffer offer) => throw UnimplementedError();

  @override
  Future<void> restore() => throw UnimplementedError();

  @override
  Future<List<CreditPackage>> loadCreditPackages() async {
    loadCallCount++;
    if (loadError != null) throw loadError!;
    return creditPackages;
  }

  @override
  Future<void> purchaseCredit(CreditPackage package) async {
    purchaseCallCount++;
    if (purchaseError != null) throw purchaseError!;
  }

  @override
  Future<bool> isEntitlementActive(String entitlementId) async => false;
}

// ── Container helpers ─────────────────────────────────────────────────────────

ProviderContainer _container({
  required CreditRepository creditRepo,
  _FakeUsageRepo? usageRepo,
}) {
  final c = ProviderContainer(
    overrides: [
      creditRepositoryProvider.overrideWith((ref) => creditRepo),
      if (usageRepo != null)
        usageRepositoryProvider.overrideWith((ref) => usageRepo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

ProviderContainer _containerWithGateway(
  _FakeGateway gateway, {
  CreditRepository? creditRepo,
  _FakeUsageRepo? usageRepo,
}) {
  final c = ProviderContainer(
    overrides: [
      revenueCatGatewayProvider.overrideWith((ref) => gateway),
      if (creditRepo != null)
        creditRepositoryProvider.overrideWith((ref) => creditRepo),
      if (usageRepo != null)
        usageRepositoryProvider.overrideWith((ref) => usageRepo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const creditPackages = [
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

  group('CreditController.loadPackages', () {
    test('populates state from gateway credit products', () async {
      final gateway = _FakeGateway(creditPackages: creditPackages);
      final c = _containerWithGateway(gateway);

      await c.read(creditControllerProvider.notifier).loadPackages('user-1');

      expect(c.read(creditControllerProvider).packages, creditPackages);
      expect(c.read(creditControllerProvider).error, isNull);
      expect(gateway.loadCallCount, 1);
    });

    test('second call is ignored when packages are already loaded', () async {
      final gateway = _FakeGateway(creditPackages: creditPackages);
      final c = _containerWithGateway(gateway);
      final notifier = c.read(creditControllerProvider.notifier);

      await notifier.loadPackages('user-1');
      await notifier.loadPackages('user-1');

      expect(gateway.loadCallCount, 1);
    });

    test('sets error message when gateway throws', () async {
      final gateway = _FakeGateway(
        loadError: const SubscriptionException(
          'The annual subscription is currently unavailable.',
        ),
      );
      final c = _containerWithGateway(gateway);

      await c.read(creditControllerProvider.notifier).loadPackages('user-1');

      expect(c.read(creditControllerProvider).packages, isEmpty);
      expect(
        c.read(creditControllerProvider).error,
        'The annual subscription is currently unavailable.',
      );
    });
  });

  group('CreditController.purchase', () {
    test('calls purchaseCredit, syncs backend, and refreshes usage', () async {
      final gateway = _FakeGateway(creditPackages: creditPackages);
      final creditRepo = _FakeCreditRepo();
      final usageRepo = _FakeUsageRepo();
      final c = _containerWithGateway(
        gateway,
        creditRepo: creditRepo,
        usageRepo: usageRepo,
      );
      await c.read(creditControllerProvider.notifier).loadPackages('user-1');

      final success = await c
          .read(creditControllerProvider.notifier)
          .purchase('user-1', creditPackages.first);

      expect(success, isTrue);
      expect(gateway.purchaseCallCount, 1);
      expect(creditRepo.callCount, 1);
      expect(usageRepo.fetchCount, 1);
      expect(c.read(creditControllerProvider).error, isNull);
    });

    test('cancelled purchase returns false and exposes no error', () async {
      final gateway = _FakeGateway(
        creditPackages: creditPackages,
        purchaseError: const SubscriptionException(
          'Purchase cancelled.',
          cancelled: true,
        ),
      );
      final c = _containerWithGateway(gateway);
      await c.read(creditControllerProvider.notifier).loadPackages('user-1');

      final success = await c
          .read(creditControllerProvider.notifier)
          .purchase('user-1', creditPackages.first);

      expect(success, isFalse);
      expect(c.read(creditControllerProvider).error, isNull);
    });

    test('non-cancelled purchase error returns false and sets error', () async {
      final gateway = _FakeGateway(
        creditPackages: creditPackages,
        purchaseError: const SubscriptionException(
          'Purchase failed. Please try again.',
        ),
      );
      final c = _containerWithGateway(gateway);
      await c.read(creditControllerProvider.notifier).loadPackages('user-1');

      final success = await c
          .read(creditControllerProvider.notifier)
          .purchase('user-1', creditPackages.first);

      expect(success, isFalse);
      expect(
        c.read(creditControllerProvider).error,
        'Purchase failed. Please try again.',
      );
    });
  });

  group('CreditController.syncCredits', () {
    test('calls sync and refreshes usage on success', () async {
      final creditRepo = _FakeCreditRepo();
      final usageRepo = _FakeUsageRepo();
      final c = _container(creditRepo: creditRepo, usageRepo: usageRepo);

      await c.read(creditControllerProvider.notifier).syncCredits();

      expect(creditRepo.callCount, 1);
      expect(usageRepo.fetchCount, 1);
    });

    test('swallows errors silently — does not throw or change state', () async {
      final creditRepo = _FakeCreditRepo(
        error: const ApiError(
          code: 'CREDIT_SYNC_FAILED',
          message: 'Backend down.',
          statusCode: 503,
        ),
      );
      final usageRepo = _FakeUsageRepo();
      final c = _container(creditRepo: creditRepo, usageRepo: usageRepo);

      await expectLater(
        c.read(creditControllerProvider.notifier).syncCredits(),
        completes,
      );

      expect(usageRepo.fetchCount, 0);
      expect(c.read(creditControllerProvider).error, isNull);
    });

    test('does not call usage refresh when sync throws', () async {
      final creditRepo = _FakeCreditRepo(
        error: const ApiError(
          code: 'NETWORK_ERROR',
          message: 'No connection.',
          statusCode: 0,
        ),
      );
      final usageRepo = _FakeUsageRepo();
      final c = _container(creditRepo: creditRepo, usageRepo: usageRepo);

      await c.read(creditControllerProvider.notifier).syncCredits();

      expect(usageRepo.fetchCount, 0);
    });
  });
}
