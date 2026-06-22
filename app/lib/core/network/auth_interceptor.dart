import 'package:dio/dio.dart';

import '../../features/auth/data/token_storage.dart';

typedef UnauthorizedRecovery = Future<bool> Function();

/// Adds bearer tokens and delegates 401 recovery to the single auth owner.
///
/// Recovery and token mutation live in AuthController. This interceptor only
/// retries the original request once after recovery succeeds.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.rawDio,
    required this.recoverUnauthorized,
  });

  static const _recoveryAttemptedKey = 'authRecoveryAttempted';

  final TokenStorage tokenStorage;
  final Dio rawDio;
  final UnauthorizedRecovery recoverUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra[_recoveryAttemptedKey] == true) {
      handler.next(err);
      return;
    }

    try {
      final recovered = await recoverUnauthorized();
      if (!recovered) {
        handler.next(err);
        return;
      }

      final token = await tokenStorage.getAccessToken();
      if (token == null) {
        handler.next(err);
        return;
      }

      final request = err.requestOptions;
      request.extra[_recoveryAttemptedKey] = true;
      request.headers['Authorization'] = 'Bearer $token';
      final response = await rawDio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }
}
