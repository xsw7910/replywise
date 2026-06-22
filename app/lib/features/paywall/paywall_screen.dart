import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  void _showPreviewMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Purchases are not available in this preview.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Choose your plan',
      showBackButton: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Write with confidence',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'This is a static preview of the two planned ways to continue.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ReplyWise Premium',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    const _Badge(label: 'Best value'),
                  ],
                ),
                const SizedBox(height: 16),
                const _Benefit(text: 'Unlimited reply and polish previews'),
                const _Benefit(text: 'Premium writing experience'),
                const _Benefit(text: 'Cancel anytime'),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => _showPreviewMessage(context),
                  child: const Text('Start 3-day Free Trial'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Free for 3 days, then billed monthly at the price shown at checkout. Cancel anytime.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buy Credits', style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'One-time packs for occasional use. No subscription.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 14),
                for (final credits in const [10, 50, 100])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => _showPreviewMessage(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text('$credits AI uses'),
                          const Spacer(),
                          const Text('Preview'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showPreviewMessage(context),
            child: const Text('Restore purchases'),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}
