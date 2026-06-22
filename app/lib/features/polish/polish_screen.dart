import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/generated_result_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'application/polish_controller.dart';
import 'domain/polish_models.dart';
import '../entitlement/usage_controller.dart';

class PolishScreen extends ConsumerStatefulWidget {
  const PolishScreen({super.key});

  @override
  ConsumerState<PolishScreen> createState() => _PolishScreenState();
}

class _PolishScreenState extends ConsumerState<PolishScreen> {
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

  @override
  void dispose() {
    _draftController.dispose();
    _customGuidanceController.dispose();
    super.dispose();
  }

  Future<void> _polish() => ref
      .read(polishControllerProvider.notifier)
      .polish(
        PolishRequest(
          draft: _draftController.text,
          direction: _direction.toLowerCase(),
          custom: _direction == 'Custom'
              ? _customGuidanceController.text
              : null,
          guidanceLang: 'en',
        ),
      );

  @override
  Widget build(BuildContext context) {
    final polishState = ref.watch(polishControllerProvider);
    final usageState = ref.watch(usageControllerProvider);

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
            usageState.usage.isPremium
                ? 'Premium'
                : usageState.usage.freeUsesLeft == null
                ? 'Checking remaining uses…'
                : '${usageState.usage.freeUsesLeft} free uses left · ${usageState.usage.paidCredits} credits',
            style: AppTextStyles.labelMedium,
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
              maxLength: 4000,
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
                    maxLength: 500,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: polishState.isLoading ? null : _polish,
            icon: polishState.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            label: Text(polishState.isLoading ? 'Polishing…' : 'Polish Text'),
          ),
          if (polishState.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                polishState.error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            if (polishState.errorCode == 'PAYWALL_REQUIRED')
              TextButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: const Text('View plans'),
              ),
          ],
          if (polishState.result != null) ...[
            const SizedBox(height: 26),
            Text('Polished result', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            GeneratedResultCard(
              label: _direction,
              text: polishState.result!.polished,
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
                    polishState.result!.changes,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: polishState.isLoading ? null : _polish,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Regenerate'),
            ),
            if (!usageState.usage.isPremium)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Regenerating consumes 1 use.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
