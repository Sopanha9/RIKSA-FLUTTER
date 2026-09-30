import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Adds a press response without taking ownership of the child's tap, keyboard
/// activation or semantics. Scrolling and cancelled pointers release the press.
class RiksaTapFeedback extends StatefulWidget {
  const RiksaTapFeedback({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<RiksaTapFeedback> createState() => _RiksaTapFeedbackState();
}

class _RiksaTapFeedbackState extends State<RiksaTapFeedback> {
  int? _pointer;
  Offset? _origin;

  void _release() {
    if (_pointer == null) return;
    setState(() {
      _pointer = null;
      _origin = null;
    });
  }

  @override
  void didUpdateWidget(covariant RiksaTapFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pointer = null;
      _origin = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final animate = widget.enabled && !MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (event) {
        if (!animate || _pointer != null) return;
        setState(() {
          _pointer = event.pointer;
          _origin = event.position;
        });
      },
      onPointerMove: (event) {
        if (event.pointer == _pointer &&
            (event.position - _origin!).distance > 8) {
          _release();
        }
      },
      onPointerUp: (event) {
        if (event.pointer == _pointer) _release();
      },
      onPointerCancel: (event) {
        if (event.pointer == _pointer) _release();
      },
      child: AnimatedScale(
        scale: animate && _pointer != null ? .97 : 1,
        duration: RiksaMotion.resolve(context, RiksaMotion.fast),
        curve: RiksaMotion.standardCurve,
        child: widget.child,
      ),
    );
  }
}

/// A short arrival for changed content. The wrapper stays in the tree so text
/// fields keep focus and selection; no outgoing, still-tappable copy is kept.
class RiksaContentReveal extends StatefulWidget {
  const RiksaContentReveal({
    super.key,
    required this.identity,
    required this.child,
  });
  final Object identity;
  final Widget child;

  @override
  State<RiksaContentReveal> createState() => _RiksaContentRevealState();
}

class _RiksaContentRevealState extends State<RiksaContentReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: RiksaMotion.standard,
  );
  late final _progress = _controller.drive(
    CurveTween(curve: RiksaMotion.standardCurve),
  );

  void _arrive() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant RiksaContentReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) _arrive();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _progress,
    child: SlideTransition(
      position: _progress.drive(
        Tween(begin: const Offset(0, .025), end: Offset.zero),
      ),
      child: widget.child,
    ),
  );
}

/// A single drawn check for a confirmed success, never a looping celebration.
class RiksaSuccessMark extends StatelessWidget {
  const RiksaSuccessMark({super.key, required this.label, this.size = 48});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reduced ? 1 : 0, end: 1),
          duration: RiksaMotion.resolve(context, RiksaMotion.emphasis),
          curve: RiksaMotion.standardCurve,
          builder: (context, progress, _) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: context.riksa.jade,
              borderRadius: BorderRadius.circular(size * .34),
            ),
            child: CustomPaint(
              painter: _CheckPainter(
                progress: reduced ? 1 : progress,
                color: context.riksa.onJade,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .28, size.height * .51)
      ..lineTo(size.width * .44, size.height * .67)
      ..lineTo(size.width * .74, size.height * .34);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .065
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
