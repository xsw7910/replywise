import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_error.dart';
import '../auth_state.dart';
import '../data/auth_repository.dart';
import '../data/token_storage.dart';

part 'auth_controller.g.dart';

final authRetryBaseDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  Future<void>? _initializationFuture;
  Future<bool>? _recoveryFuture;

  @override
  AuthState build() {
    Future<void>.microtask(initialize);
    return const AuthState();
  }

  Future<void> initialize() {
    final existing = _initializationFuture;
    if (existing != null) return existing;

    final future = _runInitialize();
    _initializationFuture = future;
    return future.whenComplete(() {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    });
  }

  Future<void> retry() => initialize();

  /// Single-flight recovery used by every intercepted 401.
  Future<bool> recoverFromUnauthorized() {
    final existing = _recoveryFuture;
    if (existing != null) return existing;

    final future = _recoverSession();
    _recoveryFuture = future;
    return future.whenComplete(() {
      if (identical(_recoveryFuture, future)) {
        _recoveryFuture = null;
      }
    });
  }

  Future<void> _runInitialize() async {
    state = const AuthState(status: AuthStatus.authenticating);

    try {
      final storage = ref.read(tokenStorageProvider);
      final repo = ref.read(authRepositoryProvider);
      final appUserId = await _ensureAppUserId(storage);
      final accessToken = await storage.getAccessToken();

      if (accessToken == null) {
        await _anonymousAuth(storage, repo, appUserId);
        return;
      }

      try {
        final me = await repo.me(accessToken: accessToken);
        state = _authenticated(me);
      } on ApiError catch (error) {
        if (error.statusCode == 401) {
          await recoverFromUnauthorized();
        } else {
          await _anonymousAuth(storage, repo, appUserId);
        }
      }
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.failure,
        errorMessage: 'Unable to initialize authentication. Please retry.',
      );
    }
  }

  Future<bool> _recoverSession() async {
    final storage = ref.read(tokenStorageProvider);
    final repo = ref.read(authRepositoryProvider);
    final appUserId = await _ensureAppUserId(storage);

    state = state.copyWith(
      status: AuthStatus.refreshing,
      appUserId: appUserId,
      clearError: true,
    );

    final refreshToken = await storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        final newToken = await repo.refresh(refreshToken: refreshToken);
        await storage.saveAccessToken(newToken);
        final me = await repo.me(accessToken: newToken);
        state = _authenticated(me);
        return true;
      } catch (_) {
        // Continue to anonymous recovery with the stable local identifiers.
      }
    }

    state = state.copyWith(
      status: AuthStatus.tokenExpired,
      appUserId: appUserId,
      clearError: true,
    );
    await Future<void>.delayed(Duration.zero);
    return _anonymousAuth(storage, repo, appUserId);
  }

  Future<bool> _anonymousAuth(
    TokenStorage storage,
    AuthRepository repo,
    String appUserId,
  ) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      appUserId: appUserId,
      clearError: true,
    );

    final deviceId = await _ensureDeviceId(storage);
    final baseDelay = ref.read(authRetryBaseDelayProvider);

    const maxAttempts = 3;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final result = await repo.anonymous(
          appUserId: appUserId,
          deviceId: deviceId,
          platform: 'android',
        );
        await storage.saveTokens(
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        );
        state = _authenticated(result.me);
        return true;
      } catch (_) {
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(
            Duration(microseconds: baseDelay.inMicroseconds * (1 << attempt)),
          );
        }
      }
    }

    state = AuthState(
      status: AuthStatus.failure,
      appUserId: appUserId,
      errorMessage: 'Unable to connect. Check your network and retry.',
    );
    return false;
  }

  AuthState _authenticated(MeData me) => AuthState(
    status: AuthStatus.authenticated,
    userId: me.userId,
    appUserId: me.appUserId,
  );

  Future<String> _ensureAppUserId(TokenStorage storage) async {
    var id = await storage.getAppUserId();
    if (id == null) {
      id = const Uuid().v4();
      await storage.saveAppUserId(id);
    }
    return id;
  }

  Future<String> _ensureDeviceId(TokenStorage storage) async {
    var id = await storage.getDeviceId();
    if (id == null) {
      id = const Uuid().v4();
      await storage.saveDeviceId(id);
    }
    return id;
  }
}
