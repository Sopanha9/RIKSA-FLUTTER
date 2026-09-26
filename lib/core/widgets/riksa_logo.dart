import 'package:flutter/material.dart';

import 'riksa_brand.dart';

/// Riksa logo. Kept as the app-wide entry point; it draws [RiksaWordmark].
class RiksaLogo extends StatelessWidget {
  const RiksaLogo({super.key, this.fontSize = 36, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      RiksaWordmark(fontSize: fontSize, color: color);
}
