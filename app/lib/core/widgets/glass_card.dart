import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_feature_theme.dart';

/// A frosted-glass card ready for glassmorphism layouts.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.blur = 12,
    this.fillColor,
    this.feature,
    this.tintStrength = 1,
    this.tintColor,
    this.showFeatureImage = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final double blur;
  final Color? fillColor;
  final AppFeature? feature;
  final double tintStrength;
  final Color? tintColor;

  /// When false, a feature card keeps its tinted glass decoration but omits the
  /// photographic background texture.
  final bool showFeatureImage;

  @override
  Widget build(BuildContext context) {
    final f = feature;
    final radius = borderRadius ?? (f == null ? 20 : 28);

    // Feature cards use the themed background image as their fill, keeping the
    // soft border + shadow so they stay distinct from the page background.
    if (f != null) {
      final content = Padding(padding: padding, child: child);
      return Container(
        decoration: f.glassCardDecoration(
          borderRadius: radius,
          tintStrength: tintStrength,
          tintColor: tintColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: showFeatureImage
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(f.backgroundImage, fit: BoxFit.cover),
                    ),
                    content,
                  ],
                )
              : content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.cardSoftShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: fillColor ?? Colors.white,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: AppColors.cardBorder, width: 1.4),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
