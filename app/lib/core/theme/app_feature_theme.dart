import 'package:flutter/material.dart';

import 'app_colors.dart';

enum AppFeature { reply, polish, explain, guidance }

extension AppFeatureTheme on AppFeature {
  Color get accentColor => switch (this) {
    AppFeature.reply => AppColors.replyColor,
    AppFeature.polish => AppColors.polishColor,
    AppFeature.explain => AppColors.explainColor,
    AppFeature.guidance => AppColors.guidanceColor,
  };

  /// Icon image shown on the Home feature card and each feature page header.
  /// Single source so the two stay in sync.
  String get iconImage => switch (this) {
    AppFeature.reply => 'assets/icons/reply.png',
    AppFeature.polish => 'assets/icons/polish.png',
    AppFeature.explain => 'assets/icons/explain.png',
    AppFeature.guidance => 'assets/icons/guidance.png',
  };

  /// Texture used as the fill of feature [GlassCard]s and home feature cards.
  String get backgroundImage => switch (this) {
    AppFeature.reply => 'assets/image/reply_background.png',
    AppFeature.polish => 'assets/image/polish_background.png',
    AppFeature.explain => 'assets/image/explain_background.png',
    AppFeature.guidance => 'assets/image/guidance_background.png',
  };

  /// Full-page background shown behind the content of each feature page.
  String get pageBackgroundImage => switch (this) {
    AppFeature.reply => 'assets/image/reply_page_backgroud.png',
    AppFeature.polish => 'assets/image/polish_page_backgroud.png',
    AppFeature.explain => 'assets/image/explain_page_backgroud.png',
    AppFeature.guidance => 'assets/image/guidance_page_backgroud.png',
  };

  Color get lightTintColor => switch (this) {
    AppFeature.reply => const Color(0xFFEAF4FF),
    AppFeature.polish => const Color(0xFFF3EFFF),
    AppFeature.explain => const Color(0xFFEAFBF7),
    AppFeature.guidance => const Color(0xFFFFF4E5),
  };

  Color get selectedChipColor => Color.lerp(Colors.white, accentColor, 0.14)!;

  Color get iconBackgroundColor => Color.lerp(Colors.white, accentColor, 0.18)!;

  Color get primaryButtonColor => accentColor;

  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(Colors.white, lightTintColor, 0.35)!, lightTintColor],
  );

  BoxDecoration glassCardDecoration({
    double borderRadius = 28,
    double tintStrength = 1,
    Color? tintColor,
  }) {
    final strength = tintStrength.clamp(0.0, 1.0);
    final tint = tintColor ?? lightTintColor;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(Colors.white, tint, 0.35 * strength)!,
          Color.lerp(Colors.white, tint, strength)!,
        ],
      ),
      border: Border.all(color: const Color(0xE0FFFFFF), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x326B8FBF),
          offset: Offset(0, 13),
          blurRadius: 25,
          spreadRadius: -7,
        ),
        BoxShadow(
          color: Color(0x206B8FBF),
          offset: Offset(1, 4),
          blurRadius: 8,
          spreadRadius: -3,
        ),
        BoxShadow(
          color: Color(0x8FFFFFFF),
          offset: Offset(-3, -3),
          blurRadius: 9,
          spreadRadius: -4,
        ),
      ],
    );
  }
}
