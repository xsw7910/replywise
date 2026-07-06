import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/input_limits.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feature_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/generated_result_card.dart';
import '../../core/widgets/glass_card.dart';
import '../guidance/application/pending_guidance_provider.dart';
import '../guidance/domain/guidance_template.dart';
import '../guidance/presentation/guidance_picker_sheet.dart';
import '../guidance/presentation/guidance_text_field.dart';
import '../recent/application/recent_providers.dart';
import '../recent/domain/recent_item.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'widgets/reply_status_badge.dart';
import 'application/explain_controller.dart';
import 'application/pending_reply_input_provider.dart';
import 'application/reply_controller.dart';
import 'domain/reply_models.dart';
import '../entitlement/usage_controller.dart';
import '../entitlement/presentation/out_of_credits_dialog.dart';

const _kColor = AppColors.replyColor;
const _feature = AppFeature.reply;

// Every card on the Reply page shares one plain white surface so the page
// reads as a single consistent, uncluttered surface.
const _kCardTint = Colors.white;
const _kCardTintStrength = 1.0;

class ReplyScreen extends ConsumerStatefulWidget {
  const ReplyScreen({super.key});

  @override
  ConsumerState<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends ConsumerState<ReplyScreen> {
  final _incomingController = TextEditingController();
  final _guidanceController = TextEditingController();
  final _customToneController = TextEditingController();
  final _customAudienceController = TextEditingController();

  bool _guidanceExpanded = false;
  String _tone = 'Auto';
  String _audience = 'Auto';
  String _length = 'Medium';
  String _channel = 'Auto';
  bool _moreOptionsExpanded = false;

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
  static const _lengths = ['Short', 'Medium', 'Detailed'];
  static const _channels = ['Auto', 'Text', 'Email', 'Chat'];

  @override
  void dispose() {
    _incomingController.dispose();
    _guidanceController.dispose();
    _customToneController.dispose();
    _customAudienceController.dispose();
    super.dispose();
  }

  void _appendGuidanceText(String text) {
    final current = _guidanceController.text.trim();
    _guidanceController.text = current.isEmpty ? text : '$current\n$text';
    _guidanceController.selection = TextSelection.collapsed(
      offset: _guidanceController.text.length,
    );
    // Applying any guidance reveals the field so the user sees what was added.
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
  /// Library ("Use in Reply"). Consumed exactly once.
  void _consumePendingGuidance() {
    if (ref.watch(pendingGuidanceProvider) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final template = ref.read(pendingGuidanceProvider.notifier).take();
      if (template != null) _appendGuidance(template);
    });
  }

  /// Applies the original message handed over from the standalone Explain page.
  /// The user explicitly chooses this flow by tapping "Generate Reply".
  void _consumePendingReplyInput() {
    if (ref.watch(pendingReplyInputProvider) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = ref.read(pendingReplyInputProvider.notifier).take();
      if (message == null) return;
      _incomingController.text = message;
      _incomingController.selection = TextSelection.collapsed(
        offset: _incomingController.text.length,
      );
    });
  }

  ReplyRequest _request() {
    final String mode;
    String? preset;
    String? custom;
    if (_audience == 'Auto') {
      mode = 'auto';
    } else if (_audience == 'Custom') {
      mode = 'custom';
      custom = _customAudienceController.text;
    } else {
      mode = 'preset';
      preset = _audience.toLowerCase();
    }

    return ReplyRequest(
      incoming: _incomingController.text,
      guidance: _composedGuidance(),
      guidanceLang: 'en',
      tone: _effectiveTone(),
      audience: ReplyAudience(
        mode: mode,
        preset: preset,
        custom: custom?.trim(),
        formality: _formalityForTone(_tone),
      ),
    );
  }

  String? _effectiveTone() {
    final value = _tone == 'Custom' ? _customToneController.text.trim() : _tone;
    return value == 'Auto' || value.isEmpty ? null : value;
  }

