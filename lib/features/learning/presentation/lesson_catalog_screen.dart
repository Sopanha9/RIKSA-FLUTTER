import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../social/presentation/widgets/streak_details_sheet.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/learning_models.dart';
import '../providers/lesson_catalog_provider.dart';

class LessonCatalogScreen extends ConsumerStatefulWidget {
  const LessonCatalogScreen({super.key});

  @override
  ConsumerState<LessonCatalogScreen> createState() =>
      _LessonCatalogScreenState();
}

class _LessonCatalogScreenState extends ConsumerState<LessonCatalogScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMore);
  }

  void _loadMore() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 520) {
      ref.read(lessonCatalogProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMore)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonCatalogProvider);
    final streak = ref.watch(communityStreakProvider);
    final l10n = AppLocalizations.of(context)!;
    final lessons = _orderedLessons(state.lessons);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? context.riksa.canvas
          : AppColors.editorialCanvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.editorialPink,
          onRefresh: ref.read(lessonCatalogProvider.notifier).load,
          child: CustomScrollView(
            key: const PageStorageKey('lesson-catalog-scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: _CatalogHeader(
                    title: l10n.learningTitle,
                    searchLabel: l10n.searchLessons,
                    filterLabel: l10n.filterLessons,
                    filterCount: state.filterCount,
                    onSearch: () => _showSearch(lessons),
                    onFilter: () => _showFilters(state),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 24),
                sliver: SliverToBoxAdapter(
                  child: _SubjectStrip(
                    categories: state.categories,
                    selectedCategoryId: state.selectedCategoryId,
                    allLabel: l10n.forYou,
                    streak: streak.value?.current,
                    streakLoading: streak.isLoading,
                    onSelected: (id) => ref
                        .read(lessonCatalogProvider.notifier)
                        .selectCategory(id),
                    onStreak: streak.value == null
                        ? null
                        : () => showStreakDetailsSheet(context, streak.value!),
                  ),
                ),
              ),
              if (state.isLoading && state.lessons.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.editorialPink,
                    ),
                  ),
                ),
              ..._lessonSlivers(state: state, lessons: lessons, l10n: l10n),
              const SliverToBoxAdapter(child: SizedBox(height: 112)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _lessonSlivers({
    required LessonCatalogState state,
    required List<LessonSummary> lessons,
    required AppLocalizations l10n,
  }) {
    if (state.isLoading && state.lessons.isEmpty) {
      return const [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
          sliver: SliverToBoxAdapter(child: _LessonStackPlaceholder()),
        ),
      ];
    }

    if (lessons.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 112),
            child: IllustratedEmptyState(
              title: state.errorMessage == null
                  ? l10n.noLessonsFound
                  : l10n.lessonLoadFailed,
              body: state.errorMessage ?? l10n.noLessonsForFilters,
              actionLabel: l10n.tryAgain,
              onAction: ref.read(lessonCatalogProvider.notifier).load,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        sliver: SliverList.builder(
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            final progress = _lessonProgress(lesson);
            final isFirst = index == 0;
            final height = isFirst && progress != null ? 278.0 : 246.0;
            return _LessonCardSlot(
              height: height,
              isLast: index == lessons.length - 1,
              child: _EditorialLessonCard(
                key: ValueKey('lesson-card-${lesson.id}'),
                lesson: lesson,
                index: index,
                hasTopNotch: !isFirst,
                eyebrow: isFirst && progress != null && progress < 1
                    ? l10n.continueLearning
                    : _subject(l10n, lesson),
                subject: _subject(l10n, lesson),
                duration: l10n.minutesShort(_duration(lesson)),
                difficulty: _difficulty(l10n, lesson.difficulty),
                exercises: l10n.exerciseCount(lesson.exerciseCount),
                completedLabel: l10n.completedLabel,
                progress: progress,
                onTap: () => _open(lesson),
              ),
            );
          },
        ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.editorialPink),
            ),
          ),
        ),
    ];
  }

  List<LessonSummary> _orderedLessons(List<LessonSummary> lessons) {
    final indexed = lessons.indexed.toList();
    indexed.sort((a, b) {
      final aPriority = _lessonPriority(a.$2);
      final bPriority = _lessonPriority(b.$2);
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return a.$1.compareTo(b.$1);
    });
    return [for (final item in indexed) item.$2];
  }

  int _lessonPriority(LessonSummary lesson) {
    final progress = lesson.progress;
    if (!lesson.completed && progress != null && progress > 0 && progress < 1) {
      return 0;
    }
    if (!lesson.completed) return 1;
    return 2;
  }

  void _open(LessonSummary lesson) {
    final category = lesson.categoryName.toLowerCase();
    if (category.contains('math')) {
      context.push('/learn/mathematics', extra: lesson);
      return;
    }
    context.push('/learn/${lesson.id}', extra: lesson);
  }

  Future<void> _showSearch(List<LessonSummary> lessons) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showSearch<LessonSummary?>(
      context: context,
      delegate: _LessonSearchDelegate(
        lessons: lessons,
        hint: l10n.searchLessons,
        emptyLabel: l10n.noLessonsFound,
        subject: (lesson) => _subject(l10n, lesson),
      ),
    );
    if (selected != null && mounted) _open(selected);
  }

  Future<void> _showFilters(LessonCatalogState state) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) {
          final l10n = AppLocalizations.of(sheetContext)!;
          return FilterBottomSheet(
            key: const ValueKey('lesson-filter-sheet'),
            title: l10n.filterLessons,
            gradeTitle: l10n.gradeFilter,
            subjectTitle: l10n.subjectFilter,
            difficultyTitle: l10n.difficultyFilter,
            applyLabel: l10n.applyFilters,
            resetLabel: l10n.resetFilters,
            grades: [
              for (var grade = 7; grade <= 12; grade++)
                RiksaFilterOption(id: '$grade', label: l10n.gradeNumber(grade)),
            ],
            subjects: [
              for (final category in state.categories)
                RiksaFilterOption(id: category.id, label: category.name),
            ],
            difficulties: [
              for (final value in LessonDifficulty.values)
                RiksaFilterOption(
                  id: value.name,
                  label: _difficulty(l10n, value),
                ),
            ],
            selection: RiksaFilterSelection(
              grade: state.selectedGrade?.toString(),
              subject: state.selectedCategoryId,
              difficulty: state.selectedDifficulty?.name,
            ),
            onApply: (selection) => ref
                .read(lessonCatalogProvider.notifier)
                .applyFilters(
                  grade: int.tryParse(selection.grade ?? ''),
                  categoryId: selection.subject,
                  difficulty: LessonDifficulty.values
                      .where((item) => item.name == selection.difficulty)
                      .firstOrNull,
                ),
          );
        },
      );
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.title,
    required this.searchLabel,
    required this.filterLabel,
    required this.filterCount,
    required this.onSearch,
    required this.onFilter,
  });

  final String title;
  final String searchLabel;
  final String filterLabel;
  final int filterCount;
  final VoidCallback onSearch;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: context.riksa.ink,
            fontSize: 48,
            height: 1,
            letterSpacing: -1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      _CatalogActionButton(
        key: const ValueKey('lesson-search-button'),
        tooltip: searchLabel,
        icon: Icons.search_rounded,
        onTap: onSearch,
      ),
      const SizedBox(width: 10),
      _CatalogActionButton(
        key: const ValueKey('lesson-filter-button'),
        tooltip: filterLabel,
        icon: Icons.tune_rounded,
        badgeCount: filterCount,
        onTap: onFilter,
      ),
    ],
  );
}

