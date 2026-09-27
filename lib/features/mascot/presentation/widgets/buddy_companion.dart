import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/buddy_behavior.dart';
import '../../domain/mascot.dart';
import '../../providers/buddy_preferences_provider.dart';
import '../../providers/buddy_care_provider.dart';
import '../../providers/mascot_provider.dart';
import 'buddy_look.dart';
import 'mascot_speech.dart';
import 'mascot_view.dart';

class BuddyCompanionInline extends ConsumerWidget {
  const BuddyCompanionInline({
    super.key,
    required this.reaction,
    this.speech,
    this.size = 52,
  });

  final BuddyReaction reaction;
  final String? speech;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(buddyReactionsEnabledProvider);
    final effective = enabled ? reaction : reaction.withoutAutonomousReaction();
    final line = enabled && effective.speechAllowed ? speech : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BuddyFaceReaction(face: effective.face, size: size),
        if (line != null && line.isNotEmpty) ...[
          const SizedBox(width: RiksaSpacing.sm),
          Expanded(
            child: MascotSpeechBubble(
              line: line,
              tail: SpeechTail.left,
              maxWidth: double.infinity,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}

/// A preference-aware everyday buddy face. Turning reactions off produces a
/// neutral first frame immediately while retaining the learner's identity.
class BuddyFaceReaction extends ConsumerWidget {
  const BuddyFaceReaction({
    super.key,
    required this.face,
    this.size = 44,
    this.loops = 1,
  });

  final MascotFace face;
  final double size;
  final int loops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(buddyReactionsEnabledProvider);
    final look = ref.watch(buddyLookProvider);
    final avatar = BuddyLook(
      species: look.species,
      face: enabled ? face : MascotFace.neutral,
      equipped: look.equipped,
      size: size,
      loops: enabled ? loops : 0,
      semanticLabel: look.name,
    );
    if (enabled || MediaQuery.disableAnimationsOf(context)) return avatar;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: avatar,
    );
  }
}

class BuddyEarnedMoment extends ConsumerWidget {
  const BuddyEarnedMoment({
    super.key,
    required this.reaction,
    this.speech,
    this.size = 180,
    this.moodOverride,
  });

  final BuddyReaction reaction;
  final String? speech;
  final double size;
  final MascotMood? moodOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(buddyReactionsEnabledProvider);
    final profile = ref.watch(mascotProvider).profile;
    final species = profile?.species ?? MascotSpecies.crocodile;
    final mood = enabled
        ? moodOverride ?? reaction.mood ?? MascotMood.trophy
        : MascotMood.idle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enabled && reaction.speechAllowed && speech != null)
          MascotSpeechBubble(line: speech!),
        _StaticWhenDisabled(
          disabled: !enabled,
          child: MascotView(
            species: species,
            mood: mood,
            size: size,
            alive: enabled,
            interactive: false,
          ),
        ),
      ],
    );
  }
}

class _StaticWhenDisabled extends StatelessWidget {
  const _StaticWhenDisabled({required this.disabled, required this.child});

  final bool disabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!disabled || MediaQuery.disableAnimationsOf(context)) return child;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    );
  }
}
