import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../polish/application/pending_polish_input_provider.dart';
import '../../reply/application/pending_explain_input_provider.dart';
import '../../reply/application/pending_reply_input_provider.dart';
import '../domain/recent_item.dart';

/// A tappable recent-activity row: type icon, title, timestamp, and a type
/// pill. Shared by the Home Recent section and the History page.
class RecentItemRow extends StatelessWidget {
  const RecentItemRow({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
  });

  final RecentItem item;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = item.type.accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.type.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _localizedTimestamp(context, item.createdAt),
                      style: AppTextStyles.helper,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TypePill(
                label: switch (item.type) {
                  RecentType.reply => context.l10n.reply,
                  RecentType.polish => context.l10n.polish,
                  RecentType.explain => context.l10n.explain,
                },
                color: accent,
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

String _localizedTimestamp(BuildContext context, DateTime dt) =>
    localizedRecentTimestamp(context, dt);

/// Localized `Today · 2:30 PM` / `Yesterday · 9:15 AM` / `Jul 4 · 3:20 PM`
/// timestamp, shared by the Recent row and the Recent Detail page.
String localizedRecentTimestamp(BuildContext context, DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dt.year, dt.month, dt.day);
  final days = today.difference(that).inDays;
  final material = MaterialLocalizations.of(context);
  final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(dt));
  if (days == 0) return context.l10n.todayAt(time);
  if (days == 1) return context.l10n.yesterdayAt(time);
  return context.l10n.dateAt(material.formatShortDate(dt), time);
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: color)),
    );
  }
}

/// Opens the Recent Detail page for [item]. The item is handed over via `extra`
/// so the page renders instantly; it also falls back to loading by id (deep
/// links) via [recentItemByIdProvider].
void openRecentItem(BuildContext context, RecentItem item) {
  context.push(AppRoutes.recentDetailPath(item.id), extra: item);
}

/// Re-opens the feature screen that produced [item] with its original input
/// pre-filled, then leaves the detail page. Each feature consumes its pending
/// input exactly once on entry.
void useRecentItemAgain(BuildContext context, WidgetRef ref, RecentItem item) {
  switch (item.type) {
    case RecentType.reply:
      ref.read(pendingReplyInputProvider.notifier).set(item.inputText);
    case RecentType.polish:
      ref.read(pendingPolishInputProvider.notifier).set(item.inputText);
    case RecentType.explain:
      ref.read(pendingExplainInputProvider.notifier).set(item.inputText);
  }
  context.go(item.type.routePath);
}

/// Local, dependency-free timestamp formatting:
/// `Today · 2:30 PM`, `Yesterday · 9:15 AM`, `Jul 4 · 3:20 PM`.
String formatRecentTimestamp(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dt.year, dt.month, dt.day);
  final days = today.difference(that).inDays;
  final time = _formatTime(dt);
  if (days == 0) return 'Today · $time';
  if (days == 1) return 'Yesterday · $time';
  return '${_month(dt.month)} ${dt.day} · $time';
}

String _formatTime(DateTime dt) {
  final isPm = dt.hour >= 12;
  var hour = dt.hour % 12;
  if (hour == 0) hour = 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${isPm ? 'PM' : 'AM'}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _month(int month) => _months[(month - 1) % 12];
