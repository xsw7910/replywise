import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import 'entitlement_state.dart';

class SubscriptionOffer {
  const SubscriptionOffer({
    required this.packageIdentifier,
    required this.productIdentifier,
    required this.priceString,
    this.hasTrial = false,
  });

  final String packageIdentifier;
  final String productIdentifier;
  final String priceString;
  final bool hasTrial;
}

class SubscriptionException implements Exception {
  const SubscriptionException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
}

class CreditPackage {
  const CreditPackage({
    required this.packageIdentifier,
    required this.productIdentifier,
    required this.credits,
    required this.priceString,
  });

  final String packageIdentifier;
  final String productIdentifier;
  final int credits;
  final String priceString;
}

abstract class RevenueCatGateway {
  Future<void> configure({required String apiKey, required String appUserId});
  Future<SubscriptionOffer> loadAnnualOffer();
  Future<void> purchase(SubscriptionOffer offer);
  Future<void> restore();
  Future<List<CreditPackage>> loadCreditPackages();
  Future<void> purchaseCredit(CreditPackage package);

  /// Silent, read-only check of RevenueCat's current CustomerInfo. Returns true
  /// when [entitlementId] is active. Uses getCustomerInfo() only — it never
  /// starts a purchase, shows the store UI, or calls restorePurchases.
  Future<bool> isEntitlementActive(String entitlementId);
}

class SdkRevenueCatGateway implements RevenueCatGateway {
  String? _configuredAppUserId;
  Future<void>? _initializationFuture;
  Future<void>? _identityFuture;
  final Map<String, Package> _packages = {};
  final Map<String, StoreProduct> _creditProducts = {};

  @override
  Future<void> configure({
    required String apiKey,
    required String appUserId,
  }) async {
    if (apiKey.isEmpty) {
      throw const SubscriptionException(
        'Subscriptions are not configured for this build.',
      );
    }
    if (_configuredAppUserId == appUserId && _identityFuture == null) return;

    final initial = _initializationFuture;
    if (initial != null) {
      await initial;
      await _logInSingleFlight(appUserId);
      return;
    }

    // Store the future before awaiting it so subscription and credit package
    // loaders share one Purchases.configure call for the app session.
    final future = _configureOnce(apiKey, appUserId);
    _initializationFuture = future;
    await future;
  }

  Future<void> _configureOnce(String apiKey, String appUserId) async {
    final configuration = PurchasesConfiguration(apiKey)..appUserID = appUserId;
    await Purchases.configure(configuration);
    _configuredAppUserId = appUserId;
  }

  Future<void> _logInSingleFlight(String appUserId) async {
    while (true) {
      final existing = _identityFuture;
      if (existing != null) {
        await existing;
        continue;
      }
      if (_configuredAppUserId == appUserId) return;
      final future = _logIn(appUserId);
      _identityFuture = future;
      try {
        await future;
      } finally {
        if (identical(_identityFuture, future)) {
          _identityFuture = null;
        }
      }
    }
  }

  Future<void> _logIn(String appUserId) async {
    await Purchases.logIn(appUserId);
    _configuredAppUserId = appUserId;
  }

  @override
  Future<SubscriptionOffer> loadAnnualOffer() async {
    final offerings = await Purchases.getOfferings();
    final offering = offerings.getOffering('default');
    final package = offering?.getPackage(r'$rc_annual') ?? offering?.annual;
    if (package == null) {
      throw const SubscriptionException(
        'The annual subscription is currently unavailable.',
      );
    }
    _packages[package.identifier] = package;
    return SubscriptionOffer(
      packageIdentifier: package.identifier,
      productIdentifier: package.storeProduct.identifier,
      priceString: package.storeProduct.priceString,
      hasTrial: package.storeProduct.introductoryPrice != null,
    );
  }

