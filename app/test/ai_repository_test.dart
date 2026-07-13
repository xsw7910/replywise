import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/network/api_error.dart';
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
  Options? options;
  Map<String, dynamic> response = {};

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    this.path = path;
    payload = data;
    this.options = options;
    return Response<T>(
      data: response as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

/// Throws IDEMPOTENCY_CONFLICT/processing for the first [failTimes] calls,
/// then returns [successResponse].
class _ConflictClient extends ApiClient {
  _ConflictClient({
    required this.failTimes,
    required this.successResponse,
    this.conflictMessage = 'Request is still processing.',
  }) : super(
         rawDio: Dio(),
         tokenStorage: _Storage(),
         recoverUnauthorized: () async => false,
       );

  final int failTimes;
  final Map<String, dynamic> successResponse;
  final String conflictMessage;
  var callCount = 0;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    callCount++;
    if (callCount <= failTimes) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response<Map<String, dynamic>>(
          data: {
            'error': {
              'code': 'IDEMPOTENCY_CONFLICT',
              'message': conflictMessage,
            },
          },
          statusCode: 409,
          requestOptions: RequestOptions(path: path),
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return Response<T>(
      data: successResponse as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  test(
    'ReplyRepository sends fixed English output and parses versions',
    () async {
      // Legacy labels from a not-yet-updated backend: parsing must map them
      // to the renamed Formal/Casual/Concise labels.
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
          guidanceLang: 'zh',
          appLocale: 'zh',
          audience: ReplyAudience(mode: 'auto', formality: 50),
        ),
      );

      expect(client.path, '/v1/reply');
      expect(client.payload['outputLang'], 'en');
      expect(client.payload['appLocale'], 'zh');
      expect(client.payload['guidanceLang'], 'zh');
      expect(client.payload['guidance'], 'Respond warmly');
      expect(client.options?.headers?['X-Idempotency-Key'], isNotEmpty);
      expect(result.versions, hasLength(3));
      expect(result.versions.map((v) => v.label).toList(), [
        'Formal',
        'Casual',
        'Concise',
      ]);
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
          guidanceLang: 'zh',
          appLocale: 'zh',
        ),
      );

      expect(client.path, '/v1/polish');
      expect(client.payload['direction'], 'natural');
      expect(client.payload['appLocale'], 'zh');
      expect(client.payload['guidanceLang'], 'zh');
      expect(client.options?.headers?['X-Idempotency-Key'], isNotEmpty);
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
      ).explain(text: 'Things are hectic.', explainLang: 'zh', appLocale: 'zh');

      expect(client.path, '/v1/explain');
      expect(client.payload['explainLang'], 'zh');
      expect(client.payload['appLocale'], 'zh');
      expect(result.hiddenMeaning, 'Subtext');
      expect(result.suggestedReplies, hasLength(1));
    },
  );

  const replyRequest = ReplyRequest(
    incoming: 'Hello',
    guidance: 'Reply warmly',
    guidanceLang: 'en',
    audience: ReplyAudience(mode: 'auto', formality: 50),
  );

  const successVersions = {
    'versions': [
      {'label': 'Formal', 'text': 'Hi.'},
      {'label': 'Casual', 'text': 'Hey!'},
      {'label': 'Concise', 'text': 'Hi!'},
    ],
    'why': 'Clear.',
  };

  test(
    'ReplyRepository retries IDEMPOTENCY_CONFLICT/processing and succeeds',
    () async {
      // 2 failures then success → 3 total calls
      final client = _ConflictClient(
        failTimes: 2,
        successResponse: successVersions,
      );

      final result = await ReplyRepository(client).generate(replyRequest);

      expect(client.callCount, 3);
      expect(result.versions, hasLength(3));
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  test(
    'ReplyRepository gives up after 3 processing conflicts',
    () async {
      // 3 consecutive failures → throws after 3 calls
      final client = _ConflictClient(failTimes: 10, successResponse: {});

      await expectLater(
        ReplyRepository(client).generate(replyRequest),
        throwsA(
          isA<ApiError>().having((e) => e.code, 'code', 'IDEMPOTENCY_CONFLICT'),
        ),
      );

      expect(client.callCount, 3);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  test(
    'ReplyRepository does not retry non-processing IDEMPOTENCY_CONFLICT',
    () async {
      // "reused" message does not contain "processing" → no retry
      final client = _ConflictClient(
        failTimes: 10,
        successResponse: {},
        conflictMessage: 'Idempotency key was reused.',
      );

      await expectLater(
        ReplyRepository(client).generate(replyRequest),
        throwsA(isA<ApiError>()),
      );

      expect(client.callCount, 1);
    },
  );
}
