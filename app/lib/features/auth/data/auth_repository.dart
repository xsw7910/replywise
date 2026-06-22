import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

part 'auth_repository.g.dart';

class MeData {
  const MeData({required this.userId, required this.appUserId});

  final int userId;
  final String appUserId;

  factory MeData.fromJson(Map<String, dynamic> json) => MeData(
    userId: json['userId'] as int,
    appUserId: json['appUserId'] as String,
  );
}

class AnonymousAuthResult {
  const AnonymousAuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.me,
  });

  final String accessToken;
  final String refreshToken;
  final MeData me;

  factory AnonymousAuthResult.fromJson(Map<String, dynamic> json) =>
      AnonymousAuthResult(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        me: MeData.fromJson(json['me'] as Map<String, dynamic>),
      );
}

/// Uses a raw Dio (no auth interceptor) — auth calls must not recurse.
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AnonymousAuthResult> anonymous({
    required String appUserId,
    required String deviceId,
    required String platform,
  }) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/anonymous',
        data: {
          'appUserId': appUserId,
          'deviceId': deviceId,
          'platform': platform,
        },
      );
      return AnonymousAuthResult.fromJson(resp.data!);
    } on DioException catch (e) {
      throw ApiError(
        message: e.message ?? 'Anonymous auth failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<String> refresh({required String refreshToken}) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return resp.data!['accessToken'] as String;
    } on DioException catch (e) {
      throw ApiError(
        message: e.message ?? 'Token refresh failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Calls /v1/me with an explicit token so auth calls stay on the raw Dio.
  Future<MeData> me({required String accessToken}) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/v1/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return MeData.fromJson(resp.data!);
    } on DioException catch (e) {
      throw ApiError(
        message: e.message ?? '/v1/me failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) =>
    AuthRepository(ref.watch(rawDioProvider));
