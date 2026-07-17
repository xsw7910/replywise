import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/input_limits.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/text/paste_into_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feature_theme.dart';
import '../app_status/presentation/app_status_dialogs.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/feature_page_header.dart';
import '../../core/widgets/generated_result_card.dart';
import '../../core/widgets/glass_card.dart';
import '../guidance/application/pending_guidance_provider.dart';
import '../guidance/domain/guidance_template.dart';
import '../guidance/presentation/guidance_library_screen.dart';
import '../guidance/presentation/guidance_picker_sheet.dart';
import '../guidance/presentation/guidance_text_field.dart';
import '../recent/application/recent_providers.dart';
import '../recent/domain/recent_item.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'widgets/reply_status_badge.dart';
import 'application/pending_reply_input_provider.dart';
import 'application/reply_controller.dart';
import 'application/reply_page_controller.dart';
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
  // Controllers stay widget-local (they are lifecycle objects and must not
  // live in a provider). Their text is mirrored into ReplyPageController so it
  // survives navigation; on rebuild the text is restored from that provider.
  late final TextEditingController _incomingController;
  late final TextEditingController _guidanceController;
  late final TextEditingController _customToneController;
  late final TextEditingController _customAudienceController;

  ReplyPageController get _page =>
      ref.read(replyPageControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Restore each field from the kept-alive page state, then wire a one-way
    // controller→provider sync. We never write provider→controller outside of
    // this initial restore, so normal typing keeps its cursor position.
    final state = ref.read(replyPageControllerProvider);
    _incomingController = TextEditingController(text: state.incoming)
      ..addListener(() => _page.setIncoming(_incomingController.text));
    _guidanceController = TextEditingController(text: state.guidance)
      ..addListener(() => _page.setGuidance(_guidanceController.text));
    _customToneController = TextEditingController(text: state.customTone)
      ..addListener(() => _page.setCustomTone(_customToneController.text));
    _customAudienceController =
        TextEditingController(text: state.customAudience)..addListener(
          () => _page.setCustomAudience(_customAudienceController.text),
        );
  }

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
    final next = current.isEmpty ? text : '$current\n$text';
    // Atomic value update: text, caret at the end of the inserted guidance,
    // and cleared composing region in one frame. The caret is moved to the
    // end ONLY here (explicit Quick Guidance insertion) — never during normal
    // typing or rebuilds.
    _guidanceController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    // Applying any guidance reveals the field so the user sees what was added.
    _page.setGuidanceExpanded(true);
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
    // Atomic replacement with the caret at the end — used only for explicit
    // template insertions, never during normal typing.
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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

  void _consumePendingTargetedGuidance() {
    if (ref.watch(pendingTargetedGuidanceProvider) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingTargetedGuidanceProvider.notifier).take();
      if (pending == null) return;
      switch (pending.target) {
        case GuidanceInsertionTarget.replyTone:
          _setControllerText(_customToneController, pending.template.content);
          break;
        case GuidanceInsertionTarget.replyAudience:
          _setControllerText(
            _customAudienceController,
            pending.template.content,
          );
          break;
        case GuidanceInsertionTarget.polishTone:
        case GuidanceInsertionTarget.polishAudience:
          break;
      }
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

  ReplyRequest _request(String appLocale, ReplyPageState page) {
    final String mode;
    String? preset;
    String? custom;
    if (page.audience == 'Auto') {
      mode = 'auto';
    } else if (page.audience == 'Custom') {
      mode = 'custom';
      custom = _customAudienceController.text;
    } else {
      mode = 'preset';
      preset = page.audience.toLowerCase();
    }

    return ReplyRequest(
      incoming: _incomingController.text,
      guidance: _composedGuidance(page),
      guidanceLang: appLocale,
      appLocale: appLocale,
      tone: _effectiveTone(page),
      audience: ReplyAudience(
        mode: mode,
        preset: preset,
        custom: custom?.trim(),
        formality: _formalityForTone(page.tone),
      ),
    );
  }

  String? _effectiveTone(ReplyPageState page) {
    final value = page.tone == 'Custom'
        ? _customToneController.text.trim()
        : page.tone;
    return value == 'Auto' || value.isEmpty ? null : value;
  }

  /// Folds Length / Channel selections into the free-text guidance. Tone is a
  /// dedicated request field so custom and predefined values share one path.
  String _composedGuidance(ReplyPageState page) {
    final hints = <String>[];
    final length = _lengthHint(page.length);
    if (length != null) hints.add(length);
    final channel = _channelHint(page.channel);
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
    // No API request (and no credit/status gating) for an empty input.
    if (_incomingController.text.trim().isEmpty) {
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
    // Capture the received message and option snapshot before the async gap.
    final incoming = _incomingController.text;
    final page = ref.read(replyPageControllerProvider);
    await ref
        .read(replyControllerProvider.notifier)
        .generate(_request(appLocale, page));
    if (!mounted) return;
    final state = ref.read(replyControllerProvider);
    // A network/server failure re-checks status: maintenance or fallback UI.
    if (isNetworkFailure(state.errorCode)) {
      await handleAiRequestFailure(
        context: context,
        ref: ref,
        feature: _feature,
        onRetry: _generate,
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
        onRetry: _generate,
      );
      return;
    }
    final result = state.result;
    // Only record a recent item on a fresh success (no error, has output).
    if (state.error == null &&
        !state.isLoading &&
        result != null &&
        result.versions.isNotEmpty) {
      final guidance = _guidanceController.text.trim();
      String? versionText(String label) {
        for (final version in result.versions) {
          if (version.label.toLowerCase() == label.toLowerCase()) {
            return version.text;
          }
        }
        return null;
      }

      final formal = versionText('Formal');
      final casual = versionText('Casual');
      final concise = versionText('Concise');
      await saveRecentItem(
        ref,
        RecentItem.create(
          type: RecentType.reply,
          inputText: incoming,
          outputText: formal ?? result.versions.first.text,
          formalText: formal,
          casualText: casual,
          conciseText: concise,
          guidance: guidance.isEmpty ? null : guidance,
          tone: page.tone == 'Auto' ? null : page.tone,
          channel: page.channel == 'Auto' ? null : page.channel,
          length: page.length,
        ),
      );
    }
  }

  Future<void> _pasteIncoming() async {
    await pasteIntoController(_incomingController, maxLength: 4000);
  }

  @override
  Widget build(BuildContext context) {
    final replyState = ref.watch(replyControllerProvider);
    final usageState = ref.watch(usageControllerProvider);
    // Watch only the flag/enum fields so per-keystroke text updates (mirrored
    // into the same provider) never rebuild this large page — the controllers
    // drive the text fields directly.
    final guidanceExpanded = ref.watch(
      replyPageControllerProvider.select((s) => s.guidanceExpanded),
    );
    final moreOptionsExpanded = ref.watch(
      replyPageControllerProvider.select((s) => s.moreOptionsExpanded),
    );
    final tone = ref.watch(replyPageControllerProvider.select((s) => s.tone));
    final audience = ref.watch(
      replyPageControllerProvider.select((s) => s.audience),
    );
    final length = ref.watch(
      replyPageControllerProvider.select((s) => s.length),
    );
    final channel = ref.watch(
      replyPageControllerProvider.select((s) => s.channel),
    );
    _consumePendingGuidance();
    _consumePendingTargetedGuidance();
    _consumePendingReplyInput();

    return AppPage(
      title: context.l10n.reply,
      accentColor: _kColor,
      backgroundImagePath: _feature.pageBackgroundImage,
      showAppBar: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: FeatureHeroHeader(
              key: const Key('reply-hero-header'),
              feature: _feature,
              title: context.l10n.reply,
              color: _kColor,
              trailing: ReplyStatusBadge(
                usage: usageState.usage,
                onTap: () => context.push(AppRoutes.paywall),
              ),
            ),
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
                        showClearButton: true,
                        fieldActions: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                        onTap: _page.toggleGuidanceExpanded,
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
                                  _ExpandButton(expanded: guidanceExpanded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (guidanceExpanded) ...[
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
                                onOpenTemplates: _openLibrary,
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
                  expanded: moreOptionsExpanded,
                  onToggle: _page.toggleMoreOptionsExpanded,
                  tones: _tones,
                  tone: tone,
                  onTone: _page.setTone,
                  onOpenTemplatePage: _openTemplatePage,
                  customToneController: _customToneController,
                  audiences: _audiences,
                  audience: audience,
                  onAudience: _page.setAudience,
                  customAudienceController: _customAudienceController,
                  lengths: _lengths,
                  length: length,
                  onLength: _page.setLength,
                  channels: _channels,
                  channel: channel,
                  onChannel: _page.setChannel,
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
                      shareTooltip: context.l10n.shareReply,
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

/// Reply guidance shortcuts. The first chip opens the templates picker; the
/// rest are one-tap reply intents that append a short guidance instruction.
class _QuickGuidanceChips extends StatelessWidget {
  const _QuickGuidanceChips({
    required this.onAppend,
    required this.onOpenTemplates,
  });

  final ValueChanged<String> onAppend;
  final VoidCallback onOpenTemplates;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Guidance shortcuts (localized label, icon, tap action), sorted shortest
    // label first so the grid reads top-down from compact to longer chips.
    final guidance = <(String, IconData, VoidCallback)>[
      (
        l10n.acceptPolitely,
        Icons.check_circle_outline,
        () => onAppend('Accept the request politely.'),
      ),
      (
        l10n.declinePolitely,
        Icons.do_not_disturb_alt_outlined,
        () => onAppend('Politely decline the request without sounding rude.'),
      ),
      (
        l10n.askForClarification,
        Icons.help_outline,
        () => onAppend('Ask for clarification about the details.'),
      ),
      (
        l10n.explainTheReason,
        Icons.info_outline,
        () => onAppend('Explain the reason behind the reply.'),
      ),
      (
        l10n.offerAnAlternative,
        Icons.alt_route_rounded,
        () => onAppend('Offer an alternative option.'),
      ),
      (
        l10n.suggestACompromise,
        Icons.handshake_outlined,
        () => onAppend('Suggest a compromise that works for both sides.'),
      ),
      (
        l10n.showAppreciation,
        Icons.volunteer_activism_outlined,
        () => onAppend('Show appreciation and thank them.'),
      ),
      (
        l10n.apologizeBriefly,
        Icons.sentiment_dissatisfied_outlined,
        () => onAppend('Apologize briefly and sincerely.'),
      ),
      (
        l10n.beFirmButKind,
        Icons.shield_outlined,
        () => onAppend('Be firm but kind in the reply.'),
      ),
    ]..sort((a, b) => a.$1.length.compareTo(b.$1.length));

    // The templates picker stays pinned first. Use the self-contained
    // useATemplate string rather than concatenating use + useATemplate: the
    // latter duplicated the verb in languages where useATemplate is already a
    // full "Use a template" phrase (e.g. zh "使用 使用模板").
    final items = <(String, IconData, VoidCallback)>[
      (l10n.useATemplate, Icons.menu_book_rounded, onOpenTemplates),
      ...guidance,
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
            for (final item in items)
              _chip(item, maxWidth: MediaQuery.sizeOf(context).width - 48),
          ],
        ),
      ],
    );
  }

  Widget _chip(
    (String, IconData, VoidCallback) item, {
    required double maxWidth,
  }) {
    final (label, icon, onTap) = item;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: _feature.selectedChipColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassEdgeStrong),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: _kColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kColor),
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
    required this.onOpenTemplatePage,
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
  final ValueChanged<GuidanceInsertionTarget> onOpenTemplatePage;
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
                    accentColor: _kColor,
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
                      fieldActions: IconButton(
                        tooltip: context.l10n.templates,
                        visualDensity: VisualDensity.compact,
                        color: _kColor,
                        onPressed: () => onOpenTemplatePage(
                          GuidanceInsertionTarget.replyTone,
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                      ),
                    ),
                  ],
                  const _OptionDivider(),
                  _OptionGroup(
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
                      key: const Key('reply-custom-audience-field'),
                      label: context.l10n.describeRelationship,
                      feature: _feature,
                      showHeader: false,
                      showCounter: false,
                      controller: customAudienceController,
                      hintText: context.l10n.relationshipHint,
                      maxLines: 1,
                      maxLength: 500,
                      fieldActions: IconButton(
                        tooltip: context.l10n.templates,
                        visualDensity: VisualDensity.compact,
                        color: _kColor,
                        onPressed: () => onOpenTemplatePage(
                          GuidanceInsertionTarget.replyAudience,
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                      ),
                    ),
                  ],
                  const _OptionDivider(),
                  _OptionGroup(
                    label: context.l10n.length,
                    groupIcon: Icons.format_size_rounded,
                    accentColor: _kColor,
                    options: lengths,
                    selected: length,
                    onSelected: onLength,
                  ),
                  const _OptionDivider(),
                  _OptionGroup(
                    label: context.l10n.channel,
                    groupIcon: Icons.send_outlined,
                    accentColor: _kColor,
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
