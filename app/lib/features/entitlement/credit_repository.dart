import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';

class CreditSyncResult {
  const CreditSyncResult({
    required this.isPremium,
    required this.freeUsesLeft,
    required this.paidCredits,
    required this.upgradeRequired,
    required this.grantedThisSync,
  });

  final bool isPremium;
  final int? freeUsesLeft;
  final int paidCredits;
  final bool upgradeRequired;
  final int grantedThisSync;

  factory CreditSyncResult.fromJson(Map<String, dynamic> json) =>
      CreditSyncResult(
        isPremium: json['isPremium'] as bool? ?? false,
        freeUsesLeft: json['freeUsesLeft'] as int?,
        paidCredits: json['paidCredits'] as int? ?? 0,
        upgradeRequired: json['upgradeRequired'] as bool? ?? false,
        grantedThisSync: json['grantedThisSync'] as int? ?? 0,
      );
}

class CreditRepository {
  const CreditRepository(this._client);

  final ApiClient _client;

  Future<CreditSyncResult> sync() async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/v1/credits/sync',
      );
      return CreditSyncResult.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(
        error,
        fallback: 'Unable to sync credit purchases.',
      );
    }
  }
}

final creditRepositoryProvider = Provider<CreditRepository>(
  (ref) => CreditRepository(ref.watch(apiClientProvider)),
);
