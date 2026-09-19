import 'package:flutter/material.dart';

import 'auth_switcher_screen.dart';

/// Backward-compatible entry point for callers that still import LoginScreen.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthSwitcherScreen();
  }
}
