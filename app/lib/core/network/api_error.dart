import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({
    required this.message,
    this.statusCode,
    this.code,
    this.field,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final String? field;

  String displayMessage({required String fallback}) {
    return switch (code) {
      'PAYWALL_REQUIRED' =>
        'You have no generations left. Choose Premium or add credits to continue.',
      'RATE_LIMITED' =>
        'You’re going a little fast. Wait a moment, then try again.',
      'MODEL_UNAVAILABLE' =>
        'The writing service is temporarily unavailable. Please try again.',
      'MODEL_PARSE_ERROR' =>
        'We couldn’t finish that result. Please try again.',
      'IDEMPOTENCY_CONFLICT' =>
        'That request is still finishing. Please wait a moment and try again.',
      'ENTITLEMENT_SYNC_FAILED' =>
        'We couldn’t verify Premium right now. Your access has not changed.',
      'CREDIT_SYNC_FAILED' =>
        'We couldn’t verify credit purchases right now. Please try again.',
      'UNAUTHENTICATED' || 'TOKEN_EXPIRED' =>
        'Your secure session needs to reconnect. Please try again.',
      'VALIDATION_ERROR' || 'INPUT_TOO_LONG' => fallback,
      _ when statusCode == null =>
        'You appear to be offline. Check your connection and try again.',
      _ when statusCode != null && statusCode! >= 500 =>
        'ReplyWise is temporarily unavailable. Please try again shortly.',
      _ => fallback,
    };
  }

  factory ApiError.fromDio(DioException error, {String? fallback}) {
    final data = error.response?.data;
    final errorData = data is Map<String, dynamic> ? data['error'] : null;
    if (errorData is Map<String, dynamic>) {
      return ApiError(
        message:
            errorData['message'] as String? ?? fallback ?? 'Request failed',
        statusCode: error.response?.statusCode,
        code: errorData['code'] as String?,
        field: errorData['field'] as String?,
      );
    }
    return ApiError(
      message: fallback ?? error.message ?? 'Network request failed',
      statusCode: error.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
