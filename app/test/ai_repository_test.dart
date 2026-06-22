import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/polish/data/polish_repository.dart';
import 'package:replywise/features/polish/domain/polish_models.dart';
import 'package:replywise/features/reply/data/explain_repository.dart';
import 'package:replywise/features/reply/data/reply_repository.dart';
import 'package:replywise/features/reply/domain/reply_models.dart';

class _Storage extends TokenStorage {
  _Storage() : super(const FlutterSecureStorage());
}

class _RecordingClient extends ApiClient {
  _RecordingClient()
    : super(
        rawDio: Dio(),
        tokenStorage: _Storage(),
        recoverUnauthorized: () async => false,
      );

  String? path;
  dynamic payload;
  Map<String, dynamic> response = {};

  @override
  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    this.path = path;
    payload = data;
    return Response<T>(
      data: response as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  test(
    'ReplyRepository sends fixed English output and parses versions',
    () async {
      final client = _RecordingClient()
        ..response = {
          'versions': [
            {'label': 'Professional', 'text': 'Professional reply'},
            {'label': 'Friendly', 'text': 'Friendly reply'},
            {'label': 'Short', 'text': 'Short reply'},
          ],
          'why': 'Clear and natural.',
        };

      final result = await ReplyRepository(client).generate(
        const ReplyRequest(
          incoming: 'Hello',
          guidance: 'Respond warmly',
          guidanceLang: 'en',
          audience: ReplyAudience(mode: 'auto', formality: 50),
        ),
      );

      expect(client.path, '/v1/reply');
      expect(client.payload['outputLang'], 'en');
      expect(client.payload['guidance'], 'Respond warmly');
      expect(result.versions, hasLength(3));
    },
  );

  test(
    'PolishRepository sends the selected direction and parses result',
    () async {
      final client = _RecordingClient()
        ..response = {
          'polished': 'Hello there.',
          'changes': 'Improved punctuation.',
        };

      final result = await PolishRepository(client).polish(
        const PolishRequest(
          draft: 'hello there',
          direction: 'natural',
          guidanceLang: 'en',
        ),
      );

      expect(client.path, '/v1/polish');
      expect(client.payload['direction'], 'natural');
      expect(result.polished, 'Hello there.');
    },
  );

  test(
    'ExplainRepository sends interface language and parses four sections',
    () async {
      final client = _RecordingClient()
        ..response = {
          'meaning': 'Meaning',
          'tone': 'Tone',
          'hiddenMeaning': 'Subtext',
          'suggestedReplies': ['Thanks for letting me know.'],
        };

      final result = await ExplainRepository(
        client,
      ).explain(text: 'Things are hectic.', explainLang: 'en');

      expect(client.path, '/v1/explain');
      expect(client.payload['explainLang'], 'en');
      expect(result.hiddenMeaning, 'Subtext');
      expect(result.suggestedReplies, hasLength(1));
    },
  );
}
