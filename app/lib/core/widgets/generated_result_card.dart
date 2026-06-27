import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_feature_theme.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

class GeneratedResultCard extends StatelessWidget {
  const GeneratedResultCard({
    super.key,
    required this.label,
    required this.text,
    this.feature,
  });

  final String label;
  final String text;
  final AppFeature? feature;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: feature,
      blur: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
              IconButton.filledTonal(
                tooltip: 'Copy result',
                style: feature == null
                    ? null
                    : IconButton.styleFrom(
                        foregroundColor: feature!.accentColor,
                        backgroundColor: feature!.iconBackgroundColor,
                      ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('Copied')));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
