import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/reply_models.dart';

part 'explain_repository.g.dart';

class ExplainRepository {
  const ExplainRepository(this._client);

  final ApiClient _client;

  Future<ExplainResult> explain({
    required String text,
    required String explainLang,
    String? appLocale,
  }) async {
    // Explain is billed like Reply/Polish: one idempotency key per attempt so
    // retries of the same request can never charge twice.
    final key = const Uuid().v4();
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client.post<Map<String, dynamic>>(
          '/v1/explain',
          data: {
            'text': text,
            'explainLang': explainLang,
            'appLocale': ?appLocale,
          },
          options: Options(headers: {'X-Idempotency-Key': key}),
        );
        return ExplainResult.fromJson(response.data!);
      } on DioException catch (error) {
        final apiError = ApiError.fromDio(
          error,
          fallback: 'Unable to explain this message.',
        );
        final processing =
            apiError.code == 'IDEMPOTENCY_CONFLICT' &&
            apiError.message.toLowerCase().contains('processing');
        if (!processing || attempt == 2) throw apiError;
        await Future<void>.delayed(Duration(seconds: attempt + 1));
      }
    }
    throw const ApiError(message: 'Unable to explain this message.');
  }
}

@riverpod
ExplainRepository explainRepository(ExplainRepositoryRef ref) =>
    ExplainRepository(ref.watch(apiClientProvider));
