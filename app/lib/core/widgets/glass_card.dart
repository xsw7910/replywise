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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final double blur;
  final Color? fillColor;
  final AppFeature? feature;
  final double tintStrength;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (feature == null ? 20 : 28);

    return Container(
      decoration:
          feature?.glassCardDecoration(
            borderRadius: radius,
            tintStrength: tintStrength,
          ) ??
          BoxDecoration(
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
            color: feature == null
                ? fillColor ?? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              padding: padding,
              decoration: feature == null
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.4,
                      ),
                    )
                  : null,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
