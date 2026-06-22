import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_error.dart';
import 'package:replywise/features/auth/application/auth_controller.dart';
import 'package:replywise/features/auth/auth_state.dart';
import 'package:replywise/features/auth/data/auth_repository.dart';
import 'package:replywise/features/auth/data/token_storage.dart';

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({
    this.appUserId,
    this.deviceId,
    this.accessToken,
    this.refreshToken,
  }) : super(const FlutterSecureStorage());

  String? appUserId;
  String? deviceId;
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAppUserId() async => appUserId;
  @override
  Future<String?> getDeviceId() async => deviceId;
  @override
  Future<String?> getAccessToken() async => accessToken;
  @override
  Future<String?> getRefreshToken() async => refreshToken;
  @override
  Future<void> saveAppUserId(String id) async => appUserId = id;
  @override
  Future<void> saveDeviceId(String id) async => deviceId = id;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;
  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(Dio());

  int anonymousCalls = 0;
  int refreshCalls = 0;
  int meCalls = 0;

  Future<AnonymousAuthResult> Function(
    String appUserId,
    String deviceId,
    String platform,
  )?
  anonymousHandler;
  Future<String> Function(String refreshToken)? refreshHandler;
  Future<MeData> Function(String accessToken)? meHandler;

  @override
  Future<AnonymousAuthResult> anonymous({
    required String appUserId,
    required String deviceId,
    required String platform,
  }) async {
    anonymousCalls++;
    return anonymousHandler?.call(appUserId, deviceId, platform) ??
        AnonymousAuthResult(
          accessToken: 'anonymous-access',
          refreshToken: 'anonymous-refresh',
          me: MeData(userId: 1, appUserId: appUserId),
        );
  }

  @override
  Future<String> refresh({required String refreshToken}) async {
    refreshCalls++;
    return refreshHandler?.call(refreshToken) ?? 'refreshed-access';
  }

  @override
  Future<MeData> me({required String accessToken}) async {
    meCalls++;
    return meHandler?.call(accessToken) ??
        const MeData(userId: 1, appUserId: 'stable-app-user');
  }
}

ProviderContainer _container(
  _MemoryTokenStorage storage,
  _FakeAuthRepository repository,
) => ProviderContainer(
  overrides: [
    tokenStorageProvider.overrideWith((ref) => storage),
    authRepositoryProvider.overrideWith((ref) => repository),
    authRetryBaseDelayProvider.overrideWithValue(Duration.zero),
  ],
);

void main() {
  test('first launch creates stable identifiers and persists tokens', () async {
    final storage = _MemoryTokenStorage();
    final repository = _FakeAuthRepository();
    final container = _container(storage, repository);
    addTearDown(container.dispose);

    final statuses = <AuthStatus>[];
    container.listen(
      authControllerProvider,
      (_, next) => statuses.add(next.status),
      fireImmediately: true,
    );
    await container.read(authControllerProvider.notifier).initialize();

    expect(storage.appUserId, isNotNull);
    expect(storage.deviceId, isNotNull);
    expect(storage.accessToken, 'anonymous-access');
    expect(storage.refreshToken, 'anonymous-refresh');
    expect(repository.anonymousCalls, 1);
    expect(statuses, contains(AuthStatus.authenticating));
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
  });

  test(
    'expired access token refreshes and validates the new session',
    () async {
      final storage = _MemoryTokenStorage(
        appUserId: 'stable-app-user',
        deviceId: 'stable-device',
        accessToken: 'expired-access',
        refreshToken: 'valid-refresh',
      );
      final repository = _FakeAuthRepository()
        ..meHandler = (token) async {
          if (token == 'expired-access') {
            throw const ApiError(message: 'expired', statusCode: 401);
          }
          return const MeData(userId: 7, appUserId: 'stable-app-user');
        };
      final container = _container(storage, repository);
      addTearDown(container.dispose);

      final statuses = <AuthStatus>[];
      container.listen(
        authControllerProvider,
        (_, next) => statuses.add(next.status),
        fireImmediately: true,
      );
      await container.read(authControllerProvider.notifier).initialize();

      expect(repository.refreshCalls, 1);
      expect(storage.accessToken, 'refreshed-access');
      expect(statuses, contains(AuthStatus.refreshing));
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    },
  );

  test(
    'refresh failure falls back anonymously with stable identifiers',
    () async {
      final storage = _MemoryTokenStorage(
        appUserId: 'stable-app-user',
        deviceId: 'stable-device',
        accessToken: 'expired-access',
        refreshToken: 'invalid-refresh',
      );
      final repository = _FakeAuthRepository();
      repository.meHandler = (_) async =>
          throw const ApiError(message: 'expired', statusCode: 401);
      repository.refreshHandler = (_) async =>
          throw const ApiError(message: 'invalid refresh', statusCode: 401);
      final container = _container(storage, repository);
      addTearDown(container.dispose);

      final statuses = <AuthStatus>[];
      container.listen(
        authControllerProvider,
        (_, next) => statuses.add(next.status),
        fireImmediately: true,
      );
      await container.read(authControllerProvider.notifier).initialize();

      expect(repository.anonymousCalls, 1);
      expect(storage.appUserId, 'stable-app-user');
      expect(storage.deviceId, 'stable-device');
      expect(storage.accessToken, 'anonymous-access');
      expect(statuses, contains(AuthStatus.tokenExpired));
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    },
  );

  test('concurrent unauthorized recovery is single-flight', () async {
    final storage = _MemoryTokenStorage(
      appUserId: 'stable-app-user',
      deviceId: 'stable-device',
      accessToken: 'valid-access',
      refreshToken: 'valid-refresh',
    );
    final repository = _FakeAuthRepository();
    final container = _container(storage, repository);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).initialize();

    final gate = Future<String>.delayed(
      const Duration(milliseconds: 20),
      () => 'single-flight-access',
    );
    repository.refreshHandler = (_) => gate;

    final notifier = container.read(authControllerProvider.notifier);
    final results = await Future.wait([
      notifier.recoverFromUnauthorized(),
      notifier.recoverFromUnauthorized(),
      notifier.recoverFromUnauthorized(),
    ]);

    expect(results, everyElement(isTrue));
    expect(repository.refreshCalls, 1);
    expect(storage.accessToken, 'single-flight-access');
  });

  test('offline startup emits failure and retry can recover', () async {
    final storage = _MemoryTokenStorage();
    final repository = _FakeAuthRepository()
      ..anonymousHandler = (_, _, _) async =>
          throw const ApiError(message: 'offline');
    final container = _container(storage, repository);
    addTearDown(container.dispose);

    final notifier = container.read(authControllerProvider.notifier);
    await notifier.initialize();

    expect(repository.anonymousCalls, 3);
    expect(container.read(authControllerProvider).status, AuthStatus.failure);
    expect(container.read(authControllerProvider).errorMessage, isNotEmpty);

    repository.anonymousHandler = null;
    await notifier.retry();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
  });
}
