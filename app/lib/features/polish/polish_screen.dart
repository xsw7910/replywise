import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/input_limits.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feature_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/generated_result_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'application/polish_controller.dart';
import 'domain/polish_models.dart';
import '../entitlement/usage_controller.dart';
import '../guidance/application/pending_guidance_provider.dart';
import '../guidance/domain/guidance_template.dart';
import '../guidance/presentation/guidance_chip_row.dart';
import '../guidance/presentation/guidance_picker_sheet.dart';
import '../guidance/presentation/guidance_text_field.dart';
import '../reply/widgets/reply_status_badge.dart';

const _kColor = AppColors.polishColor;
const _feature = AppFeature.polish;
const _kCardTint = Color(0xFFE8F2FF);
const _kCardTintStrength = 0.65;

class PolishScreen extends ConsumerStatefulWidget {
  const PolishScreen({super.key});

  @override
  ConsumerState<PolishScreen> createState() => _PolishScreenState();
}

class _PolishScreenState extends ConsumerState<PolishScreen> {
  final _draftController = TextEditingController();
  final _guidanceController = TextEditingController();
  final _customToneController = TextEditingController();
  final _customAudienceController = TextEditingController();
  final _extraInstructionController = TextEditingController();
  bool _guidanceExpanded = false;
  bool _moreOptionsExpanded = false;
  String _tone = 'Natural';
  String _audience = 'Auto';
  String _length = 'Same';

  static const _tones = ['Natural', 'Professional', 'Friendly', 'Custom'];
  static const _audiences = [
    'Auto',
    'Friend',
    'Customer',
    'Coworker',
    'Manager',
    'Custom',
  ];
  static const _lengths = ['Shorter', 'Same', 'Longer'];

  @override
  void dispose() {
    _draftController.dispose();
    _guidanceController.dispose();
    _customToneController.dispose();
    _customAudienceController.dispose();
    _extraInstructionController.dispose();
    super.dispose();
  }

  void _appendGuidance(GuidanceTemplate template) {
    final current = _guidanceController.text.trim();
    final content = template.content;
    _guidanceController.text = current.isEmpty ? content : '$current\n$content';
    _guidanceController.selection = TextSelection.collapsed(
      offset: _guidanceController.text.length,
    );
    if (!_guidanceExpanded) setState(() => _guidanceExpanded = true);
  }

  void _openLibrary() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GuidancePickerSheet(onSelected: _appendGuidance),
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

