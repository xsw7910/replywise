import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replywise/core/localization/locale_controller.dart';
import 'package:replywise/core/localization/localization_extensions.dart';
import 'package:replywise/features/guidance/data/guidance_library_repository.dart';
import 'package:replywise/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to system and persists an explicit locale', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), 'system');
    expect(
      localeFromPreference(container.read(localeControllerProvider)),
      isNull,
    );

    await container.read(localeControllerProvider.notifier).select('zh_Hant');

    expect(container.read(localeControllerProvider), 'zh_Hant');
    expect(prefs.getString(localePreferenceKey), 'zh_Hant');
    expect(
      localeFromPreference('zh_Hant'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
  });

  test('declares all 20 supported locales', () {
    expect(AppLocalizations.supportedLocales, hasLength(20));
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
    );
    expect(AppLocalizations.supportedLocales, contains(const Locale('ar')));
  });

  testWidgets('changing locale rebuilds the app immediately', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: Consumer(
          builder: (context, ref, _) {
            final preference = ref.watch(localeControllerProvider);
            return MaterialApp(
              locale: localeFromPreference(preference),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) =>
                    Scaffold(body: Text(context.l10n.settings)),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    final context = tester.element(find.byType(MaterialApp));
    final container = ProviderScope.containerOf(context);
    await container.read(localeControllerProvider.notifier).select('zh');
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('Arabic selection enables RTL directionality', (tester) async {
    SharedPreferences.setMockInitialValues({localePreferenceKey: 'ar'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: localeFromPreference(ref.watch(localeControllerProvider)),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Text('RTL')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.text('RTL'))),
      TextDirection.rtl,
    );
  });
}
