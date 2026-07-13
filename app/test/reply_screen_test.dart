import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/network/api_client.dart';
import 'package:replywise/core/share/share_helper.dart';
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
  List<Override> overrides = const [],
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
        ...overrides,
      ],
      child: const MaterialApp(home: ReplyScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps the Reply screen with an overridden text scale, for exercising the
/// Quick guidance chip grid at large system font sizes.
Future<void> _pumpReplyScaled(WidgetTester tester, double textScale) async {
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
      child: MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: const ReplyScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Reply result shows share before copy and copy still works', (
    tester,
  ) async {
    _useTallView(tester);
    final repository = _RecordingReplyRepository();
    final shared = <String>[];
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>;
          copied.add(args['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pumpReply(
      tester,
      repository: repository,
      overrides: [
        generatedTextSharerProvider.overrideWithValue((
          text, {
          String? subject,
        }) async {
          shared.add(text);
        }),
      ],
    );
    await tester.enterText(
      _editableIn(const Key('reply-incoming-field')),
      'Can you send the report?',
    );
    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();

    final share = find.byTooltip('Share reply').first;
    final copy = find.byKey(const Key('result-copy-button')).first;
    expect(tester.getTopLeft(share).dx, lessThan(tester.getTopLeft(copy).dx));

    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(shared, ['Professional reply']);

    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(copied, ['Professional reply']);
    expect(find.text('Copied'), findsOneWidget);
  });

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
    expect(
      find.descendant(
        of: find.byKey(const Key('reply-custom-tone-field')),
        matching: find.byIcon(Icons.menu_book_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('reply-custom-tone-field'))).height,
      lessThan(70),
    );
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
    expect(
      find.descendant(
        of: find.byKey(const Key('reply-custom-audience-field')),
        matching: find.byIcon(Icons.menu_book_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('reply-custom-audience-field')))
          .height,
      lessThan(70),
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
    expect(
      find.descendant(
        of: find.byKey(const Key('reply-message-card')),
        matching: find.byIcon(Icons.lightbulb_outline_rounded),
      ),
      findsNothing,
    );
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
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(_editableIn(const Key('reply-guidance-field')))
          .controller
          .text,
      'Accept the request politely.',
    );

    await tester.tap(find.text('Generate Reply'));
    await tester.pumpAndSettle();
    expect(repository.lastRequest?.guidance, 'Accept the request politely.');
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
    expect(_actionIn(fieldKey, 'Templates'), findsOneWidget);
    expect(_actionIn(fieldKey, 'Paste'), findsOneWidget);
    // Clear only appears once the field has text.
    expect(_actionIn(fieldKey, 'Clear'), findsNothing);

    await tester.enterText(_editableIn(fieldKey), 'Old guidance');
    await tester.pump();
    expect(_actionIn(fieldKey, 'Clear'), findsOneWidget);
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
    await tester.tap(_actionIn(fieldKey, 'Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Choose guidance'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Use').first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
      isNotEmpty,
    );
  });

  testWidgets('Reply custom tone template icon fills the custom tone field', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpReply(tester);
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').first);
    await tester.pumpAndSettle();

    const fieldKey = Key('reply-custom-tone-field');
    await tester.tap(_actionIn(fieldKey, 'Templates'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Use').first);
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
      isNotEmpty,
    );
  });

  testWidgets(
    'Reply custom audience template icon fills the custom audience field',
    (tester) async {
      _useTallView(tester);
      await _pumpReply(tester);
      await tester.tap(find.text('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom').last);
      await tester.pumpAndSettle();

      const fieldKey = Key('reply-custom-audience-field');
      await tester.tap(_actionIn(fieldKey, 'Templates'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Use').first);
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(_editableIn(fieldKey)).controller.text,
        isNotEmpty,
      );
    },
  );

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
    await tester.pumpAndSettle();

    // Empty input is now reported via the shared error bottom sheet and no
    // request is started.
    expect(find.byKey(const Key('empty-input-sheet')), findsOneWidget);
    expect(find.text('Add a message first'), findsOneWidget);
    expect(find.text('Generating…'), findsNothing);
  });

  testWidgets('Quick guidance chips wrap naturally on a normal screen', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpReply(tester);
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    expect(find.text('Use template'), findsOneWidget);
    expect(find.text('Firm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quick guidance chips do not overflow at large text scale', (
    tester,
  ) async {
    _useTallView(tester);
    await _pumpReplyScaled(tester, 1.4);
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    expect(find.text('Use template'), findsOneWidget);
    expect(find.text('Firm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quick guidance chips do not overflow on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 5200); // width < 360
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpReply(tester);
    await tester.tap(find.text('Guidance'));
    await tester.pumpAndSettle();

    expect(find.text('Use template'), findsOneWidget);
    expect(find.text('Firm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
