import 'package:flutter/material.dart';

import '../../../core/widgets/google_logo.dart';

Widget buildGoogleProviderButton({
  required String label,
  required String locale,
  required bool loading,
  required VoidCallback onPressed,
}) {
  return OutlinedButton.icon(
    key: const Key('google_auth_button'),
    onPressed: loading ? null : onPressed,
    icon: loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : const GoogleLogo(size: 20),
    label: Text(label),
  );
}
