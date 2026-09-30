import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../learning/providers/learning_home_provider.dart';
import '../../../mascot/domain/buddy_behavior.dart';
import '../../../mascot/domain/mascot.dart';
import '../../../mascot/presentation/widgets/mascot_face.dart';
import '../../../mascot/providers/buddy_preferences_provider.dart';
import '../../../mascot/providers/mascot_provider.dart';

/// The one study nudge on the timeline, in the slot X gives its "live now"
/// strip: the learner's buddy and their next lesson, one tap from resuming.
///
/// It stays quiet while the lesson loads or fails, because the timeline
/// underneath is the page; a spinner or an error up here would push it down
/// for something the learner did not ask about.
class HomeStudyBanner extends ConsumerWidget {
  const HomeStudyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(learningHomeProvider).asData?.value;
    if (data == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mascot = ref.watch(mascotProvider).profile;
    final species = mascot?.species ?? MascotSpecies.crocodile;
    final reaction = BuddyBehavior.resolve(
      BuddyEvent.appHomeArrival,
      reactionsEnabled: ref.watch(buddyReactionsEnabledProvider),
    );

    final subject = data.resumeSubject;
    final lesson = data.resumeLesson;
    final hasLesson = subject != null && lesson != null;
    final progress = hasLesson
        ? (lesson.progress ?? subject.fraction).clamp(0, 1).toDouble()
        : 0.0;
    final title = hasLesson ? lesson.title : l10n.homeStartHere;
    final details = <String>[
      if (hasLesson) subject.category.name,
      if (hasLesson && lesson.durationMinutes != null)
        l10n.homeLessonMinutes(lesson.durationMinutes!),
      if (hasLesson && lesson.baseXp > 0) '+${lesson.baseXp} XP',
      if (!hasLesson) l10n.homeStartHereBody,
    ].join(' · ');
    final action = !hasLesson
        ? l10n.homeStartHere
        : progress > 0
        ? l10n.homeContinue
        : l10n.homeStartHere;
    final fill = isDark ? palette.surfaceRaised : palette.brandSoft;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Semantics(
        button: true,
        label: '$action: $title',
        excludeSemantics: true,
        child: Material(
          key: const ValueKey('home-study-banner'),
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? palette.outline
                  : palette.brand.withValues(alpha: .25),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => hasLesson
                ? context.push(
                    '/learn/${Uri.encodeComponent(lesson.id)}',
                    extra: lesson,
                  )
                : context.go('/learn'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        // One play on arrival, then still: a face that
                        // never stops moving pulls the eye off the feed.
                        child: MascotFaceView(
                          species: species,
                          face: reaction.face,
                          size: 38,
                          loops: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RiksaTypography.titleStyleFor(
                                title,
                                theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RiksaTypography.bodyStyleFor(
                                details,
                                theme.textTheme.labelMedium?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? palette.brand : palette.brandStrong,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: palette.onBrand,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress > 0)
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: isDark ? palette.brand : palette.brandStrong,
                    backgroundColor: Colors.transparent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
