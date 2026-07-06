import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/v1/explain',
        data: {
          'text': text,
          'explainLang': explainLang,
          'appLocale': ?appLocale,
        },
      );
      return ExplainResult.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(
        error,
        fallback: 'Unable to explain this message.',
      );
    }
  }
}

@riverpod
ExplainRepository explainRepository(ExplainRepositoryRef ref) =>
    ExplainRepository(ref.watch(apiClientProvider));
