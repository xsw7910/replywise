import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Raised when a rewarded ad fails to load or fails to show.
class RewardedAdException implements Exception {
  const RewardedAdException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin, testable seam over the `google_mobile_ads` rewarded-ad API.
///
/// Keeping the plugin types behind this interface lets [AdRewardController] be
/// unit-tested with a fake, and confines the callback-based ad SDK to one file.
abstract class RewardedAdGateway {
  /// Whether a rewarded ad is loaded and ready to show.
  bool get isReady;

  /// Loads a rewarded ad for [adUnitId]. Completes with true once ready.
  /// Throws [RewardedAdException] if loading fails.
  Future<bool> load(String adUnitId);

  /// Shows the currently loaded ad. Completes with true **only** if the user
  /// earned the reward (`onUserEarnedReward` fired), false if they dismissed it
  /// early. Throws [RewardedAdException] when there is no ad or it fails to
  /// show. A loaded ad is single-use; a fresh [load] is required afterwards.
  Future<bool> show();

  void dispose();
}

/// Production [RewardedAdGateway] backed by google_mobile_ads.
class GoogleRewardedAdGateway implements RewardedAdGateway {
  RewardedAd? _ad;
  bool _loading = false;

  @override
  bool get isReady => _ad != null;

  @override
  Future<bool> load(String adUnitId) {
    if (_ad != null) return Future.value(true);
    if (_loading) return Future.value(false);
    _loading = true;

    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
          if (!completer.isCompleted) {
            completer.completeError(RewardedAdException(error.message));
          }
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<bool> show() {
    final ad = _ad;
    if (ad == null) {
      return Future.error(const RewardedAdException('No ad loaded.'));
    }
    // A rewarded ad can only be shown once; drop our reference up front so a
    // stray second show() cannot reuse a disposed ad.
    _ad = null;

    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.completeError(RewardedAdException(error.message));
        }
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}

final rewardedAdGatewayProvider = Provider<RewardedAdGateway>((ref) {
  final gateway = GoogleRewardedAdGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});
