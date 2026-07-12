import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_feature_theme.dart';
import '../theme/app_text_styles.dart';

/// Shared presentation for user-facing errors on the Reply / Explain / Polish
/// action flows. Slides up from the bottom with rounded top corners and the
/// app's soft light-blue card styling.
///
/// [showAppErrorBottomSheet] covers the common "show, then dismiss on tap"
/// case; blocking states (maintenance / force update) embed
/// [AppErrorSheetBody] in their own stateful wrappers so the buttons can run
/// async work without dismissing the sheet.
Future<T?> showAppErrorBottomSheet<T>({
  required BuildContext context,
  required AppFeature feature,
  Key? sheetKey,
  required IconData icon,
  required String title,
  required String message,
  required String primaryLabel,
  Key? primaryKey,
  VoidCallback? onPrimary,
  String? secondaryLabel,
  Key? secondaryKey,
  VoidCallback? onSecondary,
  bool isDismissible = true,
  String? technicalDetails,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AppErrorSheetContainer(
      sheetKey: sheetKey,
      child: AppErrorSheetBody(
        feature: feature,
        icon: icon,
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        primaryKey: primaryKey,
        onPrimary: () {
          Navigator.of(sheetContext).pop();
          onPrimary?.call();
        },
        secondaryLabel: secondaryLabel,
        secondaryKey: secondaryKey,
        onSecondary: onSecondary == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onSecondary();
              },
        showHandle: isDismissible,
        technicalDetails: technicalDetails,
      ),
    ),
  );
}

/// Rounded-top, soft-card container shared by every error bottom sheet.
class AppErrorSheetContainer extends StatelessWidget {
  const AppErrorSheetContainer({super.key, this.sheetKey, required this.child});

  final Key? sheetKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sheetKey,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 14,
            bottom: 18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Icon + title + message + primary/secondary action layout used inside
/// [AppErrorSheetContainer].
class AppErrorSheetBody extends StatelessWidget {
  const AppErrorSheetBody({
    super.key,
    required this.icon,
    required this.feature,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryKey,
    this.primaryBusy = false,
    this.secondaryLabel,
    this.secondaryKey,
    this.onSecondary,
    this.secondaryBusy = false,
    this.showHandle = true,
    this.technicalDetails,
  });

  final IconData icon;
  final AppFeature feature;
  final String title;
  final String message;
  final String primaryLabel;
  final Key? primaryKey;
  final VoidCallback? onPrimary;
  final bool primaryBusy;
  final String? secondaryLabel;
  final Key? secondaryKey;
  final VoidCallback? onSecondary;
  final bool secondaryBusy;
  final bool showHandle;

  /// Raw error detail shown only in debug builds; never in release.
  final String? technicalDetails;

  @override
  Widget build(BuildContext context) {
    final accentColor = feature.accentColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle)
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
        else
          const SizedBox(height: 8),
        Center(
          child: Container(
            key: const Key('app-error-sheet-icon-container'),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: feature.iconBackgroundColor,
              border: Border.all(color: feature.selectedChipColor),
            ),
            child: Icon(
              icon,
              key: const Key('app-error-sheet-icon'),
              size: 32,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        if (kDebugMode && technicalDetails != null) ...[
          const SizedBox(height: 10),
          Text(
            technicalDetails!,
            textAlign: TextAlign.center,
            style: AppTextStyles.helper.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton(
          key: primaryKey,
          onPressed: primaryBusy ? null : onPrimary,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: primaryBusy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(primaryLabel),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 8),
          TextButton(
            key: secondaryKey,
            onPressed: secondaryBusy ? null : onSecondary,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: accentColor,
            ),
            child: secondaryBusy
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: accentColor,
                    ),
                  )
                : Text(secondaryLabel!),
          ),
        ],
      ],
    );
  }
}
