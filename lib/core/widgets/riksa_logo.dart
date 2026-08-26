import 'package:flutter/material.dart';

/// Riksa logo as a styled text wordmark — no asset dependency.
class RiksaLogo extends StatelessWidget {
  const RiksaLogo({super.key, this.fontSize = 36, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final primary =
        color ?? (dark ? theme.colorScheme.primary : const Color(0xFF1B4332));
    final accent =
        color ?? (dark ? theme.colorScheme.secondary : const Color(0xFFB5828C));
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: primary,
        ),
        children: [
          TextSpan(
            text: 'Rik',
            style: TextStyle(color: primary),
          ),
          TextSpan(
            text: 'sa',
            style: TextStyle(color: accent),
          ),
        ],
      ),
    );
  }
}
