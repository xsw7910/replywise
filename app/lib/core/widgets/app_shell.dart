import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (route: AppRoutes.reply, label: 'Reply', icon: Icons.reply_rounded),
    (
      route: AppRoutes.explain,
      label: 'Explain',
      icon: Icons.psychology_alt_rounded,
    ),
    (
      route: AppRoutes.polish,
      label: 'Polish',
      icon: Icons.auto_fix_high_rounded,
    ),
    (
      route: AppRoutes.settings,
      label: 'Settings',
      icon: Icons.settings_rounded,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.route));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].route),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}
