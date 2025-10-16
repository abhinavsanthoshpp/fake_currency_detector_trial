import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void _loadLocale() {
    final box = Hive.box('settings');
    final savedLocale = box.get(_localeKey, defaultValue: 'en');
    _locale = Locale(savedLocale);
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    final box = Hive.box('settings');
    await box.put(_localeKey, newLocale.languageCode);
    notifyListeners();
  }
}
