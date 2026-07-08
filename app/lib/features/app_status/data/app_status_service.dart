import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/app_status.dart';

part 'app_status_service.g.dart';

/// Calls the public `GET /v1/app-status` remote-config endpoint.
///
/// This never posts to OpenAI/RevenueCat and is the only network call the
/// app-status feature makes. Callers should treat a thrown [ApiError] as
/// "server unreachable" and keep using the last cached status.
class AppStatusService {
  const AppStatusService(this._client);

  final ApiClient _client;

  Future<AppStatus> fetch({
    String appName = 'replywise',
    String platform = 'android',
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/v1/app-status',
        queryParameters: <String, dynamic>{
          'appName': appName,
          'platform': platform,
        },
      );
      return AppStatus.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(
        error,
        fallback: 'Unable to reach the ReplyWise service.',
      );
    } catch (_) {
      throw const ApiError(message: 'Unable to load app status.');
    }
  }
}

@Riverpod(keepAlive: true)
AppStatusService appStatusService(AppStatusServiceRef ref) =>
    AppStatusService(ref.watch(apiClientProvider));
