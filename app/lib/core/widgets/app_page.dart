import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBackButton = false,
    this.showAppBar = true,
    this.useSafeArea = true,
    this.accentColor,
    this.headerImagePath,
    this.headerIcon,
    this.subtitle,
    this.backgroundImagePath,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showAppBar;
  final bool useSafeArea;
  final Color? accentColor;
  final String? headerImagePath;
  final IconData? headerIcon;
  final String? subtitle;
  final String? backgroundImagePath;

  @override
  Widget build(BuildContext context) {
    final hasFeatureHeader = headerImagePath != null || headerIcon != null;
    final toolbarHeight = hasFeatureHeader ? 68.0 : kToolbarHeight;
    final titleStyle = accentColor != null
        ? (Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle())
              .copyWith(color: accentColor, fontWeight: FontWeight.w700)
        : null;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: showAppBar
          ? AppBar(
              toolbarHeight: toolbarHeight,
              titleSpacing: showBackButton ? 0 : 16,
              title: hasFeatureHeader
                  ? _FeatureNavigationTitle(
                      title: title,
                      subtitle: subtitle,
                      imagePath: headerImagePath,
                      icon: headerIcon,
                      color: accentColor ?? AppColors.primary,
                    )
                  : Text(title, style: titleStyle),
              actions: actions,
              automaticallyImplyLeading: showBackButton,
              backgroundColor: Colors.white.withAlpha(175),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: accentColor != null
                  ? IconThemeData(color: accentColor)
                  : null,
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: backgroundImagePath != null
                ? Image.asset(backgroundImagePath!, fit: BoxFit.cover)
                : const ColoredBox(color: AppColors.backgroundBase),
          ),
          if (useSafeArea)
            SafeArea(top: !showAppBar, child: child)
          else
            child,
        ],
      ),
    );
  }
}

class _FeatureNavigationTitle extends StatelessWidget {
  const _FeatureNavigationTitle({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
  });

  final String title;
  final String? subtitle;
  final String? imagePath;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: imagePath != null
                ? Transform.scale(
                    scale: 1.08,
                    child: Image.asset(imagePath!, fit: BoxFit.cover),
                  )
                : ColoredBox(
                    color: color.withAlpha(30),
                    child: Icon(icon, color: color, size: 22),
                  ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
