import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's selected language. A null [locale] means "follow the
/// device" (the platform locale, falling back to the first supported one).
///
/// Arabic automatically flips the whole app to right-to-left — MaterialApp
/// derives text direction from the active locale, so no extra wiring is needed.
class LocaleController extends ChangeNotifier {
  LocaleController() {
    _restore();
  }

  static const _prefsKey = 'app_locale';

  /// Languages the app ships. Order also drives the picker.
  static const supported = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
  ];

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supported.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
