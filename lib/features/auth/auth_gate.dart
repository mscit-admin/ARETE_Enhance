import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../shell/app_shell.dart';
import 'auth_screen.dart';

/// Routes between the auth screen and the app based on session state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;
    return switch (status) {
      AuthStatus.unknown =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.unauthenticated => const AuthScreen(),
      AuthStatus.authenticated => const AppShell(),
    };
  }
}
