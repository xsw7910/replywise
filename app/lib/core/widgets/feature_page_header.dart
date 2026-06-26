import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Large icon + colored title + subtitle shown at the top of a feature page's
/// scroll content. Mirrors the style of the Home page feature tiles.
class FeaturePageHeader extends StatelessWidget {
  const FeaturePageHeader({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    required this.color,
  }) : assert(icon != null || imagePath != null);

  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        imagePath != null
            ? Image.asset(imagePath!, width: 44, height: 44)
            : Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.white, 0.28)!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(70),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small numbered circle badge + label used to introduce a form section.
class StepLabel extends StatelessWidget {
  const StepLabel({
    super.key,
    required this.step,
    required this.label,
    required this.color,
  });

  final int step;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
