import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/mascot.dart';
import '../../../providers/mascot_provider.dart';
import '../mascot_face.dart';

/// The floating buddy's replaceable face layer. It deliberately has no
/// background, shape clip, or border so later looks can supply full art.
class BuddyHeadArt extends ConsumerWidget {
  const BuddyHeadArt({
    super.key,
    required this.face,
    required this.size,
    this.semanticLabel,
  });

  final MascotFace face;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species =
        ref.watch(mascotProvider).profile?.species ?? MascotSpecies.crocodile;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark ? Colors.white.withValues(alpha: .8) : Colors.black;

    Widget image(double dimension, {String? label}) => MascotFaceView(
      species: species,
      face: face,
      size: dimension,
      // Play once and hold, like the old head: an endless loop on an
      // always-visible overlay costs battery and never lets tests settle.
      loops: 1,
      semanticLabel: label,
    );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 7,
            child: Opacity(
              opacity: .34,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                  child: image(size),
                ),
              ),
            ),
          ),
          if (dark)
            ColorFiltered(
              colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
              child: Transform.scale(scale: 1.055, child: image(size)),
            ),
          image(size, label: semanticLabel),
        ],
      ),
    );
  }
}
