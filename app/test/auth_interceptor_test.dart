import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/auth_interceptor.dart';
import 'package:replywise/features/auth/data/token_storage.dart';

class _TokenStorage extends TokenStorage {
  _TokenStorage(this.accessToken) : super(const FlutterSecureStorage());

  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}

class _AuthAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final token = options.headers['Authorization'];
    if (token == 'Bearer recovered-token') {
      return ResponseBody.fromString(
        '{"ok":true}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      '{"detail":"expired"}',
      401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    '401 delegates recovery and retries the original request once',
    () async {
      final storage = _TokenStorage('expired-token');
      final adapter = _AuthAdapter();
      final rawDio = Dio()..httpClientAdapter = adapter;
      var recoveryCalls = 0;
      final dio = Dio()
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(
            tokenStorage: storage,
            rawDio: rawDio,
            recoverUnauthorized: () async {
              recoveryCalls++;
              storage.accessToken = 'recovered-token';
              return true;
            },
          ),
        );

      final response = await dio.get<Map<String, dynamic>>('/protected');

      expect(response.statusCode, 200);
      expect(response.data, {'ok': true});
      expect(recoveryCalls, 1);
      expect(adapter.calls, 2);
    },
  );
}
