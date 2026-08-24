import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/learning_models.dart';

class LessonExperienceScreen extends StatelessWidget {
  const LessonExperienceScreen({
    super.key,
    required this.lessonId,
    this.lesson,
  });

  final String lessonId;
  final LessonSummary? lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = lesson;
    if (summary == null) {
      return Scaffold(
        appBar: AppBar(),
        body: IllustratedEmptyState(
          title: l10n.lessonLoadFailed,
          body: l10n.lessonContentUnavailable,
          actionLabel: l10n.backToLessons,
          onAction: () => context.go('/learn'),
        ),
      );
    }

    final subject = summary.categoryName.trim().isEmpty
        ? l10n.generalSubject
        : summary.categoryName;
    final kind = subjectKindFor(subject);
    final color = subjectColor(context, kind);
    final progress = summary.completed ? 1.0 : summary.progress ?? 0.0;
    final duration =
        summary.durationMinutes ?? math.max(5, summary.exerciseCount * 4);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RiksaSpacing.lg,
            RiksaSpacing.xs,
            RiksaSpacing.lg,
            RiksaSpacing.xl,
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: RiksaSharedElement(
                tag: 'lesson-art-${summary.id}',
                child: SubjectArtwork(kind: kind, color: color, size: 126),
              ),
            ),
            const SizedBox(height: RiksaSpacing.lg),
            Text(
              subject.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color, letterSpacing: .7),
            ),
            const SizedBox(height: RiksaSpacing.xs),
            Text(
              summary.title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            if (summary.description.trim().isNotEmpty) ...[
              const SizedBox(height: RiksaSpacing.sm),
              Text(
                summary.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: RiksaSpacing.lg),
            Wrap(
              spacing: RiksaSpacing.xs,
              runSpacing: RiksaSpacing.xs,
              children: [
                _LessonFact(
                  icon: Icons.schedule_rounded,
                  label: l10n.minutesShort(duration),
                ),
                _LessonFact(
                  icon: Icons.edit_note_rounded,
                  label: l10n.exerciseCount(summary.exerciseCount),
                ),
                if (summary.difficulty != null)
                  _LessonFact(
                    icon: Icons.signal_cellular_alt_rounded,
                    label: _difficultyLabel(l10n, summary.difficulty!),
                  ),
              ],
            ),
            if (progress > 0) ...[
              const SizedBox(height: RiksaSpacing.lg),
              AnimatedRiksaProgress(value: progress, color: color, height: 8),
            ],
            const SizedBox(height: RiksaSpacing.xl),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.riksa.surfaceRaised,
                borderRadius: AppRadii.largeBorder,
              ),
              child: Padding(
                padding: const EdgeInsets.all(RiksaSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: context.riksa.saffron),
                    const SizedBox(width: RiksaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.lessonPreviewHeading,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: RiksaSpacing.xxs),
                          Text(
                            l10n.lessonPreviewBody,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: RiksaSpacing.lg),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.lessonContentUnavailable)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.beginLesson),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonFact extends StatelessWidget {
  const _LessonFact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: context.riksa.surfaceRaised,
      shape: const StadiumBorder(),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.riksa.inkMuted),
          const SizedBox(width: RiksaSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}

String _difficultyLabel(AppLocalizations l10n, LessonDifficulty difficulty) =>
    switch (difficulty) {
      LessonDifficulty.easy => l10n.difficultyEasy,
      LessonDifficulty.medium => l10n.difficultyMedium,
      LessonDifficulty.hard => l10n.difficultyHard,
      LessonDifficulty.difficult => l10n.difficultyDifficult,
    };
