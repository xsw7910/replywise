import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/input_limits.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/feature_page_header.dart';
import '../../core/widgets/generated_result_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import '../../core/widgets/usage_badge.dart';
import 'application/polish_controller.dart';
import 'domain/polish_models.dart';
import '../entitlement/usage_controller.dart';
import '../guidance/application/pending_guidance_provider.dart';
import '../guidance/domain/guidance_template.dart';
import '../guidance/presentation/guidance_chip_row.dart';

const _kColor = AppColors.polishColor;

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

  void _appendGuidance(GuidanceTemplate template) {
    // Switch to Custom direction so the text is included in the request.
    if (_direction != 'Custom') setState(() => _direction = 'Custom');
    final current = _customGuidanceController.text.trim();
    final content = template.content;
    _customGuidanceController.text =
        current.isEmpty ? content : '$current\n\n$content';
    _customGuidanceController.selection = TextSelection.collapsed(
      offset: _customGuidanceController.text.length,
    );
  }

  /// Applies a guidance template handed over from the standalone Guidance
  /// Library ("Use in Polish"). Consumed exactly once.
  void _consumePendingGuidance() {
    if (ref.watch(pendingGuidanceProvider) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final template = ref.read(pendingGuidanceProvider.notifier).take();
      if (template != null) _appendGuidance(template);
    });
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
    _consumePendingGuidance();

    return AppPage(
      title: 'Polish',
      accentColor: _kColor,
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
          const FeaturePageHeader(
            imagePath: 'assets/icons/polish.png',
            title: 'Polish',
            subtitle: 'Make your English sound more natural.',
            color: _kColor,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: UsageBadge(
              state: usageState,
              onRetry: () =>
                  ref.read(usageControllerProvider.notifier).refresh(),
            ),
          ),
          const SizedBox(height: 16),
          const StepLabel(step: 1, label: 'Paste your draft', color: _kColor),
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
          const StepLabel(step: 2, label: 'How should it sound?', color: _kColor),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _directions
                      .map(
                        (direction) => ChoiceChip(
                          label: Text(direction),
                          selected: direction == _direction,
                          selectedColor: _kColor.withAlpha(35),
                          checkmarkColor: _kColor,
                          onSelected: (_) =>
                              setState(() => _direction = direction),
                        ),
                      )
                      .toList(),
                ),
                if (_direction == 'Custom') ...[
                  const SizedBox(height: 16),
                  LabeledTextField(
                    key: const Key('polish-custom-guidance-field'),
                    label: 'Custom guidance',
                    controller: _customGuidanceController,
                    hintText: 'For example: warmer, but still professional',
                    helperText: 'Write in any language',
                    maxLines: 3,
                    maxLength: InputLimits.guidanceMaxLength,
                  ),
                ],
                const SizedBox(height: 14),
                GuidanceChipRow(onSelected: _appendGuidance),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kColor),
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
            label: Text(polishState.isLoading ? 'Polishing…' : 'Polish draft'),
          ),
          if (polishState.isLoading) ...[
            const SizedBox(height: 10),
            Text(
              'Improving clarity while keeping your meaning…',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium,
            ),
          ],
          if (polishState.error != null) ...[
            const SizedBox(height: 12),
            InlineError(
              message: polishState.error!,
              actionLabel: polishState.errorCode == 'PAYWALL_REQUIRED'
                  ? null
                  : 'Try again',
              onAction: polishState.errorCode == 'PAYWALL_REQUIRED'
                  ? null
                  : _polish,
            ),
            if (polishState.errorCode == 'PAYWALL_REQUIRED')
              TextButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: const Text('View plans'),
              ),
          ],
          if (!polishState.isLoading &&
              polishState.error == null &&
              polishState.result == null) ...[
            const SizedBox(height: 12),
            Text(
              'Your polished draft will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium,
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
              style: OutlinedButton.styleFrom(
                foregroundColor: _kColor,
                side: const BorderSide(color: _kColor),
              ),
              onPressed: polishState.isLoading ? null : _polish,
              icon: polishState.isLoading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Polish again'),
            ),
            if (!usageState.usage.isPremium)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Polishing again creates a new result and uses 1 generation.',
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
