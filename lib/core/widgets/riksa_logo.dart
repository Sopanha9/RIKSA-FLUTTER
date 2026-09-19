import 'package:flutter/material.dart';

/// Riksa logo as a styled text wordmark — no asset dependency.
class RiksaLogo extends StatelessWidget {
  const RiksaLogo({super.key, this.fontSize = 36, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          fontFamily: 'Poppins',
        );

    final overrideColor = color;

    return Text.rich(
      TextSpan(
        style: defaultStyle,
        children: [
          TextSpan(
            text: 'Rik',
            style: TextStyle(
              color: overrideColor ?? const Color(0xFF1B4332),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'sa',
            style: TextStyle(
              color: overrideColor ?? const Color(0xFFB5828C),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}