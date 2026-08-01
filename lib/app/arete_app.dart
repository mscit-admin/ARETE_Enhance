import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/auth_gate.dart';
import '../l10n/app_localizations.dart';
import '../state/locale_controller.dart';
import '../state/session_controller.dart';

class AreteApp extends StatelessWidget {
  const AreteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final localeController = context.watch<LocaleController>();

    final ThemeMode themeMode = session.followSystemTheme
        ? ThemeMode.system
        : (session.isDark ? ThemeMode.dark : ThemeMode.light);

    return MaterialApp(
      title: 'ARETE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // Language: a null locale follows the device; Arabic flips to RTL
      // automatically via MaterialApp's directionality resolution.
      locale: localeController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const AuthGate(),
    );
  }
}
