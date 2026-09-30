import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Riksa wordmark: a heavy slanted name over a lime brush stroke, with
/// three violet sparks off the last letter.
class RiksaWordmark extends StatelessWidget {
  const RiksaWordmark({super.key, this.fontSize = 44, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final ink = color ?? palette.ink;
    return Semantics(
      label: 'Riksa',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(
            top: fontSize * .22,
            right: fontSize * .32,
            bottom: fontSize * .06,
          ),
          child: CustomPaint(
            foregroundPainter: _SparkPainter(palette.brand),
            painter: _SwooshPainter(AppColors.lime),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(-.16),
              child: Text(
                'Riksa',
                style: TextStyle(
                  fontFamily: RiksaTypography.latinFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -fontSize * .045,
                  height: 1.05,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwooshPainter extends CustomPainter {
  const _SwooshPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = h * .13;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    final path = Path()
      ..moveTo(w * .02, h * .98)
      ..quadraticBezierTo(w * .45, h * .86, w * 1.02, h * .8);
    canvas.drawPath(path, paint);
    // A thinner second pass gives the stroke its dry-brush tail.
    canvas.drawPath(
      Path()
        ..moveTo(w * .16, h * 1.06)
        ..quadraticBezierTo(w * .5, h * .97, w * .9, h * .92),
      paint
        ..strokeWidth = stroke * .45
        ..color = color.withValues(alpha: .85),
    );
  }

  @override
  bool shouldRepaint(_SwooshPainter oldDelegate) => oldDelegate.color != color;
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final origin = Offset(size.width - h * .06, h * .3);
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * .06;
    for (final (angle, length) in [(-1.4, .16), (-.8, .18), (-.2, .14)]) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      final start = origin + direction * h * .22;
      final end = origin + direction * h * (.22 + length);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => oldDelegate.color != color;
}

enum RiksaMascotPose { happy, wink, mail, pencil }

/// Riksa's mascot: a round violet study buddy with an antenna.
class RiksaMascot extends StatelessWidget {
  const RiksaMascot({
    super.key,
    this.size = 96,
    this.pose = RiksaMascotPose.happy,
    this.showSparkles = true,
  });

  final double size;
  final RiksaMascotPose pose;
  final bool showSparkles;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MascotPainter(pose, showSparkles)),
    ),
  );
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter(this.pose, this.sparkles);
  final RiksaMascotPose pose;
  final bool sparkles;

  static const _bodyLight = Color(0xFFC3B2FF);
  static const _bodyDark = Color(0xFF8566F2);
  static const _eye = AppColors.ink;
  static const _blush = Color(0xFFFF9BC6);
  static const _spark = AppColors.editorialPink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    // Shadow.
    canvas.drawOval(
      const Rect.fromLTWH(22, 90, 56, 7),
      Paint()..color = _bodyDark.withValues(alpha: .16),
    );

    if (sparkles) _drawSparkles(canvas);

    // Antenna.
    final antenna = Paint()
      ..color = _bodyDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(50, 22)
        ..quadraticBezierTo(49, 13, 54, 8),
      antenna,
    );
    canvas.drawCircle(const Offset(55, 7), 4.6, Paint()..color = _bodyDark);
    canvas.drawCircle(
      const Offset(53.6, 5.6),
      1.5,
      Paint()..color = Colors.white.withValues(alpha: .7),
    );

    // Arms sit behind the body.
    final armPaint = Paint()..color = _bodyDark;
    canvas.drawOval(const Rect.fromLTWH(8, 58, 14, 18), armPaint);
    canvas.drawOval(const Rect.fromLTWH(78, 58, 14, 18), armPaint);

    // Body: a soft blob with little bumps along the bottom.
    final body = Path()
      ..moveTo(50, 20)
      ..cubicTo(76, 20, 90, 40, 89, 64)
      ..cubicTo(89, 76, 86, 86, 78, 88)
      ..cubicTo(72, 90, 68, 86, 62, 88)
      ..cubicTo(56, 92, 44, 92, 38, 88)
      ..cubicTo(32, 86, 28, 90, 22, 88)
      ..cubicTo(14, 86, 11, 76, 11, 64)
      ..cubicTo(10, 40, 24, 20, 50, 20)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bodyLight, _bodyDark],
        ).createShader(const Rect.fromLTWH(10, 20, 80, 72)),
    );
    // Soft top highlight.
    canvas.drawOval(
      const Rect.fromLTWH(26, 26, 26, 12),
      Paint()..color = Colors.white.withValues(alpha: .28),
    );

    // Blush.
    final blush = Paint()..color = _blush.withValues(alpha: .75);
    canvas.drawOval(const Rect.fromLTWH(22, 60, 12, 7), blush);
    canvas.drawOval(const Rect.fromLTWH(66, 60, 12, 7), blush);

    // Eyes.
    final eye = Paint()..color = _eye;
    final glint = Paint()..color = Colors.white;
    canvas.drawOval(const Rect.fromLTWH(33, 45, 11, 14), eye);
    canvas.drawCircle(const Offset(40.5, 49), 2.6, glint);
    canvas.drawCircle(const Offset(36.5, 55), 1.2, glint);
    if (pose == RiksaMascotPose.wink) {
      canvas.drawPath(
        Path()
          ..moveTo(56, 53)
          ..quadraticBezierTo(61.5, 46, 67, 53),
        Paint()
          ..color = _eye
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawOval(const Rect.fromLTWH(56, 45, 11, 14), eye);
      canvas.drawCircle(const Offset(63.5, 49), 2.6, glint);
      canvas.drawCircle(const Offset(59.5, 55), 1.2, glint);
    }

    // Open smile with a tongue.
    final mouth = Path()
      ..moveTo(44, 63)
      ..quadraticBezierTo(50, 64.5, 56, 63)
      ..quadraticBezierTo(55, 72, 50, 72)
      ..quadraticBezierTo(45, 72, 44, 63)
      ..close();
    canvas.drawPath(mouth, eye);
    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawOval(
      const Rect.fromLTWH(45.5, 67, 9, 7),
      Paint()..color = const Color(0xFFFF7FB0),
    );
    canvas.restore();

    switch (pose) {
      case RiksaMascotPose.mail:
        _drawEnvelope(canvas);
      case RiksaMascotPose.pencil:
        _drawPencil(canvas);
      case RiksaMascotPose.happy:
      case RiksaMascotPose.wink:
        break;
    }
    canvas.restore();
  }

  void _drawSparkles(Canvas canvas) {
    final paint = Paint()
      ..color = _spark
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(10, 26), const Offset(15, 30), paint);
    canvas.drawLine(const Offset(6, 38), const Offset(12, 39), paint);
    canvas.drawLine(const Offset(90, 26), const Offset(85, 30), paint);
    canvas.drawLine(const Offset(94, 38), const Offset(88, 39), paint);
    canvas.drawLine(const Offset(80, 14), const Offset(77, 19), paint);
  }

  void _drawEnvelope(Canvas canvas) {
    const rect = Rect.fromLTWH(30, 68, 40, 27);
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(r, Paint()..color = Colors.white);
    final line = Paint()
      ..color = _bodyDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(r, line);
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + 1, rect.top + 2)
        ..lineTo(rect.center.dx, rect.top + 15)
        ..lineTo(rect.right - 1, rect.top + 2),
      line,
    );
    // Hands holding the envelope.
    final hand = Paint()..color = _bodyDark;
    canvas.drawCircle(Offset(rect.left, rect.center.dy + 4), 5, hand);
    canvas.drawCircle(Offset(rect.right, rect.center.dy + 4), 5, hand);
  }

  void _drawPencil(Canvas canvas) {
    canvas.save();
    canvas.translate(80, 70);
    canvas.rotate(-.75);
    const body = Rect.fromLTWH(-4, -26, 8, 34);
    canvas.drawRect(body, Paint()..color = const Color(0xFFFFD35C));
    canvas.drawRect(
      const Rect.fromLTWH(-4, -32, 8, 6),
      Paint()..color = const Color(0xFFFF8FB8),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-4, -27, 8, 2),
      Paint()..color = const Color(0xFFB9B4C8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-4, 8)
        ..lineTo(4, 8)
        ..lineTo(0, 16)
        ..close(),
      Paint()..color = const Color(0xFFF3D9B1),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-1.4, 13)
        ..lineTo(1.4, 13)
        ..lineTo(0, 16)
        ..close(),
      Paint()..color = _eye,
    );
    canvas.restore();
    canvas.drawCircle(const Offset(80, 70), 5.5, Paint()..color = _bodyDark);
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.sparkles != sparkles;
}

