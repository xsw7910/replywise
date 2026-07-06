import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/guidance/domain/guidance_template.dart';
import '../../features/guidance/presentation/guidance_edit_screen.dart';
import '../../features/guidance/presentation/guidance_library_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/recent/domain/recent_item.dart';
import '../../features/recent/presentation/history_screen.dart';
import '../../features/recent/presentation/recent_detail_screen.dart';
import '../../features/polish/polish_screen.dart';
import '../../features/reply/explain_screen.dart';
import '../../features/reply/reply_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../widgets/app_shell.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String reply = '/reply';
  static const String explain = '/explain';
  static const String polish = '/polish';
  static const String settings = '/settings';
  static const String paywall = '/paywall';
  static const String history = '/history';
  static const String recentDetail = '/recent';
  static const String guidanceLibrary = '/guidance-library';
  static const String guidanceEdit = '/guidance-library/edit';

  /// Path to the Recent Detail page for a given item id (`/recent/:id`).
  static String recentDetailPath(String id) => '$recentDetail/$id';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.recentDetail}/:id',
        builder: (context, state) {
          final extra = state.extra;
          return RecentDetailScreen(
            id: state.pathParameters['id']!,
            initialItem: extra is RecentItem ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.guidanceLibrary,
        builder: (context, state) => const GuidanceLibraryScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final extra = state.extra;
              return GuidanceEditScreen(
                existing: extra is GuidanceTemplate ? extra : null,
              );
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.reply,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReplyScreen()),
          ),
          GoRoute(
            path: AppRoutes.explain,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ExplainScreen()),
          ),
          GoRoute(
            path: AppRoutes.polish,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PolishScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}
