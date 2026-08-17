import 'package:flutter/material.dart';

/// A full-width primary action button with an optional loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        style: style,
        onPressed: loading ? null : onPressed,
        icon: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Icon(icon),
        label: Text(label),
      );
    }

    return ElevatedButton(
      style: style,
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
