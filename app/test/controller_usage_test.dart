import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';
import 'package:replywise/features/reply/application/reply_controller.dart';
import 'package:replywise/features/reply/data/reply_repository.dart';
import 'package:replywise/features/reply/domain/reply_models.dart';

// ── Infrastructure fakes ────────────────────────────────────────────────────

class _DummyStorage extends TokenStorage {
  _DummyStorage() : super(const FlutterSecureStorage());
}

ApiClient _dummyClient() => ApiClient(
      rawDio: Dio(),
      tokenStorage: _DummyStorage(),
      recoverUnauthorized: () async => false,
    );

// ── Fake repositories ────────────────────────────────────────────────────────

class _FakeReplyRepo extends ReplyRepository {
  _FakeReplyRepo({this.error}) : super(_dummyClient());

  final ApiError? error;

  @override
  Future<ReplyResult> generate(ReplyRequest request) async {
    if (error != null) throw error!;
    return const ReplyResult(
      versions: [ReplyVersion(label: 'Formal', text: 'Hi.')],
      why: 'Clear and concise.',
    );
  }
}

/// Replays [responses] in order: a [ReplyResult] succeeds, an [ApiError] throws.
class _QueuedReplyRepo extends ReplyRepository {
  _QueuedReplyRepo(this.responses) : super(_dummyClient());

  final List<Object> responses;
  var _index = 0;

  @override
  Future<ReplyResult> generate(ReplyRequest request) async {
    final next = responses[_index++];
    if (next is ApiError) throw next;
    return next as ReplyResult;
  }
}

class _FakeUsageRepo extends UsageRepository {
  _FakeUsageRepo() : super(_dummyClient());

  var fetchCount = 0;

  @override
  Future<EntitlementState> fetch() async {
    fetchCount++;
    return const EntitlementState.initial();
  }
}

// ── Helper ───────────────────────────────────────────────────────────────────

const _request = ReplyRequest(
  incoming: 'Can we reschedule?',
  guidance: 'Agree politely',
  guidanceLang: 'en',
  audience: ReplyAudience(mode: 'auto', formality: 50),
);

ProviderContainer _container({
  ReplyRepository? replyRepo,
  _FakeUsageRepo? usageRepo,
}) {
  final c = ProviderContainer(overrides: [
    if (replyRepo != null)
      replyRepositoryProvider.overrideWith((ref) => replyRepo),
    if (usageRepo != null)
      usageRepositoryProvider.overrideWith((ref) => usageRepo),
  ]);
  addTearDown(c.dispose);
  return c;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ReplyController error codes', () {
    test('surfaces PAYWALL_REQUIRED code', () async {
      final c = _container(
        replyRepo: _FakeReplyRepo(
          error: const ApiError(
            code: 'PAYWALL_REQUIRED',
            message: 'No uses remaining.',
            statusCode: 402,
          ),
        ),
      );

      await c.read(replyControllerProvider.notifier).generate(_request);

      final state = c.read(replyControllerProvider);
      expect(state.errorCode, 'PAYWALL_REQUIRED');
      expect(
        state.error,
        'You have no generations left. Choose Premium or add credits to continue.',
      );
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
    });

    test('surfaces RATE_LIMITED code', () async {
      final c = _container(
        replyRepo: _FakeReplyRepo(
          error: const ApiError(
            code: 'RATE_LIMITED',
            message: 'Too many requests.',
            statusCode: 429,
          ),
        ),
      );

      await c.read(replyControllerProvider.notifier).generate(_request);

      final state = c.read(replyControllerProvider);
      expect(state.errorCode, 'RATE_LIMITED');
      expect(state.isLoading, isFalse);
    });

    test('does not expose raw backend error messages', () async {
      final c = _container(
        replyRepo: _FakeReplyRepo(
          error: const ApiError(
            code: 'MODEL_UNAVAILABLE',
            message: 'provider_timeout: upstream stack trace',
            statusCode: 503,
          ),
        ),
      );

      await c.read(replyControllerProvider.notifier).generate(_request);

      final state = c.read(replyControllerProvider);
      expect(
        state.error,
        'The writing service is temporarily unavailable. Please try again.',
      );
      expect(state.error, isNot(contains('stack trace')));
    });

    test('preserves previous result when error occurs', () async {
      const successResult = ReplyResult(
        versions: [ReplyVersion(label: 'Formal', text: 'Hi.')],
        why: 'Clear.',
      );
      const rateError = ApiError(
        code: 'RATE_LIMITED',
        message: 'Slow down.',
        statusCode: 429,
      );

      final c = _container(
        replyRepo: _QueuedReplyRepo([successResult, rateError]),
        usageRepo: _FakeUsageRepo(),
      );

      await c.read(replyControllerProvider.notifier).generate(_request);
      expect(c.read(replyControllerProvider).result, isNotNull);

      await c.read(replyControllerProvider.notifier).generate(_request);
      final afterError = c.read(replyControllerProvider);
      expect(afterError.result, isNotNull);
      expect(afterError.errorCode, 'RATE_LIMITED');
    });
  });

  group('UsageController refresh', () {
    test('is called after successful generation', () async {
      final usageRepo = _FakeUsageRepo();
      final c = _container(
        replyRepo: _FakeReplyRepo(),
        usageRepo: usageRepo,
      );

      await c.read(replyControllerProvider.notifier).generate(_request);

      expect(usageRepo.fetchCount, greaterThan(0));
    });

    test('is NOT called after error', () async {
      final usageRepo = _FakeUsageRepo();
      final c = _container(
        replyRepo: _FakeReplyRepo(
          error: const ApiError(code: 'PAYWALL_REQUIRED', message: 'No uses.', statusCode: 402),
        ),
        usageRepo: usageRepo,
      );

      await c.read(replyControllerProvider.notifier).generate(_request);

      expect(usageRepo.fetchCount, 0);
    });
  });
}
