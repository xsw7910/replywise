import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_skin.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

class PlaceholderResultCard extends StatelessWidget {
  const PlaceholderResultCard({
    super.key,
    required this.label,
    required this.text,
    this.caption = 'Static preview',
  });

  final String label;
  final String text;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      fillColor: AppSkin.resultFill,
      blur: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(caption, style: AppTextStyles.labelMedium),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Copy preview',
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
          const SizedBox(height: 14),
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
