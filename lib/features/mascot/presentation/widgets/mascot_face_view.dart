import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/mascot.dart';
import 'sprite_frames.dart';

/// An animated head-only expression of a mascot.
///
/// Changing [face] pops the new expression in with a small wobble. The face
/// then loops its frames, gently bobbing; with [loops] set it plays that many
/// times and rests on its first frame, which keeps a list of chat avatars
/// from all moving at once. Under reduced motion it shows the first frame.
class MascotFaceView extends StatefulWidget {
  const MascotFaceView({
    super.key,
    required this.species,
    required this.face,
    this.size = 48,
    this.loops,
    this.semanticLabel,
    this.activeFrameKey,
    this.overlay,
    this.faceClipper,
  });

  final MascotSpecies species;
  final MascotFace face;
  final double size;
  final int? loops;
  final String? semanticLabel;

  /// Receives the currently displayed source frame key, such as `happy_2`.
  /// BuddyLook uses it to apply frame-specific item anchors.
  final ValueNotifier<String>? activeFrameKey;

  /// Drawn over the face inside the same pop, wobble and bob transforms, so
  /// layers such as BuddyLook's hat and glasses move with the head.
  final Widget? overlay;

  /// Clips the face art (not [overlay]), inside the same transforms, so
  /// BuddyLook can hide headwear drawn into the art under an equipped hat.
  final CustomClipper<Path>? faceClipper;

  @override
  State<MascotFaceView> createState() => _MascotFaceViewState();
}

class _MascotFaceViewState extends State<MascotFaceView>
    with SingleTickerProviderStateMixin {
  static const _popDuration = .35;

  late final Ticker _ticker = createTicker(_onTick);
  final _elapsed = ValueNotifier(Duration.zero);
  Duration _faceStart = Duration.zero;
  bool _reduceMotion = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncTicker();
    _precache();
  }

  @override
  void didUpdateWidget(MascotFaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face != widget.face ||
        oldWidget.species != widget.species ||
        oldWidget.loops != widget.loops) {
      _faceStart = _elapsed.value;
      _finished = false;
      _publishFrameKey(0);
      _syncTicker();
      _precache();
    }
  }

  void _syncTicker() {
    final run = !_reduceMotion && !_finished;
    if (run && !_ticker.isActive) {
      _ticker.start();
      _faceStart = Duration.zero;
      _elapsed.value = Duration.zero;
      _publishFrameKey(0);
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      if (_reduceMotion) _publishFrameKey(0);
    }
  }

  void _precache() {
    for (final frame in MascotFaceSprites.frames(widget.species, widget.face)) {
      unawaited(precacheImage(AssetImage(frame), context));
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed;
    final loops = widget.loops;
    final loop =
        MascotFaceSprites.loopDuration(widget.face).inMicroseconds / 1e6;
    final local = (elapsed - _faceStart).inMicroseconds / 1e6;
    _publishFrameKey(_position(local).floor());
    if (loops == null) return;
    if (local >= loops * loop + _popDuration) {
      setState(() => _finished = true);
      _ticker.stop();
      _publishFrameKey(0);
    }
  }

  void _publishFrameKey(int index) {
    final controller = widget.activeFrameKey;
    if (controller == null) return;
    final key =
        '${widget.face.name}_${index % MascotFaceSprites.frameCount + 1}';
    if (controller.value != key) controller.value = key;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  double _position(double local) {
    final holds = MascotFaceSprites.holds(widget.face);
    final total = holds.fold<int>(0, (sum, hold) => sum + hold);
    final loop =
        MascotFaceSprites.loopDuration(widget.face).inMicroseconds / 1e6;
    final units = (local / loop % 1) * total;
    var start = 0.0;
    for (var i = 0; i < holds.length; i++) {
      if (units < start + holds[i]) return i + (units - start) / holds[i];
      start += holds[i];
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final frames = MascotFaceSprites.frames(widget.species, widget.face);
    final still = _reduceMotion || _finished;
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: still
                ? _withOverlay(_frame(frames.first))
                : ValueListenableBuilder<Duration>(
                    valueListenable: _elapsed,
                    builder: (context, elapsed, _) {
                      final local = (elapsed - _faceStart).inMicroseconds / 1e6;
                      final global = elapsed.inMicroseconds / 1e6;
                      final pop = local < _popDuration
                          ? .85 +
                                .15 *
                                    Curves.easeOutBack.transform(
                                      local / _popDuration,
                                    )
                          : 1.0;
                      final wobble =
                          .08 * math.sin(local * 18) * math.exp(-local * 5);
                      final bob =
                          math.sin(2 * math.pi * global / 2.4) *
                          widget.size *
                          .015;
                      return Transform.translate(
                        offset: Offset(0, bob),
                        child: Transform.rotate(
                          angle: wobble,
                          alignment: Alignment.bottomCenter,
                          child: Transform.scale(
                            scale: pop,
                            alignment: Alignment.bottomCenter,
                            child: _withOverlay(
                              SpriteFrames(
                                frames: frames,
                                position: _position(local),
                                frameBuilder: _frame,
                                fade: .25,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _withOverlay(Widget face) {
    final clipper = widget.faceClipper;
    if (clipper != null) face = ClipPath(clipper: clipper, child: face);
    final overlay = widget.overlay;
    if (overlay == null) return face;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [face, overlay],
    );
  }

  Widget _frame(String asset) => Image.asset(
    asset,
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    gaplessPlayback: true,
    filterQuality: FilterQuality.medium,
  );
}
