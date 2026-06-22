import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/app.dart';
import 'package:replywise/features/paywall/paywall_screen.dart';
import 'package:replywise/features/reply/reply_screen.dart';

void main() {
  testWidgets('app exposes Reply, Polish, and Settings navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ReplyWiseApp()));
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsAtLeastNWidgets(1));
    expect(find.text('Polish'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Turn your intent into natural English'), findsOneWidget);

    await tester.tap(find.text('Polish'));
    await tester.pumpAndSettle();

    expect(find.text('Make your English sound natural'), findsOneWidget);
  });

  testWidgets('guidance chip fills the Reply guidance field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReplyScreen()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Be polite'));
    await tester.pump();

    final guidanceField = find.descendant(
      of: find.byKey(const Key('reply-guidance-field')),
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(guidanceField);
    expect(field.controller?.text, 'Be polite');
  });

  testWidgets('paywall clearly remains a static two-path preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PaywallScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Start 3-day Free Trial'), findsOneWidget);
    expect(find.text('Buy Credits'), findsOneWidget);
    expect(find.textContaining('static preview'), findsOneWidget);

    await tester.tap(find.text('Start 3-day Free Trial'));
    await tester.pump();

    expect(
      find.text('Purchases are not available in this preview.'),
      findsOneWidget,
    );
  });
}
