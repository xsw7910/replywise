import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/guidance_library.dart';
import '../../core/widgets/labeled_text_field.dart';
import '../../core/widgets/placeholder_result_card.dart';

class ReplyScreen extends StatefulWidget {
  const ReplyScreen({super.key});

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
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

  static const _previews = [
    (
      label: 'Professional',
      text:
          'Thanks for the update. Next week works for me—could we confirm the new time by Wednesday?',
    ),
    (
      label: 'Friendly',
      text:
          'No problem, next week works for me! Could we lock in the time by Wednesday?',
    ),
    (
      label: 'Short',
      text: 'Next week works. Could we confirm the time by Wednesday?',
    ),
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

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showExplainPreview() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explain message', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Static preview', style: AppTextStyles.labelMedium),
              const SizedBox(height: 18),
              const _ExplanationRow(
                label: 'Meaning',
                text: 'They are asking whether the meeting can move.',
              ),
              const _ExplanationRow(
                label: 'Tone',
                text: 'Neutral, considerate, and open to coordination.',
              ),
              const _ExplanationRow(
                label: 'Hidden meaning',
                text: 'They may need flexibility but still want a firm plan.',
              ),
              Text('Suggested guidance', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              ActionChip(
                label: const Text('Agree and ask to confirm by Wednesday'),
                onPressed: () {
                  Navigator.pop(context);
                  _appendGuidance('Agree and ask to confirm by Wednesday');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showExplainPreview,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                    label: const Text('Explain this message'),
                  ),
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
            onPressed: () => _showPlaceholder(
              'Static preview only — reply generation is not connected yet.',
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Generate Reply'),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reply previews',
                  style: AppTextStyles.headlineMedium,
                ),
              ),
              const _PreviewBadge(),
            ],
          ),
          const SizedBox(height: 12),
          for (final preview in _previews) ...[
            PlaceholderResultCard(label: preview.label, text: preview.text),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _showPlaceholder(
              'Static preview only — regenerate is not connected yet.',
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Regenerate preview'),
          ),
          const SizedBox(height: 6),
          Text(
            'Regenerate will use 1 AI use for non-premium users.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium,
          ),
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

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Fake data',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}
