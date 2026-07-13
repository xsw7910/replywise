import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_feature_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/generated_result_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../application/recent_providers.dart';
import '../domain/recent_item.dart';
import 'recent_item_row.dart';

/// Read-only detail view of a single saved recent item. Reached by tapping a
/// row in the Home Recent card or the History list. Shows the type, original
/// input, generated result, any saved guidance/tone/channel/length, the created
/// timestamp, a copy action for the result, and a "Use again" action that
/// re-opens the feature screen with the input pre-filled.
class RecentDetailScreen extends ConsumerWidget {
  const RecentDetailScreen({super.key, required this.id, this.initialItem});

  final String id;

  /// The item handed over during navigation. When null (e.g. a deep link) the
  /// item is loaded from [recentItemByIdProvider].
  final RecentItem? initialItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget body;
    final item = initialItem;
    if (item != null) {
      body = _DetailBody(item: item);
    } else {
      body = ref
          .watch(recentItemByIdProvider(id))
          .when(
            data: (loaded) => loaded == null
                ? const _MissingBody()
                : _DetailBody(item: loaded),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const _MissingBody(),
          );
    }

    return AppPage(
      title: context.l10n.recentDetail,
      showBackButton: true,
      child: body,
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.item});

  final RecentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = item.type.accentColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withAlpha(28),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.type.icon, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _typeLabel(context, item.type),
                    style: AppTextStyles.cardTitle.copyWith(color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizedRecentTimestamp(context, item.createdAt),
                    style: AppTextStyles.helper,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          label: _inputLabel(context, item.type),
          child: SelectableText(
            item.inputText.isEmpty ? '—' : item.inputText,
            style: AppTextStyles.body,
          ),
        ),
        const SizedBox(height: 16),
        if (item.type == RecentType.reply)
          ...item.replyVersions.indexed.expand(
            (entry) => [
              if (entry.$1 > 0) const SizedBox(height: 12),
              GeneratedResultCard(
                key: Key('recent-reply-${entry.$2.label.toLowerCase()}'),
                label: _replyVersionLabel(context, entry.$2.label),
                text: entry.$2.text,
                feature: AppFeature.reply,
                shareTooltip: context.l10n.shareReply,
                showFeatureImage: false,
              ),
            ],
          )
        else
          _Section(
            label: _resultLabel(context, item.type),
            trailing: TextButton.icon(
              onPressed: () => _copyResult(context),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(context.l10n.copyResult),
            ),
            child: SelectableText(
              item.outputText.isEmpty ? '—' : item.outputText,
              style: AppTextStyles.body,
            ),
          ),
        if (_metadata(context).isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            label: context.l10n.customizeStyleToneFormat,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, entry) in _metadata(context).indexed) ...[
                  if (index > 0) const SizedBox(height: 12),
                  _MetaRow(label: entry.$1, value: entry.$2),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),
        FilledButton.icon(
          key: const Key('recent-detail-use-again'),
          onPressed: () => useRecentItemAgain(context, ref, item),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.useAgain),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyResult(BuildContext context) async {
    // Capture context-derived values before the async gap.
    final messenger = ScaffoldMessenger.of(context);
    final copiedLabel = context.l10n.copied;
    await Clipboard.setData(ClipboardData(text: item.outputText));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copiedLabel)));
  }

  /// Saved context fields that are present, paired with their localized labels.
  List<(String, String)> _metadata(BuildContext context) {
    final l10n = context.l10n;
    return [
      if (item.guidance != null) (l10n.guidance, item.guidance!),
      if (item.tone != null) (l10n.tone, item.tone!),
      if (item.channel != null) (l10n.channel, item.channel!),
      if (item.length != null) (l10n.length, item.length!),
    ];
  }
}

String _replyVersionLabel(BuildContext context, String label) =>
    switch (label) {
      'Professional' => context.l10n.professional,
      'Friendly' => context.l10n.friendly,
      'Short' => context.l10n.short,
      _ => label,
    };

String _typeLabel(BuildContext context, RecentType type) => switch (type) {
  RecentType.reply => context.l10n.reply,
  RecentType.polish => context.l10n.polish,
  RecentType.explain => context.l10n.explain,
};

String _inputLabel(BuildContext context, RecentType type) => switch (type) {
  RecentType.reply => context.l10n.messageReceived,
  RecentType.polish => context.l10n.textToPolish,
  RecentType.explain => context.l10n.messageToUnderstand,
};

String _resultLabel(BuildContext context, RecentType type) => switch (type) {
  RecentType.reply => context.l10n.yourReplies,
  RecentType.polish => context.l10n.polishedResult,
  RecentType.explain => context.l10n.meaning,
};

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child, this.trailing});

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: SizedBox(width: double.infinity, child: child),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.helper.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
}

class _MissingBody extends StatelessWidget {
  const _MissingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.nothingHereYet, style: AppTextStyles.cardTitle),
          ],
        ),
      ),
    );
  }
}
