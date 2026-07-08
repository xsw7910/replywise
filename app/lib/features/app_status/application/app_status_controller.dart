import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_feature_theme.dart';
import '../../guidance/data/guidance_library_repository.dart'
    show sharedPreferencesProvider;
import '../data/app_status_service.dart';
import '../domain/app_status.dart';

part 'app_status_controller.g.dart';

/// How long a fetched status is considered fresh before a background refresh is
/// triggered. Requests within this window use the in-memory cache only.
const Duration appStatusCacheTtl = Duration(minutes: 5);

const String _prefsKey = 'app_status_last_known_v1';

/// The running app version used for force/optional update comparisons.
///
/// Defaults to [AppConfig.appVersion]; `main()` overrides it with the real
/// value read from the platform, and tests override it directly.
final currentAppVersionProvider = Provider<String>(
  (ref) => AppConfig.appVersion,
);

/// Wall clock used for cache-freshness math. Overridable so tests can advance
/// time past [appStatusCacheTtl] without waiting.
final appStatusClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Outcome of re-checking status after an AI request failed with a
/// network/server error (see requirement: refresh immediately, then decide).
enum AppStatusPostError { maintenance, serverUnavailable }

class AppStatusState {
  const AppStatusState({
    this.status,
    this.fetchedAt,
    this.isRefreshing = false,
    this.lastFetchFailed = false,
  });

  /// The last successfully fetched (or restored) status, if any.
  final AppStatus? status;

  /// When [status] was last fetched from the network. Null for a restored or
  /// never-fetched status, which is treated as stale.
  final DateTime? fetchedAt;

  /// A refresh is currently in flight.
  final bool isRefreshing;

  /// The most recent fetch attempt failed (server unreachable).
  final bool lastFetchFailed;

  bool get hasStatus => status != null;

  AppStatusState copyWith({
    AppStatus? status,
    DateTime? fetchedAt,
    bool? isRefreshing,
    bool? lastFetchFailed,
  }) => AppStatusState(
    status: status ?? this.status,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    lastFetchFailed: lastFetchFailed ?? this.lastFetchFailed,
  );
}

/// Holds the cached app status and owns all fetch/gate logic.
///
/// Kept alive for the whole session so the in-memory cache survives navigation.
/// Building the controller schedules a non-blocking startup fetch; the initial
/// UI is never delayed waiting for it.
@Riverpod(keepAlive: true)
class AppStatusController extends _$AppStatusController {
  @override
  AppStatusState build() {
    // Restores the last-known status (if any) for an instant, offline-friendly
    // initial value. The startup fetch is kicked off by the app shell
    // ([ReplyWiseApp]) — not here — so merely reading this controller (e.g. from
    // the per-request gate) never triggers a network call on its own.
    return _restore();
  }

  String get _currentVersion => ref.read(currentAppVersionProvider);

  DateTime _now() => ref.read(appStatusClockProvider)();

  bool get isCacheStale {
    final fetchedAt = state.fetchedAt;
    if (fetchedAt == null) return true;
    return _now().difference(fetchedAt) >= appStatusCacheTtl;
  }

  /// Fetches the latest status. On failure the last known status is kept and
  /// [AppStatusState.lastFetchFailed] is set. Concurrent calls are coalesced.
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);
    try {
      final status = await ref.read(appStatusServiceProvider).fetch();
      state = AppStatusState(status: status, fetchedAt: _now());
      _persist(status);
    } catch (_) {
      state = state.copyWith(isRefreshing: false, lastFetchFailed: true);
    }
  }

  /// Refresh only when the cache is stale. Fire-and-forget — used on foreground
  /// resume and other opportunistic triggers.
  void refreshIfStale() {
    if (isCacheStale) unawaited(refresh());
  }

  /// Gates a Reply / Polish / Explain request against the cached status.
  ///
  /// The normal path consults the in-memory cache only (no network call). When
  /// the cache is stale it refreshes in the background WITHOUT delaying the
  /// request — unless the previously cached status was itself blocking
  /// (maintenance / forceUpdate), in which case it awaits a fresh value so a
  /// stale block cannot be silently bypassed.
  Future<AppStatusGate> guardFeature(AppFeature feature) async {
    final cached = state.status;
    // With nothing cached yet, allow immediately without a network call — the
    // startup fetch is already in flight and the post-request error path
    // handles a truly unreachable server. Only an expired *cached* status
    // triggers a background (or, if it was blocking, a foreground) refresh.
    if (cached != null && isCacheStale) {
      final wasBlocking =
          cached.maintenance || cached.requiresForceUpdate(_currentVersion);
      if (wasBlocking) {
        await refresh();
      } else {
        unawaited(refresh());
      }
    }
    return evaluateGate(
      status: state.status,
      feature: feature,
      currentVersion: _currentVersion,
    );
  }

  /// Called after an AI request fails with a network/server error: refresh
  /// immediately, then report whether it is maintenance or a generic
  /// unreachable server so the UI can pick the right message.
  Future<AppStatusPostError> refreshAfterRequestFailure() async {
    await refresh();
    final status = state.status;
    if (status != null && status.maintenance) {
      return AppStatusPostError.maintenance;
    }
    return AppStatusPostError.serverUnavailable;
  }

  AppStatusState _restore() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_prefsKey);
      if (raw == null) return const AppStatusState();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // No fresh timestamp: shown immediately (useful offline) but treated as
      // stale so a refresh runs.
      return AppStatusState(status: AppStatus.fromJson(json));
    } catch (_) {
      return const AppStatusState();
    }
  }

  void _persist(AppStatus status) {
    try {
      ref
          .read(sharedPreferencesProvider)
          .setString(_prefsKey, jsonEncode(status.toJson()));
    } catch (_) {
      // Best-effort; the in-memory cache remains authoritative.
    }
  }
}
