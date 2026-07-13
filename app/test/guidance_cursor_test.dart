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

/// Cursor behavior of the guidance text field: manual edits keep the caret
/// where the user is typing; only explicit Quick Guidance insertion moves it
/// (and the scroll) to the end.
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

class _NeverReplyRepository extends ReplyRepository {
  _NeverReplyRepository() : super(_DummyClient());

  @override
  Future<ReplyResult> generate(ReplyRequest request) =>
      Completer<ReplyResult>().future;
}

const _fieldKey = Key('reply-guidance-field');

Finder _editable() => find.descendant(
  of: find.byKey(_fieldKey),
  matching: find.byType(EditableText),
);

TextEditingController _controller(WidgetTester tester) =>
    tester.widget<EditableText>(_editable()).controller;

ScrollController _scroller(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(_fieldKey),
        matching: find.byType(TextField),
      ),
    )
    .scrollController!;

Future<void> _pumpReplyWithGuidanceOpen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 5200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
  await tester.tap(find.text('Guidance'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing in the middle keeps the cursor position and does not '
      'scroll to the end', (tester) async {
    await _pumpReplyWithGuidanceOpen(tester);

    // Tall content so the field can actually scroll; enterText leaves the
    // caret at the end and (intentionally) scrolls to the bottom.
    final lines = List.generate(12, (i) => 'Guidance line $i').join('\n');
    await tester.enterText(_editable(), lines);
    await tester.pumpAndSettle();

    // Scroll back to the top and edit near the beginning, as a user would.
    _scroller(tester).jumpTo(0);
    await tester.pump();

    const caret = 9; // inside "Guidance line 0"
    final edited = lines.replaceFirst('Guidance', 'GuidanceX');
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: edited,
        selection: const TextSelection.collapsed(offset: caret),
      ),
    );
    await tester.pumpAndSettle();

    final controller = _controller(tester);
    // The caret stays where the user typed — not forced to the end.
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, caret);
    // And the field did not jump to the bottom.
    expect(_scroller(tester).offset, 0);
  });

  testWidgets('tapping a Quick Guidance chip moves the caret to the end', (
    tester,
  ) async {
    await _pumpReplyWithGuidanceOpen(tester);

    await tester.enterText(_editable(), 'Existing guidance');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    final controller = _controller(tester);
    expect(controller.text, contains('Accept the request politely.'));
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, controller.text.length);
    expect(controller.value.composing, TextRange.empty);
  });

  testWidgets('rebuilding the page does not move the cursor to the end', (
    tester,
  ) async {
    await _pumpReplyWithGuidanceOpen(tester);

    await tester.enterText(_editable(), 'Some guidance text');
    await tester.pumpAndSettle();
    _controller(tester).selection = const TextSelection.collapsed(offset: 4);
    await tester.pump();

    // Force a page rebuild via an unrelated setState (toggle More options).
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();

    final controller = _controller(tester);
    expect(controller.selection.baseOffset, 4);
    expect(controller.text, 'Some guidance text');
  });

  testWidgets('clearing the field still works normally', (tester) async {
    await _pumpReplyWithGuidanceOpen(tester);

    await tester.enterText(_editable(), 'Some guidance text');
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(_fieldKey),
        matching: find.byTooltip('Clear'),
      ),
    );
    await tester.pump();

    expect(_controller(tester).text, isEmpty);
  });
}
