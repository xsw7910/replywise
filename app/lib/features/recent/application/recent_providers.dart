import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recent_repository.dart';
import '../domain/recent_item.dart';

/// All stored recent items, newest first (used by the History page).
final recentItemsProvider = FutureProvider<List<RecentItem>>((ref) async {
  return ref.watch(recentRepositoryProvider).getAll();
});

/// The latest two recent items (shown on the Home page).
final latestRecentItemsProvider = FutureProvider<List<RecentItem>>((ref) async {
  return ref.watch(recentRepositoryProvider).getLatest(limit: 2);
});

/// Saves [item] and refreshes the recent providers so any watching UI updates.
/// Never throws — saving recent activity must not affect the result flow.
Future<void> saveRecentItem(WidgetRef ref, RecentItem item) async {
  try {
    await ref.read(recentRepositoryProvider).add(item);
    // The invalidations are inside the try on purpose: if the screen is
    // disposed while add() is awaiting, ref.invalidate throws "ref used after
    // dispose". The item is already persisted by then, so failing silently
    // just skips the live refresh (Home picks it up on its next read).
    ref.invalidate(recentItemsProvider);
    ref.invalidate(latestRecentItemsProvider);
  } catch (_) {
    // Best-effort: saving recent activity must never surface to the user.
  }
}
