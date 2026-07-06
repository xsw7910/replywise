import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../entitlement/usage_controller.dart';
import '../data/ad_reward_repository.dart';
import '../data/rewarded_ad_gateway.dart';

/// Where the reward flow currently is. Any non-idle status disables the button
/// and guards against double taps while an ad is loading, showing, or being
/// claimed on the backend.
enum AdRewardStatus { idle, loading, showing, submitting }

/// A one-shot, user-facing result of a [AdRewardController.watchAd] attempt.
/// The UI maps these to localized messages.
enum AdRewardOutcome {
  creditAdded,
  adLoading,
  loadFailed,
  dailyLimitReached,
  cooldown,
  failed,
}

class AdRewardState {
  const AdRewardState({
    this.status = AdRewardStatus.idle,
    this.outcome,
    this.outcomeToken = 0,
  });

  final AdRewardStatus status;

  /// The most recent outcome to surface. Paired with [outcomeToken] so the UI
  /// re-shows a message even when the same outcome fires twice in a row.
  final AdRewardOutcome? outcome;
  final int outcomeToken;

  /// The button is only "busy" during the actual reward flow (showing the ad
  /// or claiming the credit). Background preloading (`loading`) leaves the
  /// button tappable so a tap while the ad is still loading can surface the
  /// "Ad is loading. Please try again." message. Double taps during the reward
  /// itself are still blocked here and by the `showing`/`submitting` guards in
  /// [AdRewardController.watchAd].
  bool get isBusy =>
      status == AdRewardStatus.showing || status == AdRewardStatus.submitting;

  AdRewardState copyWith({
    AdRewardStatus? status,
    AdRewardOutcome? outcome,
    int? outcomeToken,
  }) => AdRewardState(
    status: status ?? this.status,
    outcome: outcome ?? this.outcome,
    outcomeToken: outcomeToken ?? this.outcomeToken,
  );
}

class AdRewardController extends Notifier<AdRewardState> {
  final _uuid = const Uuid();
  Future<void>? _preloadFuture;

  @override
  AdRewardState build() {
    // Preload the first ad so the button is responsive on first tap.
    Future.microtask(_preload);
    return const AdRewardState();
  }

  /// Entry point for the Settings "Watch ad" button.
  Future<void> watchAd() async {
    final gateway = ref.read(rewardedAdGatewayProvider);

    switch (state.status) {
      case AdRewardStatus.showing:
      case AdRewardStatus.submitting:
        return; // A reward is already in flight — ignore extra taps.
      case AdRewardStatus.loading:
        await _preloadFuture;
        break;
      case AdRewardStatus.idle:
        break;
    }

    // The dialog can be the first surface that reads this provider. In that
    // case its first tap must finish the initial load and continue directly to
    // showing the ad instead of asking the user to tap a second time.
    if (!gateway.isReady && state.status == AdRewardStatus.idle) {
      await _preload();
    }

    // A concurrent tap may have resumed first and started showing the ad.
    if (state.status != AdRewardStatus.idle) {
      return;
    }

    if (!gateway.isReady) {
      _emit(AdRewardOutcome.loadFailed);
      return;
    }

    await _showAndClaim(gateway);
  }

  Future<void> _preload() {
    final gateway = ref.read(rewardedAdGatewayProvider);
    if (gateway.isReady) return Future.value();

    final inFlight = _preloadFuture;
    if (inFlight != null) return inFlight;
    if (state.status != AdRewardStatus.idle) return Future.value();

    final future = _runPreload(gateway);
    _preloadFuture = future;
    return future.whenComplete(() {
      if (identical(_preloadFuture, future)) _preloadFuture = null;
    });
  }

  Future<void> _runPreload(RewardedAdGateway gateway) async {
    state = state.copyWith(status: AdRewardStatus.loading);
    try {
      await gateway.load(AppConfig.rewardedAdUnitId);
    } catch (_) {
      // The tap that awaited this load reports the localized failure.
    } finally {
      state = state.copyWith(status: AdRewardStatus.idle);
    }
  }

  Future<void> _showAndClaim(RewardedAdGateway gateway) async {
    state = state.copyWith(status: AdRewardStatus.showing);

    bool earned;
    try {
      earned = await gateway.show();
    } catch (_) {
      _finish(AdRewardOutcome.loadFailed);
      return;
    }

    if (!earned) {
      // Dismissed before earning — no reward, no message.
      _finish(null);
      return;
    }

    // Reward earned. Credits are granted only after the backend confirms.
    state = state.copyWith(status: AdRewardStatus.submitting);
    try {
      await ref
          .read(adRewardRepositoryProvider)
          .claim(idempotencyKey: _uuid.v4());
      await ref.read(usageControllerProvider.notifier).refresh();
      _finish(AdRewardOutcome.creditAdded);
    } on ApiError catch (error) {
      _finish(_outcomeForError(error));
    } catch (_) {
      _finish(AdRewardOutcome.failed);
    }
  }

  /// Returns to idle, optionally emitting [outcome], then preloads the next ad.
  void _finish(AdRewardOutcome? outcome) {
    state = state.copyWith(status: AdRewardStatus.idle);
    if (outcome != null) _emit(outcome);
    unawaited(_preload());
  }

  AdRewardOutcome _outcomeForError(ApiError error) => switch (error.code) {
    'AD_REWARD_LIMIT' => AdRewardOutcome.dailyLimitReached,
    'AD_REWARD_COOLDOWN' => AdRewardOutcome.cooldown,
    _ => AdRewardOutcome.failed,
  };

  void _emit(AdRewardOutcome outcome) {
    state = state.copyWith(
      outcome: outcome,
      outcomeToken: state.outcomeToken + 1,
    );
  }
}

final adRewardControllerProvider =
    NotifierProvider<AdRewardController, AdRewardState>(AdRewardController.new);
