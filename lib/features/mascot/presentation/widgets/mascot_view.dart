import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/mascot.dart';
import 'sprite_frames.dart';

/// Drives what a [MascotView] is doing.
///
/// [mood] is the resting state the mascot loops in. [react] plays another
/// mood for a moment and then falls back to it, which is how screens make
/// the buddy respond to the learner: a correct answer, a streak, a tap.
class MascotController extends ChangeNotifier {
  MascotController([this._mood = MascotMood.idle]);

  MascotMood _mood;
  MascotMood? _reaction;
  Timer? _reactionTimer;
  int _generation = 0;

  MascotMood get mood => _mood;

  /// The mood on screen right now: the reaction if one is playing.
  MascotMood get current => _reaction ?? _mood;
  bool get isReacting => _reaction != null;

  /// Bumps whenever [current] restarts, so the view resets its mood clock
  /// even when the same reaction plays twice in a row.
  int get generation => _generation;

  set mood(MascotMood value) {
    if (value == _mood && _reaction == null) return;
    _mood = value;
    _clearReaction();
    _restart();
  }

  /// Plays [mood] once through (or for [duration]) and returns to the
  /// resting mood.
  void react(MascotMood mood, {Duration? duration}) {
    _reactionTimer?.cancel();
    _reaction = mood;
    _restart();
    _reactionTimer = Timer(duration ?? MascotSprites.loopDuration(mood), () {
      _reaction = null;
      _restart();
    });
  }

  void _clearReaction() {
    _reactionTimer?.cancel();
    _reactionTimer = null;
    _reaction = null;
  }

  void _restart() {
    _generation++;
    notifyListeners();
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    super.dispose();
  }
}

