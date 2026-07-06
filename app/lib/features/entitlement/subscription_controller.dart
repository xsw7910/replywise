import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error.dart';
import 'subscription_repository.dart';
import 'usage_controller.dart';

class SubscriptionState {
  const SubscriptionState({
    this.offer,
    this.isLoading = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.error,
    this.message,
    this.appUserId,
  });

  final SubscriptionOffer? offer;
  final bool isLoading;
  final bool isPurchasing;
  final bool isRestoring;
  final String? error;
  final String? message;
  final String? appUserId;

  bool get isBusy => isLoading || isPurchasing || isRestoring;
}

class SubscriptionController extends Notifier<SubscriptionState> {
  Future<void>? _silentSyncInFlight;

  @override
  SubscriptionState build() => const SubscriptionState();

  /// Silently reconciles an already-active premium entitlement from RevenueCat
  /// (e.g. after a reinstall) and refreshes usage so `/v1/me` and the UI show
  /// premium automatically. Uses getCustomerInfo() only — it never starts a
  /// purchase, shows the store UI, or calls restorePurchases.
  ///
  /// Safe to call repeatedly from startup, Paywall and Settings: concurrent
  /// calls share one in-flight run. It does not touch [SubscriptionState] (so it
  /// never disturbs the Paywall UI) and, on any network/RevenueCat error, it
  /// leaves everything untouched — premium is never downgraded here.
  Future<void> syncActivePremiumSilently(String appUserId) {
    final inFlight = _silentSyncInFlight;
    if (inFlight != null) return inFlight;
    final future = _runSilentSync(appUserId);
    _silentSyncInFlight = future;
    return future.whenComplete(() {
      if (identical(_silentSyncInFlight, future)) _silentSyncInFlight = null;
    });
  }

  Future<void> _runSilentSync(String appUserId) async {
    try {
      final entitlement = await ref
          .read(subscriptionRepositoryProvider)
          .syncActivePremiumSilently(appUserId);
      // null => no active premium entitlement; the backend was not called.
      if (entitlement != null && entitlement.isPremium) {
        await ref.read(usageControllerProvider.notifier).refresh();
      }
    } catch (error, stackTrace) {
      // Background reconciliation is non-critical: never surface it and never
      // downgrade premium because a silent check failed.
      if (kDebugMode) {
        debugPrint('Silent premium sync failed: $error\n$stackTrace');
      }
    }
  }

  Future<void> load(String appUserId) async {
    if (state.isLoading ||
        (state.appUserId == appUserId && state.offer != null)) {
      return;
    }
    state = SubscriptionState(
      offer: state.offer,
      isLoading: true,
      appUserId: appUserId,
    );
    try {
      final offer = await ref
          .read(subscriptionRepositoryProvider)
          .load(appUserId);
      state = SubscriptionState(offer: offer, appUserId: appUserId);
    } catch (error) {
      state = SubscriptionState(
        appUserId: appUserId,
        error: _message(error, 'Unable to load subscription options.'),
      );
    }
  }

  Future<bool> purchase() async {
    final offer = state.offer;
    final appUserId = state.appUserId;
    if (offer == null || appUserId == null) return false;
    state = SubscriptionState(
      offer: offer,
      appUserId: appUserId,
      isPurchasing: true,
    );
    try {
      final entitlement = await ref
          .read(subscriptionRepositoryProvider)
          .purchase(appUserId, offer);
      if (!entitlement.isPremium) {
        throw const SubscriptionException(
          'Purchase completed, but premium access could not be verified.',
        );
      }
      await ref.read(usageControllerProvider.notifier).refresh();
      state = SubscriptionState(
        offer: offer,
        appUserId: appUserId,
        message: 'Premium is active.',
      );
      return true;
    } catch (error) {
      state = SubscriptionState(
        offer: offer,
        appUserId: appUserId,
        error: _message(error, 'Purchase failed. Please try again.'),
      );
      return false;
    }
  }

  Future<bool> restore() async {
    final appUserId = state.appUserId;
    if (appUserId == null) return false;
    state = SubscriptionState(
      offer: state.offer,
      appUserId: appUserId,
      isRestoring: true,
    );
    try {
      final entitlement = await ref
          .read(subscriptionRepositoryProvider)
          .restore(appUserId);
      await ref.read(usageControllerProvider.notifier).refresh();
      state = SubscriptionState(
        offer: state.offer,
        appUserId: appUserId,
        message: entitlement.isPremium
            ? 'Premium purchase restored.'
            : 'No active subscription was found.',
      );
      return entitlement.isPremium;
    } catch (error) {
      state = SubscriptionState(
        offer: state.offer,
        appUserId: appUserId,
        error: _message(error, 'Restore failed. Please try again.'),
      );
      return false;
    }
  }

  String _message(Object error, String fallback) {
    if (error is SubscriptionException) return error.message;
    if (error is ApiError) return error.displayMessage(fallback: fallback);
    return fallback;
  }
}

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );
