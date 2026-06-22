import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/token_storage.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

part 'api_client.g.dart';

Dio _buildDio() => Dio(
  BaseOptions(
    baseUrl: AppConfig.backendBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {'Accept': 'application/json'},
  ),
);

@Riverpod(keepAlive: true)
Dio rawDio(RawDioRef ref) => _buildDio();

class ApiClient {
  ApiClient({
    required Dio rawDio,
    required TokenStorage tokenStorage,
    required UnauthorizedRecovery recoverUnauthorized,
  }) : _authedDio = _buildDio() {
    _authedDio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        rawDio: rawDio,
        recoverUnauthorized: recoverUnauthorized,
      ),
    );
  }

  final Dio _authedDio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _authedDio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data, Options? options}) =>
      _authedDio.post<T>(path, data: data, options: options);
}

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient(
  rawDio: ref.watch(rawDioProvider),
  tokenStorage: ref.watch(tokenStorageProvider),
  recoverUnauthorized: () =>
      ref.read(authControllerProvider.notifier).recoverFromUnauthorized(),
);
