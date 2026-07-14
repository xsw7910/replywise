import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replywise/l10n/app_localizations.dart';

/// Regression test for the "Use template" guidance chip.
///
/// The label used to be composed as `use + useATemplate` ("Use" + "template").
/// That duplicated the verb in every language where `useATemplate` is already
/// a complete "Use a template" phrase (e.g. zh produced "使用 使用模板").
/// The chip now uses the self-contained `useATemplate` string directly, so
/// every locale must render one clean phrase with no doubled adjacent word.
void main() {
  test('useATemplate reads as one clean phrase in every supported locale',
      () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final label = l10n.useATemplate;

      expect(label.trim(), isNotEmpty, reason: 'empty for ${locale.toString()}');

      // No word appears twice in a row (catches "使用 使用模板", "Usar usar…",
      // "Use use template", etc.). Whitespace-delimited works for the Latin,
      // Cyrillic, and spaced scripts; CJK is asserted explicitly below.
      final words = label
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      for (var i = 1; i < words.length; i++) {
        expect(
          words[i].toLowerCase(),
          isNot(words[i - 1].toLowerCase()),
          reason: 'duplicated word "${words[i]}" in ${locale.toString()}: '
              '"$label"',
        );
      }

      // The old bug prepended the standalone verb `use` in front of a phrase
      // that already began with it. Assert the label does not start with the
      // verb twice.
      final verb = l10n.use.trim();
      expect(
        label.startsWith('$verb $verb'),
        isFalse,
        reason: 'verb duplicated in ${locale.toString()}: "$label"',
      );
    }
  });

  test('English useATemplate is the complete "Use template" phrase', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(l10n.useATemplate, 'Use template');
  });

  test('Simplified Chinese useATemplate is 使用模板 with no duplication',
      () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(l10n.useATemplate, '使用模板');
    expect(l10n.useATemplate.contains('使用 使用'), isFalse);
  });
}
