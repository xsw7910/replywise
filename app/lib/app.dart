import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';

class ReplyWiseApp extends ConsumerWidget {
  const ReplyWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching authControllerProvider triggers the startup auth flow.
    ref.watch(authControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ReplyWise',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