  @override
  Future<void> purchase(SubscriptionOffer offer) async {
    final package = _packages[offer.packageIdentifier];
    if (package == null) {
      throw const SubscriptionException('Reload the subscription offer.');
    }
    try {
      await Purchases.purchase(PurchaseParams.package(package));
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const SubscriptionException(
          'Purchase cancelled.',
          cancelled: true,
        );
      }
      throw const SubscriptionException('Purchase failed. Please try again.');
    }
  }

  @override
  Future<void> restore() async {
    try {
      await Purchases.restorePurchases();
    } on PlatformException {
      throw const SubscriptionException('Restore failed. Please try again.');
    }
  }

  @override
  Future<bool> isEntitlementActive(String entitlementId) async {
    // getCustomerInfo() reads the current (already-synced) entitlement state.
    // Configuring the SDK on a fresh install auto-syncs active Google Play
    // purchases to the current app user, so this reflects a reinstalled user's
    // live subscription without a purchase or restore flow.
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(entitlementId);
  }

  static const _creditsByProductId = {
    'credits_10': 10,
    'credits_50': 50,
    'credits_100': 100,
  };

  @override
  Future<List<CreditPackage>> loadCreditPackages() async {
    final productIds = _creditsByProductId.keys.toList();
    final storeProducts = await Purchases.getProducts(
      productIds,
      productCategory: ProductCategory.nonSubscription,
    );
    final result = <CreditPackage>[];
    for (final product in storeProducts) {
      final credits = _creditsByProductId[product.identifier];
      if (credits == null) continue;
      _creditProducts[product.identifier] = product;
      result.add(
        CreditPackage(
          packageIdentifier: product.identifier,
          productIdentifier: product.identifier,
          credits: credits,
          priceString: product.priceString,
        ),
      );
    }
    result.sort((a, b) => a.credits.compareTo(b.credits));
    return result;
  }

  @override
  Future<void> purchaseCredit(CreditPackage creditPackage) async {
    final storeProduct = _creditProducts[creditPackage.productIdentifier];
    if (storeProduct == null) {
      throw const SubscriptionException(
        'Reload credit packages and try again.',
      );
    }
    try {
      await Purchases.purchase(PurchaseParams.storeProduct(storeProduct));
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const SubscriptionException(
          'Purchase cancelled.',
          cancelled: true,
        );
      }
      throw const SubscriptionException('Purchase failed. Please try again.');
    }
  }
}

abstract class SubscriptionRepository {
  Future<SubscriptionOffer> load(String appUserId);
  Future<EntitlementState> purchase(String appUserId, SubscriptionOffer offer);
  Future<EntitlementState> restore(String appUserId);

  /// Silently reconciles an already-active premium entitlement.
  ///
  /// Configures RevenueCat, checks CustomerInfo via getCustomerInfo(), and only
  /// if premium is active syncs it with the backend, returning the fresh
  /// [EntitlementState]. Returns null when there is no active premium (the
  /// backend is not called). Never starts a purchase or restore flow.
  Future<EntitlementState?> syncActivePremiumSilently(String appUserId);
}

class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  const RevenueCatSubscriptionRepository(this._gateway, this._client);

  final RevenueCatGateway _gateway;
  final ApiClient _client;

  Future<void> _configure(String appUserId) => _gateway.configure(
    apiKey: AppConfig.revenueCatAndroidApiKey,
    appUserId: appUserId,
  );

  @override
  Future<SubscriptionOffer> load(String appUserId) async {
    await _configure(appUserId);
    return _gateway.loadAnnualOffer();
  }

  @override
  Future<EntitlementState> purchase(
    String appUserId,
    SubscriptionOffer offer,
  ) async {
    await _configure(appUserId);
    await _gateway.purchase(offer);
    return _sync();
  }

  @override
  Future<EntitlementState> restore(String appUserId) async {
    await _configure(appUserId);
    await _gateway.restore();
    return _sync();
  }

  @override
  Future<EntitlementState?> syncActivePremiumSilently(String appUserId) async {
    await _configure(appUserId);
    // Read-only CustomerInfo check — no purchase, no restore, no store UI.
    final active = await _gateway.isEntitlementActive(AppConfig.entitlementId);
    if (!active) return null; // No premium → do not touch the backend.
    return _sync();
  }

  Future<EntitlementState> _sync() async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/v1/entitlement/sync',
      );
      return EntitlementState.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(
        error,
        fallback: 'Unable to verify subscription status.',
      );
    }
  }
}

final revenueCatGatewayProvider = Provider<RevenueCatGateway>(
  (ref) => SdkRevenueCatGateway(),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => RevenueCatSubscriptionRepository(
    ref.watch(revenueCatGatewayProvider),
    ref.watch(apiClientProvider),
  ),
);
