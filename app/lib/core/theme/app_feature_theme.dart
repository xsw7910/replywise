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
  }) {
    final strength = tintStrength.clamp(0.0, 1.0);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(Colors.white, lightTintColor, 0.35 * strength)!,
          Color.lerp(Colors.white, lightTintColor, strength)!,
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
