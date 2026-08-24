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

class _LessonCatalogScreenState extends ConsumerState<LessonCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _entranceController;
  var _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _entranceController = AnimationController(
      vsync: this,
      duration: RiksaMotion.emphasisLong,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 420) {
      ref.read(lessonCatalogProvider.notifier).loadMore();
    }
  }

  void _startEntranceWhenReady(LessonCatalogState state) {
    if (_entranceStarted || state.lessons.isEmpty) return;
    _entranceStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonCatalogProvider);
    final streakState = ref.watch(communityStreakProvider);
    final streak = streakState.value;
    final l10n = AppLocalizations.of(context)!;
    _startEntranceWhenReady(state);

    final mission =
        state.lessons.where((lesson) => !lesson.completed).firstOrNull ??
        state.lessons.firstOrNull;

    return Scaffold(
      body: RefreshIndicator(
        color: context.riksa.jade,
        onRefresh: ref.read(lessonCatalogProvider.notifier).load,
        child: CustomScrollView(
          key: const PageStorageKey('learning-catalog-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RiksaPageHeader(
                title: l10n.learn,
                subtitle: l10n.learningHeaderSubtitle,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterButton(
                      count: state.activeFilterCount,
                      label: l10n.filters,
                      onPressed: () => _showFilters(context, state),
                    ),
                    const SizedBox(width: RiksaSpacing.xs),
                    _StreakTag(
                      value: streak?.current,
                      loading: streakState.isLoading,
                      onTap: streak == null
                          ? null
                          : () => showStreakDetailsSheet(context, streak),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                RiksaSpacing.md,
                RiksaSpacing.sm,
                RiksaSpacing.md,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  if (mission != null)
                    _CatalogReveal(
                      animation: _entranceController,
                      begin: 0,
                      end: .55,
                      child: DailyMissionCard(
                        eyebrow: l10n.dailyMissionEyebrow,
                        title: mission.title,
                        body: l10n.dailyMissionBody,
                        actionLabel: l10n.startDailyMission,
                        subject: _subjectLabel(l10n, mission),
                        onPressed: () => _openLesson(context, mission),
                      ),
                    )
                  else if (state.isLoading)
                    const _MissionSkeleton(),
                  if (state.hasActiveFilters) ...[
                    const SizedBox(height: RiksaSpacing.sm),
                    _ActiveFilters(
                      state: state,
                      onRemoveGrade: () => _applyFilters(
                        state,
                        grade: null,
                        categoryId: state.selectedCategoryId,
                        difficulty: state.selectedDifficulty,
                      ),
                      onRemoveCategory: () => _applyFilters(
                        state,
                        grade: state.selectedGrade,
                        categoryId: null,
                        difficulty: state.selectedDifficulty,
                      ),
                      onRemoveDifficulty: () => _applyFilters(
                        state,
                        grade: state.selectedGrade,
                        categoryId: state.selectedCategoryId,
                        difficulty: null,
                      ),
                    ),
                  ],
                  if (state.selectedGrade != null && !state.hasGradeData) ...[
                    const SizedBox(height: RiksaSpacing.xs),
                    _GradeDataNotice(grade: state.selectedGrade!),
                  ],
                  const SizedBox(height: RiksaSpacing.lg),
                  _CatalogReveal(
                    animation: _entranceController,
                    begin: .1,
                    end: .65,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.recommendedLessons,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (state.isLoading && state.lessons.isNotEmpty)
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.riksa.jade,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RiksaSpacing.sm),
                ],
              ),
            ),
            ..._lessonSlivers(context, state),
            const SliverToBoxAdapter(child: SizedBox(height: RiksaSpacing.lg)),
          ],
        ),
      ),
    );
  }

  List<Widget> _lessonSlivers(BuildContext context, LessonCatalogState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading && state.lessons.isEmpty) {
      return const [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              LessonCardSkeleton(),
              SizedBox(height: RiksaSpacing.sm),
              LessonCardSkeleton(),
              SizedBox(height: RiksaSpacing.sm),
              LessonCardSkeleton(),
            ]),
          ),
        ),
      ];
    }
    if (state.errorMessage != null && state.lessons.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: IllustratedEmptyState(
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
          child: IllustratedEmptyState(
            title: l10n.noLessonsFound,
            body: l10n.noLessonsForFilters,
            actionLabel: state.hasActiveFilters ? l10n.resetFilters : null,
            onAction: state.hasActiveFilters
                ? () => _applyFilters(state)
                : null,
          ),
        ),
      ];
    }

    final transitionKey = Object.hash(
      state.selectedGrade,
      state.selectedCategoryId,
      state.selectedDifficulty,
    );
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
        sliver: SliverList.separated(
          itemCount: state.lessons.length,
          separatorBuilder: (_, _) => const SizedBox(height: RiksaSpacing.sm),
          itemBuilder: (context, index) {
            final lesson = state.lessons[index];
            final card = LessonCard(
              heroTag: 'lesson-art-${lesson.id}',
              subject: _subjectLabel(l10n, lesson),
              title: lesson.title,
              durationLabel: l10n.minutesShort(_durationFor(lesson)),
              difficultyLabel: lesson.difficulty == null
                  ? l10n.allLevels
                  : _difficultyLabel(l10n, lesson.difficulty!),
              exerciseLabel: l10n.exerciseCount(lesson.exerciseCount),
              progress: lesson.completed ? 1 : lesson.progress ?? 0,
              completedLabel: l10n.completedLabel,
              onTap: () => _openLesson(context, lesson),
            );
            final revealed = index < 4
                ? _CatalogReveal(
                    animation: _entranceController,
                    begin: .18 + (index * .08),
                    end: math.min(.76 + (index * .06), 1),
                    child: card,
                  )
                : card;
            return AnimatedSwitcher(
              duration: RiksaMotion.resolve(context, RiksaMotion.standard),
              switchInCurve: RiksaMotion.standardCurve,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: .985, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey('$transitionKey-${lesson.id}'),
                child: revealed,
              ),
            );
          },
        ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(RiksaSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }

  Future<void> _showFilters(BuildContext context, LessonCatalogState state) =>
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
              for (final difficulty in LessonDifficulty.values)
                RiksaFilterOption(
                  id: difficulty.name,
                  label: _difficultyLabel(l10n, difficulty),
                ),
            ],
            selection: RiksaFilterSelection(
              grade: state.selectedGrade?.toString(),
              subject: state.selectedCategoryId,
              difficulty: state.selectedDifficulty?.name,
            ),
            onApply: (selection) => _applyFilters(
              state,
              grade: int.tryParse(selection.grade ?? ''),
              categoryId: selection.subject,
              difficulty: LessonDifficulty.values
                  .where((item) => item.name == selection.difficulty)
                  .firstOrNull,
            ),
          );
        },
      );

  Future<void> _applyFilters(
    LessonCatalogState _, {
    int? grade,
    String? categoryId,
    LessonDifficulty? difficulty,
  }) => ref
      .read(lessonCatalogProvider.notifier)
      .applyFilters(
        grade: grade,
        categoryId: categoryId,
        difficulty: difficulty,
      );

  void _openLesson(BuildContext context, LessonSummary lesson) {
    context.push('/learn/${lesson.id}', extra: lesson);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.count,
    required this.label,
    required this.onPressed,
  });
  final int count;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    value: count == 0 ? null : '$count',
    child: IconButton.filledTonal(
      key: const ValueKey('lesson-filter-button'),
      tooltip: label,
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.tune_rounded),
      ),
    ),
  );
}

