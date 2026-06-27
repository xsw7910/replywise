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
      textTheme: TextTheme(
        displayLarge: AppTextStyles.pageTitle.copyWith(
          color: AppColors.textPrimary,
        ),
        displayMedium: AppTextStyles.pageTitle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 27,
        ),
        displaySmall: AppTextStyles.pageTitle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 24,
        ),
        headlineLarge: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
        headlineMedium: AppTextStyles.sectionTitle,
        headlineSmall: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
        titleSmall: AppTextStyles.cardTitle.copyWith(fontSize: 15),
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body.copyWith(fontSize: 14),
        bodySmall: AppTextStyles.helper,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.badge,
        labelSmall: AppTextStyles.badge.copyWith(fontSize: 10),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.cardTitle,
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
            return AppTextStyles.navLabel.copyWith(
              color: AppColors.navBarSelected,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.navLabel;
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
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTextStyles.button.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.primaryBlue),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          disabledForegroundColor: AppColors.textDisabled,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppSkin.inputFill,
        hintStyle: AppTextStyles.placeholder,
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
        disabledColor: AppColors.backgroundBase,
        side: BorderSide(color: Colors.white.withAlpha(210)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: AppTextStyles.helper,
        secondaryLabelStyle: AppTextStyles.helper.copyWith(
          color: AppColors.primaryDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
        deleteIconColor: AppColors.textSecondary,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primaryBlue,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.body,
        subtitleTextStyle: AppTextStyles.helper,
        leadingAndTrailingTextStyle: AppTextStyles.helper,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.backgroundSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.sectionTitle,
        contentTextStyle: AppTextStyles.body,
        iconColor: AppColors.primaryBlue,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundSurface,
        modalBackgroundColor: AppColors.backgroundSurface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.textHint,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.backgroundSurface,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTextStyles.body,
        iconColor: AppColors.textSecondary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.helper.copyWith(color: Colors.white),
      ),
    );
  }
}
