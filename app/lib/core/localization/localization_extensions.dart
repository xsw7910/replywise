import 'package:flutter/widgets.dart';
import 'package:replywise/l10n/app_localizations.dart';
import 'package:replywise/l10n/app_localizations_en.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}