  Future<void> _pasteDraft() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _draftController.text = text.length > 4000 ? text.substring(0, 4000) : text;
    _draftController.selection = TextSelection.collapsed(
      offset: _draftController.text.length,
    );
  }

  String? _effectiveTone() {
    final value = _tone == 'Custom' ? _customToneController.text.trim() : _tone;
    return value.isEmpty ? null : value;
  }

  String? _effectiveAudience() {
    final value = _audience == 'Custom'
        ? _customAudienceController.text.trim()
        : _audience;
    return value == 'Auto' || value.isEmpty ? null : value;
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _polish() => ref
      .read(polishControllerProvider.notifier)
      .polish(
        PolishRequest(
          draft: _draftController.text,
          direction: 'natural',
          guidance: _optionalText(_guidanceController),
          tone: _effectiveTone(),
          audience: _effectiveAudience(),
          length: _length == 'Same' ? null : _length,
          extraInstruction: _optionalText(_extraInstructionController),
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
      backgroundImagePath: _feature.pageBackgroundImage,
      transparentAppBar: true,
      centerTitle: false,
      actions: [
        ReplyStatusBadge(
          usage: usageState.usage,
          onTap: () => context.push(AppRoutes.paywall),
        ),
      ],
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          GlassCard(
            feature: _feature,
            showFeatureImage: false,
            tintColor: _kCardTint,
            tintStrength: _kCardTintStrength,
            child: LabeledTextField(
              label: 'Your draft',
              feature: _feature,
              showCounter: false,
              controller: _draftController,
              hintText: 'Paste of type your draft...',
              maxLines: 7,
              maxLength: 4000,
              fieldActions: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Paste',
                    visualDensity: VisualDensity.compact,
                    color: _kColor,
                    onPressed: _pasteDraft,
                    icon: const Icon(Icons.content_paste_rounded, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Clear',
                    visualDensity: VisualDensity.compact,
                    color: _kColor,
                    onPressed: _draftController.clear,
                    icon: const Icon(Icons.close_rounded, size: 21),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _PolishGuidanceCard(
            key: const Key('polish-guidance-card'),
            expanded: _guidanceExpanded,
            onToggle: () =>
                setState(() => _guidanceExpanded = !_guidanceExpanded),
            controller: _guidanceController,
            onSelected: _appendGuidance,
            onOpenLibrary: _openLibrary,
          ),
          const SizedBox(height: 14),
          _PolishMoreOptionsCard(
            key: const Key('polish-more-options-card'),
            expanded: _moreOptionsExpanded,
            onToggle: () =>
                setState(() => _moreOptionsExpanded = !_moreOptionsExpanded),
            tones: _tones,
            tone: _tone,
            onTone: (value) => setState(() => _tone = value),
            customToneController: _customToneController,
            audiences: _audiences,
            audience: _audience,
            onAudience: (value) => setState(() => _audience = value),
            customAudienceController: _customAudienceController,
            lengths: _lengths,
            length: _length,
            onLength: (value) => setState(() => _length = value),
            extraInstructionController: _extraInstructionController,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _feature.primaryButtonColor,
            ),
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
              style: AppTextStyles.helper,
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
              style: AppTextStyles.helper,
            ),
          ],
          if (polishState.result != null) ...[
            const SizedBox(height: 26),
            Text('Polished result', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            GeneratedResultCard(
              label: _tone,
              text: polishState.result!.polished,
              feature: _feature,
              showFeatureImage: false,
              tintColor: _kCardTint,
              tintStrength: _kCardTintStrength,
            ),
            const SizedBox(height: 12),
            GlassCard(
              feature: _feature,
              blur: 8,
              showFeatureImage: false,
              tintColor: _kCardTint,
              tintStrength: _kCardTintStrength,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What changed?', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 6),
                  Text(polishState.result!.changes, style: AppTextStyles.body),
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
                  style: AppTextStyles.helper,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PolishGuidanceCard extends StatelessWidget {
  const _PolishGuidanceCard({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.controller,
    required this.onSelected,
    required this.onOpenLibrary,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController controller;
  final ValueChanged<GuidanceTemplate> onSelected;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: _feature,
      showFeatureImage: false,
      tintColor: _kCardTint,
      tintStrength: _kCardTintStrength,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: _kColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Guidance', style: AppTextStyles.cardTitle),
                  ),
                  Text(
                    expanded ? 'Hide' : 'Add guidance',
                    style: AppTextStyles.helper.copyWith(color: _kColor),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                children: [
                  GuidanceTextField(
                    key: const Key('polish-custom-guidance-field'),
                    feature: _feature,
                    controller: controller,
                    hintText: 'Describe how you want the draft polished',
                    maxLines: 3,
                    maxLength: InputLimits.guidanceMaxLength,
                    onOpenLibrary: onOpenLibrary,
                  ),
                  const SizedBox(height: 12),
                  GuidanceChipRow(feature: _feature, onSelected: onSelected),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PolishMoreOptionsCard extends StatelessWidget {
  const _PolishMoreOptionsCard({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.tones,
    required this.tone,
    required this.onTone,
    required this.customToneController,
    required this.audiences,
    required this.audience,
    required this.onAudience,
    required this.customAudienceController,
    required this.lengths,
    required this.length,
    required this.onLength,
    required this.extraInstructionController,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final List<String> tones;
  final String tone;
  final ValueChanged<String> onTone;
  final TextEditingController customToneController;
  final List<String> audiences;
  final String audience;
  final ValueChanged<String> onAudience;
  final TextEditingController customAudienceController;
  final List<String> lengths;
  final String length;
  final ValueChanged<String> onLength;
  final TextEditingController extraInstructionController;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: _feature,
      showFeatureImage: false,
      tintColor: _kCardTint,
      tintStrength: _kCardTintStrength,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: _kColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('More options', style: AppTextStyles.cardTitle),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PolishOptionGroup(
                    label: 'Tone',
                    options: tones,
                    selected: tone,
                    onSelected: onTone,
                  ),
                  if (tone == 'Custom') ...[
                    const SizedBox(height: 10),
                    LabeledTextField(
                      key: const Key('polish-custom-tone-field'),
                      label: 'Describe the tone',
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customToneController,
                      hintText: 'e.g. warm but professional',
                      maxLines: 1,
                      maxLength: 500,
                    ),
                  ],
                  const Divider(height: 28, color: AppColors.cardBorder),
                  _PolishOptionGroup(
                    label: 'Audience',
                    options: audiences,
                    selected: audience,
                    onSelected: onAudience,
                  ),
                  if (audience == 'Custom') ...[
                    const SizedBox(height: 10),
                    LabeledTextField(
                      key: const Key('polish-custom-audience-field'),
                      label: 'Describe the audience',
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customAudienceController,
                      hintText: 'e.g. my manager',
                      maxLines: 1,
                      maxLength: 500,
                    ),
                  ],
                  const Divider(height: 28, color: AppColors.cardBorder),
                  _PolishOptionGroup(
                    label: 'Length',
                    options: lengths,
                    selected: length,
                    onSelected: onLength,
                  ),
                  const SizedBox(height: 14),
                  LabeledTextField(
                    key: const Key('polish-extra-instruction-field'),
                    label: 'Extra instruction',
                    feature: _feature,
                    controller: extraInstructionController,
                    hintText: 'Add any other polishing preference',
                    showCounter: false,
                    maxLines: 2,
                    maxLength: 1000,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PolishOptionGroup extends StatelessWidget {
  const _PolishOptionGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (option) => ChoiceChip(
                  label: Text(option),
                  selected: option == selected,
                  selectedColor: _feature.selectedChipColor,
                  checkmarkColor: _kColor,
                  labelStyle: AppTextStyles.body.copyWith(
                    color: option == selected
                        ? _kColor
                        : AppColors.textSecondary,
                  ),
                  onSelected: (_) => onSelected(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
