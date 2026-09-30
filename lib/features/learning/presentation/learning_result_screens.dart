import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/buddy_behavior.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../../mascot/providers/buddy_care_provider.dart';
import '../data/learning_models.dart';
import '../providers/learning_roadmap_provider.dart';
import 'widgets/learning_atoms.dart';

class LessonCompletionScreen extends ConsumerWidget {
  const LessonCompletionScreen({
    super.key,
    required this.xpEarned,
    this.roadmapCategoryId,
    this.lessonTitle,
    this.categoryName,
    this.totalExercises,
    this.reflection,
    this.needsReview = false,
    this.lessonId,
  });

  final int xpEarned;
  final String? roadmapCategoryId,
      lessonTitle,
      categoryName,
      reflection,
      lessonId;
  final int? totalExercises;
  final bool needsReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final theme = Theme.of(context);
    final buddyCare = ref.watch(buddyCareProvider);
    final roadmap = roadmapCategoryId == null
        ? null
        : ref.watch(learningRoadmapProvider(roadmapCategoryId!)).asData?.value;
    // Only offer an unlocked, unfinished lesson that the server identifies
    // as current. An unavailable recommendation falls back to the roadmap.
    final next = roadmap?.units
        .expand((unit) => unit.lessons)
        .where(
          (lesson) =>
              lesson.id != lessonId &&
              lesson.id == roadmap.currentLessonId &&
              lesson.status != RoadmapLessonStatus.locked &&
              lesson.status != RoadmapLessonStatus.completed,
        )
        .firstOrNull;
    void openRoadmap() {
      final categoryId = roadmapCategoryId;
      if (categoryId == null) {
        context.go('/learn');
        return;
      }
      context.push('/learn/roadmap/${Uri.encodeComponent(categoryId)}');
    }

