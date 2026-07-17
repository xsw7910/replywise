import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/config/app_config.dart';
import 'package:replywise/core/launch/external_url_launcher.dart';
import 'package:replywise/core/router/app_router.dart';
import 'package:replywise/features/app_status/application/app_status_controller.dart';
import 'package:replywise/features/auth/data/auth_repository.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/subscription_repository.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/settings/application/dev_tools_controller.dart';
import 'package:replywise/features/settings/application/health_controller.dart';
import 'package:replywise/features/settings/data/health_repository.dart';
import 'package:replywise/features/settings/settings_screen.dart';
import 'package:replywise/features/support/support_screen.dart';
import 'package:replywise/features/support/support_url.dart';
import 'package:replywise/features/support/support_web_view.dart';
import 'package:replywise/l10n/app_localizations.dart';

/// Stands in for the platform WebView. It records the request so the test can
/// drive load-finished / load-error and observe reloads.
class _FakeWeb {
  SupportWebViewRequest? request;
  int reloadCount = 0;

  Widget build(SupportWebViewRequest req) {
    request = req;
    req.onReady(
      SupportWebViewHandle(
        reload: () async {
          reloadCount++;
          req.onPageStarted();
        },
        canGoBack: () async => false,
        goBack: () async {},
      ),
    );
    return const SizedBox(key: Key('fake-web'));
  }

  void finish() => request!.onPageFinished();
  void fail() => request!.onError();
}

Future<_FakeWeb> _pumpSupport(
  WidgetTester tester, {
  required List<Uri> launched,
  bool launchResult = true,
  String version = '1.0.0',
  int buildNumber = 40,
  String language = 'en',
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final fake = _FakeWeb();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAppVersionProvider.overrideWithValue(version),
        currentAppBuildNumberProvider.overrideWithValue(buildNumber),
        supportLanguageProvider.overrideWithValue(language),
        supportWebViewBuilderProvider.overrideWithValue(fake.build),
        externalUrlLauncherProvider.overrideWithValue((url) async {
          launched.add(url);
          return launchResult;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SupportScreen(),
      ),
    ),
  );
  await tester.pump();
  return fake;
}

// ── Settings navigation fakes ──────────────────────────────────────────────────

class _FakeStorage extends TokenStorage {
  _FakeStorage() : super(const FlutterSecureStorage());
  @override
  Future<String?> getAppUserId() async => 'support-test-user';
  @override
  Future<String?> getDeviceId() async => 'support-test-device';
  @override
  Future<String?> getAccessToken() async => 'fake.access.token';
  @override
  Future<String?> getRefreshToken() async => 'fake.refresh.token';
  @override
  Future<void> saveAppUserId(String id) async {}
  @override
  Future<void> saveDeviceId(String id) async {}
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> clearTokens() async {}
}

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(Dio());
  @override
  Future<MeData> me({required String accessToken}) async =>
      const MeData(userId: 1, appUserId: 'support-test-user');
}

class _FakeGateway implements RevenueCatGateway {
  const _FakeGateway();
  @override
  Future<void> configure({
    required String apiKey,
    required String appUserId,
  }) async {}
  @override
  Future<bool> isEntitlementActive(String entitlementId) async => false;
  @override
  Future<SubscriptionOffer> loadAnnualOffer() => throw UnimplementedError();
  @override
  Future<void> purchase(SubscriptionOffer offer) => throw UnimplementedError();
  @override
  Future<void> restore() => throw UnimplementedError();
  @override
  Future<List<CreditPackage>> loadCreditPackages() =>
      throw UnimplementedError();
  @override
  Future<void> purchaseCredit(CreditPackage package) =>
      throw UnimplementedError();
}

class _FakeHealthController extends HealthController {
  @override
  Future<HealthResponse> build() async =>
      const HealthResponse(status: 'ok', service: 'reply');
}

