import 'package:flutter/material.dart';

/// Google "G" logo from asset.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logos/google.svg.png',
      width: size,
      height: size,
    );
  }
}