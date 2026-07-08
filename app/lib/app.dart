import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:replywise/l10n/app_localizations.dart';

import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/app_status/application/app_status_controller.dart';
import 'features/app_status/presentation/app_status_gate.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/auth_state.dart';
import 'features/entitlement/credit_controller.dart';
import 'features/entitlement/subscription_controller.dart';
import 'features/entitlement/usage_controller.dart';

class ReplyWiseApp extends ConsumerStatefulWidget {
  const ReplyWiseApp({super.key});

  @override
  ConsumerState<ReplyWiseApp> createState() => _ReplyWiseAppState();
}

class _ReplyWiseAppState extends ConsumerState<ReplyWiseApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Startup app-status fetch — scheduled, never awaited, so the first frame
    // is never blocked on the network.
    Future.microtask(
      () => ref.read(appStatusControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check remote config when the app returns to the foreground. The fetch
    // is non-blocking, TTL-aware, and keeps the last known status on failure.
    if (state == AppLifecycleState.resumed) {
      ref.read(appStatusControllerProvider.notifier).refreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Instantiate the app-status controller so its non-blocking startup fetch
    // runs. The UI is never delayed on it: AppStatusGate and the per-request
    // gate consume whatever is cached.
    ref.watch(appStatusControllerProvider);
    // Watching authControllerProvider triggers the startup auth flow.
    ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        final appUserId = next.appUserId;
        Future.microtask(() {
          ref.read(usageControllerProvider.notifier).refresh();
          ref.read(creditControllerProvider.notifier).syncCredits();
          // Reinstall recovery: silently restore an already-active premium
          // subscription (getCustomerInfo only — no purchase/restore UI).
          if (appUserId != null) {
            ref
                .read(subscriptionControllerProvider.notifier)
                .syncActivePremiumSilently(appUserId);
          }
        });
      }
    });
    final router = ref.watch(appRouterProvider);
    final localePreference = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'ReplyWise',
      locale: localeFromPreference(localePreference),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          AppStatusBoundary(child: child ?? const SizedBox.shrink()),
    );
  }
}
