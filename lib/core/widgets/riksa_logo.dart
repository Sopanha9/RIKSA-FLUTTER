import 'package:flutter/material.dart';

/// Riksa logo as a styled text wordmark — no asset dependency.
class RiksaLogo extends StatelessWidget {
  const RiksaLogo({super.key, this.fontSize = 36, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: color ?? const Color(0xFF1B4332),
        ),
        children: const [
          TextSpan(
            text: 'Rik',
            style: TextStyle(color: Color(0xFF1B4332)),
          ),
          TextSpan(
            text: 'sa',
            style: TextStyle(color: Color(0xFFB5828C)),
          ),
        ],
      ),
    );
  }
}
