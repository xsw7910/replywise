import 'package:flutter/foundation.dart';

/// Runtime configuration injected via --dart-define at build time.
///
/// Usage:
///   flutter run \
///     --dart-define=REPLY_BACKEND_BASE_URL=https://api-reply.novaaistudio.ca \
///     --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxxxxx \
///     --dart-define=REVENUECAT_ENTITLEMENT_ID=premium \
///     --dart-define=REPLY_ADMOB_REWARDED_AD_UNIT_ID=ca-app-pub-xxx/yyy \
///     --dart-define=REPLY_ENV=dev
class AppConfig {
  const AppConfig._();

  /// Google's official Android rewarded **test** ad unit id. Used in debug
  /// builds so development never serves (or accidentally clicks) live ads.
  static const String androidRewardedTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Production rewarded ad unit id, injected at build time. Must be non-empty
  /// for release builds — see [rewardedAdUnitId].
  static const String rewardedAdUnitIdOverride = String.fromEnvironment(
    'REPLY_ADMOB_REWARDED_AD_UNIT_ID',
    defaultValue: '',
  );

  /// Resolves the rewarded ad unit id for the current build.
  ///
  /// - Release builds require [rewardedAdUnitIdOverride]; an empty value is a
  ///   build misconfiguration and throws.
  /// - Debug/profile builds fall back to Google's test unit when no override is
  ///   supplied, so ads work without extra setup.
  static String get rewardedAdUnitId {
    if (kReleaseMode) {
      if (rewardedAdUnitIdOverride.isEmpty) {
        throw StateError(
          'REPLY_ADMOB_REWARDED_AD_UNIT_ID must be provided via --dart-define '
          'for release builds.',
        );
      }
      return rewardedAdUnitIdOverride;
    }
    return rewardedAdUnitIdOverride.isNotEmpty
        ? rewardedAdUnitIdOverride
        : androidRewardedTestAdUnitId;
  }

  static const String backendBaseUrl = String.fromEnvironment(
    'REPLY_BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Hosted Tally form shown on the in-app Support page. Only non-sensitive
  /// diagnostics (app, version, build, platform, language) are appended to it —
  /// see `buildSupportFormUrl`.
  static const String supportFormUrl = 'https://tally.so/r/eqlJEo';

  /// The running app's marketing version (e.g. "1.0.0"), used for force /
  /// optional update comparisons against `GET /v1/app-status`. Defaults here
  /// and is overridden at startup with the real value from package_info; a
  /// release build can also pin it via --dart-define.
  static const String appVersion = String.fromEnvironment(
    'REPLY_APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// The running app's numeric build number (the `+NN` part of the pubspec
  /// version), used to distinguish builds that share a version name (1.0.0+32
  /// vs 1.0.0+33). Overridden at startup with the real value from
  /// package_info; a release build can also pin it via --dart-define.
  static const int appBuildNumber = int.fromEnvironment(
    'REPLY_APP_BUILD_NUMBER',
    defaultValue: 33,
  );

  static const String revenueCatAndroidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );

  static const String entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'premium',
  );

  static const String env = String.fromEnvironment(
    'REPLY_ENV',
    defaultValue: 'dev',
  );

  static const bool devToolsEnabled = bool.fromEnvironment(
    'DEV_TOOLS_ENABLED',
    defaultValue: false,
  );

  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
