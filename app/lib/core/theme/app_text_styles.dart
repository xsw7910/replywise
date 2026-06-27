import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // Soft typography system.
  // Pure black is never used for UI text; titles are soft navy, body/helper are
  // blue-gray, and the app blue is reserved for active/accent states.

  /// Large page / brand title. Apply the feature accent (or [AppColors.primaryBlue])
  /// per screen via `.copyWith(color: ...)`.
  static const TextStyle pageTitle = TextStyle(
    inherit: true,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBlue,
    letterSpacing: -0.5,
  );

  /// Section header within a page.
  static const TextStyle sectionTitle = TextStyle(
    inherit: true,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.sectionTitle,
  );

  /// Title inside a card / list tile.
  static const TextStyle cardTitle = TextStyle(
    inherit: true,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.cardTitle,
  );

  /// Primary body / descriptive text.
  static const TextStyle body = TextStyle(
    inherit: true,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Helper / subtitle / secondary text.
  static const TextStyle helper = TextStyle(
    inherit: true,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.35,
  );

  /// Input placeholder / hint text.
  static const TextStyle placeholder = TextStyle(
    inherit: true,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  /// Primary button label. Apply a color per button.
  static const TextStyle button = TextStyle(
    inherit: true,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  /// Bottom-navigation label.
  static const TextStyle navLabel = TextStyle(
    inherit: true,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.1,
  );

  /// Small pill / badge label. Apply a color per badge.
  static const TextStyle badge = TextStyle(
    inherit: true,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
}
