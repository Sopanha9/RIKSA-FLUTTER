import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import '../providers/lesson_catalog_provider.dart';
import '../providers/saved_lessons_provider.dart';
import 'learning_design.dart';

/// Lessons the learner bookmarked, filterable by subject.
class SavedLessonsScreen extends ConsumerStatefulWidget {
  const SavedLessonsScreen({super.key});

  @override
  ConsumerState<SavedLessonsScreen> createState() => _SavedLessonsScreenState();
}

class _SavedLessonsScreenState extends ConsumerState<SavedLessonsScreen> {
  /// The subject name the list is narrowed to; null shows everything.
  String? _subject;

  void _retry() {
    ref.invalidate(learningHomeProvider);
    ref.read(lessonCatalogProvider.notifier).load();
  }

  void _retrySavedIds() {
    ref.invalidate(savedLessonsProvider);
    ref.invalidate(savedLessonsRestoredProvider);
  }

  /// Drops bookmarks that no longer match any lesson in the syllabus.
  Future<void> _clearUnavailable(Iterable<String> ids) async {
    final notifier = ref.read(savedLessonsProvider.notifier);
    for (final id in ids.toList()) {
      await notifier.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final savedIds = ref.watch(savedLessonsProvider);
    final savedIdsRestored = ref.watch(savedLessonsRestoredProvider);
    final catalogState = ref.watch(lessonCatalogProvider);
    final homeState = ref.watch(learningHomeProvider);
    final palette = context.riksa;
    final theme = Theme.of(context);

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
    final subjects = {
      for (final lesson in savedLessons)
        if (lesson.categoryName.isNotEmpty) lesson.categoryName,
    }.toList();
    final visible = _subject == null
        ? savedLessons
        : savedLessons.where((l) => l.categoryName == _subject).toList();
    final title = l10n.menuSavedLessons;
    // The home syllabus holds every lesson, so only once it has loaded can a
    // bookmark that matches nothing be called unavailable.
    final unresolved = savedIds.length - savedLessons.length;
    final stillLoading =
        homeState.isLoading ||
        (catalogState.isLoading && catalogState.lessons.isEmpty);
    final loadFailed = homeState.hasError && !homeState.hasValue;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        leading: const Center(
          child: RiksaBackButton(
            fallbackLocation: '/learn',
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          title,
          style: RiksaTypography.titleStyleFor(
            title,
            theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: savedIdsRestored.isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedIdsRestored.hasError
          ? IllustratedEmptyState(
              key: const ValueKey('saved-lessons-restore-failed'),
              title: l10n.savedLessonsLoadFailed,
              body: l10n.loadFailedCheckConnection,
              actionLabel: l10n.tryAgain,
              onAction: _retrySavedIds,
            )
          : savedIds.isEmpty
          ? SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: RiksaSpacing.lg),
                  const BuddyFaceReaction(
                    face: MascotFace.thinking,
                    size: 64,
                    loops: 1,
                  ),
                  IllustratedEmptyState(
                    title: l10n.savedLessonsEmptyTitle,
                    body: l10n.savedLessonsEmptyBody,
                    actionLabel: l10n.browseLessons,
                    onAction: () => context.go('/learn'),
                  ),
                ],
              ),
            )
          : savedLessons.isEmpty && stillLoading
          ? const Center(child: CircularProgressIndicator())
          : savedLessons.isEmpty && loadFailed
          ? IllustratedEmptyState(
              key: const ValueKey('saved-lessons-load-failed'),
              title: l10n.savedLessonsLoadFailed,
              body: l10n.loadFailedCheckConnection,
              actionLabel: l10n.tryAgain,
              onAction: _retry,
            )
          : savedLessons.isEmpty
          ? IllustratedEmptyState(
              key: const ValueKey('saved-lessons-unavailable'),
              title: l10n.savedLessonsUnavailableTitle,
              body: l10n.savedLessonsUnavailableBody,
              actionLabel: l10n.browseLessons,
              onAction: () => context.go('/learn'),
              secondaryLabel: l10n.savedLessonsClear,
              onSecondary: () => _clearUnavailable(savedIds),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (unresolved > 0 && loadFailed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                    child: Row(
                      key: const ValueKey('saved-lessons-partial-failure'),
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 18,
                          color: palette.inkMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.savedLessonsSomeFailed,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _retry,
                          child: Text(l10n.tryAgain),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    children: [
                      _SubjectChip(
                        label: l10n.feedFilterAll,
                        selected: _subject == null,
                        onTap: () => setState(() => _subject = null),
                      ),
                      for (final name in subjects)
                        _SubjectChip(
                          label: name,
                          selected: _subject == name,
                          onTap: () => setState(() => _subject = name),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _SavedLessonRow(
                      lesson: visible[index],
                      removeTooltip: l10n.removeFromSaved,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = selected
        ? palette.brand.withValues(alpha: isDark ? 0.44 : 0.84)
        : isDark
        ? palette.surface.withValues(alpha: 0.34)
        : Colors.white.withValues(alpha: 0.46);
    final border = selected
        ? Colors.white.withValues(alpha: isDark ? 0.18 : 0.72)
        : Colors.white.withValues(alpha: isDark ? 0.10 : 0.58);
    final textColor = selected ? palette.onBrand : palette.inkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        selected: selected,
        child: ClipRRect(
          borderRadius: AppRadii.fullBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadii.fullBorder,
                child: AnimatedContainer(
                  duration: RiksaMotion.resolve(context, RiksaMotion.fast),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: AppRadii.fullBorder,
                    border: Border.all(color: border),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: palette.brand.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: RiksaTypography.bodyStyleFor(
                      label,
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: textColor,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedLessonRow extends ConsumerWidget {
  const _SavedLessonRow({required this.lesson, required this.removeTooltip});

  final LessonSummary lesson;
  final String removeTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.riksa;
    final theme = Theme.of(context);
    final subject = stemSubjectFor(lesson.categoryName);
    final meta = [
      if (lesson.categoryName.isNotEmpty) lesson.categoryName,
      '+${lesson.baseXp} XP',
    ].join(' • ');

    return Material(
      key: ValueKey('saved-lesson-card-${lesson.id}'),
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.largeBorder,
        side: BorderSide(color: palette.outline),
      ),
      child: InkWell(
        borderRadius: AppRadii.largeBorder,
        onTap: () => context.push('/learn/${lesson.id}', extra: lesson),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: [
              SubjectPixelArtwork(subject: subject, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        lesson.title,
                        theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        meta,
                        theme.textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('remove-saved-lesson-${lesson.id}'),
                tooltip: removeTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
                icon: Icon(
                  Icons.bookmark_rounded,
                  color: palette.brand,
                  size: 24,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(savedLessonsProvider.notifier).remove(lesson.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
