import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/generated_result_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/guidance_library.dart';
import '../../core/widgets/inline_error.dart';
import '../../core/widgets/labeled_text_field.dart';
import '../../core/widgets/usage_badge.dart';
import 'application/explain_controller.dart';
import 'application/reply_controller.dart';
import 'domain/reply_models.dart';
import '../entitlement/usage_controller.dart';

class ReplyScreen extends ConsumerStatefulWidget {
  const ReplyScreen({super.key});

  @override
  ConsumerState<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends ConsumerState<ReplyScreen> {
  final _incomingController = TextEditingController();
  final _guidanceController = TextEditingController();
  final _customAudienceController = TextEditingController();

  String _audienceMode = 'Auto';
  String _audiencePreset = 'Colleague';
  double _formality = 55;

  static const _audienceModes = ['Auto', 'Preset', 'Custom'];
  static const _audiencePresets = [
    'Boss',
    'Client',
    'Colleague',
    'Teacher',
    'Friend',
    'Dating',
  ];

  @override
  void dispose() {
    _incomingController.dispose();
    _guidanceController.dispose();
    _customAudienceController.dispose();
    super.dispose();
  }

  void _appendGuidance(String value) {
    final current = _guidanceController.text.trim();
    _guidanceController.text = current.isEmpty ? value : '$current · $value';
    _guidanceController.selection = TextSelection.collapsed(
      offset: _guidanceController.text.length,
    );
  }

  ReplyRequest _request() {
    final mode = _audienceMode.toLowerCase();
    return ReplyRequest(
      incoming: _incomingController.text,
      guidance: _guidanceController.text,
      guidanceLang: 'en',
      audience: ReplyAudience(
        mode: mode,
        preset: mode == 'preset' ? _audiencePreset.toLowerCase() : null,
        custom: mode == 'custom' ? _customAudienceController.text : null,
        formality: _formality.round(),
      ),
    );
  }

  Future<void> _generate() =>
      ref.read(replyControllerProvider.notifier).generate(_request());

  Future<void> _explain() async {
    final result = await ref
        .read(explainControllerProvider.notifier)
        .explain(text: _incomingController.text, explainLang: 'en');
    if (!mounted || result == null) return;
    await _showExplainResult(result);
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
                      style: AppTextStyles.headlineMedium,
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
              Text('Suggested replies', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              for (final suggestion in result.suggestedReplies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    blur: 6,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion,
                            style: AppTextStyles.bodyMedium,
                          ),
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

    return AppPage(
      title: 'Reply',
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
            'Turn your intent into natural English',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: UsageBadge(
              state: usageState,
              onRetry: () =>
                  ref.read(usageControllerProvider.notifier).refresh(),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Paste what you received, then describe how you want to respond.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              children: [
                LabeledTextField(
                  label: 'Message you received',
                  controller: _incomingController,
                  hintText: 'Paste the original message…',
                  helperText: 'English or any language',
                  maxLines: 5,
                  maxLength: 4000,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: explainState.isLoading ? null : _explain,
                    icon: explainState.isLoading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lightbulb_outline_rounded, size: 18),
                    label: Text(
                      explainState.isLoading
                          ? 'Explaining…'
                          : 'Explain this message',
                    ),
                  ),
                ),
                if (explainState.error != null)
                  InlineError(
                    message: explainState.error!,
                    actionLabel: 'Try again',
                    onAction: _explain,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledTextField(
                  key: const Key('reply-guidance-field'),
                  label: 'Your guidance',
                  controller: _guidanceController,
                  hintText: 'For example: agree, but ask them to confirm soon…',
                  helperText: 'Write naturally in any language',
                  maxLines: 4,
                  maxLength: 1000,
                ),
                const SizedBox(height: 14),
                GuidanceLibrary(onSelected: _appendGuidance),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who are you replying to?',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: _audienceModes
                      .map(
                        (mode) => ButtonSegment(value: mode, label: Text(mode)),
                      )
                      .toList(),
                  selected: {_audienceMode},
                  onSelectionChanged: (selection) =>
                      setState(() => _audienceMode = selection.first),
                ),
                if (_audienceMode == 'Preset') ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _audiencePresets
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: _audiencePreset == item,
                            onSelected: (_) =>
                                setState(() => _audiencePreset = item),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (_audienceMode == 'Custom') ...[
                  const SizedBox(height: 12),
                  LabeledTextField(
                    label: 'Describe the relationship',
                    controller: _customAudienceController,
                    hintText: 'For example: my landlord',
                    maxLines: 1,
                    maxLength: 500,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Casual', style: AppTextStyles.labelMedium),
                    Expanded(
                      child: Slider(
                        value: _formality,
                        min: 0,
                        max: 100,
                        onChanged: (value) =>
                            setState(() => _formality = value),
                      ),
                    ),
                    Text('Formal', style: AppTextStyles.labelMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
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
              style: AppTextStyles.labelMedium,
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
              style: AppTextStyles.labelMedium,
            ),
          ],
          if (replyState.result != null) ...[
            const SizedBox(height: 26),
            Text('Your replies', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            for (final version in replyState.result!.versions) ...[
              GeneratedResultCard(label: version.label, text: version.text),
              const SizedBox(height: 12),
            ],
            GlassCard(
              blur: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Why this works', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 6),
                  Text(replyState.result!.why, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
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
                  style: AppTextStyles.labelMedium,
                ),
              ),
          ],
        ],
      ),
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
          Text(label, style: AppTextStyles.titleMedium),
          const SizedBox(height: 3),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
