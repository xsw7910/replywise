import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/app.dart';

void main() {
  testWidgets('App smoke test — bottom nav labels are visible', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReplyWiseApp()));
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsAtLeastNWidgets(1));
    expect(find.text('Polish'), findsAtLeastNWidgets(1));
    expect(find.text('Settings'), findsAtLeastNWidgets(1));
  });
}
