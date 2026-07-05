import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/guidance/data/guidance_library_repository.dart';

const localePreferenceKey = 'replywise_locale';

class AppLocaleOption {
  const AppLocaleOption(this.code, this.nativeName);

  final String code;
  final String nativeName;
}

const appLocaleOptions = <AppLocaleOption>[
  AppLocaleOption('system', 'System default'),
  AppLocaleOption('en', 'English'),
  AppLocaleOption('zh', '简体中文'),
  AppLocaleOption('zh_Hant', '繁體中文'),
  AppLocaleOption('es', 'Español'),
  AppLocaleOption('fr', 'Français'),
  AppLocaleOption('pt', 'Português'),
  AppLocaleOption('de', 'Deutsch'),
  AppLocaleOption('ja', '日本語'),
  AppLocaleOption('ko', '한국어'),
  AppLocaleOption('hi', 'हिन्दी'),
  AppLocaleOption('ar', 'العربية'),
  AppLocaleOption('it', 'Italiano'),
  AppLocaleOption('id', 'Bahasa Indonesia'),
  AppLocaleOption('vi', 'Tiếng Việt'),
  AppLocaleOption('th', 'ไทย'),
  AppLocaleOption('tr', 'Türkçe'),
  AppLocaleOption('nl', 'Nederlands'),
  AppLocaleOption('pl', 'Polski'),
  AppLocaleOption('ru', 'Русский'),
  AppLocaleOption('uk', 'Українська'),
];

Locale? localeFromPreference(String code) {
  if (code == 'system') return null;
  if (code == 'zh_Hant') {
    return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  }
  return Locale(code);
}

class LocaleController extends StateNotifier<String> {
  LocaleController(this._prefs)
    : super(_validCode(_prefs.getString(localePreferenceKey)));

  final SharedPreferences _prefs;

  static String _validCode(String? value) {
    return appLocaleOptions.any((option) => option.code == value)
        ? value!
        : 'system';
  }

  Future<void> select(String code) async {
    final validCode = _validCode(code);
    state = validCode;
    await _prefs.setString(localePreferenceKey, validCode);
  }
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, String>((ref) {
      return LocaleController(ref.watch(sharedPreferencesProvider));
    });
