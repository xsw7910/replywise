import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:replywise/l10n/app_localizations.dart';

import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/auth_state.dart';
import 'features/entitlement/credit_controller.dart';
import 'features/entitlement/subscription_controller.dart';
import 'features/entitlement/usage_controller.dart';

class ReplyWiseApp extends ConsumerWidget {
  const ReplyWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    );
  }
}
