import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/entitlement/usage_repository.dart';
import 'package:replywise/features/settings/application/dev_tools_controller.dart';
import 'package:replywise/features/settings/data/dev_tools_repository.dart';

class _DummyStorage extends TokenStorage {
  _DummyStorage() : super(const FlutterSecureStorage());
}

ApiClient _dummyClient() => ApiClient(
  rawDio: Dio(),
  tokenStorage: _DummyStorage(),
  recoverUnauthorized: () async => false,
);

class _FakeDevToolsClient implements DevToolsClient {
  final calls = <String>[];

  @override
  Future<void> resetUsage({int? freeUsesUsed, int? paidCredits}) async {
    calls.add('reset');
  }

  @override
  Future<void> addCredits(int amount) async {
    calls.add('add:$amount');
  }

  @override
  Future<void> setPremium(bool isPremium) async {
    calls.add('premium:$isPremium');
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
      freeUsesUsed: 0,
      freeUsesLeft: 5,
      paidCredits: 0,
      upgradeRequired: false,
    );
  }
}

ProviderContainer _container({
  required _FakeDevToolsClient devTools,
  required _FakeUsageRepo usageRepo,
}) {
  final c = ProviderContainer(
    overrides: [
      devToolsRepositoryProvider.overrideWithValue(devTools),
      usageRepositoryProvider.overrideWith((ref) => usageRepo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('dev tools controller calls actions and refreshes account state', () async {
    final devTools = _FakeDevToolsClient();
    final usageRepo = _FakeUsageRepo();
    final c = _container(devTools: devTools, usageRepo: usageRepo);
    final controller = c.read(devToolsControllerProvider.notifier);

    await controller.resetUsage();
    await controller.addCredits(10);
    await controller.addCredits(50);
    await controller.setPremium(true);
    await controller.setPremium(false);
    await controller.refreshAccountState();

    expect(devTools.calls, [
      'reset',
      'add:10',
      'add:50',
      'premium:true',
      'premium:false',
    ]);
    expect(usageRepo.fetchCount, 6);
  });
}