/// A living mascot: sprite frames for the pose, with breathing, hops, tilts
/// and particles layered on top so every mood keeps moving.
///
/// With [alive] set, a resting mascot fidgets on its own every few seconds
/// and dozes off when nobody has touched it for a while. With [interactive]
/// set, a tap makes it react (and wakes it). Under reduced motion it shows
/// the first frame of the current mood and nothing moves.
class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    required this.species,
    this.size = 160,
    this.mood = MascotMood.idle,
    this.controller,
    this.alive = true,
    this.interactive = false,
    this.semanticLabel,
  });

  final MascotSpecies species;

  /// Width of the character. The widget is a little taller, to leave room
  /// for hops and for the particles above its head.
  final double size;

  /// Resting mood when no [controller] is given.
  final MascotMood mood;
  final MascotController? controller;
  final bool alive;
  final bool interactive;
  final String? semanticLabel;

  static const heightFactor = 1.25;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView>
    with SingleTickerProviderStateMixin {
  static const _dozeAfter = Duration(seconds: 40);
  static const _fidgets = [
    MascotMood.happy,
    MascotMood.thinking,
    MascotMood.greeting,
  ];

  late final Ticker _ticker = createTicker(_onTick);
  final _elapsed = ValueNotifier(Duration.zero);
  final _random = math.Random();
  MascotController? _ownController;
  Duration _moodStart = Duration.zero;
  Duration _lastInteraction = Duration.zero;
  Duration? _nextFidget;
  int _seenGeneration = -1;
  bool _dozed = false;
  bool _reduceMotion = false;

  MascotController get _controller => widget.controller ?? _ownController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownController = MascotController(widget.mood);
    }
    _controller.addListener(_onMoodChanged);
    _seenGeneration = _controller.generation;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
    _precache();
  }

  @override
  void didUpdateWidget(MascotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onMoodChanged);
      if (widget.controller == null) {
        _ownController ??= MascotController(widget.mood);
      }
      _controller.addListener(_onMoodChanged);
      _onMoodChanged();
    }
    if (widget.controller == null && oldWidget.mood != widget.mood) {
      _controller.mood = widget.mood;
    }
    if (oldWidget.species != widget.species) _precache();
  }

  void _precache() {
    for (final frame in MascotSprites.allFrames(widget.species)) {
      unawaited(precacheImage(AssetImage(frame), context));
    }
  }

  void _onMoodChanged() {
    if (_controller.generation == _seenGeneration) return;
    _seenGeneration = _controller.generation;
    _moodStart = _elapsed.value;
    _nextFidget = null;
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed;
    if (!widget.alive) return;
    final controller = _controller;
    if (controller.isReacting || controller.mood != MascotMood.idle) return;

    if (elapsed - _lastInteraction > _dozeAfter) {
      _dozed = true;
      controller.mood = MascotMood.sleep;
      return;
    }
    _nextFidget ??=
        elapsed + Duration(milliseconds: 10000 + _random.nextInt(6000));
    if (elapsed >= _nextFidget!) {
      controller.react(_fidgets[_random.nextInt(_fidgets.length)]);
    }
  }

  void _handleTap() {
    _lastInteraction = _elapsed.value;
    unawaited(HapticFeedback.selectionClick());
    final controller = _controller;
    if (_dozed && controller.mood == MascotMood.sleep) {
      _dozed = false;
      controller.mood = MascotMood.idle;
      controller.react(MascotMood.greeting);
      return;
    }
    const reactions = [MascotMood.happy, MascotMood.love, MascotMood.celebrate];
    controller.react(reactions[_random.nextInt(reactions.length)]);
  }

  @override
  void dispose() {
    _controller.removeListener(_onMoodChanged);
    _ownController?.dispose();
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget child = SizedBox(
      width: size,
      height: size * MascotView.heightFactor,
      child: _reduceMotion
          ? _frame(MascotSprites.frames(widget.species, _controller.current)[0])
          : ValueListenableBuilder<Duration>(
              valueListenable: _elapsed,
              builder: (context, elapsed, _) =>
                  _animated(elapsed, isDark: isDark),
            ),
    );
    child = RepaintBoundary(child: child);
    if (widget.interactive) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: child,
      );
    }
    return Semantics(
      label: widget.semanticLabel,
      button: widget.interactive,
      image: !widget.interactive,
      onTap: widget.interactive ? _handleTap : null,
      child: ExcludeSemantics(child: child),
    );
  }

  Widget _animated(Duration elapsed, {required bool isDark}) {
    final size = widget.size;
    final mood = _controller.current;
    final local = (elapsed - _moodStart).inMicroseconds / 1e6;
    final global = elapsed.inMicroseconds / 1e6;
    final frames = MascotSprites.frames(widget.species, mood);
    final perFrame =
        MascotSprites.frameDuration(widget.species, mood).inMicroseconds / 1e6;
    final position = local / perFrame;
    final pose = _Pose.of(mood, local, global, size);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: size * .02,
          child: Center(
            child: _Shadow(
              width: size * .56 * pose.shadow,
              opacity: (isDark ? .35 : .12) * pose.shadow,
            ),
          ),
        ),
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, -pose.lift),
            child: Transform.rotate(
              angle: pose.rotation,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scaleX: pose.scaleX,
                scaleY: pose.scaleY,
                alignment: Alignment.bottomCenter,
                child: SpriteFrames(
                  frames: frames,
                  position: position,
                  frameBuilder: _frame,
                  fade: MascotSprites.blends(mood)
                      ? math.min(.35, .12 / perFrame)
                      : 0,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _EffectsPainter(
              mood: mood,
              time: local,
              size: size,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _frame(String asset) {
    final idleHeight = MascotSprites.idlePixelHeight(widget.species);
    final scale = idleHeight / (widget.size * .95);
    return OverflowBox(
      alignment: Alignment.bottomCenter,
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      maxHeight: double.infinity,
      child: Image.asset(
        asset,
        scale: scale,
        alignment: Alignment.bottomCenter,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// How the whole sprite is displaced at one instant: body language on top
/// of the frame art.
@immutable
class _Pose {
  const _Pose({
    this.lift = 0,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.shadow = 1,
  });

  /// Upward offset in logical pixels.
  final double lift;
  final double rotation;
  final double scaleX;
  final double scaleY;

  /// Shadow size and strength, 1 on the ground and smaller in the air.
  final double shadow;

  static double _wave(double t, double period) =>
      math.sin(2 * math.pi * t / period);

  /// Body language layered on the frame art. The drawn frames already hold
  /// the real movement (the wave, the jump, the steps), so this only adds
  /// what they cannot: slow breathing, the ground shadow, and one hop per
  /// celebration timed to the jump in the drawings.
  factory _Pose.of(MascotMood mood, double t, double g, double size) {
    final pose = switch (mood) {
      MascotMood.idle => _breathing(_wave(g, 3.6) * .014, _wave(g, 6) * .006),
      MascotMood.sleep => _Pose(
        scaleX: 1 + _wave(g, 4.8) * .01,
        scaleY: 1 + _wave(g, 4.8) * .025,
      ),
      MascotMood.sad => _Pose(
        lift: -size * .006,
        scaleY: .985 + _wave(g, 5) * .008,
      ),
      MascotMood.celebrate => _celebrateHop(t, size),
      MascotMood.happy ||
      MascotMood.thinking ||
      MascotMood.greeting ||
      MascotMood.treat ||
      MascotMood.love ||
      MascotMood.walk ||
      MascotMood.trophy => _breathing(_wave(g, 3.6) * .01, 0),
    };
    // A soft settle whenever a new mood starts.
    if (t < .3) {
      return pose.scaled(1 + .04 * math.sin(math.pi * t / .3));
    }
    return pose;
  }

  /// One hop in the middle of each celebration loop, where the drawings
  /// crouch and spring.
  static _Pose _celebrateHop(double t, double size) {
    final loop =
        MascotSprites.loopDuration(MascotMood.celebrate).inMicroseconds / 1e6;
    final phase = t / loop % 1;
    const from = .3, to = .7;
    if (phase < from || phase > to) return const _Pose();
    return _bounce(
      math.sin(math.pi * (phase - from) / (to - from)),
      size * .08,
      0,
    );
  }

  static _Pose _breathing(double breath, double sway) =>
      _Pose(rotation: sway, scaleX: 1 - breath * .6, scaleY: 1 + breath);

  /// A hop with squash on landing and stretch in the air.
  static _Pose _bounce(double hop, double height, double rotation) => _Pose(
    lift: hop * height,
    rotation: rotation,
    scaleX: 1 - (hop - .5) * .06,
    scaleY: 1 + (hop - .5) * .1,
    shadow: 1 - hop * .35,
  );

  _Pose scaled(double factor) => _Pose(
    lift: lift,
    rotation: rotation,
    scaleX: scaleX * factor,
    scaleY: scaleY * factor,
    shadow: shadow,
  );
}

class _Shadow extends StatelessWidget {
  const _Shadow({required this.width, required this.opacity});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: width * .16,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: opacity),
      borderRadius: BorderRadius.all(Radius.elliptical(width, width * .16)),
    ),
  );
}

/// Hearts, sleepy z's, a thinking "?", sparkles, confetti and dust: the
/// particles that carry each mood beyond the frame art.
class _EffectsPainter extends CustomPainter {
  const _EffectsPainter({
    required this.mood,
    required this.time,
    required this.size,
    required this.isDark,
  });

  final MascotMood mood;
  final double time;
  final double size;
  final bool isDark;

  static const _heart = Color(0xFFFF6B8B);
  static const _spark = Color(0xFFF4B400);
  static const _confetti = [
    Color(0xFF7657EE),
    Color(0xFFD5F06A),
    Color(0xFFFF6B8B),
    Color(0xFF4FC3F7),
    Color(0xFFF4B400),
    Color(0xFF34C77B),
  ];

  /// Deterministic 0–1 value per particle, so particles keep their paths.
  static double _seed(int i, int salt) {
    final v = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size box) {
    // The character's box sits at the bottom of the widget.
    final top = box.height - size;
    switch (mood) {
      case MascotMood.love:
        _hearts(canvas, top);
      case MascotMood.sleep:
        _snores(canvas, top);
      case MascotMood.thinking:
        _question(canvas, top);
      case MascotMood.happy:
        _sparkles(canvas, top, 3);
      case MascotMood.treat:
        _sparkles(canvas, top, 2);
      case MascotMood.celebrate:
      case MascotMood.trophy:
        _confettiRain(canvas, box);
      case MascotMood.greeting:
        _waveLines(canvas, top);
      case MascotMood.walk:
        _dust(canvas, box);
      case MascotMood.idle:
      case MascotMood.sad:
        break;
    }
  }

  void _hearts(Canvas canvas, double top) {
    for (var i = 0; i < 4; i++) {
      final p = (time * .32 + i / 4) % 1;
      final x =
          size * (.22 + .56 * _seed(i, 1)) +
          math.sin(p * 2 * math.pi + i) * size * .04;
      final y = top + size * .4 - p * size * .5;
      final s = size * (.05 + .025 * _seed(i, 2));
      _drawHeart(canvas, Offset(x, y), s, _fade(p));
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double s, double alpha) {
    final path = Path()
      ..moveTo(c.dx, c.dy + s * .9)
      ..cubicTo(
        c.dx - s * 1.4,
        c.dy,
        c.dx - s * .8,
        c.dy - s,
        c.dx,
        c.dy - s * .35,
      )
      ..cubicTo(
        c.dx + s * .8,
        c.dy - s,
        c.dx + s * 1.4,
        c.dy,
        c.dx,
        c.dy + s * .9,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = _heart.withValues(alpha: alpha));
  }

  void _snores(Canvas canvas, double top) {
    final ink = isDark ? const Color(0xFFE9E6F5) : const Color(0xFF4A4460);
    for (var i = 0; i < 3; i++) {
      final p = (time * .22 + i / 3) % 1;
      _text(
        canvas,
        'z',
        Offset(size * (.66 + p * .18), top + size * .4 - p * size * .38),
        size * (.08 + .07 * p),
        ink.withValues(alpha: _fade(p)),
      );
    }
  }

  void _question(Canvas canvas, double top) {
    final appear = (time / .3).clamp(0.0, 1.0);
    _text(
      canvas,
      '?',
      Offset(
        size * .7,
        top + size * .14 + math.sin(2 * math.pi * time / 1.2) * size * .02,
      ),
      size * .17,
      const Color(0xFF7657EE).withValues(alpha: appear),
    );
  }

  void _sparkles(Canvas canvas, double top, int count) {
    const spots = [Offset(.14, .3), Offset(.86, .22), Offset(.8, .52)];
    for (var i = 0; i < count; i++) {
      final twinkle = math.max(
        0.0,
        math.sin(2 * math.pi * (time * .6 + i / 3)),
      );
      if (twinkle == 0) continue;
      final c = Offset(size * spots[i].dx, top + size * spots[i].dy);
      _drawSpark(canvas, c, size * .05 * twinkle, _spark);
    }
  }

  void _drawSpark(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _confettiRain(Canvas canvas, Size box) {
    for (var i = 0; i < 16; i++) {
      final p = (time * .4 + _seed(i, 3)) % 1;
      final x = box.width * _seed(i, 4) + math.sin(p * 6 + i) * size * .04;
      final y = p * box.height * .85;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p * 7 + i);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: size * .045,
          height: size * .022,
        ),
        Paint()
          ..color = _confetti[i % _confetti.length].withValues(
            alpha: p > .85 ? (1 - p) / .15 : 1,
          ),
      );
      canvas.restore();
    }
  }

  /// Two motion arcs beside the waving hand.
  void _waveLines(Canvas canvas, double top) {
    final alpha = .5 + .5 * math.sin(2 * math.pi * time / 1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * .018
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? const Color(0xFFE9E6F5) : const Color(0xFF4A4460))
          .withValues(alpha: alpha * .6);
    final center = Offset(size * .8, top + size * .42);
    for (var i = 0; i < 2; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size * (.08 + i * .05)),
        -.6,
        1.2,
        false,
        paint,
      );
    }
  }

  void _dust(Canvas canvas, Size box) {
    final paint = Paint();
    for (var i = 0; i < 3; i++) {
      final p = (time * .9 + i / 3) % 1;
      paint.color = (isDark ? Colors.white : const Color(0xFF8A8499))
          .withValues(alpha: (1 - p) * .35);
      canvas.drawCircle(
        Offset(size * (.3 - p * .14), box.height - size * (.05 + p * .05)),
        size * .025 * (1 + p),
        paint,
      );
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: RiksaTypography.latinFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  /// Fades a particle in and back out over its life.
  static double _fade(double p) => math.sin(math.pi * p).clamp(0.0, 1.0);

  @override
  bool shouldRepaint(_EffectsPainter old) =>
      old.time != time || old.mood != mood || old.isDark != isDark;
}
