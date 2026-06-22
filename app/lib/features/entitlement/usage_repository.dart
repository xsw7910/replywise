import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import 'entitlement_state.dart';

part 'usage_repository.g.dart';

class UsageRepository {
  const UsageRepository(this._client);
  final ApiClient _client;

  Future<EntitlementState> fetch() async {
    final response = await _client.get<Map<String, dynamic>>('/v1/me');
    return EntitlementState.fromJson(response.data!);
  }
}

@riverpod
UsageRepository usageRepository(UsageRepositoryRef ref) =>
    UsageRepository(ref.watch(apiClientProvider));
