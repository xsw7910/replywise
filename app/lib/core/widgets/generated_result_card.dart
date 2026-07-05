import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_feature_theme.dart';
import '../localization/localization_extensions.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

class GeneratedResultCard extends StatelessWidget {
  const GeneratedResultCard({
    super.key,
    required this.label,
    required this.text,
    this.feature,
    this.showFeatureImage = true,
    this.tintColor,
    this.tintStrength = 1,
  });

  final String label;
  final String text;
  final AppFeature? feature;
  final bool showFeatureImage;
  final Color? tintColor;
  final double tintStrength;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: feature,
      showFeatureImage: showFeatureImage,
      tintColor: tintColor,
      tintStrength: tintStrength,
      blur: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.cardTitle)),
              IconButton.filledTonal(
                tooltip: context.l10n.copyResult,
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
                    ..showSnackBar(
                      SnackBar(content: Text(context.l10n.copied)),
                    );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
