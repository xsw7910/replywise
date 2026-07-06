import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

/// Outcome of a successful `POST /v1/credits/ad-reward` call.
class AdRewardResult {
  const AdRewardResult({
    required this.credits,
    required this.awarded,
    required this.dailyRemaining,
  });

  final int credits;
  final int awarded;
  final int dailyRemaining;

  factory AdRewardResult.fromJson(Map<String, dynamic> json) => AdRewardResult(
    credits: json['credits'] as int? ?? 0,
    awarded: json['awarded'] as int? ?? 0,
    dailyRemaining: json['dailyRemaining'] as int? ?? 0,
  );
}

class AdRewardRepository {
  const AdRewardRepository(this._client);

  final ApiClient _client;

  /// Reports one completed rewarded-ad view and returns the resulting balance.
  ///
  /// The `amount: 1` below is the number of completed ad views (always one) —
  /// NOT the credit payout. The server decides how many credits a view is worth
  /// and enforces reward type, idempotency, daily cap and cooldown; the client
  /// only supplies a unique [idempotencyKey] so a retry never double-credits.
  Future<AdRewardResult> claim({required String idempotencyKey}) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/v1/credits/ad-reward',
        data: {
          'idempotencyKey': idempotencyKey,
          'rewardType': 'admob_rewarded',
          'amount': 1,
        },
      );
      return AdRewardResult.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(error, fallback: 'Unable to add your credit.');
    }
  }
}

final adRewardRepositoryProvider = Provider<AdRewardRepository>(
  (ref) => AdRewardRepository(ref.watch(apiClientProvider)),
);