enum RiksaDoodleKind { star, sparkle, arrow, crown, heart, squiggle, globe, plane }

/// Hand-drawn decorative marks used around headings and illustrations.
class RiksaDoodle extends StatelessWidget {
  const RiksaDoodle(this.kind, {super.key, this.size = 28, this.color});

  final RiksaDoodleKind kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DoodlePainter(kind, color ?? context.riksa.brand),
      ),
    ),
  );
}

class _DoodlePainter extends CustomPainter {
  const _DoodlePainter(this.kind, this.color);
  final RiksaDoodleKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case RiksaDoodleKind.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final radius = i.isEven ? 10.5 : 4.2;
          final angle = -math.pi / 2 + i * math.pi / 5;
          final point =
              Offset(12 + radius * math.cos(angle), 12.5 + radius * math.sin(angle));
          i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path..close(), stroke);
      case RiksaDoodleKind.sparkle:
        final path = Path()
          ..moveTo(12, 1)
          ..quadraticBezierTo(13, 11, 23, 12)
          ..quadraticBezierTo(13, 13, 12, 23)
          ..quadraticBezierTo(11, 13, 1, 12)
          ..quadraticBezierTo(11, 11, 12, 1)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
      case RiksaDoodleKind.arrow:
        canvas.drawPath(
          Path()
            ..moveTo(2, 16)
            ..quadraticBezierTo(10, 6, 21, 10),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(16, 5.5)
            ..lineTo(21.5, 10)
            ..lineTo(15.5, 13.5),
          stroke,
        );
      case RiksaDoodleKind.crown:
        canvas.drawPath(
          Path()
            ..moveTo(3, 18)
            ..lineTo(2, 7)
            ..lineTo(8, 12)
            ..lineTo(12, 4)
            ..lineTo(16, 12)
            ..lineTo(22, 7)
            ..lineTo(21, 18)
            ..close(),
          stroke,
        );
      case RiksaDoodleKind.heart:
        canvas.drawPath(
          Path()
            ..moveTo(12, 20.5)
            ..cubicTo(3, 14, 1, 9, 4, 5.5)
            ..cubicTo(7, 2.5, 11, 4, 12, 7.5)
            ..cubicTo(13, 4, 17, 2.5, 20, 5.5)
            ..cubicTo(23, 9, 21, 14, 12, 20.5),
          stroke,
        );
      case RiksaDoodleKind.squiggle:
        canvas.drawPath(
          Path()
            ..moveTo(2, 15)
            ..cubicTo(5, 7, 8, 7, 9, 13)
            ..cubicTo(10, 19, 14, 17, 15, 11)
            ..cubicTo(16, 5, 21, 7, 22, 10),
          stroke,
        );
      case RiksaDoodleKind.globe:
        canvas.drawCircle(const Offset(12, 12), 10, stroke);
        canvas.drawOval(const Rect.fromLTWH(7, 2, 10, 20), stroke);
        canvas.drawLine(const Offset(2, 12), const Offset(22, 12), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4, 7)
            ..quadraticBezierTo(12, 9, 20, 7)
            ..moveTo(4, 17)
            ..quadraticBezierTo(12, 15, 20, 17),
          stroke,
        );
      case RiksaDoodleKind.plane:
        canvas.drawPath(
          Path()
            ..moveTo(2, 11)
            ..lineTo(22, 3)
            ..lineTo(15, 21)
            ..lineTo(11, 13)
            ..close()
            ..moveTo(11, 13)
            ..lineTo(22, 3),
          stroke,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoodlePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

/// A rounded pastel square holding a line icon, as on the subject grid.
class RiksaIconTile extends StatelessWidget {
  const RiksaIconTile({
    super.key,
    required this.icon,
    required this.background,
    this.foreground,
    this.size = 56,
    this.iconSize,
  });

  final IconData icon;
  final Color background;
  final Color? foreground;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? Color.lerp(background, context.riksa.surfaceRaised, .82) : background,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize ?? size * .5,
        color: foreground ?? context.riksa.ink,
      ),
    );
  }
}
