import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/labeled_text_field.dart';
import '../../core/widgets/placeholder_result_card.dart';

class PolishScreen extends StatefulWidget {
  const PolishScreen({super.key});

  @override
  State<PolishScreen> createState() => _PolishScreenState();
}

class _PolishScreenState extends State<PolishScreen> {
  final _draftController = TextEditingController();
  final _customGuidanceController = TextEditingController();
  String _direction = 'Natural';

  static const _directions = [
    'Natural',
    'Professional',
    'Friendly',
    'Concise',
    'Custom',
  ];

  static const _preview =
      'I wanted to check in on the status of the report. Please let me know when you have a moment.';

  @override
  void dispose() {
    _draftController.dispose();
    _customGuidanceController.dispose();
    super.dispose();
  }

  void _showPlaceholder() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Static preview only — polishing is not connected yet.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Polish',
      actions: [
        IconButton(
          tooltip: 'Plans',
          onPressed: () => context.push(AppRoutes.paywall),
          icon: const Icon(Icons.workspace_premium_outlined),
        ),
      ],
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Text(
            'Make your English sound natural',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Keep your meaning while improving clarity, grammar, and tone.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: LabeledTextField(
              label: 'Your draft',
              controller: _draftController,
              hintText: 'Paste or type your English draft…',
              helperText: 'Your original meaning stays intact',
              maxLines: 7,
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How should it sound?', style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _directions
                      .map(
                        (direction) => ChoiceChip(
                          label: Text(direction),
                          selected: direction == _direction,
                          onSelected: (_) =>
                              setState(() => _direction = direction),
                        ),
                      )
                      .toList(),
                ),
                if (_direction == 'Custom') ...[
                  const SizedBox(height: 16),
                  LabeledTextField(
                    label: 'Custom guidance',
                    controller: _customGuidanceController,
                    hintText: 'For example: warmer, but still professional',
                    helperText: 'Write in any language',
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showPlaceholder,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Polish Text'),
          ),
          const SizedBox(height: 26),
          Text('Polished preview', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          const PlaceholderResultCard(
            label: 'Natural & professional',
            text: _preview,
          ),
          const SizedBox(height: 12),
          GlassCard(
            blur: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What changed?', style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'The wording is softer and more natural while preserving the original request.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text('Static preview', style: AppTextStyles.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
