import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_page.dart';
import '../application/recent_providers.dart';
import '../data/recent_repository.dart';
import '../domain/recent_item.dart';
import 'recent_item_row.dart';

/// Full local history: all recent items, newest first, with per-item delete and
/// a clear-all action. Reached from the Home "View all" link.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(recentItemsProvider);
    ref.invalidate(latestRecentItemsProvider);
  }

  Future<void> _delete(WidgetRef ref, String id) async {
    await ref.read(recentRepositoryProvider).delete(id);
    await _refresh(ref);
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.clearHistory),
        content: Text(context.l10n.clearHistoryDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.clearAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(recentRepositoryProvider).clear();
    await _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(recentItemsProvider);
    final hasItems =
        (itemsAsync.asData?.value ?? const <RecentItem>[]).isNotEmpty;

    return AppPage(
      title: context.l10n.history,
      showBackButton: true,
      actions: [
        if (hasItems)
          IconButton(
            tooltip: context.l10n.clearAll,
            onPressed: () => _clearAll(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
      ],
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _EmptyHistory(),
        data: (items) => items.isEmpty
            ? const _EmptyHistory()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.cardBorder),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return RecentItemRow(
                    item: item,
                    onTap: () => openRecentItem(context, item),
                    trailing: IconButton(
                      tooltip: context.l10n.delete,
                      color: AppColors.textMuted,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => _delete(ref, item.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
            const SizedBox(height: 6),
            Text(
              context.l10n.recentEmptyMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
            ),
          ],
        ),
      ),
    );
  }
}
