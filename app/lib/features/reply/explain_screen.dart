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
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'application/explain_controller.dart';
import 'application/pending_reply_input_provider.dart';
import 'domain/reply_models.dart';

const _kColor = AppColors.explainColor;
const _feature = AppFeature.explain;

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
    final result = await ref
        .read(explainControllerProvider.notifier)
        .explain(text: _messageController.text, explainLang: 'en');
    if (!mounted || result == null) return;
    setState(() => _result = result);
  }

  Future<void> _copySuggestion(String suggestion) async {
    await Clipboard.setData(ClipboardData(text: suggestion));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(_ExplainText.copied)));
  }

  void _continueToReply() {
    final original = _messageController.text.trim();
    if (original.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a message to explain first.')),
      );
      return;
    }
    ref.read(pendingReplyInputProvider.notifier).set(original);
    context.go(AppRoutes.reply);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(explainControllerProvider);

    return AppPage(
      title: _ExplainText.navTitle,
      subtitle: 'Understand the meaning and tone.',
      headerImagePath: 'assets/icons/explain.png',
      accentColor: _kColor,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          GlassCard(
            feature: _feature,
            child: LabeledTextField(
              key: const Key('explain-message-field'),
              label: _ExplainText.inputLabel,
              feature: _feature,
              showCounter: false,
              controller: _messageController,
              hintText: _ExplainText.inputHint,
              helperText: _ExplainText.inputHelper,
              maxLines: 7,
              maxLength: InputLimits.explainMessageMaxLength,
              fieldActions: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _ExplainText.paste,
                    visualDensity: VisualDensity.compact,
                    color: _kColor,
                    onPressed: state.isLoading ? null : _pasteMessage,
                    icon: const Icon(Icons.content_paste_rounded, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Clear',
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
                  ? _ExplainText.explaining
                  : _ExplainText.explainButton,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            InlineError(
              message: _friendlyError(state),
              actionLabel: 'Try again',
              onAction: state.isLoading ? null : _explain,
            ),
          ],
          if (state.isLoading) ...[
            const SizedBox(height: 14),
            Text(
              'Reading between the lines…',
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
            ),
          ],
          if (_result == null && !state.isLoading && state.error == null) ...[
            const SizedBox(height: 14),
            Text(
              'Your explanation will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultSection(
              icon: Icons.article_outlined,
              title: _ExplainText.meaning,
              text: _result!.meaning,
              color: _kColor,
            ),
            const SizedBox(height: 12),
            _ResultSection(
              icon: Icons.record_voice_over_outlined,
              title: _ExplainText.tone,
              text: _result!.tone,
              color: _kColor,
            ),
            const SizedBox(height: 12),
            _ResultSection(
              icon: Icons.visibility_outlined,
              title: _ExplainText.hiddenMeaning,
              text: _result!.hiddenMeaning.trim().isEmpty
                  ? 'No hidden meaning detected.'
                  : _result!.hiddenMeaning,
              color: _kColor,
            ),
            const SizedBox(height: 18),
            Text(
              _ExplainText.suggestedReplies,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 10),
            if (_result!.suggestedReplies.isEmpty)
              Text(
                'No suggested replies returned.',
                style: AppTextStyles.helper,
              )
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
      return _ExplainText.rateLimited;
    }
    if (state.errorCode == 'MODEL_PARSE_ERROR') {
      return 'We could not read the explanation clearly. Please try again.';
    }
    if (state.errorCode == 'MODEL_UNAVAILABLE') {
      return 'Explain is temporarily unavailable. Please try again shortly.';
    }
    return state.error ?? 'Unable to explain this message.';
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
            tooltip: _ExplainText.copy,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_ExplainText.replyCtaTitle, style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            key: const Key('explain-continue-reply-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _feature.primaryButtonColor,
            ),
            onPressed: onPressed,
            icon: const Icon(Icons.reply_rounded),
            label: const Text(_ExplainText.replyCtaButton),
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

abstract final class _ExplainText {
  static const navTitle = 'Explain';
  static const inputLabel = 'Message to understand';
  static const inputHelper = 'Paste the English message you received';
  static const inputHint =
      "Sounds good in principle, but let's circle back after Q3 — bandwidth is tight right now.";
  static const paste = 'Paste';
  static const explainButton = 'Explain this message';
  static const explaining = 'Explaining…';
  static const meaning = 'Meaning';
  static const tone = 'Tone';
  static const hiddenMeaning = 'Hidden Meaning';
  static const suggestedReplies = 'Suggested Replies';
  static const copy = 'Copy';
  static const copied = 'Copied';
  static const rateLimited =
      "You’ve reached the explain limit for now. Please try again later.";
  static const replyCtaTitle =
      'Want a reply that better matches your intention?';
  static const replyCtaButton = 'Generate Reply';
}
