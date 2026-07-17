import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/config/app_config.dart';
import 'package:replywise/features/support/support_url.dart';

void main() {
  group('buildSupportFormUrl', () {
    test('the configured base URL is the Tally support form', () {
      expect(AppConfig.supportFormUrl, 'https://tally.so/r/eqlJEo');

      final uri = buildSupportFormUrl(
        baseUrl: AppConfig.supportFormUrl,
        appVersion: '1.0.0',
        buildNumber: 40,
        language: 'en',
      );
      expect(uri.scheme, 'https');
      expect(uri.host, 'tally.so');
      expect(uri.path, '/r/eqlJEo');
    });

    test('appends app, version, build, platform and language', () {
      final uri = buildSupportFormUrl(
        baseUrl: AppConfig.supportFormUrl,
        appVersion: '1.0.0',
        buildNumber: 40,
        language: 'en',
      );

      expect(uri.queryParameters, {
        'app': 'replywise',
        'version': '1.0.0',
        'build': '40',
        'platform': 'android',
        'language': 'en',
      });
      expect(
        uri.toString(),
        'https://tally.so/r/eqlJEo'
            '?app=replywise&version=1.0.0&build=40&platform=android&language=en',
      );
    });

    test('preserves query parameters already present on the base URL', () {
      final uri = buildSupportFormUrl(
        baseUrl: 'https://tally.so/r/eqlJEo?ref=newsletter&version=stale',
        appVersion: '2.5.1',
        buildNumber: 99,
        language: 'fr',
      );

      // Existing, non-conflicting params survive.
      expect(uri.queryParameters['ref'], 'newsletter');
      // Diagnostics win on a collision.
      expect(uri.queryParameters['version'], '2.5.1');
      expect(uri.queryParameters['build'], '99');
      expect(uri.queryParameters['language'], 'fr');
    });

    test('percent-encodes values safely via the Uri API', () {
      final uri = buildSupportFormUrl(
        baseUrl: AppConfig.supportFormUrl,
        appVersion: '1.0.0 beta',
        buildNumber: 40,
        language: 'zh_Hant',
      );
      expect(uri.queryParameters['version'], '1.0.0 beta');
      expect(uri.toString(), contains('version=1.0.0+beta'));
      expect(uri.queryParameters['language'], 'zh_Hant');
    });

    test('never adds authentication, device, or payment identifiers', () {
      final uri = buildSupportFormUrl(
        baseUrl: AppConfig.supportFormUrl,
        appVersion: '1.0.0',
        buildNumber: 40,
        language: 'en',
      );

      expect(uri.queryParameters.keys.toSet(), {
        'app',
        'version',
        'build',
        'platform',
        'language',
      });
      for (final forbidden in const [
        'token',
        'access_token',
        'auth',
        'email',
        'device',
        'deviceId',
        'device_id',
        'userId',
        'user_id',
        'payment',
      ]) {
        expect(
          uri.queryParameters.containsKey(forbidden),
          isFalse,
          reason: '$forbidden must never be added to the support URL',
        );
      }
    });
  });
}
