import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';

class ReplyScreen extends StatefulWidget {
  const ReplyScreen({super.key});

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reply')),
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
                  Text('Original message', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Paste the message you want to reply to…',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // AI integration deferred
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI reply coming soon!')),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate Reply'),
            ),
            const SizedBox(height: 24),
            _PlaceholderResultCard(),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderResultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Suggested reply', style: AppTextStyles.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your AI-generated reply will appear here.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
