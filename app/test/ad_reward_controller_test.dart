import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/features/ads/application/ad_reward_controller.dart';
import 'package:replywise/features/ads/data/ad_reward_repository.dart';
import 'package:replywise/features/ads/data/rewarded_ad_gateway.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeGateway implements RewardedAdGateway {
  _FakeGateway({
    this.loadSucceeds = true,
    this.earns = true,
    this.showThrows = false,
  });

  bool loadSucceeds;
  bool earns;
  bool showThrows;
  bool _ready = false;
  int loadCalls = 0;
  int showCalls = 0;

  /// When set, [show] awaits this before completing — lets a test hold the ad
  /// on screen to exercise double-tap guarding.
  Completer<void>? showGate;
  Completer<void>? loadGate;

  @override
  bool get isReady => _ready;

  @override
  Future<bool> load(String adUnitId) async {
    loadCalls++;
    if (loadGate != null) await loadGate!.future;
    if (!loadSucceeds) {
      _ready = false;
      throw const RewardedAdException('load failed');
    }
    _ready = true;
    return true;
  }

  @override
  Future<bool> show() async {
    showCalls++;
    _ready = false;
    if (showGate != null) await showGate!.future;
    if (showThrows) throw const RewardedAdException('show failed');
    return earns;
  }

  @override
  void dispose() {}
}

class _FakeAdRewardRepo implements AdRewardRepository {
  _FakeAdRewardRepo({this.error});

  final ApiError? error;
  int claimCalls = 0;

  @override
  Future<AdRewardResult> claim({required String idempotencyKey}) async {
    claimCalls++;
    if (error != null) throw error!;
    return const AdRewardResult(credits: 1, awarded: 1, dailyRemaining: 4);
  }
}

class _FakeUsageRepo implements UsageRepository {
  int fetchCount = 0;

  @override
  Future<EntitlementState> fetch() async {
    fetchCount++;
    return const EntitlementState.initial();
  }
}

// ── Harness ───────────────────────────────────────────────────────────────────

ProviderContainer _container(
  _FakeGateway gateway,
  AdRewardRepository repo,
  _FakeUsageRepo usage,
) {
  final c = ProviderContainer(
    overrides: [
      rewardedAdGatewayProvider.overrideWith((ref) => gateway),
      adRewardRepositoryProvider.overrideWith((ref) => repo),
      usageRepositoryProvider.overrideWith((ref) => usage),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Flushes pending microtasks/zero-delay futures so the fakes settle.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  test('earned reward claims backend and refreshes usage', () async {
    final gateway = _FakeGateway(earns: true);
    final repo = _FakeAdRewardRepo();
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle(); // build() preloads the first ad
    expect(gateway.isReady, isTrue);

    await notifier.watchAd();
    await _settle();

    expect(repo.claimCalls, 1);
    expect(usage.fetchCount, 1);
    expect(
      c.read(adRewardControllerProvider).outcome,
      AdRewardOutcome.creditAdded,
    );
    expect(c.read(adRewardControllerProvider).status, AdRewardStatus.idle);
  });

  test('first tap waits for preload and then shows the ad', () async {
    final gate = Completer<void>();
    final gateway = _FakeGateway(earns: true)..loadGate = gate;
    final repo = _FakeAdRewardRepo();
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle();
    expect(c.read(adRewardControllerProvider).status, AdRewardStatus.loading);

    final watch = notifier.watchAd();
    await _settle();
    expect(gateway.showCalls, 0);

    gate.complete();
    await watch;
    await _settle();

    expect(gateway.showCalls, 1);
    expect(repo.claimCalls, 1);
    expect(usage.fetchCount, 1);
  });

  test('dismissed ad grants nothing', () async {
    final gateway = _FakeGateway(earns: false);
    final repo = _FakeAdRewardRepo();
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle();

    await notifier.watchAd();
    await _settle();

    expect(gateway.showCalls, 1);
    expect(repo.claimCalls, 0);
    expect(usage.fetchCount, 0);
    expect(c.read(adRewardControllerProvider).outcome, isNull);
  });

  test('daily-limit backend error surfaces dailyLimitReached', () async {
    final gateway = _FakeGateway(earns: true);
    final repo = _FakeAdRewardRepo(
      error: const ApiError(
        code: 'AD_REWARD_LIMIT',
        message: 'Daily ad reward limit reached.',
        statusCode: 429,
      ),
    );
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle();

    await notifier.watchAd();
    await _settle();

    expect(repo.claimCalls, 1);
    expect(usage.fetchCount, 0); // balance is not refreshed on failure
    expect(
      c.read(adRewardControllerProvider).outcome,
      AdRewardOutcome.dailyLimitReached,
    );
  });

  test('cooldown backend error surfaces cooldown outcome', () async {
    final gateway = _FakeGateway(earns: true);
    final repo = _FakeAdRewardRepo(
      error: const ApiError(
        code: 'AD_REWARD_COOLDOWN',
        message: 'Please wait.',
        statusCode: 429,
      ),
    );
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle();

    await notifier.watchAd();
    await _settle();

    expect(
      c.read(adRewardControllerProvider).outcome,
      AdRewardOutcome.cooldown,
    );
  });

  test('load failure surfaces loadFailed and never claims', () async {
    final gateway = _FakeGateway(loadSucceeds: false);
    final repo = _FakeAdRewardRepo();
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle(); // preload fails
    expect(gateway.isReady, isFalse);

    await notifier.watchAd();
    await _settle();

    expect(repo.claimCalls, 0);
    expect(
      c.read(adRewardControllerProvider).outcome,
      AdRewardOutcome.loadFailed,
    );
  });

  test('show failure surfaces loadFailed and never claims', () async {
    final gateway = _FakeGateway(earns: true, showThrows: true);
    final repo = _FakeAdRewardRepo();
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle();

    await notifier.watchAd();
    await _settle();

    expect(repo.claimCalls, 0);
    expect(
      c.read(adRewardControllerProvider).outcome,
      AdRewardOutcome.loadFailed,
    );
  });

  test('a second tap while the ad is showing is ignored', () async {
    final gate = Completer<void>();
    final gateway = _FakeGateway(earns: true)..showGate = gate;
    final repo = _FakeAdRewardRepo();
    final usage = _FakeUsageRepo();
    final c = _container(gateway, repo, usage);

    final notifier = c.read(adRewardControllerProvider.notifier);
    await _settle();

    final first = notifier.watchAd(); // enters showing, waits on the gate
    await _settle();
    expect(c.read(adRewardControllerProvider).status, AdRewardStatus.showing);

    await notifier.watchAd(); // ignored — a reward is already in flight
    expect(gateway.showCalls, 1);

    gate.complete();
    await first;
    await _settle();

    expect(repo.claimCalls, 1); // exactly one credit claimed
  });
}
