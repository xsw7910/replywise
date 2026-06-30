import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/features/auth/data/auth_repository.dart';

class _RecordingAuthAdapter implements HttpClientAdapter {
  Object? requestData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestData = options.data;
    return ResponseBody.fromString(
      jsonEncode({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'me': {'userId': 1, 'appUserId': 'app-user'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('anonymous auth sends the resolved hash as deviceId', () async {
    final adapter = _RecordingAuthAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = AuthRepository(dio);
    const hash = '12345678abcdef';

    await repository.anonymous(
      appUserId: 'different-app-user',
      deviceId: hash,
      platform: 'android',
    );

    expect(adapter.requestData, {
      'appUserId': 'different-app-user',
      'deviceId': hash,
      'platform': 'android',
    });
  });
}
