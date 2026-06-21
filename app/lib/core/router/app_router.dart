import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/reply/reply_screen.dart';
import '../../features/polish/polish_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../widgets/app_shell.dart';

part 'app_router.g.dart';

// Route path constants
abstract final class AppRoutes {
  static const String reply = '/reply';
  static const String polish = '/polish';
  static const String settings = '/settings';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.reply,
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.reply,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReplyScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.polish,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PolishScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
