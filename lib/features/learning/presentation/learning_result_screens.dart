import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/buddy_behavior.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../data/learning_models.dart';
import '../providers/learning_roadmap_provider.dart';
import '../providers/lesson_catalog_provider.dart';
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
    void openRoadmap() => context.go(
      roadmapCategoryId == null
          ? '/learn'
          : '/learn/roadmap/${Uri.encodeComponent(roadmapCategoryId!)}',
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: palette.rewardSoft,
                      borderRadius: AppRadii.featureBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: BuddyEarnedMoment(
                            reaction: BuddyBehavior.resolve(
                              BuddyEvent.lessonCompleted,
                            ),
                            speech: l10n.buddyLessonCompleted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.lessonCompletionReward,
                          style: theme.textTheme.headlineSmall,
                        ),
                        if (lessonTitle?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            lessonTitle!,
                            style: RiksaTypography.titleStyleFor(
                              lessonTitle!,
                              theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          l10n.lessonCompletedBody,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        RiksaCountUp(
                          value: xpEarned,
                          format: l10n.xpRewardAmount,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reflection?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 28),
                    Text(
                      l10n.lessonSavedReflection,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      reflection!,
                      style: RiksaTypography.bodyStyleFor(
                        reflection!,
                        theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                  if (needsReview) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.lessonRevisitTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.lessonRevisitBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                  if (next != null) ...[
                    const SizedBox(height: 28),
                    Text(
                      l10n.lessonUpNext,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      next.title,
                      key: const ValueKey('lesson-completion-next-title'),
                      style: RiksaTypography.titleStyleFor(
                        next.title,
                        theme.textTheme.titleLarge,
                      ),
                    ),
                    if (next.estimatedMinutes > 0) ...[
                      const SizedBox(height: 8),
                      Text(l10n.minutesShort(next.estimatedMinutes)),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('lesson-completion-roadmap'),
                      onPressed: openRoadmap,
                      child: Text(l10n.lessonRoadmapAction),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('lesson-completion-share'),
                    onPressed: () => context.push('/community/create'),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(l10n.lessonShareLearning),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('lesson-completion-home'),
                    onPressed: () => context.go('/learn'),
                    child: Text(l10n.lessonFinishSession),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: LearningActionBar(
        primaryKey: const ValueKey('lesson-completion-continue'),
        primaryLabel: next != null
            ? l10n.lessonNextAction
            : roadmapCategoryId == null
            ? l10n.continueLearning
            : l10n.lessonRoadmapAction,
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimary: next == null
            ? openRoadmap
            : () => context.pushReplacement(
                '/learn/${Uri.encodeComponent(next.id)}',
                extra: next.toSummary(
                  categoryId: roadmap!.categoryId,
                  categoryName: roadmap.categoryName,
                ),
              ),
      ),
    );
  }
}

class ResumeLearningScreen extends ConsumerWidget {
  const ResumeLearningScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(lessonCatalogProvider);
    final active = state.lessons
        .where((lesson) => !lesson.completed && (lesson.progress ?? 0) > 0)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resumeLearningTitle)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : active.isEmpty
          ? IllustratedEmptyState(
              title: l10n.resumeLearningEmptyTitle,
              body: l10n.resumeLearningEmptyBody,
              actionLabel: l10n.browseLessons,
              onAction: () => context.go('/learn'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lesson = active[index];
                return RiksaPastelCard(
                  onTap: () =>
                      context.push('/learn/${lesson.id}', extra: lesson),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: lesson.progress),
                      const SizedBox(height: 6),
                      Text(
                        '${((lesson.progress ?? 0) * 100).round()}% complete',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
