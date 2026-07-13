import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/polish/polish_screen.dart';
import 'package:replywise/features/reply/explain_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';

/// Header layering on Reply / Explain / Polish: the header icon+title must
/// scroll away with the content instead of staying pinned above the input
/// card. After scrolling up, the header title is either gone or entirely
/// above the viewport — never floating over the input box.
void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(360, 640), // small phone: content must scroll
  }) async {
    tester.view.physicalSize = size;
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
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// True when the header title no longer overlaps the visible input area:
  /// either it left the tree entirely or it sits fully above the viewport.
  void expectHeaderScrolledAway(WidgetTester tester, Key headerKey) {
    final header = find.byKey(headerKey);
    if (header.evaluate().isEmpty) return; // sliver disposed — gone entirely
    final rect = tester.getRect(header);
    expect(
      rect.bottom <= 0 || rect.height == 0,
      isTrue,
      reason:
          'header $headerKey should be scrolled out of the viewport, '
          'but its rect is $rect',
    );
  }

  Future<void> scrollUp(WidgetTester tester, double offset) async {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(offset);
    await tester.pump();
  }

  testWidgets('Reply: scrolled-up input card is not covered by the header', (
    tester,
  ) async {
    await pumpScreen(tester, const ReplyScreen());
    expect(find.byKey(const Key('reply-hero-header')), findsOneWidget);

    // Long multiline input plus a scroll upward.
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('reply-incoming-field')),
        matching: find.byType(EditableText),
      ),
      List.generate(8, (i) => 'Line $i of the message').join('\n'),
    );
    await tester.pump();
    await scrollUp(tester, 400);

    expectHeaderScrolledAway(tester, const Key('reply-hero-header'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Polish: scrolled-up input card is not covered by the header', (
    tester,
  ) async {
    await pumpScreen(tester, const PolishScreen());
    expect(find.byKey(const Key('polish-hero-header')), findsOneWidget);

    await scrollUp(tester, 400);

    expectHeaderScrolledAway(tester, const Key('polish-hero-header'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explain: scrolled-up input card is not covered by the header', (
    tester,
  ) async {
    await pumpScreen(tester, const ExplainScreen());
    expect(find.byKey(const Key('explain-hero-header')), findsOneWidget);
    // Unscrolled: header title is visible as before.
    expect(find.text('Explain'), findsOneWidget);

    await scrollUp(tester, 300);

    expectHeaderScrolledAway(tester, const Key('explain-hero-header'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explain: empty input and unscrolled layout keep the header '
      'visible at the top', (tester) async {
    await pumpScreen(tester, const ExplainScreen(), size: const Size(400, 900));

    final headerRect = tester.getRect(
      find.byKey(const Key('explain-hero-header')),
    );
    expect(headerRect.top, lessThanOrEqualTo(1));
    expect(headerRect.height, 112);
    expect(
      tester.getTopLeft(find.byKey(const Key('explain-message-card'))).dy,
      130,
    );
    expect(find.text('Message to understand'), findsOneWidget);
  });
}
