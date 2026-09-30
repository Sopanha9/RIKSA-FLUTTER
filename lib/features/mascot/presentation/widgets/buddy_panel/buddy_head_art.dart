import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/mascot.dart';
import '../../../providers/buddy_care_provider.dart';
import '../buddy_look.dart';

/// The floating buddy's replaceable face layer. It deliberately has no
/// background, shape clip, or border so equipped head items can overflow.
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
    final look = ref.watch(buddyLookProvider);
    return BuddyLook(
      species: look.species,
      face: face,
      equipped: look.equipped,
      size: size,
      loops: 1,
      semanticLabel: semanticLabel ?? look.name,
    );
  }
}
