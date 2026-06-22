import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

part 'health_repository.g.dart';

class HealthResponse {
  const HealthResponse({required this.status, required this.service});

  final String status;
  final String service;

  factory HealthResponse.fromJson(Map<String, dynamic> json) => HealthResponse(
    status: json['status'] as String,
    service: json['service'] as String,
  );
}

class HealthRepository {
  const HealthRepository(this._client);

  final ApiClient _client;

  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/health');
      return HealthResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(
        error,
        fallback: 'Unable to reach the ReplyWise service.',
      );
    } catch (_) {
      throw const ApiError(message: 'Unable to check service status.');
    }
  }
}

@riverpod
HealthRepository healthRepository(HealthRepositoryRef ref) =>
    HealthRepository(ref.watch(apiClientProvider));