class _StreakTag extends StatelessWidget {
  const _StreakTag({
    required this.value,
    required this.loading,
    required this.onTap,
  });
  final int? value;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.riksa.saffronSoft,
    shape: const StadiumBorder(),
    child: InkWell(
      key: const ValueKey('learning-streak-button'),
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: context.riksa.saffron,
            ),
            const SizedBox(width: 4),
            if (loading)
              const SizedBox.square(
                dimension: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                '${value ?? 0}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
      ),
    ),
  );
}

class _MissionSkeleton extends StatelessWidget {
  const _MissionSkeleton();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.riksa.surfaceRaised,
      borderRadius: AppRadii.largeBorder,
    ),
    child: const Padding(
      padding: EdgeInsets.all(RiksaSpacing.md),
      child: SizedBox(
        height: 176,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RiksaSkeleton(width: 92, height: 10),
            SizedBox(height: RiksaSpacing.sm),
            RiksaSkeleton(width: 230, height: 22),
            SizedBox(height: RiksaSpacing.xs),
            RiksaSkeleton(width: 180, height: 13),
            Spacer(),
            RiksaSkeleton(width: 140, height: 48, radius: AppRadii.medium),
          ],
        ),
      ),
    ),
  );
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.state,
    required this.onRemoveGrade,
    required this.onRemoveCategory,
    required this.onRemoveDifficulty,
  });
  final LessonCatalogState state;
  final VoidCallback onRemoveGrade;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveDifficulty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = state.categories
        .where((item) => item.id == state.selectedCategoryId)
        .firstOrNull;
    return AnimatedSize(
      duration: RiksaMotion.resolve(context, RiksaMotion.standard),
      curve: RiksaMotion.standardCurve,
      child: Wrap(
        spacing: RiksaSpacing.xs,
        runSpacing: RiksaSpacing.xs,
        children: [
          if (state.selectedGrade != null)
            ActiveFilterChip(
              key: const ValueKey('active-grade-filter'),
              label: l10n.gradeNumber(state.selectedGrade!),
              removeSemanticLabel: l10n.removeFilter(l10n.gradeFilter),
              onRemoved: onRemoveGrade,
            ),
          if (category != null)
            ActiveFilterChip(
              key: const ValueKey('active-subject-filter'),
              label: category.name,
              removeSemanticLabel: l10n.removeFilter(l10n.subjectFilter),
              onRemoved: onRemoveCategory,
            ),
          if (state.selectedDifficulty != null)
            ActiveFilterChip(
              key: const ValueKey('active-difficulty-filter'),
              label: _difficultyLabel(l10n, state.selectedDifficulty!),
              removeSemanticLabel: l10n.removeFilter(l10n.difficultyFilter),
              onRemoved: onRemoveDifficulty,
            ),
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
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: context.riksa.inkMuted,
        ),
        const SizedBox(width: RiksaSpacing.xs),
        Expanded(
          child: Text(
            l10n.gradeDataPending(grade),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _CatalogReveal extends StatelessWidget {
  const _CatalogReveal({
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
  });
  final Animation<double> animation;
  final double begin;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, end, curve: RiksaMotion.standardCurve),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .055),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

String _subjectLabel(AppLocalizations l10n, LessonSummary lesson) =>
    lesson.categoryName.trim().isEmpty
    ? l10n.generalSubject
    : lesson.categoryName;

int _durationFor(LessonSummary lesson) =>
    lesson.durationMinutes ?? math.max(5, lesson.exerciseCount * 4);

String _difficultyLabel(AppLocalizations l10n, LessonDifficulty difficulty) =>
    switch (difficulty) {
      LessonDifficulty.easy => l10n.difficultyEasy,
      LessonDifficulty.medium => l10n.difficultyMedium,
      LessonDifficulty.hard => l10n.difficultyHard,
      LessonDifficulty.difficult => l10n.difficultyDifficult,
    };

extension on LessonCatalogState {
  bool get hasActiveFilters => activeFilterCount > 0;
  int get activeFilterCount =>
      (selectedGrade == null ? 0 : 1) +
      (selectedCategoryId == null ? 0 : 1) +
      (selectedDifficulty == null ? 0 : 1);
}
