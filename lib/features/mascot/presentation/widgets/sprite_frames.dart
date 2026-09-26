import 'package:flutter/widgets.dart';

/// Draws a looping frame sequence at a fractional [position] (2.4 is 40% of
/// the way through frame 2), fading the next drawing in over the last
/// [fade] of each frame so the swap reads as movement rather than a cut.
class SpriteFrames extends StatelessWidget {
  const SpriteFrames({
    super.key,
    required this.frames,
    required this.position,
    required this.frameBuilder,
    this.fade = .35,
  });

  final List<String> frames;
  final double position;
  final Widget Function(String asset) frameBuilder;
  final double fade;

  @override
  Widget build(BuildContext context) {
    final count = frames.length;
    final index = position.floor() % count;
    final within = position - position.floorToDouble();
    final blend = count < 2 || fade <= 0
        ? 0.0
        : ((within - (1 - fade)) / fade).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        frameBuilder(frames[index]),
        if (blend > 0)
          Opacity(
            opacity: blend,
            child: frameBuilder(frames[(index + 1) % count]),
          ),
      ],
    );
  }
}