  /// Folds Length / Channel selections into the free-text guidance. Tone is a
  /// dedicated request field so custom and predefined values share one path.
  String _composedGuidance() {
    final hints = <String>[];
    final length = _lengthHint(_length);
    if (length != null) hints.add(length);
    final channel = _channelHint(_channel);
    if (channel != null) hints.add(channel);

    final base = _guidanceController.text.trim();
    return [
      if (base.isNotEmpty) base,
      if (hints.isNotEmpty) hints.join(' '),
    ].join('\n\n');
  }

  static int _formalityForTone(String tone) => switch (tone) {
    'Professional' => 80,
    'Friendly' => 35,
    'Natural' => 50,
    _ => 55,
  };

  static String? _lengthHint(String length) => switch (length) {
    'Short' => 'Keep the reply short and concise.',
    'Detailed' => 'Make the reply detailed and thorough.',
    _ => null,
  };

  static String? _channelHint(String channel) => switch (channel) {
    'Text' => 'Write it as a text message.',
    'Email' => 'Write it as an email.',
    'Chat' => 'Write it as a chat message.',
    _ => null,
  };

  Future<void> _generate() async {
    if (!await ensureGenerationAccess(context: context, ref: ref)) return;
    // Capture the received message before the async gap.
    final incoming = _incomingController.text;
    await ref.read(replyControllerProvider.notifier).generate(_request());
    if (!mounted) return;
    final state = ref.read(replyControllerProvider);
    final result = state.result;
    // Only record a recent item on a fresh success (no error, has output).
    if (state.error == null &&
        !state.isLoading &&
        result != null &&
        result.versions.isNotEmpty) {
      final guidance = _guidanceController.text.trim();
      await saveRecentItem(
        ref,
        RecentItem.create(
          type: RecentType.reply,
          inputText: incoming,
          outputText: result.versions.first.text,
          guidance: guidance.isEmpty ? null : guidance,
          tone: _tone == 'Auto' ? null : _tone,
          channel: _channel == 'Auto' ? null : _channel,
          length: _length,
        ),
      );
    }
  }

