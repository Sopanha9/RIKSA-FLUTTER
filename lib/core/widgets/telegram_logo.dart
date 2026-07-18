import 'package:flutter/material.dart';

/// Telegram logo from asset.
class TelegramLogo extends StatelessWidget {
  const TelegramLogo({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logos/tglogo.png',
      width: size,
      height: size,
    );
  }
}