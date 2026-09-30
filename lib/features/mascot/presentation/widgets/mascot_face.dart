import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/mascot.dart';
import '../../providers/buddy_care_provider.dart';
import 'buddy_look.dart';

export 'mascot_face_view.dart';

/// Compatibility wrapper for circular avatar surfaces. The face and equipped
/// items are still painted by [BuddyLook], with the old soft background kept
/// behind it for small chips and status indicators.
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
    final look = ref.watch(buddyLookProvider);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? context.riksa.brandSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.bottomCenter,
      child: BuddyLook(
        species: look.species,
        face: face,
        equipped: look.equipped,
        size: size * .92,
        loops: loops,
        semanticLabel: semanticLabel ?? look.name,
      ),
    );
  }
}
