import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_skin.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2F0EF),
      onSecondaryContainer: Color(0xFF004D4D),
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.backgroundSurface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.backgroundBase,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.textHint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundBase,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelMedium: AppTextStyles.labelMedium,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        indicatorColor: AppColors.primaryLight.withAlpha(80),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navBarSelected);
          }
          return const IconThemeData(color: AppColors.navBarUnselected);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelMedium.copyWith(
              color: AppColors.navBarSelected,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.labelMedium;
        }),
        elevation: 4,
        shadowColor: AppColors.primary.withAlpha(30),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppSkin.inputFill,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryLight.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryLight.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withAlpha(150),
        selectedColor: AppColors.primaryLight.withAlpha(100),
        side: BorderSide(color: Colors.white.withAlpha(210)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: AppTextStyles.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}
