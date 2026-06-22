import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/reply_models.dart';

part 'reply_repository.g.dart';

class ReplyRepository {
  const ReplyRepository(this._client);

  final ApiClient _client;

  Future<ReplyResult> generate(ReplyRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/v1/reply',
        data: request.toJson(),
      );
      return ReplyResult.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(error, fallback: 'Unable to generate a reply.');
    }
  }
}

@riverpod
ReplyRepository replyRepository(ReplyRepositoryRef ref) =>
    ReplyRepository(ref.watch(apiClientProvider));
