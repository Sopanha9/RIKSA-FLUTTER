import 'package:flutter/material.dart';

/// A full-width secondary (outlined) action button with an optional loading state.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: colorScheme.outline),
    );

    if (icon != null) {
      return OutlinedButton.icon(
        style: style,
        onPressed: loading ? null : onPressed,
        icon: loading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            : Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton(
      style: style,
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Text(label),
    );
  }
}
