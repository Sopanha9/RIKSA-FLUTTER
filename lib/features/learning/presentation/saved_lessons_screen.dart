import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/widgets/riksa_components.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import '../providers/lesson_catalog_provider.dart';
import '../providers/saved_lessons_provider.dart';
import 'learning_design.dart';

class SavedLessonsScreen extends ConsumerWidget {
  const SavedLessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    final l10n = AppLocalizations.of(context)!;
    final savedIds = ref.watch(savedLessonsProvider);
    final catalogState = ref.watch(lessonCatalogProvider);
    final homeState = ref.watch(learningHomeProvider);
    final palette = context.riksa;

    final homeLessons =
        homeState.asData?.value.subjects.expand((s) => s.lessons) ??
        const <LessonSummary>[];
    final allLessonsMap = <String, LessonSummary>{
      for (final l in catalogState.lessons) l.id: l,
      for (final l in homeLessons) l.id: l,
    };
    final savedLessons = savedIds
        .map((id) => allLessonsMap[id])
        .whereType<LessonSummary>()
        .toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: Text(isKhmer ? 'មេរៀនបានរក្សាទុក' : 'Saved Lessons'),
        backgroundColor: palette.canvas,
      ),
      body: catalogState.isLoading && catalogState.lessons.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : savedIds.isEmpty || savedLessons.isEmpty
          ? IllustratedEmptyState(
              title: l10n.savedLessonsEmptyTitle,
              body: l10n.savedLessonsEmptyBody,
              actionLabel: isKhmer ? 'រុករកមេរៀន' : 'Browse lessons',
              onAction: () => context.go('/learn'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: savedLessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lesson = savedLessons[index];
                final subject = stemSubjectFor(lesson.categoryName);
                final tone = subjectTone(context, subject);

                return RiksaPastelCard(
                  key: ValueKey('saved-lesson-card-${lesson.id}'),
                  onTap: () =>
                      context.push('/learn/${lesson.id}', extra: lesson),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tone.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: tone.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (lesson.categoryName.isNotEmpty) ...[
                              Text(
                                lesson.categoryName,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: tone.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              lesson.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: palette.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceRaised,
                                    borderRadius: AppRadii.fullBorder,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 14,
                                        color: palette.saffron,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '+${lesson.baseXp} XP',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: palette.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: ValueKey('remove-saved-lesson-${lesson.id}'),
                        tooltip: isKhmer
                            ? 'ដកចេញពីមេរៀនរក្សាទុក'
                            : 'Remove from saved',
                        icon: Icon(
                          Icons.bookmark_remove_rounded,
                          color: palette.inkMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(savedLessonsProvider.notifier)
                              .remove(lesson.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
