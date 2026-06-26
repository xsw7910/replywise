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
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showAppBar;
  final bool useSafeArea;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final titleStyle = accentColor != null
        ? (Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle())
            .copyWith(color: accentColor, fontWeight: FontWeight.w700)
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              title: Text(title, style: titleStyle),
              actions: actions,
              automaticallyImplyLeading: showBackButton,
              backgroundColor: Colors.white.withAlpha(175),
              iconTheme: accentColor != null
                  ? IconThemeData(color: accentColor)
                  : null,
            )
          : null,
      body: ColoredBox(
        color: AppColors.backgroundBase,
        child: Stack(
          children: [
            if (useSafeArea)
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: showAppBar ? kToolbarHeight : 0,
                  ),
                  child: child,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(top: showAppBar ? kToolbarHeight : 0),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
