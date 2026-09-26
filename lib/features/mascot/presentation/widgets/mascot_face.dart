import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/mascot.dart';
import '../../providers/mascot_provider.dart';
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
  });

  final MascotSpecies species;
  final MascotFace face;

  /// Width of the head; the widget is square.
  final double size;

  /// Plays the loop this many times, then holds. Null loops forever.
  final int? loops;
  final String? semanticLabel;

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
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
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
    if (loops == null) return;
    final loop =
        MascotFaceSprites.loopDuration(widget.face).inMicroseconds / 1e6;
    final local = (elapsed - _faceStart).inMicroseconds / 1e6;
    if (local >= loops * loop + _popDuration) {
      setState(() => _finished = true);
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  /// Where in the frame sequence a moment of the loop falls, honouring each
  /// frame's hold.
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
                ? _frame(frames.first)
                : ValueListenableBuilder<Duration>(
                    valueListenable: _elapsed,
                    builder: (context, elapsed, _) {
                      final local = (elapsed - _faceStart).inMicroseconds / 1e6;
                      final global = elapsed.inMicroseconds / 1e6;
                      // Pop in with a wobble that settles, then bob gently.
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
                            child: SpriteFrames(
                              frames: frames,
                              position: _position(local),
                              frameBuilder: _frame,
                              fade: .25,
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

  Widget _frame(String asset) => Image.asset(
    asset,
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    gaplessPlayback: true,
    filterQuality: FilterQuality.medium,
  );
}

/// The learner's own buddy as a round avatar showing [face].
///
/// Falls back to the crocodile before a buddy has been chosen.
class MascotFaceAvatar extends ConsumerWidget {
  const MascotFaceAvatar({
    super.key,
    this.face = MascotFace.neutral,
    this.size = 40,
    this.loops,
    this.background,
    this.semanticLabel,
  });

  final MascotFace face;
  final double size;
  final int? loops;
  final Color? background;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species =
        ref.watch(mascotProvider).profile?.species ?? MascotSpecies.crocodile;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background ?? context.riksa.brandSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.bottomCenter,
      child: MascotFaceView(
        species: species,
        face: face,
        size: size * .92,
        loops: loops,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
