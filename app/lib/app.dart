import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/auth_state.dart';
import 'features/entitlement/credit_controller.dart';
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
        Future.microtask(() {
          ref.read(usageControllerProvider.notifier).refresh();
          ref.read(creditControllerProvider.notifier).syncCredits();
        });
      }
    });
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ReplyWise',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
