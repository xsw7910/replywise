import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class GuidanceLibrary extends StatelessWidget {
  const GuidanceLibrary({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const suggestions = [
    'Be polite',
    'Keep it short',
    "Don't be too formal",
    'Decline politely',
    'Be confident',
    'Add appreciation',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick guidance', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (suggestion) => ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 16),
                  label: Text(suggestion),
                  onPressed: () => onSelected(suggestion),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
