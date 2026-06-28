import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/features/auth/data/token_storage.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/reply/data/reply_repository.dart';
import 'package:replywise/features/reply/domain/reply_models.dart';
import 'package:replywise/features/reply/reply_screen.dart';

class _Storage extends TokenStorage {
  _Storage() : super(const FlutterSecureStorage());
}

class _DummyClient extends ApiClient {
  _DummyClient()
    : super(
        rawDio: Dio(),
        tokenStorage: _Storage(),
        recoverUnauthorized: () async => false,
      );
}

/// Hangs forever so we can assert on the state produced by validation
/// (either an error or a loading indicator) without hitting a real network.
class _NeverReplyRepository extends ReplyRepository {
  _NeverReplyRepository() : super(_DummyClient());

  @override
  Future<ReplyResult> generate(ReplyRequest request) =>
      Completer<ReplyResult>().future;
}

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 5200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpReply(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        guidanceLibraryRepositoryProvider.overrideWith(
          (ref) =>
              GuidanceLibraryRepository(ref.watch(sharedPreferencesProvider)),
        ),
        replyRepositoryProvider.overrideWith((ref) => _NeverReplyRepository()),
      ],
      child: const MaterialApp(home: ReplyScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'empty guidance does not block Generate Reply — shows loading instead',
    (tester) async {
      _useTallView(tester);
      await _pumpReply(tester);

      await tester.enterText(
        _editableIn(const Key('reply-incoming-field')),
        'Can we move the meeting to tomorrow?',
      );

      await tester.tap(find.text('Generate Reply'));
      await tester.pump(); // one frame: validation runs, loading begins

      expect(find.text('Describe how you want to reply.'), findsNothing);
      expect(find.text('Generating…'), findsOneWidget);
    },
  );

  testWidgets(
    'whitespace-only guidance also does not block Generate Reply',
    (tester) async {
      _useTallView(tester);
      await _pumpReply(tester);

      await tester.enterText(
        _editableIn(const Key('reply-incoming-field')),
        'Sounds great, thanks.',
      );

      // Expand the guidance section and type only whitespace.
      await tester.tap(find.text('Add guidance'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _editableIn(const Key('reply-guidance-field')),
        '   ',
      );

      await tester.tap(find.text('Generate Reply'));
      await tester.pump();

      expect(find.text('Describe how you want to reply.'), findsNothing);
      expect(find.text('Generating…'), findsOneWidget);
    },
  );

  testWidgets('empty incoming still blocks Generate Reply', (tester) async {
    _useTallView(tester);
    await _pumpReply(tester);

    // Tap Generate without entering any incoming text.
    await tester.tap(find.text('Generate Reply'));
    await tester.pump();

    expect(find.text('Enter the message you received.'), findsOneWidget);
    expect(find.text('Generating…'), findsNothing);
  });
}
