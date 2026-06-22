import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/polish_models.dart';

part 'polish_repository.g.dart';

class PolishRepository {
  const PolishRepository(this._client);

  final ApiClient _client;

  Future<PolishResult> polish(PolishRequest request) async {
    final key = const Uuid().v4();
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client.post<Map<String, dynamic>>(
          '/v1/polish',
          data: request.toJson(),
          options: Options(headers: {'X-Idempotency-Key': key}),
        );
        return PolishResult.fromJson(response.data!);
      } on DioException catch (error) {
        final apiError = ApiError.fromDio(
          error,
          fallback: 'Unable to polish this draft.',
        );
        final processing =
            apiError.code == 'IDEMPOTENCY_CONFLICT' &&
            apiError.message.toLowerCase().contains('processing');
        if (!processing || attempt == 2) throw apiError;
        await Future<void>.delayed(Duration(seconds: attempt + 1));
      }
    }
    throw const ApiError(message: 'Unable to polish this draft.');
  }
}

@riverpod
PolishRepository polishRepository(PolishRepositoryRef ref) =>
    PolishRepository(ref.watch(apiClientProvider));
