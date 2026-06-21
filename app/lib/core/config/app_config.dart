/// Runtime configuration injected via --dart-define at build time.
///
/// Usage:
///   flutter run \
///     --dart-define=REPLY_BACKEND_BASE_URL=https://api-reply.novaaistudio.ca \
///     --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxxxxx \
///     --dart-define=REVENUECAT_ENTITLEMENT_ID=premium \
///     --dart-define=REPLY_ENV=dev
class AppConfig {
  const AppConfig._();

  static const String backendBaseUrl = String.fromEnvironment(
    'REPLY_BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
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

  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
