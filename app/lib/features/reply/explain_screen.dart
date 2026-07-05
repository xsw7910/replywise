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
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import '../entitlement/usage_controller.dart';
import '../recent/application/recent_providers.dart';
import '../recent/domain/recent_item.dart';
import 'application/explain_controller.dart';
import 'application/pending_reply_input_provider.dart';
import 'domain/reply_models.dart';
import 'widgets/reply_status_badge.dart';

const _kColor = AppColors.explainColor;
const _feature = AppFeature.explain;
// Match the Reply page: every card shares one plain white surface so the app
// reads as a single consistent surface.
const _kCardTint = Colors.white;
const _kCardTintStrength = 1.0;

class ExplainScreen extends ConsumerStatefulWidget {
  const ExplainScreen({super.key});

  @override
  ConsumerState<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends ConsumerState<ExplainScreen> {
  final _messageController = TextEditingController();
  ExplainResult? _result;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pasteMessage() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _messageController.text = text.length > InputLimits.explainMessageMaxLength
        ? text.substring(0, InputLimits.explainMessageMaxLength)
        : text;
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
  }

  Future<void> _explain() async {
    // Capture the message before the async gap.
    final input = _messageController.text;
    final result = await ref
        .read(explainControllerProvider.notifier)
        .explain(text: input, explainLang: 'en');
    if (!mounted || result == null) return;
    setState(() => _result = result);
    await saveRecentItem(
      ref,
      RecentItem.create(
        type: RecentType.explain,
        inputText: input,
        outputText: result.meaning,
      ),
    );
  }

  Future<void> _copySuggestion(String suggestion) async {
    await Clipboard.setData(ClipboardData(text: suggestion));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  void _continueToReply() {
    final original = _messageController.text.trim();
    if (original.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.enterMessageFirst)));
      return;
    }
    ref.read(pendingReplyInputProvider.notifier).set(original);
    context.go(AppRoutes.reply);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(explainControllerProvider);
    final usage = ref.watch(usageControllerProvider).usage;

    return AppPage(
      title: context.l10n.explain,
      accentColor: _kColor,
      backgroundImagePath: _feature.pageBackgroundImage,
      transparentAppBar: true,
      centerTitle: false,
      actions: [
        ReplyStatusBadge(
          usage: usage,
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
              key: const Key('explain-message-field'),
              label: context.l10n.messageToUnderstand,
              feature: _feature,
              showCounter: false,
              controller: _messageController,
              hintText: context.l10n.pasteMessageReceived,
              maxLines: 7,
              maxLength: InputLimits.explainMessageMaxLength,
              fieldActions: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.l10n.paste,
                    visualDensity: VisualDensity.compact,
                    color: _kColor,
                    onPressed: state.isLoading ? null : _pasteMessage,
                    icon: const Icon(Icons.content_paste_rounded, size: 20),
                  ),
                  IconButton(
                    tooltip: context.l10n.clear,
                    visualDensity: VisualDensity.compact,
                    color: _kColor,
                    onPressed: _messageController.clear,
                    icon: const Icon(Icons.close_rounded, size: 21),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('explain-submit-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _feature.primaryButtonColor,
            ),
            onPressed: state.isLoading ? null : _explain,
            icon: state.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.psychology_alt_rounded),
            label: Text(
              state.isLoading
                  ? context.l10n.explaining
                  : context.l10n.explainThisMessage,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            InlineError(
              message: _friendlyError(state),
              actionLabel: context.l10n.tryAgain,
              onAction: state.isLoading ? null : _explain,
            ),
          ],
          if (state.isLoading) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.readingBetweenLines,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
            ),
          ],
          if (_result == null && !state.isLoading && state.error == null) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.explanationAppearsHere,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultSection(
              icon: Icons.article_outlined,
              title: context.l10n.meaning,
              text: _result!.meaning,
              color: _kColor,
            ),
            const SizedBox(height: 12),
            _ResultSection(
              icon: Icons.record_voice_over_outlined,
              title: context.l10n.tone,
              text: _result!.tone,
              color: _kColor,
            ),
            const SizedBox(height: 12),
            _ResultSection(
              icon: Icons.visibility_outlined,
              title: context.l10n.hiddenMeaning,
              text: _result!.hiddenMeaning.trim().isEmpty
                  ? context.l10n.noHiddenMeaning
                  : _result!.hiddenMeaning,
              color: _kColor,
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.suggestedReplies,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 10),
            if (_result!.suggestedReplies.isEmpty)
              Text(context.l10n.noSuggestedReplies, style: AppTextStyles.helper)
            else
              for (final suggestion in _result!.suggestedReplies) ...[
                _SuggestionCard(
                  suggestion: suggestion,
                  onCopy: () => _copySuggestion(suggestion),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 12),
            _ContinueCard(onPressed: _continueToReply),
          ],
        ],
      ),
    );
  }

  String _friendlyError(ExplainState state) {
    if (state.errorCode == 'RATE_LIMITED') {
      return context.l10n.explainRateLimited;
    }
    if (state.errorCode == 'MODEL_PARSE_ERROR') {
      return context.l10n.explainParseError;
    }
    if (state.errorCode == 'MODEL_UNAVAILABLE') {
      return context.l10n.explainUnavailable;
    }
    return state.error ?? context.l10n.unableToExplain;
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: _feature,
      blur: 8,
      showFeatureImage: false,
      tintColor: _kCardTint,
      tintStrength: _kCardTintStrength,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 6),
                Text(text, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onCopy});

  final String suggestion;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: _feature,
      blur: 8,
      showFeatureImage: false,
      tintColor: _kCardTint,
      tintStrength: _kCardTintStrength,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconBadge(
            icon: Icons.chat_bubble_outline_rounded,
            color: _kColor,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(suggestion, style: AppTextStyles.body)),
          IconButton(
            tooltip: context.l10n.copy,
            style: IconButton.styleFrom(
              foregroundColor: _kColor,
              backgroundColor: _feature.iconBackgroundColor,
            ),
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      feature: _feature,
      showFeatureImage: false,
      tintColor: _kCardTint,
      tintStrength: _kCardTintStrength,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.replyCtaTitle, style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            key: const Key('explain-continue-reply-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _feature.primaryButtonColor,
            ),
            onPressed: onPressed,
            icon: const Icon(Icons.reply_rounded),
            label: Text(context.l10n.generateReply),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
