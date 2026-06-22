import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/credit_controller.dart';
import 'package:replywise/features/entitlement/credit_repository.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';

// ── Infrastructure fakes ─────────────────────────────────────────────────────

class _DummyStorage extends TokenStorage {
  _DummyStorage() : super(const FlutterSecureStorage());
}

ApiClient _dummyClient() => ApiClient(
      rawDio: Dio(),
      tokenStorage: _DummyStorage(),
      recoverUnauthorized: () async => false,
    );

// ── Fake repositories ─────────────────────────────────────────────────────────

class _FakeCreditRepo extends CreditRepository {
  _FakeCreditRepo({this.error}) : super(_dummyClient());

  final ApiError? error;
  int callCount = 0;

  @override
  Future<CreditSyncResult> sync() async {
    callCount++;
    if (error != null) throw error!;
    return const CreditSyncResult(
      isPremium: false,
      freeUsesLeft: 4,
      paidCredits: 10,
      upgradeRequired: false,
      grantedThisSync: 10,
    );
  }
}

class _FakeUsageRepo extends UsageRepository {
  _FakeUsageRepo() : super(_dummyClient());
  int fetchCount = 0;

  @override
  Future<EntitlementState> fetch() async {
    fetchCount++;
    return const EntitlementState(
      isPremium: false,
      freeUsesLimit: 5,
      freeUsesUsed: 1,
      freeUsesLeft: 4,
      paidCredits: 10,
      upgradeRequired: false,
    );
  }
}

// ── Container helper ──────────────────────────────────────────────────────────

ProviderContainer _container({
  required CreditRepository creditRepo,
  _FakeUsageRepo? usageRepo,
}) {
  final c = ProviderContainer(
    overrides: [
      creditRepositoryProvider.overrideWith((ref) => creditRepo),
      if (usageRepo != null)
        usageRepositoryProvider.overrideWith((ref) => usageRepo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CreditController.syncCredits', () {
    test('calls sync and refreshes usage on success', () async {
      final creditRepo = _FakeCreditRepo();
      final usageRepo = _FakeUsageRepo();
      final c = _container(creditRepo: creditRepo, usageRepo: usageRepo);

      await c.read(creditControllerProvider.notifier).syncCredits();

      expect(creditRepo.callCount, 1);
      expect(usageRepo.fetchCount, 1);
    });

    test('swallows errors silently — does not throw or change state', () async {
      final creditRepo = _FakeCreditRepo(
        error: const ApiError(
          code: 'CREDIT_SYNC_FAILED',
          message: 'Backend down.',
          statusCode: 503,
        ),
      );
      final usageRepo = _FakeUsageRepo();
      final c = _container(creditRepo: creditRepo, usageRepo: usageRepo);

      await expectLater(
        c.read(creditControllerProvider.notifier).syncCredits(),
        completes,
      );

      expect(usageRepo.fetchCount, 0);
      expect(c.read(creditControllerProvider).error, isNull);
    });

    test('does not call usage refresh when sync throws', () async {
      final creditRepo = _FakeCreditRepo(
        error: const ApiError(
          code: 'NETWORK_ERROR',
          message: 'No connection.',
          statusCode: 0,
        ),
      );
      final usageRepo = _FakeUsageRepo();
      final c = _container(creditRepo: creditRepo, usageRepo: usageRepo);

      await c.read(creditControllerProvider.notifier).syncCredits();

      expect(usageRepo.fetchCount, 0);
    });
  });
}
