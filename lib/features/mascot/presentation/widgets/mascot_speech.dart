import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Where the bubble's tail points: down at a buddy below it, or left at a
/// buddy beside it.
enum SpeechTail { down, left }

/// What the buddy is saying, typed out whenever [line] changes.
///
/// The full line is laid out invisibly underneath, so the bubble takes its
/// final size at once and nothing around it shifts while it types.
class MascotSpeechBubble extends StatelessWidget {
  const MascotSpeechBubble({
    super.key,
    required this.line,
    this.tail = SpeechTail.down,
    this.maxWidth = 280,
    this.textAlign = TextAlign.center,
    this.style,
  });

  final String line;
  final SpeechTail tail;
  final double maxWidth;
  final TextAlign textAlign;
  final TextStyle? style;

  static const _tailSize = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final length = line.characters.length;
    final textStyle = RiksaTypography.bodyStyleFor(
      line,
      style ??
          theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );
    return Semantics(
      liveRegion: true,
      label: line,
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _TailPainter(
            tail: tail,
            fill: palette.surface,
            border: palette.outline,
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            margin: switch (tail) {
              SpeechTail.down => const EdgeInsets.only(bottom: _tailSize),
              SpeechTail.left => const EdgeInsets.only(left: _tailSize),
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.outline),
              boxShadow: [
                BoxShadow(
                  color: palette.brand.withValues(alpha: .08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(line),
              tween: Tween(begin: reduce ? 1 : 0, end: 1),
              duration: Duration(milliseconds: 24 * length),
              builder: (context, progress, _) {
                final shown = line.characters
                    .take((length * progress).ceil())
                    .toString();
                return Stack(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: Text(line, textAlign: textAlign, style: textStyle),
                    ),
                    Positioned.fill(
                      child: Text(
                        shown,
                        textAlign: textAlign,
                        style: textStyle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({
    required this.tail,
    required this.fill,
    required this.border,
  });

  final SpeechTail tail;
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    const t = MascotSpeechBubble._tailSize;
    final path = Path();
    switch (tail) {
      case SpeechTail.down:
        final x = size.width / 2;
        final y = size.height - t - 1;
        path
          ..moveTo(x - 9, y)
          ..lineTo(x, y + t)
          ..lineTo(x + 9, y);
      case SpeechTail.left:
        final x = t + 1;
        final y = size.height * .62;
        path
          ..moveTo(x, y - 8)
          ..lineTo(x - t, y + 4)
          ..lineTo(x, y + 6);
    }
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.tail != tail || old.fill != fill || old.border != border;
}
