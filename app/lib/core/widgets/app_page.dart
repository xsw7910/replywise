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
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showAppBar;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: actions,
              automaticallyImplyLeading: showBackButton,
              backgroundColor: Colors.white.withAlpha(175),
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