  Future<void> _pasteIncoming() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _incomingController.text = text.length > 4000
        ? text.substring(0, 4000)
        : text;
    _incomingController.selection = TextSelection.collapsed(
      offset: _incomingController.text.length,
    );
  }

  Future<void> _explain() async {
    if (!await ensureGenerationAccess(context: context, ref: ref)) return;
    final result = await ref
        .read(explainControllerProvider.notifier)
        .explain(text: _incomingController.text, explainLang: 'en');
    if (!mounted) return;
    if (result == null) {
      final error =
          ref.read(explainControllerProvider).error ??
          'Unable to explain this message. Please try again.';
      await _showExplainError(error);
      return;
    }
    await _showExplainResult(result);
  }

  Future<void> _showExplainError(String message) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.couldNotExplain,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(context.l10n.close),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _feature.primaryButtonColor,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _explain();
                      },
                      child: Text(context.l10n.tryAgain),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExplainResult(ExplainResult result) {
    final copyText = [
      '${context.l10n.meaning}: ${result.meaning}',
      '${context.l10n.tone}: ${result.tone}',
      '${context.l10n.hiddenMeaning}: ${result.hiddenMeaning}',
    ].join('\n\n');

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.explainMessage,
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.copyExplanation,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: copyText));
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(content: Text(sheetContext.l10n.copied)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ExplanationRow(
                label: context.l10n.meaning,
                text: result.meaning,
              ),
              _ExplanationRow(label: context.l10n.tone, text: result.tone),
              _ExplanationRow(
                label: context.l10n.hiddenMeaning,
                text: result.hiddenMeaning.isEmpty
                    ? context.l10n.noHiddenMeaning
                    : result.hiddenMeaning,
              ),
              Text(
                context.l10n.suggestedReplies,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 8),
              for (final suggestion in result.suggestedReplies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    feature: _feature,
                    showFeatureImage: false,
                    tintStrength: _kCardTintStrength,
                    tintColor: _kCardTint,
                    blur: 6,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(suggestion, style: AppTextStyles.body),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _guidanceController.text = suggestion;
                          },
                          child: Text(context.l10n.use),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final replyState = ref.watch(replyControllerProvider);
    final explainState = ref.watch(explainControllerProvider);
    final usageState = ref.watch(usageControllerProvider);
    _consumePendingGuidance();
    _consumePendingReplyInput();

    return AppPage(
      title: context.l10n.reply,
      accentColor: _kColor,
      backgroundImagePath: _feature.pageBackgroundImage,
      showAppBar: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverAppBar(
            key: const Key('reply-hero-header'),
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
              context.l10n.reply,
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
                  key: const Key('reply-message-card'),
                  feature: _feature,
                  showFeatureImage: false,
                  tintStrength: _kCardTintStrength,
                  tintColor: _kCardTint,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _CardHeader(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: context.l10n.messageReceived,
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        key: const Key('reply-incoming-field'),
                        label: context.l10n.messageYouReceived,
                        feature: _feature,
                        showHeader: false,
                        showCounter: false,
                        controller: _incomingController,
                        hintText: context.l10n.pasteOriginalMessage,
                        maxLines: 5,
                        maxLength: 4000,
                        fieldActions: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: context.l10n.explain,
                              visualDensity: VisualDensity.compact,
                              color: _kColor,
                              onPressed: explainState.isLoading
                                  ? null
                                  : _explain,
                              icon: explainState.isLoading
                                  ? const SizedBox.square(
                                      dimension: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 20,
                                    ),
                            ),
                            IconButton(
                              tooltip: context.l10n.paste,
                              visualDensity: VisualDensity.compact,
                              color: _kColor,
                              onPressed: _pasteIncoming,
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: context.l10n.clear,
                              visualDensity: VisualDensity.compact,
                              color: _kColor,
                              onPressed: _incomingController.clear,
                              icon: const Icon(Icons.close_rounded, size: 21),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  key: const Key('reply-guidance-card'),
                  feature: _feature,
                  showFeatureImage: false,
                  tintStrength: _kCardTintStrength,
                  tintColor: _kCardTint,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(
                          () => _guidanceExpanded = !_guidanceExpanded,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const _GradientIconBadge(
                                    icon: Icons.lightbulb_outline_rounded,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  _ExpandButton(expanded: _guidanceExpanded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_guidanceExpanded) ...[
                        const Divider(height: 1, color: AppColors.cardBorder),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GuidanceTextField(
                                key: const Key('reply-guidance-field'),
                                feature: _feature,
                                controller: _guidanceController,
                                hintText: context.l10n.addReplyInstructions,
                                maxLines: 4,
                                maxLength: InputLimits.guidanceMaxLength,
                                onOpenLibrary: _openLibrary,
                              ),
                              const SizedBox(height: 14),
                              _QuickGuidanceChips(
                                onAppend: _appendGuidanceText,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _MoreOptionsSection(
                  key: const Key('reply-more-options-card'),
                  expanded: _moreOptionsExpanded,
                  onToggle: () => setState(
                    () => _moreOptionsExpanded = !_moreOptionsExpanded,
                  ),
                  tones: _tones,
                  tone: _tone,
                  onTone: (v) => setState(() => _tone = v),
                  customToneController: _customToneController,
                  audiences: _audiences,
                  audience: _audience,
                  onAudience: (v) => setState(() => _audience = v),
                  customAudienceController: _customAudienceController,
                  lengths: _lengths,
                  length: _length,
                  onLength: (v) => setState(() => _length = v),
                  channels: _channels,
                  channel: _channel,
                  onChannel: (v) => setState(() => _channel = v),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _feature.primaryButtonColor,
                  ),
                  onPressed: replyState.isLoading ? null : _generate,
                  icon: replyState.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    replyState.isLoading
                        ? context.l10n.generating
                        : context.l10n.generateReply,
                  ),
                ),
                if (replyState.isLoading) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.creatingNaturalOptions,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.helper,
                  ),
                ],
                if (replyState.error != null) ...[
                  const SizedBox(height: 12),
                  InlineError(
                    message: replyState.error!,
                    actionLabel: replyState.errorCode == 'PAYWALL_REQUIRED'
                        ? null
                        : context.l10n.tryAgain,
                    onAction: replyState.errorCode == 'PAYWALL_REQUIRED'
                        ? null
                        : _generate,
                  ),
                  if (replyState.errorCode == 'PAYWALL_REQUIRED')
                    TextButton(
                      onPressed: () => context.push(AppRoutes.paywall),
                      child: Text(context.l10n.viewPlans),
                    ),
                ],
                if (!replyState.isLoading &&
                    replyState.error == null &&
                    replyState.result == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.replyOptionsAppearHere,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.helper,
                  ),
                ],
                if (replyState.result != null) ...[
                  const SizedBox(height: 26),
                  Text(
                    context.l10n.yourReplies,
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  for (final version in replyState.result!.versions) ...[
                    GeneratedResultCard(
                      label: version.label,
                      text: version.text,
                      feature: _feature,
                      showFeatureImage: false,
                      tintStrength: _kCardTintStrength,
                      tintColor: _kCardTint,
                    ),
                    const SizedBox(height: 12),
                  ],
                  GlassCard(
                    feature: _feature,
                    showFeatureImage: false,
                    tintStrength: _kCardTintStrength,
                    tintColor: _kCardTint,
                    blur: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.whyThisWorks,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(replyState.result!.why, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kColor,
                      side: const BorderSide(color: _kColor),
                    ),
                    onPressed: replyState.isLoading ? null : _generate,
                    icon: replyState.isLoading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.regenerateReplies),
                  ),
                  if (!usageState.usage.isPremium)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.l10n.regenerateUsageNote,
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

/// Icon-circle + title used as the header for the Message card.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GradientIconBadge(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular gradient icon badge used on the Message received, Guidance and
/// More options section headers.
class _GradientIconBadge extends StatelessWidget {
  const _GradientIconBadge({required this.icon});

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

/// Circular expand/collapse affordance shown at the end of a section header.
class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.expanded});

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

/// Fixed one-tap instruction chips. Each shows a short label but appends the
/// canonical built-in guidance content (sourced by stable id) so the chips stay
/// in sync with the Guidance Library.
class _QuickGuidanceChips extends StatelessWidget {
  const _QuickGuidanceChips({required this.onAppend});

  final ValueChanged<String> onAppend;

  // (chip label, built-in template id, icon)
  static const _chips = <(String, String, IconData)>[
    ('Be polite', 'builtin_be_polite', Icons.sentiment_satisfied_alt_rounded),
    ('Keep it short', 'builtin_keep_short', Icons.short_text_rounded),
    ('Professional', 'builtin_professional', Icons.business_center_outlined),
    ('Friendly', 'builtin_friendly', Icons.waving_hand_outlined),
    ('Decline politely', 'builtin_decline', Icons.do_not_disturb_alt_outlined),
    ('Say thank you', 'builtin_thanks', Icons.volunteer_activism_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final labels = {
      'builtin_be_polite': context.l10n.bePolite,
      'builtin_keep_short': context.l10n.keepItShort,
      'builtin_professional': context.l10n.professional,
      'builtin_friendly': context.l10n.friendly,
      'builtin_decline': context.l10n.declinePolitely,
      'builtin_thanks': context.l10n.sayThankYou,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.quickGuidance, style: AppTextStyles.badge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, id, icon) in _chips)
              ActionChip(
                backgroundColor: _feature.selectedChipColor,
                side: const BorderSide(color: AppColors.glassEdgeStrong),
                avatar: Icon(icon, size: 15, color: _kColor),
                label: Text(
                  labels[id] ?? label,
                  style: const TextStyle(color: _kColor),
                ),
                onPressed: () => onAppend(
                  kBuiltInTemplates.firstWhere((t) => t.id == id).content,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Lightweight, collapsible section holding the optional Tone / Audience /
/// Length / Channel controls.
class _MoreOptionsSection extends StatelessWidget {
  const _MoreOptionsSection({
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
    required this.channels,
    required this.channel,
    required this.onChannel,
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
  final List<String> channels;
  final String channel;
  final ValueChanged<String> onChannel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: _feature,
      showFeatureImage: false,
      tintStrength: _kCardTintStrength,
      tintColor: _kCardTint,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _GradientIconBadge(icon: Icons.tune_rounded),
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
                              context.l10n.customizeStyleToneFormat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.helper,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ExpandButton(expanded: expanded),
                    ],
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
                  _OptionGroup(
                    label: context.l10n.tone,
                    groupIcon: Icons.record_voice_over_outlined,
                    accentColor: AppColors.replyColor,
                    options: tones,
                    selected: tone,
                    onSelected: onTone,
                  ),
                  if (tone == 'Custom') ...[
                    const SizedBox(height: 10),
                    LabeledTextField(
                      key: const Key('reply-custom-tone-field'),
                      label: context.l10n.describeTone,
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customToneController,
                      hintText: context.l10n.toneHint,
                      maxLines: 1,
                      maxLength: 500,
                    ),
                  ],
                  const _OptionDivider(),
                  _OptionGroup(
                    label: context.l10n.audience,
                    groupIcon: Icons.groups_outlined,
                    accentColor: AppColors.explainColor,
                    options: audiences,
                    selected: audience,
                    onSelected: onAudience,
                  ),
                  if (audience == 'Custom') ...[
                    const SizedBox(height: 10),
                    LabeledTextField(
                      key: const Key('reply-custom-audience-field'),
                      label: context.l10n.describeRelationship,
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customAudienceController,
                      hintText: context.l10n.relationshipHint,
                      maxLines: 1,
                      maxLength: 500,
                    ),
                  ],
                  const _OptionDivider(),
                  _OptionGroup(
                    label: context.l10n.length,
                    groupIcon: Icons.format_size_rounded,
                    accentColor: AppColors.polishColor,
                    options: lengths,
                    selected: length,
                    onSelected: onLength,
                  ),
                  const _OptionDivider(),
                  _OptionGroup(
                    label: context.l10n.channel,
                    groupIcon: Icons.send_outlined,
                    accentColor: AppColors.replyColor,
                    options: channels,
                    selected: channel,
                    onSelected: onChannel,
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

/// A labelled row of single-select chips used inside More options.
class _OptionGroup extends StatelessWidget {
  const _OptionGroup({
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(groupIcon, size: 17, color: accentColor),
            const SizedBox(width: 5),
            Text(label, style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
          ],
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
                  _optionIcon(option),
                  size: 16,
                  color: option == selected
                      ? accentColor
                      : AppColors.textSecondary,
                ),
                label: Text(
                  _localizedOption(context, option),
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

  IconData _optionIcon(String option) {
    return switch (option) {
      'Auto' => Icons.auto_awesome_rounded,
      'Natural' => Icons.spa_outlined,
      'Professional' => Icons.business_center_outlined,
      'Friendly' => Icons.sentiment_satisfied_alt_rounded,
      'Friend' => Icons.person_outline_rounded,
      'Customer' => Icons.storefront_outlined,
      'Coworker' => Icons.groups_outlined,
      'Manager' => Icons.supervisor_account_outlined,
      'Short' => Icons.short_text_rounded,
      'Medium' => Icons.subject_rounded,
      'Detailed' => Icons.notes_rounded,
      'Text' => Icons.sms_outlined,
      'Email' => Icons.email_outlined,
      'Chat' => Icons.chat_bubble_outline_rounded,
      _ => Icons.tune_rounded,
    };
  }
}

String _localizedOption(BuildContext context, String option) =>
    switch (option) {
      'Auto' => context.l10n.auto,
      'Natural' => context.l10n.natural,
      'Professional' => context.l10n.professional,
      'Friendly' => context.l10n.friendly,
      'Custom' => context.l10n.custom,
      'Friend' => context.l10n.friend,
      'Customer' => context.l10n.customer,
      'Coworker' => context.l10n.coworker,
      'Manager' => context.l10n.manager,
      'Short' => context.l10n.short,
      'Medium' => context.l10n.medium,
      'Detailed' => context.l10n.detailed,
      'Text' => context.l10n.textChannel,
      'Email' => context.l10n.email,
      'Chat' => context.l10n.chat,
      _ => option,
    };

class _OptionDivider extends StatelessWidget {
  const _OptionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: AppColors.cardBorder),
    );
  }
}

class _ExplanationRow extends StatelessWidget {
  const _ExplanationRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.cardTitle),
          const SizedBox(height: 3),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
