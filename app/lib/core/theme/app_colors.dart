import 'package:flutter/material.dart';

/// Pale-blue palette — chosen to work as a glassmorphism base.
abstract final class AppColors {
  // Primary blues
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryLight = Color(0xFF82B8F0);
  static const Color primaryDark = Color(0xFF2265A8);

  // Backgrounds — near-white with a blue tint
  static const Color backgroundBase = Color(0xFFF7F9FD);
  static const Color backgroundSurface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFD3DCEC);
  static const Color cardShadow = Color(0x3C49619A);
  static const Color cardSoftShadow = Color(0x1E49619A);

  // Glass layer (semi-transparent white for glassmorphism cards)
  static const Color glassFill = Color(0xCCFFFFFF); // 80 % white
  static const Color glassBorder = Color(0x33FFFFFF); // 20 % white

  // Text
  static const Color textPrimary = Color(0xFF1A2340);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textHint = Color(0xFFADB8CC);

  // Accents / semantic
  static const Color accent = Color(0xFF3ECFCF);
  static const Color error = Color(0xFFE05252);
  static const Color success = Color(0xFF3BC47C);

  // Nav bar
  static const Color navBarBackground = Color(0xFFF8FBFF);
  static const Color navBarSelected = Color(0xFF4A90D9);
  static const Color navBarUnselected = Color(0xFFADB8CC);
}
