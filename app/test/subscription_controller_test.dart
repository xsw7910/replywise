import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/subscription_controller.dart';
import 'package:replywise/features/entitlement/subscription_repository.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';

class _DummyStorage extends TokenStorage {
  _DummyStorage() : super(const FlutterSecureStorage());
}

ApiClient _dummyClient() => ApiClient(
  rawDio: Dio(),
  tokenStorage: _DummyStorage(),
  recoverUnauthorized: () async => false,
);

const _offer = SubscriptionOffer(
  packageIdentifier: r'$rc_annual',
  productIdentifier: 'premium_yearly:yearly',
  priceString: r'$4.99',
  hasTrial: true,
);

const _premium = EntitlementState(
  isPremium: true,
  freeUsesLimit: 5,
  freeUsesUsed: 2,
  freeUsesLeft: null,
  paidCredits: 4,
  upgradeRequired: false,
);

class _FakeSubscriptionRepository implements SubscriptionRepository {
  EntitlementState purchaseResult = _premium;
  EntitlementState restoreResult = _premium;
  Object? purchaseError;
  var purchaseCalls = 0;
  var restoreCalls = 0;

  @override
  Future<SubscriptionOffer> load(String appUserId) async => _offer;

  @override
  Future<EntitlementState> purchase(
    String appUserId,
    SubscriptionOffer offer,
  ) async {
    purchaseCalls++;
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult;
  }

  @override
  Future<EntitlementState> restore(String appUserId) async {
    restoreCalls++;
    return restoreResult;
  }
}

class _FakeUsageRepository extends UsageRepository {
  _FakeUsageRepository() : super(_dummyClient());
  var fetchCalls = 0;

  @override
  Future<EntitlementState> fetch() async {
    fetchCalls++;
    return _premium;
  }
}

ProviderContainer _container(
  _FakeSubscriptionRepository subscription,
  _FakeUsageRepository usage,
) {
  final container = ProviderContainer(
    overrides: [
      subscriptionRepositoryProvider.overrideWithValue(subscription),
      usageRepositoryProvider.overrideWith((ref) => usage),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('purchase syncs premium and refreshes backend usage', () async {
    final subscription = _FakeSubscriptionRepository();
    final usage = _FakeUsageRepository();
    final container = _container(subscription, usage);
    final controller = container.read(subscriptionControllerProvider.notifier);

    await controller.load('stable-app-user');
    final success = await controller.purchase();

    expect(success, isTrue);
    expect(subscription.purchaseCalls, 1);
    expect(usage.fetchCalls, 1);
    expect(
      container.read(subscriptionControllerProvider).message,
      'Premium is active.',
    );
  });

  test(
    'restore syncs and refreshes usage without granting inactive access',
    () async {
      final subscription = _FakeSubscriptionRepository()
        ..restoreResult = const EntitlementState(
          isPremium: false,
          freeUsesLimit: 5,
          freeUsesUsed: 1,
          freeUsesLeft: 4,
          paidCredits: 0,
          upgradeRequired: false,
        );
      final usage = _FakeUsageRepository();
      final container = _container(subscription, usage);
      final controller = container.read(
        subscriptionControllerProvider.notifier,
      );

      await controller.load('stable-app-user');
      final restored = await controller.restore();

      expect(restored, isFalse);
      expect(subscription.restoreCalls, 1);
      expect(usage.fetchCalls, 1);
      expect(
        container.read(subscriptionControllerProvider).message,
        'No active subscription was found.',
      );
    },
  );

  test('cancelled purchase does not refresh or grant access', () async {
    final subscription = _FakeSubscriptionRepository()
      ..purchaseError = const SubscriptionException(
        'Purchase cancelled.',
        cancelled: true,
      );
    final usage = _FakeUsageRepository();
    final container = _container(subscription, usage);
    final controller = container.read(subscriptionControllerProvider.notifier);

    await controller.load('stable-app-user');
    final success = await controller.purchase();

    expect(success, isFalse);
    expect(usage.fetchCalls, 0);
    expect(
      container.read(subscriptionControllerProvider).error,
      'Purchase cancelled.',
    );
  });
}
