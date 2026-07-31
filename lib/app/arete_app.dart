import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/shell/app_shell.dart';
import '../state/session_controller.dart';

class AreteApp extends StatelessWidget {
  const AreteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    final ThemeMode themeMode = session.followSystemTheme
        ? ThemeMode.system
        : (session.isDark ? ThemeMode.dark : ThemeMode.light);

    return MaterialApp(
      title: 'ARETE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
