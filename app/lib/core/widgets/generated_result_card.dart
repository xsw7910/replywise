import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../share/share_helper.dart';
import '../theme/app_feature_theme.dart';
import '../localization/localization_extensions.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

class GeneratedResultCard extends ConsumerWidget {
  const GeneratedResultCard({
    super.key,
    required this.label,
    required this.text,
    this.feature,
    this.shareTooltip,
    this.showFeatureImage = true,
    this.tintColor,
    this.tintStrength = 1,
  });

  final String label;
  final String text;
  final AppFeature? feature;

  /// Accessibility tooltip for the share button (e.g. "Share reply"). The
  /// share button is only shown when this is provided.
  final String? shareTooltip;

  final bool showFeatureImage;
  final Color? tintColor;
  final double tintStrength;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonStyle = feature == null
        ? null
        : IconButton.styleFrom(
            foregroundColor: feature!.accentColor,
            backgroundColor: feature!.iconBackgroundColor,
          );

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
              if (shareTooltip != null)
                IconButton.filledTonal(
                  key: const Key('result-share-button'),
                  tooltip: shareTooltip,
                  style: buttonStyle,
                  // Disabled rather than shown enabled for empty results —
                  // empty text is never shared.
                  onPressed: text.trim().isEmpty
                      ? null
                      : () => shareGeneratedText(
                          context,
                          ref,
                          text,
                          feature: feature ?? AppFeature.reply,
                        ),
                  icon: const Icon(Icons.ios_share_outlined, size: 18),
                ),
              IconButton.filledTonal(
                key: const Key('result-copy-button'),
                tooltip: context.l10n.copyResult,
                style: buttonStyle,
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
