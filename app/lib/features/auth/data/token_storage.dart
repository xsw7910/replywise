import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

class TokenStorage {
  const TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyAppUserId = 'rw_app_user_id';
  static const _keyDeviceId = 'rw_device_id';
  static const _keyAccessToken = 'rw_access_token';
  static const _keyRefreshToken = 'rw_refresh_token';

  Future<String?> getAppUserId() => _storage.read(key: _keyAppUserId);
  Future<String?> getDeviceId() => _storage.read(key: _keyDeviceId);
  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<void> saveAppUserId(String id) =>
      _storage.write(key: _keyAppUserId, value: id);

  Future<void> saveDeviceId(String id) =>
      _storage.write(key: _keyDeviceId, value: id);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      Future.wait([
        _storage.write(key: _keyAccessToken, value: accessToken),
        _storage.write(key: _keyRefreshToken, value: refreshToken),
      ]);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  Future<void> clearTokens() => Future.wait([
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
      ]);
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(TokenStorageRef ref) => TokenStorage(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    );
