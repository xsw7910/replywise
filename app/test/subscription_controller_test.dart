import 'dart:async';

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
  freeUsesLimit: 3,
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

  // Silent sync: null => no active premium (backend not called).
  EntitlementState? silentResult;
  Object? silentError;
  var silentCalls = 0;
  Completer<void>? silentGate;

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

  @override
  Future<EntitlementState?> syncActivePremiumSilently(String appUserId) async {
    silentCalls++;
    if (silentGate != null) await silentGate!.future;
    if (silentError != null) throw silentError!;
    return silentResult;
  }
}

/// Fake gateway used for repository-level silent-sync tests. Only
/// [isEntitlementActive] and [configure] are exercised.
class _FakeGateway implements RevenueCatGateway {
  _FakeGateway(this.active);

  final bool active;

  @override
  Future<void> configure({
    required String apiKey,
    required String appUserId,
  }) async {}

  @override
  Future<bool> isEntitlementActive(String entitlementId) async => active;

  @override
  Future<SubscriptionOffer> loadAnnualOffer() => throw UnimplementedError();
  @override
  Future<void> purchase(SubscriptionOffer offer) => throw UnimplementedError();
  @override
  Future<void> restore() => throw UnimplementedError();
  @override
  Future<List<CreditPackage>> loadCreditPackages() =>
      throw UnimplementedError();
  @override
  Future<void> purchaseCredit(CreditPackage package) =>
      throw UnimplementedError();
}

/// ApiClient spy that records POST paths and returns canned JSON without any
/// network. If the repository calls the backend when it should not, the
/// recorded [postPaths] make it visible.
class _SpyApiClient extends ApiClient {
  _SpyApiClient(this._response)
    : super(
        rawDio: Dio(),
        tokenStorage: _DummyStorage(),
        recoverUnauthorized: _noRecovery,
      );

  final Map<String, dynamic> _response;
  final List<String> postPaths = [];

  static Future<bool> _noRecovery() async => false;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    postPaths.add(path);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: _response as T,
    );
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
          freeUsesLimit: 3,
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

  // ── Silent premium reconciliation (reinstall recovery) ──────────────────────

  group('syncActivePremiumSilently (controller)', () {
    test('active premium triggers a usage refresh', () async {
      final subscription = _FakeSubscriptionRepository()
        ..silentResult = _premium;
      final usage = _FakeUsageRepository();
      final container = _container(subscription, usage);

      await container
          .read(subscriptionControllerProvider.notifier)
          .syncActivePremiumSilently('reinstalled-user');

      expect(subscription.silentCalls, 1);
      expect(usage.fetchCalls, 1); // /v1/me refreshed → UI shows premium
    });

    test('no active premium does not refresh usage', () async {
      final subscription = _FakeSubscriptionRepository()..silentResult = null;
      final usage = _FakeUsageRepository();
      final container = _container(subscription, usage);

      await container
          .read(subscriptionControllerProvider.notifier)
          .syncActivePremiumSilently('user');

      expect(subscription.silentCalls, 1);
      expect(usage.fetchCalls, 0);
    });

    test('an error is swallowed and never downgrades premium', () async {
      final subscription = _FakeSubscriptionRepository()
        ..silentError = Exception('network down');
      final usage = _FakeUsageRepository();
      final container = _container(subscription, usage);
      final controller = container.read(
        subscriptionControllerProvider.notifier,
      );

      await expectLater(
        controller.syncActivePremiumSilently('user'),
        completes,
      );

      // No refresh on failure → existing premium/usage state is left untouched,
      // and nothing is surfaced to the Paywall UI.
      expect(usage.fetchCalls, 0);
      expect(container.read(subscriptionControllerProvider).error, isNull);
    });

    test('concurrent calls share one in-flight run', () async {
      final gate = Completer<void>();
      final subscription = _FakeSubscriptionRepository()
        ..silentResult = _premium
        ..silentGate = gate;
      final usage = _FakeUsageRepository();
      final container = _container(subscription, usage);
      final controller = container.read(
        subscriptionControllerProvider.notifier,
      );

      final first = controller.syncActivePremiumSilently('user');
      final second = controller.syncActivePremiumSilently('user');
      gate.complete();
      await Future.wait([first, second]);

      expect(subscription.silentCalls, 1); // deduped
      expect(usage.fetchCalls, 1);
    });
  });

  group('syncActivePremiumSilently (repository gating)', () {
    test('calls the backend only when the entitlement is active', () async {
      final client = _SpyApiClient(const {
        'isPremium': true,
        'freeUsesLimit': 3,
        'freeUsesUsed': 0,
        'freeUsesLeft': null,
        'paidCredits': 0,
        'upgradeRequired': false,
      });
      final repo = RevenueCatSubscriptionRepository(_FakeGateway(true), client);

      final result = await repo.syncActivePremiumSilently('user');

      expect(client.postPaths, ['/v1/entitlement/sync']);
      expect(result?.isPremium, isTrue);
    });

    test('skips the backend when there is no active entitlement', () async {
      final client = _SpyApiClient(const {});
      final repo = RevenueCatSubscriptionRepository(
        _FakeGateway(false),
        client,
      );

      final result = await repo.syncActivePremiumSilently('user');

      expect(
        client.postPaths,
        isEmpty,
      ); // getCustomerInfo only, no backend call
      expect(result, isNull);
    });
  });
}
