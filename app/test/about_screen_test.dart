import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/constants/legal_urls.dart';
import 'package:replywise/core/launch/external_url_launcher.dart';
import 'package:replywise/core/router/app_router.dart';
import 'package:replywise/features/about/about_screen.dart';
import 'package:replywise/features/app_status/application/app_status_controller.dart';
import 'package:replywise/features/auth/data/auth_repository.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/subscription_repository.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/settings/application/dev_tools_controller.dart';
import 'package:replywise/features/settings/application/health_controller.dart';
import 'package:replywise/features/settings/data/health_repository.dart';
import 'package:replywise/features/settings/settings_screen.dart';
import 'package:replywise/l10n/app_localizations.dart';

// ── About page harness ─────────────────────────────────────────────────────────

Future<void> _pumpAbout(
  WidgetTester tester, {
  required List<Uri> launched,
  String version = '1.0.0',
  int buildNumber = 40,
  bool launchResult = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAppVersionProvider.overrideWithValue(version),
        currentAppBuildNumberProvider.overrideWithValue(buildNumber),
        externalUrlLauncherProvider.overrideWithValue((url) async {
          launched.add(url);
          return launchResult;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AboutScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── Settings navigation fakes ──────────────────────────────────────────────────

class _FakeStorage extends TokenStorage {
  _FakeStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getAppUserId() async => 'about-test-user';
  @override
  Future<String?> getDeviceId() async => 'about-test-device';
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
      const MeData(userId: 1, appUserId: 'about-test-user');
}

/// Never touches the store: entitlement is inactive and no offers are loaded.
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
  testWidgets('renders app identity, legal rows, version and copyright', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpAbout(tester, launched: launched);

    // App icon + identity.
    final icon = tester.widget<Image>(find.byKey(const Key('about-app-icon')));
    expect((icon.image as AssetImage).assetName, 'assets/icons/app_icon.png');
    expect(find.text('ReplyWise'), findsOneWidget);
    expect(find.text('NovaAI Studio'), findsOneWidget);
    expect(
      find.text(
        'Your AI assistant for replies, polished writing, and clear '
        'explanations.',
      ),
      findsOneWidget,
    );

    // Legal rows.
    expect(find.byKey(const Key('about-privacy-row')), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.byKey(const Key('about-terms-row')), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);

    // Version + copyright.
    expect(find.text('Version 1.0.0 (40)'), findsOneWidget);
    expect(find.text('© NovaAI Studio'), findsOneWidget);
  });

  testWidgets('tapping Privacy Policy opens the privacy URL', (tester) async {
    final launched = <Uri>[];
    await _pumpAbout(tester, launched: launched);

    await tester.tap(find.byKey(const Key('about-privacy-row')));
    await tester.pumpAndSettle();

    expect(launched, [Uri.parse(AppLinks.privacyPolicy)]);
  });

  testWidgets('tapping Terms of Service opens the terms URL', (tester) async {
    final launched = <Uri>[];
    await _pumpAbout(tester, launched: launched);

    await tester.tap(find.byKey(const Key('about-terms-row')));
    await tester.pumpAndSettle();

    expect(launched, [Uri.parse(AppLinks.termsOfService)]);
  });

  testWidgets('shows the version name and build number from package info', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpAbout(
      tester,
      launched: launched,
      version: '2.5.1',
      buildNumber: 99,
    );

    expect(find.text('Version 2.5.1 (99)'), findsOneWidget);
    expect(find.text('Version 1.0.0 (40)'), findsNothing);
  });

  testWidgets('surfaces the error UI when a link cannot be opened', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pumpAbout(tester, launched: launched, launchResult: false);

    await tester.tap(find.byKey(const Key('about-privacy-row')));
    await tester.pump(); // start the SnackBar animation

    expect(launched, [Uri.parse(AppLinks.privacyPolicy)]);
    expect(
      find.text("Couldn't open the link. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('tapping About in Settings opens the About page', (tester) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.about,
          builder: (context, state) => const AboutScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Hide the developer-only cards so the screen has no backend deps.
          devToolsPanelVisibleProvider.overrideWithValue(false),
          // Settings watches health on every build — keep it off the network.
          healthControllerProvider.overrideWith(_FakeHealthController.new),
          tokenStorageProvider.overrideWith((ref) => _FakeStorage()),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepo()),
          revenueCatGatewayProvider.overrideWithValue(const _FakeGateway()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Start on Settings: the About page is not shown yet.
    expect(find.byKey(const Key('settings-about-row')), findsOneWidget);
    expect(find.byKey(const Key('about-version')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('settings-about-row')));
    await tester.tap(find.byKey(const Key('settings-about-row')));
    await tester.pumpAndSettle();

    // The About page is now on screen.
    expect(find.byKey(const Key('about-app-icon')), findsOneWidget);
    expect(find.byKey(const Key('about-version')), findsOneWidget);
  });
}
