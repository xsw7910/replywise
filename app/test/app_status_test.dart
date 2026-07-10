import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/core/theme/app_feature_theme.dart';
import 'package:replywise/features/app_status/application/app_status_controller.dart';
import 'package:replywise/features/app_status/data/app_status_service.dart';
import 'package:replywise/features/app_status/domain/app_status.dart';
import 'package:replywise/features/app_status/presentation/app_status_dialogs.dart';
import 'package:replywise/features/app_status/presentation/app_status_gate.dart';
import 'package:replywise/features/app_status/presentation/app_status_launcher.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/l10n/app_localizations.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

class FakeAppStatusService implements AppStatusService {
  FakeAppStatusService(this._onFetch);

  final Future<AppStatus> Function() _onFetch;
  int callCount = 0;

  @override
  Future<AppStatus> fetch({
    String appName = 'replywise',
    String platform = 'android',
  }) {
    callCount++;
    return _onFetch();
  }
}

AppStatus buildStatus({
  bool maintenance = false,
  String maintenanceMessage = 'Scheduled maintenance in progress.',
  String minSupportedVersion = '1.0.0',
  int minSupportedBuildNumber = 0,
  String latestVersion = '1.0.0',
  int latestBuildNumber = 0,
  bool forceUpdate = false,
  String updateMessage = 'Please update ReplyWise.',
  List<String> disabledFeatures = const <String>[],
}) => AppStatus(
  appName: 'replywise',
  platform: 'android',
  maintenance: maintenance,
  maintenanceMessage: maintenanceMessage,
  minSupportedVersion: minSupportedVersion,
  minSupportedBuildNumber: minSupportedBuildNumber,
  latestVersion: latestVersion,
  latestBuildNumber: latestBuildNumber,
  forceUpdate: forceUpdate,
  updateMessage: updateMessage,
  disabledFeatures: disabledFeatures,
  supportEmail: 'support@novaaistudio.ca',
  updatedAt: DateTime.utc(2026, 1, 1),
);

