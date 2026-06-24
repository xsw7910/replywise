import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A frosted-glass card ready for glassmorphism layouts.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.blur = 12,
    this.fillColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
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
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor ?? Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: AppColors.cardBorder, width: 1.4),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
