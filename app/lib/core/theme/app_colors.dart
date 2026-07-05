import 'package:flutter/material.dart';

/// Pale-blue palette — chosen to work as a glassmorphism base.
abstract final class AppColors {
  // Unified app blue for default active states, buttons, links, and focus.
  static const Color primary = Color(0xFF2F80ED);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color primaryDark = Color(0xFF1D5FBF);

  // Backgrounds — near-white with a blue tint
  static const Color backgroundBase = Color(0xFFFBFCFE);
  static const Color backgroundSurface = Color(0xFFFFFFFF);
  static const Color recentCardBackground = Color(0xFFF1F6FF);
  static const Color cardBorder = Color(0xFFD3DCEC);
  static const Color cardShadow = Color(0x3C49619A);
  static const Color cardSoftShadow = Color(0x1E49619A);
  static const Color softBlueShadow = Color(0x246B8FBF);
  static const Color softOutline = Color(0x14143A66);
  static const Color softNeutralShadow = Color(0x1A49619A);

  // Glass layer (semi-transparent white for glassmorphism cards)
  static const Color glassFill = Color(0xCCFFFFFF); // 80 % white
  static const Color glassBorder = Color(0x33FFFFFF); // 20 % white
  static const Color glassEdgeStrong = glassFill;

  // Text — soft navy / blue-gray typography system
  static const Color textPrimary = Color(0xFF1E2A44); // page titles
  static const Color cardTitle = Color(0xFF3E5578);
  static const Color sectionTitle = Color(0xFF4F6585);
  static const Color textTitleAlt = Color(
    0xFF24324F,
  ); // alternative softer title
  static const Color textSecondary = Color(0xFF71809A); // body / helper
  static const Color textMuted = Color(0xFF8FA0BA); // secondary muted text
  static const Color textHint = Color(0xFFAAB5C8); // input placeholders
  static const Color textDisabled = Color(0xFFB8C2D3); // disabled text

  // App primary blue — active states, buttons, selected tabs, links, accents.
  static const Color primaryBlue = primary;

  // Feature accent colors — matched to Home page feature tiles.
  static const Color replyColor = Color(0xFF2F80ED);
  static const Color polishColor = Color(0xFF8B5CF6);
  static const Color explainColor = Color(0xFF20C7B5);
  static const Color guidanceColor = Color(0xFFF59E0B);
  static const Color guidanceDark = Color(0xFFB86E00);

  // Accents / semantic
  static const Color accent = Color(0xFF3ECFCF);
  static const Color error = Color(0xFFE05252);
  static const Color success = Color(0xFF3BC47C);

  // Premium / subscription accent (gold) used for crown badges.
  static const Color premiumGold = Color(0xFFD99A00);

  // Nav bar
  static const Color navBarBackground = Color(0xFFF8FBFF);
  static const Color navBarSelected = primaryBlue;
  static const Color navBarUnselected = textMuted;
}