ProviderContainer makeContainer({
  required FakeAppStatusService service,
  String version = '1.0.0',
  int buildNumber = 0,
  DateTime Function()? clock,
}) {
  final container = ProviderContainer(
    overrides: [
      appStatusServiceProvider.overrideWithValue(service),
      currentAppVersionProvider.overrideWithValue(version),
      currentAppBuildNumberProvider.overrideWithValue(buildNumber),
      if (clock != null) appStatusClockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

AppStatusController notifierOf(ProviderContainer c) =>
    c.read(appStatusControllerProvider.notifier);

Future<void> settle() => Future<void>.delayed(Duration.zero);

// ── Model / gate ─────────────────────────────────────────────────────────────

void main() {
  group('version compare + model', () {
    test('compareVersions orders dotted and suffixed versions', () {
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersions('1.2.0', '1.1.9'), greaterThan(0));
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0.0+29', '1.0.0'), 0);
      expect(compareVersions('2.0', '1.9.9'), greaterThan(0));
    });

    test('fromJson normalises disabled features and applies defaults', () {
      final status = AppStatus.fromJson(<String, dynamic>{
        'appName': 'replywise',
        'platform': 'android',
        'maintenance': true,
        'disabledFeatures': <dynamic>['Reply', ' POLISH '],
      });
      expect(status.maintenance, isTrue);
      expect(status.disabledFeatures, ['reply', 'polish']);
      expect(status.minSupportedVersion, '1.0.0');
      expect(status.supportEmail, 'support@novaaistudio.ca');
      expect(
        status.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });

    test('requiresForceUpdate / hasOptionalUpdate', () {
      final force = buildStatus(
        forceUpdate: true,
        minSupportedVersion: '2.0.0',
      );
      expect(force.requiresForceUpdate('1.0.0', 0), isTrue);

      final optional = buildStatus(latestVersion: '1.5.0');
      expect(optional.requiresForceUpdate('1.0.0', 0), isFalse);
      expect(optional.hasOptionalUpdate('1.0.0', 0), isTrue);
      expect(optional.hasOptionalUpdate('1.5.0', 0), isFalse);
    });

    test('build number breaks ties between equal version names', () {
      // compareVersionAndBuild: semantic version first, then build number.
      expect(compareVersionAndBuild('1.0.0', 32, '1.0.0', 33), lessThan(0));
      expect(compareVersionAndBuild('1.0.0', 33, '1.0.0', 33), 0);
      // 1.0.1+1 is newer than 1.0.0+99: version wins over build number.
      expect(compareVersionAndBuild('1.0.1', 1, '1.0.0', 99), greaterThan(0));

      final min33 = buildStatus(
        forceUpdate: true,
        minSupportedVersion: '1.0.0',
        minSupportedBuildNumber: 33,
      );
      // 1.0.0+32 requires the update; 1.0.0+33 and newer do not.
      expect(min33.requiresForceUpdate('1.0.0', 32), isTrue);
      expect(min33.requiresForceUpdate('1.0.0', 33), isFalse);
      expect(min33.requiresForceUpdate('1.0.0', 34), isFalse);
      expect(min33.requiresForceUpdate('1.0.1', 1), isFalse);
    });

    test('forceUpdate=false never blocks, even below the minimum', () {
      final status = buildStatus(
        forceUpdate: false,
        minSupportedVersion: '1.0.0',
        minSupportedBuildNumber: 33,
      );
      expect(status.requiresForceUpdate('1.0.0', 32), isFalse);
      expect(
        evaluateGate(
          status: status,
          feature: AppFeature.reply,
          currentVersion: '1.0.0',
          currentBuildNumber: 32,
        ),
        AppStatusGate.allowed,
      );
    });

    test('forceUpdate=true does not block a build at or above the floor', () {
      final status = buildStatus(
        forceUpdate: true,
        minSupportedVersion: '1.0.0',
        minSupportedBuildNumber: 33,
      );
      expect(status.requiresForceUpdate('1.0.0', 33), isFalse);
      expect(status.requiresForceUpdate('1.0.1', 1), isFalse);
    });

    test('optional update compares build numbers too', () {
      final status = buildStatus(
        latestVersion: '1.0.0',
        latestBuildNumber: 34,
      );
      expect(status.hasOptionalUpdate('1.0.0', 33), isTrue);
      expect(status.hasOptionalUpdate('1.0.0', 34), isFalse);
      expect(status.hasOptionalUpdate('1.0.1', 1), isFalse);
    });

    test('evaluateGate precedence: maintenance > force > disabled', () {
      expect(
        evaluateGate(
          status: buildStatus(maintenance: true, forceUpdate: true),
          feature: AppFeature.reply,
          currentVersion: '1.0.0',
        ),
        AppStatusGate.maintenance,
      );
      expect(
        evaluateGate(
          status: buildStatus(disabledFeatures: ['reply']),
          feature: AppFeature.reply,
          currentVersion: '1.0.0',
        ),
        AppStatusGate.featureDisabled,
      );
      expect(
        evaluateGate(
          status: null,
          feature: AppFeature.reply,
          currentVersion: '1.0.0',
        ),
        AppStatusGate.allowed,
      );
    });
  });

  // ── Controller: caching / gate / lifecycle ─────────────────────────────────

  group('AppStatusController', () {
    test('app starts without waiting: reading the controller never blocks on '
        'a slow fetch', () {
      final service = FakeAppStatusService(() => Completer<AppStatus>().future);
      final container = makeContainer(service: service);

      // Reading returns immediately with an empty, non-blocking state and does
      // not itself hit the network.
      final state = container.read(appStatusControllerProvider);
      expect(state.status, isNull);
      expect(service.callCount, 0);
    });

    test(
      'no cached status allows the request without a network call',
      () async {
        final service = FakeAppStatusService(() async => buildStatus());
        final container = makeContainer(service: service);

        final gate = await notifierOf(container).guardFeature(AppFeature.reply);
        expect(gate, AppStatusGate.allowed);
        expect(service.callCount, 0);
      },
    );

    test('a fresh normal cache is reused: no app-status call before each '
        'request', () async {
      final service = FakeAppStatusService(() async => buildStatus());
      final container = makeContainer(service: service);
      final notifier = notifierOf(container);

      await notifier.refresh();
      expect(service.callCount, 1);

      final gates = [
        await notifier.guardFeature(AppFeature.reply),
        await notifier.guardFeature(AppFeature.polish),
        await notifier.guardFeature(AppFeature.explain),
      ];
      expect(gates, everyElement(AppStatusGate.allowed));
      // Crucially, no additional fetches were made.
      expect(service.callCount, 1);
    });

    test('cached status expires after 5 minutes and refreshes in the '
        'background without delaying the request', () async {
      var now = DateTime(2026, 1, 1, 12);
      final service = FakeAppStatusService(() async => buildStatus());
      final container = makeContainer(service: service, clock: () => now);
      final notifier = notifierOf(container);

      await notifier.refresh();
      expect(service.callCount, 1);
      expect(notifier.isCacheStale, isFalse);

      now = now.add(const Duration(minutes: 6));
      expect(notifier.isCacheStale, isTrue);

      final gate = await notifier.guardFeature(AppFeature.reply);
      // Request is allowed immediately (not delayed) using the cached value...
      expect(gate, AppStatusGate.allowed);
      // ...while a background refresh was kicked off.
      expect(service.callCount, 2);
      await settle();
    });

    test('maintenance cached status blocks the request', () async {
      final service = FakeAppStatusService(
        () async => buildStatus(maintenance: true),
      );
      final container = makeContainer(service: service);
      final notifier = notifierOf(container);

      await notifier.refresh();
      final gate = await notifier.guardFeature(AppFeature.reply);
      expect(gate, AppStatusGate.maintenance);
    });

    test('force update (version below minimum) blocks the request', () async {
      final service = FakeAppStatusService(
        () async =>
            buildStatus(forceUpdate: true, minSupportedVersion: '2.0.0'),
      );
      final container = makeContainer(service: service, version: '1.0.0');
      final notifier = notifierOf(container);

      await notifier.refresh();
      expect(
        await notifier.guardFeature(AppFeature.reply),
        AppStatusGate.forceUpdate,
      );
    });

    test('force update (same version, older build number) blocks the '
        'request', () async {
      final service = FakeAppStatusService(
        () async => buildStatus(
          forceUpdate: true,
          minSupportedVersion: '1.0.0',
          minSupportedBuildNumber: 33,
        ),
      );
      final container = makeContainer(
        service: service,
        version: '1.0.0',
        buildNumber: 32,
      );
      final notifier = notifierOf(container);

      await notifier.refresh();
      expect(
        await notifier.guardFeature(AppFeature.reply),
        AppStatusGate.forceUpdate,
      );
    });

    test('refresh with forceUpdate=false clears a blocking force-update '
        'state', () async {
      var forceUpdate = true;
      final service = FakeAppStatusService(
        () async => buildStatus(
          forceUpdate: forceUpdate,
          minSupportedVersion: '1.0.0',
          minSupportedBuildNumber: 33,
        ),
      );
      final container = makeContainer(
        service: service,
        version: '1.0.0',
        buildNumber: 32,
      );
      final notifier = notifierOf(container);

      await notifier.refresh();
      expect(
        await notifier.guardFeature(AppFeature.reply),
        AppStatusGate.forceUpdate,
      );

      // Backend turns the flag off; the next refresh clears the block.
      forceUpdate = false;
      await notifier.refresh();
      expect(
        await notifier.guardFeature(AppFeature.reply),
        AppStatusGate.allowed,
      );
    });

    test('a stale blocking force-update cache awaits the refresh and unblocks '
        'when the backend clears the flag', () async {
      var now = DateTime(2026, 1, 1, 12);
      var forceUpdate = true;
      final service = FakeAppStatusService(
        () async => buildStatus(
          forceUpdate: forceUpdate,
          minSupportedVersion: '1.0.0',
          minSupportedBuildNumber: 33,
        ),
      );
      final container = makeContainer(
        service: service,
        version: '1.0.0',
        buildNumber: 32,
        clock: () => now,
      );
      final notifier = notifierOf(container);

      await notifier.refresh(); // cached: force update required
      now = now.add(const Duration(minutes: 6)); // stale
      forceUpdate = false; // backend no longer forces the update

      final gate = await notifier.guardFeature(AppFeature.reply);
      expect(gate, AppStatusGate.allowed);
      expect(service.callCount, 2);
    });

    test('optional update does not block the request', () async {
      final service = FakeAppStatusService(
        () async => buildStatus(latestVersion: '2.0.0'),
      );
      final container = makeContainer(service: service, version: '1.0.0');
      final notifier = notifierOf(container);

      await notifier.refresh();
      expect(
        await notifier.guardFeature(AppFeature.reply),
        AppStatusGate.allowed,
      );
    });

    test('disabledFeatures blocks only the matching feature', () async {
      final service = FakeAppStatusService(
        () async => buildStatus(disabledFeatures: ['reply']),
      );
      final container = makeContainer(service: service);
      final notifier = notifierOf(container);

      await notifier.refresh();
      expect(
        await notifier.guardFeature(AppFeature.reply),
        AppStatusGate.featureDisabled,
      );
      expect(
        await notifier.guardFeature(AppFeature.polish),
        AppStatusGate.allowed,
      );
      expect(
        await notifier.guardFeature(AppFeature.explain),
        AppStatusGate.allowed,
      );
    });

    test('a stale maintenance cache is re-checked before allowing (awaits '
        'refresh)', () async {
      var now = DateTime(2026, 1, 1, 12);
      // First fetch reports maintenance; a later fetch clears it.
      var maintenance = true;
      final service = FakeAppStatusService(
        () async => buildStatus(maintenance: maintenance),
      );
      final container = makeContainer(service: service, clock: () => now);
      final notifier = notifierOf(container);

      await notifier.refresh(); // cached: maintenance
      now = now.add(const Duration(minutes: 6)); // stale
      maintenance = false; // backend recovered

      final gate = await notifier.guardFeature(AppFeature.reply);
      // Because the stale cache was blocking, the guard awaited a fresh value,
      // saw maintenance cleared, and allowed the request.
      expect(gate, AppStatusGate.allowed);
      expect(service.callCount, 2);
    });

    test(
      'refreshAfterRequestFailure reports maintenance vs serverUnavailable',
      () async {
        final maintenanceService = FakeAppStatusService(
          () async => buildStatus(maintenance: true),
        );
        final c1 = makeContainer(service: maintenanceService);
        expect(
          await notifierOf(c1).refreshAfterRequestFailure(),
          AppStatusPostError.maintenance,
        );

        final downService = FakeAppStatusService(
          () => Future<AppStatus>.error(const ApiError(message: 'offline')),
        );
        final c2 = makeContainer(service: downService);
        expect(
          await notifierOf(c2).refreshAfterRequestFailure(),
          AppStatusPostError.serverUnavailable,
        );
      },
    );

    test('persists the last known status and restores it on rebuild', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = FakeAppStatusService(
        () async => buildStatus(maintenance: true),
      );
      final container = ProviderContainer(
        overrides: [
          appStatusServiceProvider.overrideWithValue(service),
          currentAppVersionProvider.overrideWithValue('1.0.0'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await notifierOf(container).refresh();
      expect(prefs.getString('app_status_last_known_v1'), isNotNull);

      // A fresh container (new controller) restores the persisted status.
      final revived = ProviderContainer(
        overrides: [
          appStatusServiceProvider.overrideWithValue(
            FakeAppStatusService(() => Completer<AppStatus>().future),
          ),
          currentAppVersionProvider.overrideWithValue('1.0.0'),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(revived.dispose);
      expect(
        revived.read(appStatusControllerProvider).status?.maintenance,
        isTrue,
      );
    });
  });

  // ── Presentation ───────────────────────────────────────────────────────────

  group('widgets', () {
    Widget wrap({required List<Override> overrides, required Widget home}) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );
    }

    testWidgets('force update shows a full-screen block over the app', (
      tester,
    ) async {
      var launched = 0;
      final service = FakeAppStatusService(
        () async =>
            buildStatus(forceUpdate: true, minSupportedVersion: '2.0.0'),
      );
      await tester.pumpWidget(
        wrap(
          overrides: [
            appStatusServiceProvider.overrideWithValue(service),
            currentAppVersionProvider.overrideWithValue('1.0.0'),
            currentAppBuildNumberProvider.overrideWithValue(1),
            storeLauncherProvider.overrideWithValue(() async {
              launched++;
              return true;
            }),
          ],
          home: const AppStatusBoundary(child: Text('APP BODY')),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppStatusBoundary)),
      );
      await container.read(appStatusControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('force-update-block')), findsOneWidget);
      expect(find.text('APP BODY'), findsNothing); // app is blocked

      await tester.tap(find.byKey(const Key('force-update-block-update')));
      await tester.pump();
      expect(launched, 1);
    });

    testWidgets('force update block clears when a retry finds '
        'forceUpdate=false', (tester) async {
      var forceUpdate = true;
      final service = FakeAppStatusService(
        () async => buildStatus(
          forceUpdate: forceUpdate,
          minSupportedVersion: '1.0.0',
          minSupportedBuildNumber: 33,
        ),
      );
      await tester.pumpWidget(
        wrap(
          overrides: [
            appStatusServiceProvider.overrideWithValue(service),
            currentAppVersionProvider.overrideWithValue('1.0.0'),
            currentAppBuildNumberProvider.overrideWithValue(32),
            storeLauncherProvider.overrideWithValue(() async => true),
          ],
          home: const AppStatusBoundary(child: Text('APP BODY')),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppStatusBoundary)),
      );
      await container.read(appStatusControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('force-update-block')), findsOneWidget);

      // Backend stops forcing the update; Retry refreshes and unblocks.
      forceUpdate = false;
      await tester.tap(find.byKey(const Key('force-update-block-retry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('force-update-block')), findsNothing);
      expect(find.text('APP BODY'), findsOneWidget);
    });

    testWidgets('force update block does not appear for a build at the '
        'supported floor', (tester) async {
      final service = FakeAppStatusService(
        () async => buildStatus(
          forceUpdate: true,
          minSupportedVersion: '1.0.0',
          minSupportedBuildNumber: 33,
        ),
      );
      await tester.pumpWidget(
        wrap(
          overrides: [
            appStatusServiceProvider.overrideWithValue(service),
            currentAppVersionProvider.overrideWithValue('1.0.0'),
            currentAppBuildNumberProvider.overrideWithValue(33),
            storeLauncherProvider.overrideWithValue(() async => true),
          ],
          home: const AppStatusBoundary(child: Text('APP BODY')),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppStatusBoundary)),
      );
      await container.read(appStatusControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('force-update-block')), findsNothing);
      expect(find.text('APP BODY'), findsOneWidget);
    });

    testWidgets('optional update overlays without blocking the app', (
      tester,
    ) async {
      final service = FakeAppStatusService(
        () async => buildStatus(latestVersion: '2.0.0'),
      );
      await tester.pumpWidget(
        wrap(
          overrides: [
            appStatusServiceProvider.overrideWithValue(service),
            currentAppVersionProvider.overrideWithValue('1.0.0'),
            currentAppBuildNumberProvider.overrideWithValue(1),
            storeLauncherProvider.overrideWithValue(() async => true),
          ],
          home: const AppStatusBoundary(child: Text('APP BODY')),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppStatusBoundary)),
      );
      await container.read(appStatusControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('optional-update-prompt')), findsOneWidget);
      // The app is still present underneath (not blocked).
      expect(find.text('APP BODY'), findsOneWidget);

      await tester.tap(find.byKey(const Key('optional-update-later')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('optional-update-prompt')), findsNothing);
      expect(find.text('APP BODY'), findsOneWidget);
    });

    testWidgets('optional update triggers on a newer build number alone', (
      tester,
    ) async {
      final service = FakeAppStatusService(
        () async => buildStatus(
          latestVersion: '1.0.0',
          latestBuildNumber: 34,
        ),
      );
      await tester.pumpWidget(
        wrap(
          overrides: [
            appStatusServiceProvider.overrideWithValue(service),
            currentAppVersionProvider.overrideWithValue('1.0.0'),
            currentAppBuildNumberProvider.overrideWithValue(33),
            storeLauncherProvider.overrideWithValue(() async => true),
          ],
          home: const AppStatusBoundary(child: Text('APP BODY')),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppStatusBoundary)),
      );
      await container.read(appStatusControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('optional-update-prompt')), findsOneWidget);
      expect(find.text('APP BODY'), findsOneWidget);
    });

    testWidgets('ensureAppStatusAllows blocks with a maintenance dialog', (
      tester,
    ) async {
      final service = FakeAppStatusService(
        () async => buildStatus(maintenance: true),
      );
      await tester.pumpWidget(
        wrap(
          overrides: [
            appStatusServiceProvider.overrideWithValue(service),
            currentAppVersionProvider.overrideWithValue('1.0.0'),
          ],
          home: const _GateHarness(feature: AppFeature.reply),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(_GateHarness)),
      );
      await container.read(appStatusControllerProvider.notifier).refresh();
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // The blocking maintenance dialog is shown (request never proceeds).
      expect(find.byKey(const Key('maintenance-dialog')), findsOneWidget);
    });

    testWidgets('ensureAppStatusAllows shows a snackbar only for the disabled '
        'feature', (tester) async {
      final service = FakeAppStatusService(
        () async => buildStatus(disabledFeatures: ['reply']),
      );
      bool? allowed;
      await tester.pumpWidget(
        wrap(
          overrides: [
            appStatusServiceProvider.overrideWithValue(service),
            currentAppVersionProvider.overrideWithValue('1.0.0'),
          ],
          home: _GateHarness(
            feature: AppFeature.polish,
            onResult: (v) => allowed = v,
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(_GateHarness)),
      );
      await container.read(appStatusControllerProvider.notifier).refresh();
      await tester.pump();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // Polish is not disabled → allowed, no snackbar.
      expect(allowed, isTrue);
      expect(
        find.byKey(const Key('feature-unavailable-snackbar')),
        findsNothing,
      );
    });

    testWidgets(
      'handleAiRequestFailure shows the server-unavailable fallback',
      (tester) async {
        final service = FakeAppStatusService(
          () => Future<AppStatus>.error(const ApiError(message: 'offline')),
        );
        await tester.pumpWidget(
          wrap(
            overrides: [
              appStatusServiceProvider.overrideWithValue(service),
              currentAppVersionProvider.overrideWithValue('1.0.0'),
            ],
            home: const _FailureHarness(),
          ),
        );

        await tester.tap(find.text('fail'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('server-unavailable-dialog')),
          findsOneWidget,
        );
      },
    );
  });
}

class _GateHarness extends ConsumerWidget {
  const _GateHarness({required this.feature, this.onResult});

  final AppFeature feature;
  final void Function(bool)? onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () async {
          final ok = await ensureAppStatusAllows(
            context: context,
            ref: ref,
            feature: feature,
          );
          onResult?.call(ok);
        },
        child: const Text('go'),
      ),
    ),
  );
}

class _FailureHarness extends ConsumerWidget {
  const _FailureHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () => handleAiRequestFailure(context: context, ref: ref),
        child: const Text('fail'),
      ),
    ),
  );
}
