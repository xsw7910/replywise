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

class _RecordingReplyRepository extends ReplyRepository {
  _RecordingReplyRepository() : super(_DummyClient());

  ReplyRequest? lastRequest;

  @override
  Future<ReplyResult> generate(ReplyRequest request) async {
    lastRequest = request;
    return const ReplyResult(
      versions: [
        ReplyVersion(label: 'Professional', text: 'Professional reply'),
        ReplyVersion(label: 'Friendly', text: 'Friendly reply'),
        ReplyVersion(label: 'Short', text: 'Short reply'),
      ],
      why: 'Test result',
    );
  }
}

Finder _editableIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

Finder _actionIn(Key key, String tooltip) =>
    find.descendant(of: find.byKey(key), matching: find.byTooltip(tooltip));

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 5200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpReply(
  WidgetTester tester, {
  ReplyRepository? repository,
}) async {
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
        replyRepositoryProvider.overrideWith(
          (ref) => repository ?? _NeverReplyRepository(),
        ),
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

  testWidgets('whitespace-only guidance also does not block Generate Reply', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpReply(tester);

    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Sounds great, thanks.',
    );

    // Expand the guidance section and type only whitespace.
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    await tester.enterText(
      _editableIn(const Key('reply-guidance-field')),
      '   ',
    );

    await tester.tap(find.text('Generate Reply'));
    await tester.pump();

    expect(find.text('Describe how you want to reply.'), findsNothing);
    expect(find.text('Generating…'), findsOneWidget);
  });

  testWidgets('custom tone input is shown and sent', (tester) async {
    _useTallView(tester);
    final repository = _RecordingReplyRepository();
    await _pumpReply(tester, repository: repository);
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can you send the report?',
    );
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').at(0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reply-custom-tone-field')), findsOneWidget);
    await tester.enterText(
      _editableIn(const Key('reply-custom-tone-field')),
      ' warm but professional ',
    );
    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();
    expect(repository.lastRequest?.tone, 'warm but professional');
  });

  testWidgets('custom audience input is shown and sent', (tester) async {
    _useTallView(tester);
    final repository = _RecordingReplyRepository();
    await _pumpReply(tester, repository: repository);
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can you send the report?',
    );
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').at(1));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('reply-custom-audience-field')),
      findsOneWidget,
    );
    await tester.enterText(
      _editableIn(const Key('reply-custom-audience-field')),
      ' my manager ',
    );
    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();
    expect(repository.lastRequest?.audience.mode, 'custom');
    expect(repository.lastRequest?.audience.custom, 'my manager');
  });

  testWidgets('predefined tone and audience are sent', (tester) async {
    _useTallView(tester);
    final repository = _RecordingReplyRepository();
    await _pumpReply(tester, repository: repository);
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can you send the report?',
    );
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Professional'));
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();
    expect(repository.lastRequest?.tone, 'Professional');
    expect(repository.lastRequest?.audience.mode, 'preset');
    expect(repository.lastRequest?.audience.preset, 'customer');
  });

  testWidgets('Guidance collapsed header shows badge + subtitle and toggles', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpReply(tester);

    expect(find.text('Guidance'), findsOneWidget);
    expect(find.text('Help AI understand your intent'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsWidgets);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsWidgets);
    expect(find.text('Add guidance'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('reply-more-options-card'))).height,
      tester.getSize(find.byKey(const Key('reply-guidance-card'))).height,
    );

    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reply-guidance-field')), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsWidgets);

    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reply-guidance-field')), findsNothing);
  });

  testWidgets('selected Reply guidance remains visible and is sent', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = _RecordingReplyRepository();
    await _pumpReply(tester, repository: repository);
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can we reschedule?',
    );

    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Be polite'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(_editableIn(const Key('reply-guidance-field')))
          .controller
          .text,
      'Make the reply polite and respectful.',
    );

    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();
    expect(
      repository.lastRequest?.guidance,
      'Make the reply polite and respectful.',
    );
  });

  testWidgets('Reply guidance shows Library, Paste, Clear and clears payload', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = _RecordingReplyRepository();
    await _pumpReply(tester, repository: repository);
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can we reschedule?',
    );
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    const fieldKey = Key('reply-guidance-field');
    expect(_actionIn(fieldKey, 'Guidance Library'), findsOneWidget);
    expect(_actionIn(fieldKey, 'Paste'), findsOneWidget);
    expect(_actionIn(fieldKey, 'Clear'), findsOneWidget);

    await tester.enterText(_editableIn(fieldKey), 'Old guidance');
    await tester.tap(_actionIn(fieldKey, 'Clear'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
      isEmpty,
    );

    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();
    expect(repository.lastRequest?.guidance, isEmpty);
  });

  testWidgets('Reply Guidance Library action inserts a selected template', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpReply(tester);
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    const fieldKey = Key('reply-guidance-field');
    await tester.tap(_actionIn(fieldKey, 'Guidance Library'));
    await tester.pumpAndSettle();
    expect(find.text('Choose guidance'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Use').first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
      isNotEmpty,
    );
  });

  testWidgets('Reply guidance scrolls to the bottom when text grows', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpReply(tester);
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    const fieldKey = Key('reply-guidance-field');
    await tester.enterText(
      _editableIn(fieldKey),
      List.generate(12, (index) => 'Guidance line $index').join('\n'),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(fieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(textField.scrollController, isNotNull);
    expect(textField.scrollController!.offset, greaterThan(0));
    expect(
      textField.scrollController!.offset,
      textField.scrollController!.position.maxScrollExtent,
    );
  });

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
