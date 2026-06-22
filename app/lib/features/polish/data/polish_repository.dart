import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/polish_models.dart';

part 'polish_repository.g.dart';

class PolishRepository {
  const PolishRepository(this._client);

  final ApiClient _client;

  Future<PolishResult> polish(PolishRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/v1/polish',
        data: request.toJson(),
      );
      return PolishResult.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(error, fallback: 'Unable to polish this draft.');
    }
  }
}

@riverpod
PolishRepository polishRepository(PolishRepositoryRef ref) =>
    PolishRepository(ref.watch(apiClientProvider));
