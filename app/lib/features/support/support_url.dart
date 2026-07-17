import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/locale_controller.dart';
import '../app_status/application/app_status_controller.dart';

/// Query keys ReplyWise appends to the support form. Kept explicit so it is
/// obvious that only non-sensitive diagnostics are shared — never tokens,
/// device identifiers, payment details, or the user's email.
const _kApp = 'app';
const _kVersion = 'version';
const _kBuild = 'build';
const _kPlatform = 'platform';
const _kLanguage = 'language';

/// Builds the prefilled Tally support URL.
///
/// Only the whitelisted diagnostic parameters are added. Any query already
/// present on [baseUrl] is preserved (the new keys win on a collision). Uses
/// the [Uri] API so values are percent-encoded safely.
Uri buildSupportFormUrl({
  required String baseUrl,
  required String appVersion,
  required int buildNumber,
  required String language,
  String platform = 'android',
}) {
  final base = Uri.parse(baseUrl);
  return base.replace(
    queryParameters: <String, String>{
      ...base.queryParameters,
      _kApp: 'replywise',
      _kVersion: appVersion,
      _kBuild: '$buildNumber',
      _kPlatform: platform,
      _kLanguage: language,
    },
  );
}

/// The concrete language code sent to the support form. Resolves the "system"
/// preference to the actual app language so the diagnostic is meaningful.
/// Overridable in tests.
final supportLanguageProvider = Provider<String>((ref) {
  final preference = ref.watch(localeControllerProvider);
  return preference == 'system' ? resolvedAppLocaleCode(null) : preference;
});

/// The fully-built support URL for the current install (version/build from
/// package info, current app language). Reused by the WebView and the
/// "Open in Browser" action so both always point at the same URL.
final supportFormUrlProvider = Provider<Uri>((ref) {
  return buildSupportFormUrl(
    baseUrl: AppConfig.supportFormUrl,
    appVersion: ref.watch(currentAppVersionProvider),
    buildNumber: ref.watch(currentAppBuildNumberProvider),
    language: ref.watch(supportLanguageProvider),
  );
});
