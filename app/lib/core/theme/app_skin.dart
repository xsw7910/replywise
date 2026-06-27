import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Fixed design tokens for the single ReplyWise light glass theme.
abstract final class AppSkin {
  static const List<Color> backgroundGradient = [
    Color(0xFFDCE9FF),
    Color(0xFFEAF1FF),
    Color(0xFFF4F8FF),
  ];

  static const Color panelFill = Color(0xB8FFFFFF);
  static const Color panelBorder = AppColors.glassEdgeStrong;
  static const Color resultFill = Color(0xF2FFFFFF);
  static const Color inputFill = Color(0xE6FFFFFF);
  static const Color blueGlow = Color(0x405B9CF5);

  static const double panelBlur = 18;
  static const double panelRadius = 18;
  static const double pagePadding = 16;
}
