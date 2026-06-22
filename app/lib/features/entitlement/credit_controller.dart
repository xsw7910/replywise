import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_error.dart';
import 'credit_repository.dart';
import 'subscription_repository.dart';
import 'usage_controller.dart';

class CreditState {
  const CreditState({
    this.packages = const [],
    this.isLoading = false,
    this.isPurchasing = false,
    this.error,
  });

  final List<CreditPackage> packages;
  final bool isLoading;
  final bool isPurchasing;
  final String? error;

  bool get isBusy => isLoading || isPurchasing;
}

class CreditController extends Notifier<CreditState> {
  @override
  CreditState build() => const CreditState();

  /// Silent background sync — called on app startup and paywall open.
  /// Grants any RevenueCat transactions not yet recorded, then refreshes /v1/me.
  Future<void> syncCredits() async {
    try {
      await ref.read(creditRepositoryProvider).sync();
      await ref.read(usageControllerProvider.notifier).refresh();
    } catch (_) {
      // Purchase-loss recovery is best-effort; do not surface errors here.
    }
  }

  /// Loads credit packages from RevenueCat. Guards against redundant calls.
  Future<void> loadPackages(String appUserId) async {
    if (state.isLoading || state.packages.isNotEmpty) return;
    state = CreditState(isLoading: true);
    try {
      await ref.read(revenueCatGatewayProvider).configure(
        apiKey: _apiKey,
        appUserId: appUserId,
      );
      final packages = await ref.read(revenueCatGatewayProvider).loadCreditPackages();
      state = CreditState(packages: packages);
    } catch (error) {
      state = CreditState(error: _message(error));
    }
  }

  /// Purchases a credit package, syncs with backend, and refreshes balance.
  /// Returns true on success, false on cancellation or error.
  Future<bool> purchase(String appUserId, CreditPackage package) async {
    state = CreditState(packages: state.packages, isPurchasing: true);
    try {
      await ref.read(revenueCatGatewayProvider).configure(
        apiKey: _apiKey,
        appUserId: appUserId,
      );
      await ref.read(revenueCatGatewayProvider).purchaseCredit(package);
      await ref.read(creditRepositoryProvider).sync();
      await ref.read(usageControllerProvider.notifier).refresh();
      state = CreditState(packages: state.packages);
      return true;
    } catch (error) {
      final cancelled = error is SubscriptionException && error.cancelled;
      state = CreditState(
        packages: state.packages,
        error: cancelled ? null : _message(error),
      );
      return false;
    }
  }

  String _message(Object error) {
    if (error is SubscriptionException) return error.message;
    if (error is ApiError) return error.message;
    return 'Something went wrong. Please try again.';
  }

  String get _apiKey => AppConfig.revenueCatAndroidApiKey;
}

final creditControllerProvider =
    NotifierProvider<CreditController, CreditState>(CreditController.new);
