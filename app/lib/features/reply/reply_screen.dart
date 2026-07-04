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
import '../guidance/application/pending_guidance_provider.dart';
import '../guidance/domain/guidance_template.dart';
import '../guidance/presentation/guidance_picker_sheet.dart';
import '../guidance/presentation/guidance_text_field.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'widgets/reply_status_badge.dart';
import 'application/explain_controller.dart';
import 'application/pending_reply_input_provider.dart';
import 'application/reply_controller.dart';
import 'domain/reply_models.dart';
import '../entitlement/usage_controller.dart';

const _kColor = AppColors.replyColor;
const _feature = AppFeature.reply;

// Every card on the Reply page shares one surface tint (matching the
// "More options" card) so the page reads as a single consistent surface.
const _kCardTint = Color(0xFFE8F2FF);
const _kCardTintStrength = 0.65;

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

  Future<void> _generate() =>
      ref.read(replyControllerProvider.notifier).generate(_request());

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
                'Couldn’t explain this message',
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
                      child: const Text('Close'),
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
                      child: const Text('Try again'),
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
      'Meaning: ${result.meaning}',
      'Tone: ${result.tone}',
      'Hidden meaning: ${result.hiddenMeaning}',
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
                      'Explain message',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy explanation',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: copyText));
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(
                        sheetContext,
                      ).showSnackBar(const SnackBar(content: Text('Copied')));
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ExplanationRow(label: 'Meaning', text: result.meaning),
              _ExplanationRow(label: 'Tone', text: result.tone),
              _ExplanationRow(
                label: 'Hidden meaning',
                text: result.hiddenMeaning.isEmpty
                    ? 'No hidden meaning detected.'
                    : result.hiddenMeaning,
              ),
              Text('Suggested replies', style: AppTextStyles.cardTitle),
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
                          child: const Text('Use'),
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
      title: 'Reply',
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
            tintStrength: _kCardTintStrength,
            tintColor: _kCardTint,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const _CardHeader(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Message received',
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  key: const Key('reply-incoming-field'),
                  label: 'Message you received',
                  feature: _feature,
                  showHeader: false,
                  showCounter: false,
                  controller: _incomingController,
                  hintText: 'Paste the original message here…',
                  maxLines: 5,
                  maxLength: 4000,
                  fieldActions: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Explain',
                        visualDensity: VisualDensity.compact,
                        color: _kColor,
                        onPressed: explainState.isLoading ? null : _explain,
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
                        tooltip: 'Paste',
                        visualDensity: VisualDensity.compact,
                        color: _kColor,
                        onPressed: _pasteIncoming,
                        icon: const Icon(Icons.content_paste_rounded, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Clear',
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
                  onTap: () =>
                      setState(() => _guidanceExpanded = !_guidanceExpanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: _kColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Guidance',
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        Text(
                          _guidanceExpanded ? 'Hide' : 'Add guidance',
                          style: AppTextStyles.helper.copyWith(color: _kColor),
                        ),
                        Icon(
                          _guidanceExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
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
                          hintText: 'Add your reply instructions…',
                          maxLines: 4,
                          maxLength: InputLimits.guidanceMaxLength,
                          onOpenLibrary: _openLibrary,
                        ),
                        const SizedBox(height: 14),
                        _QuickGuidanceChips(onAppend: _appendGuidanceText),
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
            onToggle: () =>
                setState(() => _moreOptionsExpanded = !_moreOptionsExpanded),
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
              replyState.isLoading ? 'Generating…' : 'Generate Reply',
            ),
          ),
          if (replyState.isLoading) ...[
            const SizedBox(height: 10),
            Text(
              'Creating a few natural options…',
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
                  : 'Try again',
              onAction: replyState.errorCode == 'PAYWALL_REQUIRED'
                  ? null
                  : _generate,
            ),
            if (replyState.errorCode == 'PAYWALL_REQUIRED')
              TextButton(
                onPressed: () => context.push(AppRoutes.paywall),
                child: const Text('View plans'),
              ),
          ],
          if (!replyState.isLoading &&
              replyState.error == null &&
              replyState.result == null) ...[
            const SizedBox(height: 12),
            Text(
              'Your reply options will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
            ),
          ],
          if (replyState.result != null) ...[
            const SizedBox(height: 26),
            Text('Your replies', style: AppTextStyles.sectionTitle),
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
                  Text('Why this works', style: AppTextStyles.cardTitle),
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
              label: const Text('Regenerate replies'),
            ),
            if (!usageState.usage.isPremium)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Regenerating creates new replies and uses 1 generation.',
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

/// Icon-circle + title used as the header for the Message card.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(210),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: AppColors.softBlueShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _kColor, size: 21),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick guidance', style: AppTextStyles.badge),
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
                label: Text(label, style: const TextStyle(color: _kColor)),
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
                  _OptionGroup(
                    label: 'Tone',
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
                  const _OptionDivider(),
                  _OptionGroup(
                    label: 'Audience',
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
                      label: 'Describe the relationship',
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customAudienceController,
                      hintText: 'For example: my landlord',
                      maxLines: 1,
                      maxLength: 500,
                    ),
                  ],
                  const _OptionDivider(),
                  _OptionGroup(
                    label: 'Length',
                    groupIcon: Icons.format_size_rounded,
                    accentColor: AppColors.polishColor,
                    options: lengths,
                    selected: length,
                    onSelected: onLength,
                  ),
                  const _OptionDivider(),
                  _OptionGroup(
                    label: 'Channel',
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
                  option,
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
    return switch (label) {
      'Tone' => switch (option) {
        'Auto' => Icons.auto_awesome_rounded,
        'Natural' => Icons.spa_outlined,
        'Professional' => Icons.business_center_outlined,
        'Friendly' => Icons.sentiment_satisfied_alt_rounded,
        _ => Icons.tune_rounded,
      },
      'Audience' => switch (option) {
        'Auto' => Icons.auto_awesome_rounded,
        'Friend' => Icons.person_outline_rounded,
        'Customer' => Icons.storefront_outlined,
        'Coworker' => Icons.groups_outlined,
        'Manager' => Icons.supervisor_account_outlined,
        _ => Icons.person_search_outlined,
      },
      'Length' => switch (option) {
        'Short' => Icons.short_text_rounded,
        'Medium' => Icons.subject_rounded,
        _ => Icons.notes_rounded,
      },
      _ => switch (option) {
        'Auto' => Icons.devices_rounded,
        'Text' => Icons.sms_outlined,
        'Email' => Icons.email_outlined,
        _ => Icons.chat_bubble_outline_rounded,
      },
    };
  }
}

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
