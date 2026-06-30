import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:replywise/core/theme/app_theme.dart';
import 'package:replywise/core/widgets/app_page.dart';
import 'package:replywise/features/entitlement/entitlement_state.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/features/reply/reply_screen.dart';
import 'package:replywise/features/reply/widgets/reply_status_badge.dart';

EntitlementState _state({
  required bool isPremium,
  int? freeUsesLeft,
  int paidCredits = 0,
}) => EntitlementState(
  isPremium: isPremium,
  freeUsesLimit: 5,
  freeUsesUsed: 0,
  freeUsesLeft: freeUsesLeft,
  paidCredits: paidCredits,
  upgradeRequired: false,
);

void main() {
  Future<void> pumpBadge(WidgetTester tester, EntitlementState usage) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [ReplyStatusBadge(usage: usage, onTap: () {})],
          ),
        ),
      ),
    );
  }

  testWidgets('premium user sees crown + Premium and no credits count', (
    tester,
  ) async {
    await pumpBadge(tester, _state(isPremium: true, freeUsesLeft: null));

    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    // No credit icon and no number when premium.
    expect(find.byIcon(Icons.toll_rounded), findsNothing);
  });

  testWidgets('non-premium user sees credit icon and total credits', (
    tester,
  ) async {
    // Total usable = freeUsesLeft (3) + paidCredits (4) = 7.
    await pumpBadge(
      tester,
      _state(isPremium: false, freeUsesLeft: 3, paidCredits: 4),
    );

    expect(find.byIcon(Icons.toll_rounded), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
    expect(find.text('Premium'), findsNothing);
  });

  testWidgets(
    'Reply header shows a left-aligned title and drops the old subtitle',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            guidanceLibraryRepositoryProvider.overrideWith(
              (ref) => GuidanceLibraryRepository(
                ref.watch(sharedPreferencesProvider),
              ),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const ReplyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The old large header subtitle is gone.
      expect(find.text('Generate natural English replies.'), findsNothing);

      // Only the header title "Reply" remains, left-aligned near the leading edge.
      final title = find.text('Reply');
      expect(title, findsOneWidget);
      expect(tester.getTopLeft(title).dx, lessThan(60));
      final titleCenter = tester.getCenter(title).dx;
      final appBarCenter = tester.getCenter(find.byType(AppBar)).dx;
      expect(titleCenter, lessThan(appBarCenter - 80));
    },
  );

  testWidgets(
    'AppPage header keeps its physical height when Display Size shrinks',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      Widget page() => const MaterialApp(
        home: AppPage(title: 'Fixed header', child: SizedBox.shrink()),
      );

      await tester.pumpWidget(page());
      final normalPhysicalHeight =
          tester.getSize(find.byType(AppBar)).height *
          tester.view.devicePixelRatio;

      // Android's smaller Display Size exposes more logical pixels by lowering
      // DPR while physical screen dimensions stay unchanged.
      tester.view.devicePixelRatio = 2.5;
      await tester.pumpWidget(page());
      final smallerDisplayPhysicalHeight =
          tester.getSize(find.byType(AppBar)).height *
          tester.view.devicePixelRatio;

      expect(smallerDisplayPhysicalHeight, closeTo(normalPhysicalHeight, 0.1));
    },
  );
}
