import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_bottom_navigation_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
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
  bool _navigationCollapsed = false;
  double _directionTravel = 0;
  double? _lastOffset;
  ScrollDirection? _trackedDirection;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter < 420) {
      ref.read(lessonCatalogProvider.notifier).loadMore();
    }

    final current = position.pixels;
    final previous = _lastOffset ?? current;
    _lastOffset = current;
    final delta = current - previous;
    final direction = position.userScrollDirection;
    final down = direction == ScrollDirection.reverse && delta > 0;
    final up = direction == ScrollDirection.forward && delta < 0;
    if ((!down && !up) || delta.abs() < .1) return;

    if (_trackedDirection != direction) {
      _trackedDirection = direction;
      _directionTravel = 0;
    }
    _directionTravel += delta.abs();
    if (_directionTravel < 18) return;
    _directionTravel = 0;
    if (_navigationCollapsed != down) {
      setState(() => _navigationCollapsed = down);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonCatalogProvider);
    final streak = ref.watch(communityStreakProvider).value?.current ?? 0;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: RiksaBottomNavigationBar(
        currentIndex: 1,
        collapsed: _navigationCollapsed,
        onSelected: (index) {
          if (index == 0) {
            ref.invalidate(socialFeedProvider);
            context.go('/home');
          }
          if (index == 2) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.aiTutorComingSoon)));
          }
          if (index == 4) context.go('/profile');
        },
        onCollapsedTap: () {
          ref.invalidate(socialFeedProvider);
          context.go('/home');
        },
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimaryHover,
        onRefresh: ref.read(lessonCatalogProvider.notifier).load,
        child: CustomScrollView(
          key: const PageStorageKey('learning-catalog-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                l10n.learn,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 19,
                            color: Color(0xFFF97316),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$streak',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              sliver: SliverList.list(
                children: [
                  _LearningOverview(state: state),
                  const SizedBox(height: 25),
                  _FilterLabel(
                    icon: Icons.school_outlined,
                    label: l10n.gradeFilter,
                  ),
                  const SizedBox(height: 10),
                  _GradeFilter(state: state),
                  if (state.selectedGrade != null && !state.hasGradeData) ...[
                    const SizedBox(height: 9),
                    _GradeDataNotice(grade: state.selectedGrade!),
                  ],
                  const SizedBox(height: 22),
                  _FilterLabel(
                    icon: Icons.grid_view_rounded,
                    label: l10n.subjectFilter,
                  ),
                  const SizedBox(height: 10),
                  _CategoryFilter(state: state),
                  const SizedBox(height: 22),
                  _FilterLabel(
                    icon: Icons.tune_rounded,
                    label: l10n.difficultyFilter,
                  ),
                  const SizedBox(height: 10),
                  _DifficultyFilter(state: state),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.recommendedLessons,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (state.isLoading && state.lessons.isNotEmpty)
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            ..._lessonSlivers(context, state),
            const SliverToBoxAdapter(child: SizedBox(height: 116)),
          ],
        ),
      ),
    );
  }

  List<Widget> _lessonSlivers(BuildContext context, LessonCatalogState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading && state.lessons.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state.errorMessage != null && state.lessons.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CatalogMessage(
            icon: Icons.cloud_off_rounded,
            title: l10n.lessonLoadFailed,
            body: state.errorMessage!,
            actionLabel: l10n.tryAgain,
            onAction: ref.read(lessonCatalogProvider.notifier).load,
          ),
        ),
      ];
    }
    if (state.lessons.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CatalogMessage(
            icon: Icons.menu_book_rounded,
            title: l10n.noLessonsFound,
            body: l10n.noLessonsForFilters,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: state.lessons.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) =>
              _LessonCard(lesson: state.lessons[index], index: index),
        ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }
}

class _LearningOverview extends StatelessWidget {
  const _LearningOverview({required this.state});