class _CatalogActionButton extends StatelessWidget {
  const _CatalogActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? context.riksa.surfaceRaised
          : AppColors.editorialSurface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 52,
          child: Center(
            child: Badge(
              key: badgeCount > 0
                  ? const ValueKey('active-filter-count')
                  : null,
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount'),
              backgroundColor: AppColors.editorialPink,
              textColor: AppColors.editorialAubergine,
              child: Icon(icon, color: context.riksa.ink, size: 23),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SubjectStrip extends StatelessWidget {
  const _SubjectStrip({
    required this.categories,
    required this.selectedCategoryId,
    required this.allLabel,
    required this.streak,
    required this.streakLoading,
    required this.onSelected,
    required this.onStreak,
  });

  final List<LearningCategory> categories;
  final String? selectedCategoryId;
  final String allLabel;
  final int? streak;
  final bool streakLoading;
  final ValueChanged<String?> onSelected;
  final VoidCallback? onStreak;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('lesson-subject-strip'),
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      children: [
        _SubjectChip(
          key: const ValueKey('lesson-category-all'),
          label: allLabel,
          selected: selectedCategoryId == null,
          onTap: () => onSelected(null),
        ),
        for (final category in categories) ...[
          const SizedBox(width: 9),
          _SubjectChip(
            key: ValueKey('lesson-category-${category.id}'),
            label: category.name,
            selected: selectedCategoryId == category.id,
            onTap: () => onSelected(category.id),
          ),
        ],
        const SizedBox(width: 9),
        _StreakChip(streak: streak, loading: streakLoading, onTap: onStreak),
      ],
    ),
  );
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? AppColors.editorialAubergine
        : Theme.of(context).brightness == Brightness.dark
        ? context.riksa.surfaceRaised
        : AppColors.editorialSurface,
    borderRadius: AppRadii.fullBorder,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadii.fullBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? const Color(0xFFFFF8FC) : context.riksa.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({
    required this.streak,
    required this.loading,
    required this.onTap,
  });

  final int? streak;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.riksa.saffronSoft,
    borderRadius: AppRadii.fullBorder,
    child: InkWell(
      key: const ValueKey('learning-streak-button'),
      onTap: onTap,
      borderRadius: AppRadii.fullBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: context.riksa.saffron,
              size: 22,
            ),
            const SizedBox(width: 4),
            if (loading)
              const SizedBox.square(
                dimension: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                '${streak ?? 0}',
                style: TextStyle(
                  color: context.riksa.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _LessonCardSlot extends StatelessWidget {
  const _LessonCardSlot({
    required this.height,
    required this.isLast,
    required this.child,
  });

  static const overlap = 16.0;

  final double height;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height - (isLast ? 0 : overlap),
    child: OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: height,
      maxHeight: height,
      child: SizedBox(height: height, child: child),
    ),
  );
}

class _EditorialLessonCard extends StatelessWidget {
  const _EditorialLessonCard({
    super.key,
    required this.lesson,
    required this.index,
    required this.hasTopNotch,
    required this.eyebrow,
    required this.subject,
    required this.duration,
    required this.difficulty,
    required this.exercises,
    required this.completedLabel,
    required this.progress,
    required this.onTap,
  });

  final LessonSummary lesson;
  final int index;
  final bool hasTopNotch;
  final String eyebrow;
  final String subject;
  final String duration;
  final String difficulty;
  final String exercises;
  final String completedLabel;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _LessonTone.forSubject(context, subject, index);
    return PhysicalShape(
      clipper: _LessonCardClipper(hasTopNotch: hasTopNotch),
      color: tone.background,
      shadowColor: Colors.black.withValues(alpha: .12),
      elevation: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                end: 4,
                top: 30,
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _DashedRingsPainter(color: tone.accent),
                ),
              ),
              PositionedDirectional(
                end: 28,
                top: 62,
                child: _SubjectArtwork(tone: tone),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(26, hasTopNotch ? 30 : 24, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tone.accentStrong,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 112),
                      child: Text(
                        lesson.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: tone.foreground,
                              fontSize: 25,
                              height: 1.08,
                              letterSpacing: -.45,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _LessonMeta(
                          icon: tone.icon,
                          label: subject,
                          tone: tone,
                        ),
                        _LessonMeta(
                          icon: Icons.schedule_rounded,
                          label: duration,
                          tone: tone,
                        ),
                        _LessonMeta(
                          icon: Icons.signal_cellular_alt_rounded,
                          label: difficulty,
                          tone: tone,
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadii.fullBorder,
                              child: LinearProgressIndicator(
                                key: ValueKey('lesson-progress-${lesson.id}'),
                                value: progress,
                                minHeight: 7,
                                color: tone.accentStrong,
                                backgroundColor: tone.foreground.withValues(
                                  alpha: .12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            lesson.completed
                                ? completedLabel
                                : '${(progress! * 100).round()}%',
                            style: TextStyle(
                              color: tone.foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        '$exercises · ${lesson.baseXp} XP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tone.foreground.withValues(alpha: .7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PositionedDirectional(
                end: 20,
                bottom: 20,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.editorialAubergine,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFFFF8FC),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final _LessonTone tone;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: tone.accentStrong),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: tone.foreground.withValues(alpha: .78),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SubjectArtwork extends StatelessWidget {
  const _SubjectArtwork({required this.tone});

  final _LessonTone tone;

  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    height: 82,
    decoration: BoxDecoration(
      color: tone.accent.withValues(alpha: .24),
      shape: BoxShape.circle,
      border: Border.all(color: tone.accent.withValues(alpha: .48), width: 2),
    ),
    child: Icon(tone.icon, color: tone.accentStrong, size: 38),
  );
}

class _LessonTone {
  const _LessonTone({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.accentStrong,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final Color accent;
  final Color accentStrong;
  final IconData icon;

  static _LessonTone forSubject(
    BuildContext context,
    String subject,
    int index,
  ) {
    final value = subject.toLowerCase();
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = switch (value) {
      final s when s.contains('math') => const (
        Color(0xFFF7C9E9),
        Color(0xFFCF4C9C),
        Icons.functions_rounded,
      ),
      final s when s.contains('bio') => const (
        Color(0xFFFFFBF5),
        Color(0xFF45A76B),
        Icons.eco_rounded,
      ),
      final s when s.contains('phys') || s.contains('chem') => const (
        Color(0xFFFFD467),
        Color(0xFFD68C00),
        Icons.science_rounded,
      ),
      final s
          when s.contains('tech') ||
              s.contains('computer') ||
              s.contains('code') =>
        const (Color(0xFFC9F1D7), Color(0xFF25885A), Icons.code_rounded),
      final s when s.contains('language') || s.contains('khmer') => const (
        Color(0xFFDCCEFF),
        Color(0xFF7B58B3),
        Icons.translate_rounded,
      ),
      _ => _fallbackTone(index),
    };
    final background = isDark
        ? Color.alphaBlend(
            spec.$1.withValues(alpha: .15),
            palette.surfaceRaised,
          )
        : spec.$1;
    return _LessonTone(
      background: background,
      foreground: palette.ink,
      accent: spec.$2,
      accentStrong: isDark ? Color.lerp(spec.$2, Colors.white, .25)! : spec.$2,
      icon: spec.$3,
    );
  }

  static (Color, Color, IconData) _fallbackTone(int index) {
    const tones = [
      (Color(0xFFF7C9E9), Color(0xFFCF4C9C), Icons.auto_awesome_rounded),
      (Color(0xFFFFFBF5), Color(0xFF6A8F5A), Icons.menu_book_rounded),
      (Color(0xFFFFD467), Color(0xFFD68C00), Icons.lightbulb_rounded),
      (Color(0xFFC9F1D7), Color(0xFF25885A), Icons.school_rounded),
      (Color(0xFFDCCEFF), Color(0xFF7B58B3), Icons.public_rounded),
    ];
    return tones[index % tones.length];
  }
}

class _LessonCardClipper extends CustomClipper<Path> {
  const _LessonCardClipper({required this.hasTopNotch});

  final bool hasTopNotch;

  @override
  Path getClip(Size size) {
    const radius = 28.0;
    const notchHalfWidth = 30.0;
    const notchDepth = 14.0;
    final path = Path()..moveTo(radius, 0);
    if (hasTopNotch) {
      path
        ..lineTo((size.width / 2) - notchHalfWidth, 0)
        ..cubicTo(
          (size.width / 2) - 18,
          0,
          (size.width / 2) - 17,
          notchDepth,
          size.width / 2,
          notchDepth,
        )
        ..cubicTo(
          (size.width / 2) + 17,
          notchDepth,
          (size.width / 2) + 18,
          0,
          (size.width / 2) + notchHalfWidth,
          0,
        );
    }
    path
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _LessonCardClipper oldClipper) =>
      oldClipper.hasTopNotch != hasTopNotch;
}

class _DashedRingsPainter extends CustomPainter {
  const _DashedRingsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (final radius in [48.0, 67.0]) {
      const segments = 18;
      for (var index = 0; index < segments; index += 2) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          (math.pi * 2 / segments) * index,
          math.pi * 2 / segments * .72,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LessonStackPlaceholder extends StatelessWidget {
  const _LessonStackPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final color in const [
        AppColors.editorialPinkSoft,
        AppColors.editorialSurface,
        Color(0xFFFFD467),
      ])
        Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? context.riksa.surfaceRaised
                : color,
            borderRadius: AppRadii.extraLargeBorder,
          ),
        ),
    ],
  );
}

class _LessonSearchDelegate extends SearchDelegate<LessonSummary?> {
  _LessonSearchDelegate({
    required this.lessons,
    required this.hint,
    required this.emptyLabel,
    required this.subject,
  }) : super(searchFieldLabel: hint);

  final List<LessonSummary> lessons;
  final String hint;
  final String emptyLabel;
  final String Function(LessonSummary lesson) subject;

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.close_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final results = normalized.isEmpty
        ? lessons
        : lessons.where((lesson) {
            return lesson.title.toLowerCase().contains(normalized) ||
                lesson.description.toLowerCase().contains(normalized) ||
                subject(lesson).toLowerCase().contains(normalized);
          }).toList();
    if (results.isEmpty) return Center(child: Text(emptyLabel));
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final lesson = results[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mediumBorder),
          tileColor: context.riksa.surface,
          leading: const CircleAvatar(
            backgroundColor: AppColors.editorialPinkSoft,
            foregroundColor: AppColors.editorialAubergine,
            child: Icon(Icons.menu_book_rounded),
          ),
          title: Text(
            lesson.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subject(lesson)),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: () => close(context, lesson),
        );
      },
    );
  }
}

double? _lessonProgress(LessonSummary lesson) {
  if (lesson.completed) return 1;
  return lesson.progress;
}

String _subject(AppLocalizations l10n, LessonSummary lesson) =>
    lesson.categoryName.trim().isEmpty
    ? l10n.generalSubject
    : lesson.categoryName;

int _duration(LessonSummary lesson) =>
    lesson.durationMinutes ?? math.max(5, lesson.exerciseCount * 4);

String _difficulty(AppLocalizations l10n, LessonDifficulty? value) =>
    switch (value) {
      LessonDifficulty.easy => l10n.difficultyEasy,
      LessonDifficulty.medium => l10n.difficultyMedium,
      LessonDifficulty.hard => l10n.difficultyHard,
      LessonDifficulty.difficult => l10n.difficultyDifficult,
      null => l10n.allLevels,
    };

extension on LessonCatalogState {
  int get filterCount =>
      (selectedGrade == null ? 0 : 1) +
      (selectedCategoryId == null ? 0 : 1) +
      (selectedDifficulty == null ? 0 : 1);
}
