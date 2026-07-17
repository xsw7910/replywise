import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/theme/app_feature_theme.dart';
import 'package:replywise/core/widgets/labeled_text_field.dart';

/// The clear button inside input fields: pinned to the top-right corner,
/// visible only when the field has text, and clears on tap.
void main() {
  const fieldKey = Key('clear-test-field');

  Future<TextEditingController> pumpField(
    WidgetTester tester, {
    int maxLines = 5,
  }) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LabeledTextField(
              key: fieldKey,
              label: 'Message',
              controller: controller,
              hintText: 'Type here',
              feature: AppFeature.reply,
              showHeader: false,
              showCounter: false,
              maxLines: maxLines,
              showClearButton: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Finder clearIn(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byTooltip('Clear'));

  testWidgets('clear button is hidden while the field is empty', (
    tester,
  ) async {
    await pumpField(tester);
    expect(clearIn(fieldKey), findsNothing);
  });

  testWidgets('clear button appears at the top-right corner when text is '
      'entered', (tester) async {
    await pumpField(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(fieldKey),
        matching: find.byType(EditableText),
      ),
      'Hello there',
    );
    await tester.pump();

    expect(clearIn(fieldKey), findsOneWidget);

    final fieldRect = tester.getRect(
      find.descendant(
        of: find.byKey(fieldKey),
        matching: find.byType(TextField),
      ),
    );
    final buttonCenter = tester.getCenter(clearIn(fieldKey));
    // Top-right corner: near the top edge, near the right edge — NOT
    // vertically centered in the multiline field.
    expect(buttonCenter.dy, lessThan(fieldRect.top + 44));
    expect(buttonCenter.dx, greaterThan(fieldRect.right - 60));
  });

  testWidgets('clear button stays at the top with long multiline text and '
      'clears on tap', (tester) async {
    final controller = await pumpField(tester);
    final longText = List.generate(
      12,
      (i) => 'Line $i of a long draft',
    ).join('\n');
    await tester.enterText(
      find.descendant(
        of: find.byKey(fieldKey),
        matching: find.byType(EditableText),
      ),
      longText,
    );
    await tester.pump();

    final fieldRect = tester.getRect(
      find.descendant(
        of: find.byKey(fieldKey),
        matching: find.byType(TextField),
      ),
    );
    final buttonCenter = tester.getCenter(clearIn(fieldKey));
    expect(buttonCenter.dy, lessThan(fieldRect.top + 44));

    await tester.tap(clearIn(fieldKey));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(clearIn(fieldKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('works on a small screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpField(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(fieldKey),
        matching: find.byType(EditableText),
      ),
      'A fairly long single line of text that wraps on a narrow screen',
    );
    await tester.pump();

    expect(clearIn(fieldKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
