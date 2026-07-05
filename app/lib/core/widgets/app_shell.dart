import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../localization/localization_extensions.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

const _navInactive = AppColors.navBarUnselected;

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  List<_TabData> _tabs(BuildContext context) => [
    (
      route: AppRoutes.home,
      label: context.l10n.home,
      icon: Icons.home_rounded,
      color: AppColors.primaryBlue,
    ),
    (
      route: AppRoutes.reply,
      label: context.l10n.reply,
      icon: Icons.reply_rounded,
      color: AppColors.replyColor,
    ),
    (
      route: AppRoutes.explain,
      label: context.l10n.explain,
      icon: Icons.psychology_alt_rounded,
      color: AppColors.explainColor,
    ),
    (
      route: AppRoutes.polish,
      label: context.l10n.polish,
      icon: Icons.auto_fix_high_rounded,
      color: AppColors.polishColor,
    ),
    (
      route: AppRoutes.settings,
      label: context.l10n.settings,
      icon: Icons.settings_rounded,
      color: AppColors.primaryBlue,
    ),
  ];

  int _selectedIndex(BuildContext context, List<_TabData> tabs) {
    final location = GoRouterState.of(context).uri.path;
    if (location == AppRoutes.home) return 0;
    final idx = tabs.indexWhere(
      (t) => t.route != AppRoutes.home && location.startsWith(t.route),
    );
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs(context);
    final selectedIndex = _selectedIndex(context, tabs);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: child,
      bottomNavigationBar: _SoftNavBar(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onSelected: (i) => context.go(tabs[i].route),
      ),
    );
  }
}

typedef _TabData = ({String route, String label, IconData icon, Color color});

class _SoftNavBar extends StatelessWidget {
  const _SoftNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_TabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // Full-width bar attached to the bottom edge, with a soft upward shadow
    // to lift it off the content.
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x3349619A),
            blurRadius: 28,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    data: tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _TabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? data.color : _navInactive;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.navLabel.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
