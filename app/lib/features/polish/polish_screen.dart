import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/input_limits.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feature_theme.dart';
import '../app_status/presentation/app_status_dialogs.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/feature_page_header.dart';
import '../../core/widgets/generated_result_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'application/pending_polish_input_provider.dart';
import 'application/polish_controller.dart';
import 'domain/polish_models.dart';
import '../entitlement/usage_controller.dart';
import '../entitlement/presentation/out_of_credits_dialog.dart';
import '../guidance/application/pending_guidance_provider.dart';
import '../guidance/domain/guidance_template.dart';
import '../guidance/presentation/guidance_library_screen.dart';
import '../guidance/presentation/guidance_picker_sheet.dart';
import '../guidance/presentation/guidance_text_field.dart';
import '../recent/application/recent_providers.dart';
import '../recent/domain/recent_item.dart';
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
  String _tone = 'Auto';
  String _audience = 'Auto';
  String _length = 'Same';

  static const _tones = [
    'Auto',
    'Natural',
    'Professional',
    'Friendly',
    'Custom',
  ];
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

  Future<void> _openTemplatePage(GuidanceInsertionTarget target) async {
    ref.read(activeGuidanceInsertionTargetProvider.notifier).set(target);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GuidanceLibraryScreen()),
    );
    if (!mounted) return;
    ref.read(activeGuidanceInsertionTargetProvider.notifier).clear();
  }

  void _setControllerText(TextEditingController controller, String text) {
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
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

  void _consumePendingTargetedGuidance() {
    if (ref.watch(pendingTargetedGuidanceProvider) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingTargetedGuidanceProvider.notifier).take();
      if (pending == null) return;
      switch (pending.target) {
        case GuidanceInsertionTarget.polishTone:
          _setControllerText(_customToneController, pending.template.content);
          break;
        case GuidanceInsertionTarget.polishAudience:
          _setControllerText(
            _customAudienceController,
            pending.template.content,
          );
          break;
        case GuidanceInsertionTarget.replyTone:
        case GuidanceInsertionTarget.replyAudience:
          break;
      }
    });
  }

  /// Applies a draft handed over from a recent item ("Use again"). Consumed
  /// exactly once so it does not overwrite later edits.
  void _consumePendingInput() {
    if (ref.watch(pendingPolishInputProvider) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final draft = ref.read(pendingPolishInputProvider.notifier).take();
      if (draft == null) return;
      _draftController.text = draft.length > 4000
          ? draft.substring(0, 4000)
          : draft;
      _draftController.selection = TextSelection.collapsed(
        offset: _draftController.text.length,
      );
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
    return value == 'Auto' || value.isEmpty ? null : value;
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

  Future<void> _polish() async {
    // No API request (and no credit/status gating) for an empty input.
    if (_draftController.text.trim().isEmpty) {
      await showEmptyInputSheet(context, feature: _feature);
      return;
    }
    if (!mounted) return;
    final appLocale = resolvedAppLocaleCode(
      Localizations.maybeLocaleOf(context),
    );
    if (!await ensureGenerationAccess(
      context: context,
      ref: ref,
      feature: _feature,
    )) {
      return;
    }
    if (!mounted) return;
    // Gate against cached app status (maintenance / force update / disabled).
    if (!await ensureAppStatusAllows(
      context: context,
      ref: ref,
      feature: _feature,
    )) {
      return;
    }
    if (!mounted) return;
    // Capture the draft before the async gap.
    final draft = _draftController.text;
    await ref
        .read(polishControllerProvider.notifier)
        .polish(
          PolishRequest(
            draft: draft,
            direction: 'natural',
            guidance: _optionalText(_guidanceController),
            tone: _effectiveTone(),
            audience: _effectiveAudience(),
            length: _length == 'Same' ? null : _length,
            extraInstruction: _optionalText(_extraInstructionController),
            guidanceLang: appLocale,
            appLocale: appLocale,
          ),
        );
    if (!mounted) return;
    final state = ref.read(polishControllerProvider);
    // A network/server failure re-checks status: maintenance or fallback UI.
    if (isNetworkFailure(state.errorCode)) {
      await handleAiRequestFailure(
        context: context,
        ref: ref,
        feature: _feature,
        onRetry: _polish,
      );
      return;
    }
    // Any other failure is routed to the matching error bottom sheet.
    if (state.error != null) {
      await showAiErrorSheet(
        context: context,
        ref: ref,
        feature: _feature,
        errorCode: state.errorCode,
        message: state.error!,
        onRetry: _polish,
      );
      return;
    }
    final result = state.result;
    if (state.error == null && !state.isLoading && result != null) {
      await saveRecentItem(
        ref,
        RecentItem.create(
          type: RecentType.polish,
          inputText: draft,
          outputText: result.polished,
          guidance: _optionalText(_guidanceController),
          tone: _effectiveTone(),
          length: _length == 'Same' ? null : _length,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final polishState = ref.watch(polishControllerProvider);
    final usageState = ref.watch(usageControllerProvider);
    _consumePendingGuidance();
    _consumePendingTargetedGuidance();
    _consumePendingInput();

    return AppPage(
      title: context.l10n.polish,
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
            title: FeatureHeaderTitle(
              feature: _feature,
              title: context.l10n.polish,
              color: _kColor,
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
                      _PolishCardHeader(
                        icon: Icons.edit_note_rounded,
                        title: context.l10n.textToPolish,
                        subtitle: context.l10n.pasteTextToImprove,
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        key: const Key('polish-draft-field'),
                        label: context.l10n.textToPolish,
                        feature: _feature,
                        showHeader: false,
                        showCounter: false,
                        controller: _draftController,
                        hintText: context.l10n.pasteYourText,
                        maxLines: 5,
                        maxLength: 4000,
                        fieldActions: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: context.l10n.paste,
                              visualDensity: VisualDensity.compact,
                              color: _kColor,
                              onPressed: _pasteDraft,
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: context.l10n.clear,
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
                  onOpenTemplatePage: _openTemplatePage,
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
                    context.l10n.improvingClarity,
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
                        : context.l10n.tryAgain,
                    onAction: polishState.errorCode == 'PAYWALL_REQUIRED'
                        ? null
                        : _polish,
                  ),
                  if (polishState.errorCode == 'PAYWALL_REQUIRED')
                    TextButton(
                      onPressed: () => context.push(AppRoutes.paywall),
                      child: Text(context.l10n.viewPlans),
                    ),
                ],
                if (!polishState.isLoading &&
                    polishState.error == null &&
                    polishState.result == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.polishedTextAppearsHere,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.helper,
                  ),
                ],
                if (polishState.result != null) ...[
                  const SizedBox(height: 26),
                  Text(
                    context.l10n.polishedResult,
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  GeneratedResultCard(
                    label: _tone,
                    text: polishState.result!.polished,
                    feature: _feature,
                    shareTooltip: context.l10n.sharePolishedText,
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
                        Text(
                          context.l10n.whatChanged,
                          style: AppTextStyles.cardTitle,
                        ),
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
                    label: Text(context.l10n.polishAgain),
                  ),
                  if (!usageState.usage.isPremium)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.l10n.polishAgainUsageNote,
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
  const _PolishQuickGuidanceChips({
    required this.onAppend,
    required this.onOpenLibrary,
  });

  final ValueChanged<String> onAppend;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(String, IconData, VoidCallback)>[
      (
        '${l10n.use} ${l10n.useATemplate.toLowerCase()}',
        Icons.menu_book_rounded,
        onOpenLibrary,
      ),
      (
        l10n.improveGrammar,
        Icons.spellcheck_rounded,
        () => onAppend(l10n.instructionGrammar),
      ),
      (
        l10n.fixSpelling,
        Icons.abc_rounded,
        () => onAppend(l10n.instructionSpelling),
      ),
      (
        l10n.morePersuasive,
        Icons.campaign_outlined,
        () => onAppend(l10n.instructionPersuasive),
      ),
      (
        l10n.moreConfident,
        Icons.shield_outlined,
        () => onAppend(l10n.instructionConfident),
      ),
      (
        l10n.simplifyWording,
        Icons.filter_alt_off_rounded,
        () => onAppend(l10n.instructionSimple),
      ),
      (
        l10n.betterFlow,
        Icons.water_rounded,
        () => onAppend(l10n.instructionFlow),
      ),
      (
        l10n.explainTheReason,
        Icons.info_outline,
        () => onAppend('Make the reasoning clearer and easier to follow.'),
      ),
      (
        l10n.showAppreciation,
        Icons.volunteer_activism_outlined,
        () => onAppend('Add polite appreciation where appropriate.'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.quickGuidance, style: AppTextStyles.badge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, icon, onPressed) in items)
              ActionChip(
                backgroundColor: _feature.selectedChipColor,
                side: const BorderSide(color: AppColors.glassEdgeStrong),
                avatar: Icon(icon, size: 15, color: _kColor),
                label: Text(label, style: const TextStyle(color: _kColor)),
                onPressed: onPressed,
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
                  loading ? context.l10n.polishing : context.l10n.polishText,
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
                          context.l10n.guidance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.helpAiUnderstandIntent,
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
                    hintText: context.l10n.describePolish,
                    maxLines: 3,
                    maxLength: InputLimits.guidanceMaxLength,
                    onOpenLibrary: onOpenLibrary,
                  ),
                  const SizedBox(height: 14),
                  _PolishQuickGuidanceChips(
                    onAppend: onQuickGuidance,
                    onOpenLibrary: onOpenLibrary,
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

class _PolishMoreOptionsCard extends StatelessWidget {
  const _PolishMoreOptionsCard({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.tones,
    required this.tone,
    required this.onTone,
    required this.onOpenTemplatePage,
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
  final ValueChanged<GuidanceInsertionTarget> onOpenTemplatePage;
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
                          context.l10n.moreOptions,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.adjustToneLengthFormat,
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
                    label: context.l10n.tone,
                    groupIcon: Icons.record_voice_over_outlined,
                    accentColor: _kColor,
                    options: tones,
                    selected: tone,
                    onSelected: onTone,
                  ),
                  if (tone == 'Custom') ...[
                    const SizedBox(height: 10),
                    LabeledTextField(
                      key: const Key('polish-custom-tone-field'),
                      label: context.l10n.describeTone,
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customToneController,
                      hintText: context.l10n.toneHint,
                      maxLines: 1,
                      maxLength: 500,
                      fieldActions: IconButton(
                        tooltip: context.l10n.templates,
                        visualDensity: VisualDensity.compact,
                        color: _kColor,
                        onPressed: () => onOpenTemplatePage(
                          GuidanceInsertionTarget.polishTone,
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                      ),
                    ),
                  ],
                  const _PolishOptionDivider(),
                  _PolishOptionGroup(
                    label: context.l10n.audience,
                    groupIcon: Icons.groups_outlined,
                    accentColor: _kColor,
                    options: audiences,
                    selected: audience,
                    onSelected: onAudience,
                  ),
                  if (audience == 'Custom') ...[
                    const SizedBox(height: 10),
                    LabeledTextField(
                      key: const Key('polish-custom-audience-field'),
                      label: context.l10n.describeAudience,
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customAudienceController,
                      hintText: context.l10n.audienceHint,
                      maxLines: 1,
                      maxLength: 500,
                      fieldActions: IconButton(
                        tooltip: context.l10n.templates,
                        visualDensity: VisualDensity.compact,
                        color: _kColor,
                        onPressed: () => onOpenTemplatePage(
                          GuidanceInsertionTarget.polishAudience,
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                      ),
                    ),
                  ],
                  const _PolishOptionDivider(),
                  _PolishOptionGroup(
                    label: context.l10n.length,
                    groupIcon: Icons.format_size_rounded,
                    accentColor: _kColor,
                    options: lengths,
                    selected: length,
                    onSelected: onLength,
                  ),
                  const _PolishOptionDivider(),
                  _PolishOptionHeader(
                    label: context.l10n.extraInstruction,
                    groupIcon: Icons.edit_note_rounded,
                    accentColor: _kColor,
                  ),
                  const SizedBox(height: 8),
                  LabeledTextField(
                    key: const Key('polish-extra-instruction-field'),
                    label: context.l10n.extraInstruction,
                    feature: _feature,
                    showHeader: false,
                    controller: extraInstructionController,
                    hintText: context.l10n.extraPolishHint,
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
    required this.groupIcon,
    required this.accentColor,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData groupIcon;
  final Color accentColor;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolishOptionHeader(
          label: label,
          groupIcon: groupIcon,
          accentColor: accentColor,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                backgroundColor: Colors.white.withAlpha(110),
                avatar: Icon(
                  _polishOptionIcon(option),
                  size: 16,
                  color: option == selected
                      ? accentColor
                      : AppColors.textSecondary,
                ),
                label: Text(
                  _localizedPolishOption(context, option),
                  style: TextStyle(
                    color: option == selected
                        ? accentColor
                        : AppColors.textSecondary,
                  ),
                ),
                selected: option == selected,
                selectedColor: Color.lerp(Colors.white, accentColor, 0.14),
                showCheckmark: false,
                side: BorderSide(
                  color: option == selected
                      ? accentColor.withAlpha(65)
                      : AppColors.cardBorder.withAlpha(150),
                ),
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _PolishOptionHeader extends StatelessWidget {
  const _PolishOptionHeader({
    required this.label,
    required this.groupIcon,
    required this.accentColor,
  });

  final String label;
  final IconData groupIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(groupIcon, size: 17, color: accentColor),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
      ],
    );
  }
}

IconData _polishOptionIcon(String option) {
  return switch (option) {
    'Auto' => Icons.auto_awesome_rounded,
    'Natural' => Icons.spa_outlined,
    'Professional' => Icons.business_center_outlined,
    'Friendly' => Icons.sentiment_satisfied_alt_rounded,
    'Custom' => Icons.edit_outlined,
    'Friend' => Icons.person_outline_rounded,
    'Customer' => Icons.storefront_outlined,
    'Coworker' => Icons.groups_outlined,
    'Manager' => Icons.supervisor_account_outlined,
    'Shorter' => Icons.compress_rounded,
    'Same' => Icons.swap_vert_rounded,
    'Longer' => Icons.expand_rounded,
    _ => Icons.tune_rounded,
  };
}

String _localizedPolishOption(BuildContext context, String option) =>
    switch (option) {
      'Natural' => context.l10n.natural,
      'Professional' => context.l10n.professional,
      'Friendly' => context.l10n.friendly,
      'Custom' => context.l10n.custom,
      'Auto' => context.l10n.auto,
      'Friend' => context.l10n.friend,
      'Customer' => context.l10n.customer,
      'Coworker' => context.l10n.coworker,
      'Manager' => context.l10n.manager,
      'Shorter' => context.l10n.shorter,
      'Same' => context.l10n.sameLength,
      'Longer' => context.l10n.longer,
      _ => option,
    };

class _PolishOptionDivider extends StatelessWidget {
  const _PolishOptionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: AppColors.cardBorder),
    );
  }
}
