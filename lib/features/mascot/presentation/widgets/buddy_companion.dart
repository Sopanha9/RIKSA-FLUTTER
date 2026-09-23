import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/buddy_behavior.dart';
import '../../domain/mascot.dart';
import '../../providers/buddy_preferences_provider.dart';
import '../../providers/mascot_provider.dart';
import 'mascot_face.dart';
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
        MascotFaceAvatar(
          face: effective.face,
          size: size,
          loops: enabled && !MediaQuery.disableAnimationsOf(context) ? 1 : 0,
        ),
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

class BuddyEarnedMoment extends ConsumerWidget {
  const BuddyEarnedMoment({
    super.key,
    required this.reaction,
    this.speech,
    this.size = 180,
  });

  final BuddyReaction reaction;
  final String? speech;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(buddyReactionsEnabledProvider);
    final profile = ref.watch(mascotProvider).profile;
    final species = profile?.species ?? MascotSpecies.crocodile;
    final mood = enabled ? reaction.mood ?? MascotMood.trophy : MascotMood.idle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enabled && reaction.speechAllowed && speech != null)
          MascotSpeechBubble(line: speech!),
        MascotView(
          species: species,
          mood: mood,
          size: size,
          alive: enabled,
          interactive: false,
        ),
      ],
    );
  }
}
