/// Localization configuration
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';

class L10n {
  L10n._();

  static const List<Locale> supportedLocales = [
    Locale('id'), // Indonesian
    Locale('en'), // English
  ];

  static const Locale defaultLocale = Locale('id');

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
    AppLocalizations.delegate,
  ];

  static AppLocalizations? of(BuildContext context) {
    return AppLocalizations.of(context);
  }
}

/// Extension for easy access to localization
extension LocalizationExtension on BuildContext {
  AppLocalizations? get l10n => AppLocalizations.of(this);
}
