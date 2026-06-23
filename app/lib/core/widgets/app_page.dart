import 'package:flutter/material.dart';

import '../theme/app_skin.dart';

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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppSkin.backgroundGradient,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: 90, right: -70, child: _Glow(size: 210)),
            const Positioned(top: 430, left: -85, child: _Glow(size: 180)),
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

class _Glow extends StatelessWidget {
  const _Glow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppSkin.blueGlow,
        ),
      ),
    );
  }
}