void main() {
  testWidgets('shows the privacy notice and a loading indicator while loading', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpSupport(tester, launched: launched);

    expect(find.byKey(const Key('support-sensitive-notice')), findsOneWidget);
    expect(
      find.text(
        'Please do not include passwords, payment card details, or other '
        'sensitive information.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('support-loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading support form…'), findsOneWidget);
  });

  testWidgets('hides the loading indicator once the form finishes loading', (
    tester,
  ) async {
    final launched = <Uri>[];
    final fake = await _pumpSupport(tester, launched: launched);

    fake.finish();
    await tester.pump();

    expect(find.byKey(const Key('support-loading')), findsNothing);
    expect(find.byKey(const Key('support-error')), findsNothing);
    expect(find.byKey(const Key('fake-web')), findsOneWidget);
  });

  testWidgets('shows the error state when the form fails to load', (
    tester,
  ) async {
    final launched = <Uri>[];
    final fake = await _pumpSupport(tester, launched: launched);

    fake.fail();
    await tester.pump();

    expect(find.byKey(const Key('support-error')), findsOneWidget);
    expect(find.text('Unable to load the support form'), findsOneWidget);
    expect(
      find.text('Please check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('support-try-again')), findsOneWidget);
    expect(find.byKey(const Key('support-open-browser')), findsOneWidget);
  });

  testWidgets('Try Again reloads the form and returns to loading', (
    tester,
  ) async {
    final launched = <Uri>[];
    final fake = await _pumpSupport(tester, launched: launched);

    fake.fail();
    await tester.pump();
    expect(find.byKey(const Key('support-error')), findsOneWidget);

    await tester.tap(find.byKey(const Key('support-try-again')));
    await tester.pump();

    expect(fake.reloadCount, 1);
    expect(find.byKey(const Key('support-error')), findsNothing);
    expect(find.byKey(const Key('support-loading')), findsOneWidget);
  });

  testWidgets('Open in Browser launches the generated support URL', (
    tester,
  ) async {
    final launched = <Uri>[];
    final fake = await _pumpSupport(tester, launched: launched);

    fake.fail();
    await tester.pump();

    await tester.tap(find.byKey(const Key('support-open-browser')));
    await tester.pump();

    final expected = buildSupportFormUrl(
      baseUrl: AppConfig.supportFormUrl,
      appVersion: '1.0.0',
      buildNumber: 40,
      language: 'en',
    );
    expect(launched, [expected]);
    expect(
      expected.toString(),
      'https://tally.so/r/eqlJEo'
          '?app=replywise&version=1.0.0&build=40&platform=android&language=en',
    );
  });

  testWidgets('Support row on Settings opens the Support page', (tester) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = _FakeWeb();

    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (context, state) => const SupportScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          devToolsPanelVisibleProvider.overrideWithValue(false),
          healthControllerProvider.overrideWith(_FakeHealthController.new),
          tokenStorageProvider.overrideWith((ref) => _FakeStorage()),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepo()),
          revenueCatGatewayProvider.overrideWithValue(const _FakeGateway()),
          currentAppVersionProvider.overrideWithValue('1.0.0'),
          currentAppBuildNumberProvider.overrideWithValue(40),
          supportLanguageProvider.overrideWithValue('en'),
          supportWebViewBuilderProvider.overrideWithValue(fake.build),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The Support row is present on Settings, and the Support page is not shown.
    expect(find.byKey(const Key('settings-support-row')), findsOneWidget);
    expect(find.byKey(const Key('support-sensitive-notice')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('settings-support-row')));
    await tester.tap(find.byKey(const Key('settings-support-row')));
    // Not pumpAndSettle: the form stays in the loading state (the fake never
    // reports a finished load), so the spinner would never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The Support page (native header + form container) is now on screen.
    expect(find.byKey(const Key('support-sensitive-notice')), findsOneWidget);
    expect(find.byKey(const Key('fake-web')), findsOneWidget);
  });
}
