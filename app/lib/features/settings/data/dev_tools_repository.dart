import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

abstract interface class DevToolsClient {
  Future<void> resetUsage({int? freeUsesUsed, int? paidCredits});
  Future<void> addCredits(int amount);
  Future<void> setPremium(bool isPremium);
}

class DevToolsRepository implements DevToolsClient {
  const DevToolsRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> resetUsage({int? freeUsesUsed, int? paidCredits}) async {
    final data = <String, dynamic>{};
    if (freeUsesUsed != null) data['freeUsesUsed'] = freeUsesUsed;
    if (paidCredits != null) data['paidCredits'] = paidCredits;
    await _post('/v1/dev/reset-usage', data);
  }

  @override
  Future<void> addCredits(int amount) async {
    await _post('/v1/dev/add-credits', {'amount': amount});
  }

  @override
  Future<void> setPremium(bool isPremium) async {
    await _post('/v1/dev/set-premium', {'isPremium': isPremium});
  }

  Future<void> _post(String path, Map<String, dynamic> data) async {
    try {
      await _client.post<Map<String, dynamic>>(path, data: data);
    } on DioException catch (error) {
      throw ApiError.fromDio(error, fallback: 'Developer test action failed.');
    }
  }
}

final devToolsRepositoryProvider = Provider<DevToolsClient>(
  (ref) => DevToolsRepository(ref.watch(apiClientProvider)),
);
