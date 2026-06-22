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