    final categoryId = roadmapCategoryId;
    final shareInsteadOfFinish = next == null && categoryId == null;
    final backLocation = categoryId == null
        ? '/learn'
        : '/learn/roadmap/${Uri.encodeComponent(categoryId)}';
    void leaveCompletion() => context.go(backLocation);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leaveCompletion();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RiksaSpacing.md,
                ),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      RiksaBackButton(
                        key: const ValueKey('lesson-completion-back'),
                        fallbackLocation: backLocation,
                        onPressed: leaveCompletion,
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: palette.ink,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The reward reads as one warm moment: buddy, result,
                          // what the buddy gained, and the XP, together.
                          Container(
                            key: const ValueKey('lesson-completion-reward'),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                            decoration: BoxDecoration(
                              color: palette.rewardSoft,
                              borderRadius: AppRadii.featureBorder,
                            ),
                            child: Column(
                              children: [
                                BuddyEarnedMoment(
                                  reaction: BuddyBehavior.resolve(
                                    BuddyEvent.lessonCompleted,
                                  ),
                                  speech: l10n.buddyLessonCompleted,
                                  size: 116,
                                  moodOverride: buddyCare.care.bondLevel >= 2
                                      ? MascotMood.treat
                                      : null,
                                ),
                                const SizedBox(height: RiksaSpacing.sm),
                                Text(
                                  l10n.lessonCompletionReward,
                                  textAlign: TextAlign.center,
                                  style: RiksaTypography.titleStyleFor(
                                    l10n.lessonCompletionReward,
                                    theme.textTheme.headlineSmall?.copyWith(
                                      color: palette.ink,
                                    ),
                                    khmerHeight: 1.5,
                                  ),
                                ),
                                if (lessonTitle?.isNotEmpty == true) ...[
                                  const SizedBox(height: RiksaSpacing.xs),
                                  Text(
                                    lessonTitle!,
                                    textAlign: TextAlign.center,
                                    style: RiksaTypography.titleStyleFor(
                                      lessonTitle!,
                                      theme.textTheme.titleMedium?.copyWith(
                                        color: palette.ink,
                                      ),
                                      khmerHeight: 1.5,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: RiksaSpacing.sm),
                                Text(
                                  l10n.lessonCompletedBody,
                                  textAlign: TextAlign.center,
                                  style: _completionBodyStyle(
                                    l10n.lessonCompletedBody,
                                    theme.textTheme.bodyMedium?.copyWith(
                                      color: palette.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: RiksaSpacing.md),
                                RiksaCountUp(
                                  value: xpEarned,
                                  format: l10n.xpRewardAmount,
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(
                                        fontSize: 30,
                                        height: 1.3,
                                        color: palette.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: RiksaSpacing.xs),
                                Text(
                                  l10n.buddyLessonEnergyLine(buddyCare.name),
                                  key: const ValueKey(
                                    'lesson-buddy-energy-reward',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: _completionBodyStyle(
                                    l10n.buddyLessonEnergyLine(buddyCare.name),
                                    theme.textTheme.labelMedium?.copyWith(
                                      color: palette.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (reflection?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 32),
                            Text(
                              l10n.lessonSavedReflection,
                              style: RiksaTypography.titleStyleFor(
                                l10n.lessonSavedReflection,
                                theme.textTheme.titleMedium,
                                khmerHeight: 1.5,
                              ),
                            ),
                            const SizedBox(height: RiksaSpacing.xs),
                            SelectableText(
                              reflection!,
                              style: _completionBodyStyle(
                                reflection!,
                                theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                          if (needsReview) ...[
                            const SizedBox(height: RiksaSpacing.lg),
                            Text(
                              l10n.lessonRevisitTitle,
                              style: RiksaTypography.titleStyleFor(
                                l10n.lessonRevisitTitle,
                                theme.textTheme.titleMedium,
                                khmerHeight: 1.5,
                              ),
                            ),
                            const SizedBox(height: RiksaSpacing.xs),
                            Text(
                              l10n.lessonRevisitBody,
                              style: _completionBodyStyle(
                                l10n.lessonRevisitBody,
                                theme.textTheme.bodyMedium?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                            ),
                          ],
                          if (next != null) ...[
                            const SizedBox(height: RiksaSpacing.lg),
                            Text(
                              l10n.lessonUpNext,
                              style: RiksaTypography.bodyStyleFor(
                                l10n.lessonUpNext,
                                theme.textTheme.labelLarge?.copyWith(
                                  color: palette.inkMuted,
                                  height:
                                      RiksaTypography.containsKhmer(
                                        l10n.lessonUpNext,
                                      )
                                      ? 1.6
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: RiksaSpacing.xs),
                            Text(
                              next.title,
                              key: const ValueKey(
                                'lesson-completion-next-title',
                              ),
                              style: RiksaTypography.titleStyleFor(
                                next.title,
                                theme.textTheme.titleLarge,
                                khmerHeight: 1.5,
                              ),
                            ),
                            if (next.estimatedMinutes > 0) ...[
                              const SizedBox(height: RiksaSpacing.xs),
                              Text(
                                l10n.minutesShort(next.estimatedMinutes),
                                style: _completionBodyStyle(
                                  l10n.minutesShort(next.estimatedMinutes),
                                  theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: const ValueKey(
                                  'lesson-completion-roadmap',
                                ),
                                onPressed: openRoadmap,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(l10n.lessonRoadmapAction),
                              ),
                            ),
                          ],
                          if (!shareInsteadOfFinish) ...[
                            const SizedBox(height: RiksaSpacing.md),
                            OutlinedButton.icon(
                              key: const ValueKey('lesson-completion-share'),
                              onPressed: () =>
                                  context.push('/community/create'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.ios_share_rounded),
                              label: Text(l10n.lessonShareLearning),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, RiksaSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: LearningPrimaryButton(
                        key: const ValueKey('lesson-completion-continue'),
                        label: next != null
                            ? l10n.lessonNextAction
                            : roadmapCategoryId == null
                            ? l10n.continueLearning
                            : l10n.lessonRoadmapAction,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: next == null
                            ? openRoadmap
                            : () => context.pushReplacement(
                                '/learn/${Uri.encodeComponent(next.id)}',
                                extra: next.toSummary(
                                  categoryId: roadmap!.categoryId,
                                  categoryName: roadmap.categoryName,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: RiksaSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        key: const ValueKey('lesson-completion-secondary'),
                        onPressed: shareInsteadOfFinish
                            ? () => context.push('/community/create')
                            : () => context.go('/learn'),
                        style: TextButton.styleFrom(
                          foregroundColor: palette.inkMuted,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          shareInsteadOfFinish
                              ? l10n.lessonShareLearning
                              : l10n.lessonFinishSession,
                          textAlign: TextAlign.center,
                          style: _completionBodyStyle(
                            shareInsteadOfFinish
                                ? l10n.lessonShareLearning
                                : l10n.lessonFinishSession,
                            theme.textTheme.labelLarge?.copyWith(
                              color: palette.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? _completionBodyStyle(String text, TextStyle? style) {
  final resolved = RiksaTypography.bodyStyleFor(text, style);
  if (!RiksaTypography.containsKhmer(text)) return resolved;
  return resolved?.copyWith(
    height: (resolved.height ?? 0) < 1.5 ? 1.6 : resolved.height,
  );
}