  final LessonCatalogState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completed = state.lessons.where((lesson) => lesson.completed).length;
    final total = state.lessons.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF8EF), Color(0xFFCFF2DA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFB7E7C6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimaryPressed.withValues(alpha: .09),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.learningHeadline,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    color: const Color(0xFF123C20),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  l10n.learningSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: const Color(0xFF42634B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox.square(
            dimension: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: .72),
                  color: AppColors.brandPrimaryHover,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF123C20),
                      ),
                    ),
                    Text(
                      l10n.doneLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF42634B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: AppColors.brandPrimaryPressed),
      const SizedBox(width: 8),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _GradeFilter extends ConsumerWidget {
  const _GradeFilter({required this.state});

  final LessonCatalogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            key: const Key('grade-filter-all'),
            label: l10n.allGrades,
            selected: state.selectedGrade == null,
            onTap: () =>
                ref.read(lessonCatalogProvider.notifier).selectGrade(null),
          ),
          for (var grade = 7; grade <= 12; grade++) ...[
            const SizedBox(width: 9),
            _FilterPill(
              key: Key('grade-filter-$grade'),
              label: l10n.gradeNumber(grade),
              selected: state.selectedGrade == grade,
              onTap: () =>
                  ref.read(lessonCatalogProvider.notifier).selectGrade(grade),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeDataNotice extends StatelessWidget {
  const _GradeDataNotice({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            l10n.gradeDataPending(grade),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.state});

  final LessonCatalogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: l10n.allSubjects,
            selected: state.selectedCategoryId == null,
            onTap: () =>
                ref.read(lessonCatalogProvider.notifier).selectCategory(null),
          ),
          for (final category in state.categories) ...[
            const SizedBox(width: 9),
            _FilterPill(
              label: category.name,
              selected: state.selectedCategoryId == category.id,
              onTap: () => ref
                  .read(lessonCatalogProvider.notifier)
                  .selectCategory(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyFilter extends ConsumerWidget {
  const _DifficultyFilter({required this.state});

  final LessonCatalogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: l10n.allLevels,
            selected: state.selectedDifficulty == null,
            onTap: () =>
                ref.read(lessonCatalogProvider.notifier).selectDifficulty(null),
          ),
          for (final difficulty in LessonDifficulty.values) ...[
            const SizedBox(width: 9),
            _FilterPill(
              label: _difficultyLabel(l10n, difficulty),
              selected: state.selectedDifficulty == difficulty,
              onTap: () => ref
                  .read(lessonCatalogProvider.notifier)
                  .selectDifficulty(difficulty),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandPrimaryHover
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimaryHover
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brandPrimaryPressed.withValues(
                        alpha: .16,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.index});

  final LessonSummary lesson;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _cardPalettes[index % _cardPalettes.length];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .78),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _categoryIcon(lesson.categoryName),
                      color: palette.foreground,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      lesson.categoryName.isEmpty
                          ? l10n.generalSubject
                          : lesson.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.foreground.withValues(alpha: .82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (lesson.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimaryHover,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.completedLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (lesson.difficulty != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _difficultyLabel(l10n, lesson.difficulty!),
                        style: TextStyle(
                          color: palette.foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                lesson.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  color: palette.foreground,
                ),
              ),
              if (lesson.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lesson.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: palette.foreground.withValues(alpha: .72),
                  ),
                ),
              ],
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 19,
                    color: palette.foreground.withValues(alpha: .74),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.exerciseCount(lesson.exerciseCount),
                    style: TextStyle(
                      color: palette.foreground.withValues(alpha: .74),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: palette.foreground.withValues(alpha: .74),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      l10n.baseXpLabel(lesson.baseXp),
                      style: TextStyle(
                        color: palette.foreground.withValues(alpha: .74),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .86),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.foreground.withValues(alpha: .14),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: palette.foreground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.brandPrimaryHover),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
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

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('math')) return Icons.calculate_outlined;
  if (value.contains('computer') || value.contains('tech')) {
    return Icons.computer_rounded;
  }
  if (value.contains('chem')) return Icons.science_outlined;
  if (value.contains('bio') || value.contains('health')) {
    return Icons.eco_outlined;
  }
  if (value.contains('english') || value.contains('khmer')) {
    return Icons.translate_rounded;
  }
  return Icons.menu_book_rounded;
}

const _cardPalettes = <_LessonCardPalette>[
  _LessonCardPalette(
    background: Color(0xFFE5F3EA),
    border: Color(0xFFCDE6D5),
    foreground: Color(0xFF173F25),
  ),
  _LessonCardPalette(
    background: Color(0xFFF1EEE3),
    border: Color(0xFFE4DECC),
    foreground: Color(0xFF3D3A25),
  ),
  _LessonCardPalette(
    background: Color(0xFFEDF4EC),
    border: Color(0xFFD8E7D5),
    foreground: Color(0xFF29452B),
  ),
];

class _LessonCardPalette {
  const _LessonCardPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
