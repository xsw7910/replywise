import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
    this.transparentAppBar = false,
    this.centerTitle,
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

  /// When true the app bar is fully transparent and the body (including the
  /// background image) extends to the top of the screen, behind the header.
  final bool transparentAppBar;

  /// Overrides the app bar title alignment. Null inherits the app theme
  /// (centered); false left-aligns the title.
  final bool? centerTitle;

  @override
  Widget build(BuildContext context) {
    final hasFeatureHeader = headerImagePath != null || headerIcon != null;
    final toolbarHeight = hasFeatureHeader ? 68.0 : kToolbarHeight;
    final titleStyle = accentColor != null
        ? (Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle())
              .copyWith(color: accentColor, fontWeight: FontWeight.w700)
        : null;

    return Scaffold(
      extendBodyBehindAppBar: transparentAppBar,
      appBar: showAppBar
          ? AppBar(
              toolbarHeight: toolbarHeight,
              centerTitle: centerTitle,
              titleSpacing: showBackButton ? 0 : 16,
              title: hasFeatureHeader
                  ? _FeatureNavigationTitle(
                      title: title,
                      subtitle: subtitle,
                      imagePath: headerImagePath,
                      icon: headerIcon,
                      color: accentColor ?? AppColors.primaryBlue,
                    )
                  : Text(title, style: titleStyle),
              actions: actions,
              automaticallyImplyLeading: showBackButton,
              backgroundColor: transparentAppBar
                  ? Colors.transparent
                  : Colors.white.withAlpha(175),
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
            SafeArea(
              top: transparentAppBar || !showAppBar,
              child: transparentAppBar && showAppBar
                  ? Padding(
                      padding: EdgeInsets.only(top: toolbarHeight),
                      child: child,
                    )
                  : child,
            )
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
                style: AppTextStyles.cardTitle.copyWith(
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
                  style: AppTextStyles.helper.copyWith(
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
