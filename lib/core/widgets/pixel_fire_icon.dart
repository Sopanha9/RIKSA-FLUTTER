import 'package:flutter/material.dart';

class PixelFireIcon extends StatelessWidget {
  const PixelFireIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: const _PixelFirePainter()),
  );
}

class _PixelFirePainter extends CustomPainter {
  const _PixelFirePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32, size.height / 32);

    final ember = _fill(const Color(0xFF6E1F0D));
    final outline = _fill(const Color(0xFF9F2B12));
    final red = _fill(const Color(0xFFE6411E));
    final orange = _fill(const Color(0xFFFF6A22));
    final gold = _fill(const Color(0xFFFFBA24));
    final cream = _fill(const Color(0xFFFFF0A0));

    canvas.drawRect(const Rect.fromLTWH(16, 2, 3, 4), outline);
    canvas.drawRect(const Rect.fromLTWH(14, 6, 6, 3), outline);
    canvas.drawRect(const Rect.fromLTWH(12, 9, 9, 4), outline);
    canvas.drawRect(const Rect.fromLTWH(9, 13, 13, 4), outline);
    canvas.drawRect(const Rect.fromLTWH(7, 17, 17, 5), outline);
    canvas.drawRect(const Rect.fromLTWH(6, 22, 19, 4), ember);
    canvas.drawRect(const Rect.fromLTWH(9, 26, 13, 3), ember);

    canvas.drawRect(const Rect.fromLTWH(17, 6, 2, 4), red);
    canvas.drawRect(const Rect.fromLTWH(15, 9, 5, 5), red);
    canvas.drawRect(const Rect.fromLTWH(12, 13, 8, 5), red);
    canvas.drawRect(const Rect.fromLTWH(9, 18, 13, 5), red);
    canvas.drawRect(const Rect.fromLTWH(11, 23, 9, 3), red);

    canvas.drawRect(const Rect.fromLTWH(10, 11, 3, 5), orange);
    canvas.drawRect(const Rect.fromLTWH(20, 14, 3, 6), orange);
    canvas.drawRect(const Rect.fromLTWH(13, 14, 7, 7), orange);
    canvas.drawRect(const Rect.fromLTWH(11, 21, 10, 4), orange);

    canvas.drawRect(const Rect.fromLTWH(16, 13, 3, 5), gold);
    canvas.drawRect(const Rect.fromLTWH(14, 18, 6, 5), gold);
    canvas.drawRect(const Rect.fromLTWH(15, 23, 3, 2), gold);

    canvas.drawRect(const Rect.fromLTWH(17, 17, 1, 4), cream);
    canvas.drawRect(const Rect.fromLTWH(16, 21, 2, 2), cream);
  }

  static Paint _fill(Color color) => Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.fill
    ..color = color;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
