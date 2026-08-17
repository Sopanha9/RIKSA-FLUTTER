import 'package:flutter/material.dart';

/// Shows a themed snackbar. Pass [isError] for error-styled feedback.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.onSurface,
      ),
    );
}
