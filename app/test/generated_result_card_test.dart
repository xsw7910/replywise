import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/core/share/share_helper.dart';
import 'package:replywise/core/theme/app_feature_theme.dart';
import 'package:replywise/core/widgets/generated_result_card.dart';
import 'package:replywise/l10n/app_localizations.dart';

void main() {
  testWidgets('share button is disabled for empty generated text', (
    tester,
  ) async {
    var shareCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generatedTextSharerProvider.overrideWithValue((
            text, {
            String? subject,
          }) async {
            shareCalls++;
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GeneratedResultCard(
              label: 'Empty',
              text: '   ',
              feature: AppFeature.reply,
              shareTooltip: 'Share reply',
            ),
          ),
        ),
      ),
    );

    final shareButton = tester.widget<IconButton>(
      find.byKey(const Key('result-share-button')),
    );
    expect(shareButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('result-share-button')));
    await tester.pumpAndSettle();
    expect(shareCalls, 0);
  });
}
