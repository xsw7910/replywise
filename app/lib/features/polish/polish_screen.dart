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
import '../guidance/presentation/guidance_picker_sheet.dart';
import '../guidance/presentation/guidance_text_field.dart';
import '../reply/widgets/reply_status_badge.dart';

const _kColor = AppColors.polishColor;
const _feature = AppFeature.polish;
// Match the Reply page: every card shares one plain white surface so the app
// reads as a single consistent surface.
const _kCardTint = Colors.white;
const _kCardTintStrength = 1.0;

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

  void _appendGuidanceText(String content) {
    final current = _guidanceController.text.trim();
    _guidanceController.text = current.isEmpty ? content : '$current\n$content';
    _guidanceController.selection = TextSelection.collapsed(
      offset: _guidanceController.text.length,
    );
    if (!_guidanceExpanded) setState(() => _guidanceExpanded = true);
  }

  void _appendGuidance(GuidanceTemplate template) =>
      _appendGuidanceText(template.content);

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
      showAppBar: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverAppBar(
            key: const Key('polish-hero-header'),
            pinned: true,
            expandedHeight: 112,
            toolbarHeight: kToolbarHeight,
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 16,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Polish',
              style:
                  (Theme.of(context).appBarTheme.titleTextStyle ??
                          const TextStyle())
                      .copyWith(color: _kColor, fontWeight: FontWeight.w700),
            ),
            actions: [
              ReplyStatusBadge(
                usage: usageState.usage,
                onTap: () => context.push(AppRoutes.paywall),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                GlassCard(
                  key: const Key('polish-text-card'),
                  feature: _feature,
                  showFeatureImage: false,
                  tintColor: _kCardTint,
                  tintStrength: _kCardTintStrength,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const _PolishCardHeader(
                        icon: Icons.edit_note_rounded,
                        title: 'Text to polish',
                        subtitle: "Paste the text you'd like to improve",
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        key: const Key('polish-draft-field'),
                        label: 'Text to polish',
                        feature: _feature,
                        showHeader: false,
                        showCounter: false,
                        controller: _draftController,
                        hintText: 'Paste your text here…',
                        maxLines: 5,
                        maxLength: 4000,
                        fieldActions: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Paste',
                              visualDensity: VisualDensity.compact,
                              color: _kColor,
                              onPressed: _pasteDraft,
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 20,
                              ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PolishGuidanceCard(
                  key: const Key('polish-guidance-card'),
                  expanded: _guidanceExpanded,
                  onToggle: () =>
                      setState(() => _guidanceExpanded = !_guidanceExpanded),
                  controller: _guidanceController,
                  onQuickGuidance: _appendGuidanceText,
                  onOpenLibrary: _openLibrary,
                ),
                const SizedBox(height: 18),
                _PolishMoreOptionsCard(
                  key: const Key('polish-more-options-card'),
                  expanded: _moreOptionsExpanded,
                  onToggle: () => setState(
                    () => _moreOptionsExpanded = !_moreOptionsExpanded,
                  ),
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
                const SizedBox(height: 18),
                _PolishPrimaryButton(
                  onPressed: polishState.isLoading ? null : _polish,
                  loading: polishState.isLoading,
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
                    'Your polished text will appear here.',
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
                        Text(
                          polishState.result!.changes,
                          style: AppTextStyles.body,
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
                        style: AppTextStyles.helper,
                      ),
                    ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolishCardHeader extends StatelessWidget {
  const _PolishCardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PolishGradientIconBadge(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.helper,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PolishGradientIconBadge extends StatelessWidget {
  const _PolishGradientIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kColor, Color.lerp(_kColor, Colors.white, 0.35)!],
        ),
        boxShadow: [
          BoxShadow(
            color: _kColor.withAlpha(70),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _PolishExpandButton extends StatelessWidget {
  const _PolishExpandButton({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.softBlueShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
        color: _kColor,
        size: 19,
      ),
    );
  }
}

class _PolishQuickGuidanceChips extends StatelessWidget {
  const _PolishQuickGuidanceChips({required this.onAppend});

  final ValueChanged<String> onAppend;

  static const _items = [
    (
      label: 'Professional',
      instruction: 'Make the writing sound professional.',
      icon: Icons.business_center_outlined,
    ),
    (
      label: 'Friendly',
      instruction: 'Make the writing warmer and friendlier.',
      icon: Icons.sentiment_satisfied_alt_rounded,
    ),
    (
      label: 'Concise',
      instruction: 'Make the writing concise and direct.',
      icon: Icons.short_text_rounded,
    ),
    (
      label: 'More natural',
      instruction: 'Make the wording sound natural and fluent.',
      icon: Icons.auto_awesome_rounded,
    ),
    (
      label: 'Improve grammar',
      instruction: 'Correct the grammar while preserving the meaning.',
      icon: Icons.spellcheck_rounded,
    ),
    (
      label: 'Fix spelling',
      instruction: 'Correct all spelling errors.',
      icon: Icons.abc_rounded,
    ),
    (
      label: 'More persuasive',
      instruction: 'Make the writing more persuasive and compelling.',
      icon: Icons.campaign_outlined,
    ),
    (
      label: 'More confident',
      instruction: 'Make the writing sound clear and confident.',
      icon: Icons.shield_outlined,
    ),
    (
      label: 'Simplify wording',
      instruction: 'Use simpler, easier-to-read wording.',
      icon: Icons.filter_alt_off_rounded,
    ),
    (
      label: 'Better flow',
      instruction: 'Improve sentence flow and transitions.',
      icon: Icons.water_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick guidance', style: AppTextStyles.badge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in _items)
              ActionChip(
                backgroundColor: _feature.selectedChipColor,
                side: const BorderSide(color: AppColors.glassEdgeStrong),
                avatar: Icon(item.icon, size: 15, color: _kColor),
                label: Text(item.label, style: const TextStyle(color: _kColor)),
                onPressed: () => onAppend(item.instruction),
              ),
          ],
        ),
      ],
    );
  }
}

class _PolishPrimaryButton extends StatelessWidget {
  const _PolishPrimaryButton({required this.onPressed, required this.loading});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [_kColor, _kColor, Color.lerp(_kColor, Colors.white, 0.18)!],
        ),
        boxShadow: [
          BoxShadow(
            color: _kColor.withAlpha(68),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 9),
                Text(
                  loading ? 'Polishing…' : 'Polish Text',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    required this.onQuickGuidance,
    required this.onOpenLibrary,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController controller;
  final ValueChanged<String> onQuickGuidance;
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
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const _PolishGradientIconBadge(
                    icon: Icons.auto_fix_high_rounded,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Guidance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Help AI understand your intent',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.helper,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PolishExpandButton(expanded: expanded),
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
                  const SizedBox(height: 14),
                  _PolishQuickGuidanceChips(onAppend: onQuickGuidance),
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
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const _PolishGradientIconBadge(icon: Icons.tune_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More options',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Adjust tone, length and format',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.helper,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PolishExpandButton(expanded: expanded),
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
