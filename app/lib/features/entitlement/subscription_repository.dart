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
  });

  final String packageIdentifier;
  final String productIdentifier;
  final String priceString;
}

class SubscriptionException implements Exception {
  const SubscriptionException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
}

abstract class RevenueCatGateway {
  Future<void> configure({required String apiKey, required String appUserId});
  Future<SubscriptionOffer> loadMonthlyOffer();
  Future<void> purchase(SubscriptionOffer offer);
  Future<void> restore();
}

class SdkRevenueCatGateway implements RevenueCatGateway {
  String? _configuredAppUserId;
  final Map<String, Package> _packages = {};

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
    if (_configuredAppUserId == appUserId) return;
    if (_configuredAppUserId != null) {
      await Purchases.logIn(appUserId);
      _configuredAppUserId = appUserId;
      return;
    }
    final configuration = PurchasesConfiguration(apiKey)..appUserID = appUserId;
    await Purchases.configure(configuration);
    _configuredAppUserId = appUserId;
  }

  @override
  Future<SubscriptionOffer> loadMonthlyOffer() async {
    final offerings = await Purchases.getOfferings();
    final package = offerings.getOffering('default')?.monthly;
    if (package == null) {
      throw const SubscriptionException(
        'The monthly subscription is currently unavailable.',
      );
    }
    _packages[package.identifier] = package;
    return SubscriptionOffer(
      packageIdentifier: package.identifier,
      productIdentifier: package.storeProduct.identifier,
      priceString: package.storeProduct.priceString,
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
}

abstract class SubscriptionRepository {
  Future<SubscriptionOffer> load(String appUserId);
  Future<EntitlementState> purchase(String appUserId, SubscriptionOffer offer);
  Future<EntitlementState> restore(String appUserId);
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
    return _gateway.loadMonthlyOffer();
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
