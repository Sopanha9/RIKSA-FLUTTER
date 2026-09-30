import 'package:flutter/material.dart';

import 'auth_switcher_screen.dart';

/// Backward-compatible entry point for callers that still import RegisterScreen.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthSwitcherScreen(initialPage: PageState.register);
  }
}
