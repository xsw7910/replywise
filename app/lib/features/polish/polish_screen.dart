import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';

class PolishScreen extends StatefulWidget {
  const PolishScreen({super.key});

  @override
  State<PolishScreen> createState() => _PolishScreenState();
}

class _PolishScreenState extends State<PolishScreen> {
  final _inputController = TextEditingController();
  String _selectedTone = 'Professional';

  static const _tones = ['Professional', 'Friendly', 'Concise', 'Formal'];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polish')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your draft', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Paste your draft to polish…',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tone', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _tones.map((tone) {
                      final selected = tone == _selectedTone;
                      return ChoiceChip(
                        label: Text(tone),
                        selected: selected,
                        selectedColor: AppColors.primaryLight.withAlpha(160),
                        onSelected: (_) => setState(() => _selectedTone = tone),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI polish coming soon!')),
                );
              },
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Polish Text'),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_fix_high_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Polished result', style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your polished text will appear here.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
