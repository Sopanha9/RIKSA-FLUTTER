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
  int _deckActiveIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMore);
  }

  void _loadMore() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 480) {
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
    final mission = _mission(state.lessons);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: RefreshIndicator(
        onRefresh: ref.read(lessonCatalogProvider.notifier).load,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  streak: streak.value?.current,
                  streakLoading: streak.isLoading,
                  filterCount: state.filterCount,
                  onFilter: () => _showFilters(state),
                  onStreak: streak.value == null
                      ? null
                      : () => showStreakDetailsSheet(context, streak.value!),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              sliver: SliverToBoxAdapter(
                child: mission == null
                    ? const _MissionPlaceholder()
                    : _MissionCard(
                        lesson: mission,
                        subject: _subject(l10n, mission),
                        duration: l10n.minutesShort(_duration(mission)),
                        difficulty: _difficulty(l10n, mission.difficulty),
                        onTap: () => _open(mission),
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 34, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Recommended for you',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.riksa.ink,
                                letterSpacing: -.2,
                              ),
                        ),
                        const Spacer(),
                        if (state.lessons.isNotEmpty)
                          _DeckProgress(
                            activeIndex: _deckActiveIndex,
                            count: state.lessons.length,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Swipe up to explore more lessons',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.riksa.inkMuted.withValues(alpha: .7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ..._lessons(state, l10n),
            const SliverToBoxAdapter(child: _DeckSwipeHint()),
          ],
        ),
      ),
    );
  }

  LessonSummary? _mission(List<LessonSummary> lessons) {
    for (final lesson in lessons) {
      if (lesson.title.toLowerCase().contains('chemical equilibrium')) {
        return lesson;
      }
    }
    return lessons.where((lesson) => !lesson.completed).firstOrNull ??
        lessons.firstOrNull;
  }

  List<Widget> _lessons(LessonCatalogState state, AppLocalizations l10n) {
    if (state.isLoading && state.lessons.isEmpty) {
      return const [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(child: _DeckPlaceholder()),
        ),
      ];
    }
    if (state.lessons.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: IllustratedEmptyState(
            title: state.errorMessage == null
                ? l10n.noLessonsFound
                : l10n.lessonLoadFailed,
            body: state.errorMessage ?? l10n.noLessonsForFilters,
            actionLabel: l10n.tryAgain,
            onAction: ref.read(lessonCatalogProvider.notifier).load,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: _LessonDeck(
            lessons: state.lessons,
            subject: (lesson) => _subject(l10n, lesson),
            duration: (lesson) => l10n.minutesShort(_duration(lesson)),
            difficulty: (lesson) => _difficulty(l10n, lesson.difficulty),
            exercises: (lesson) => l10n.exerciseCount(lesson.exerciseCount),
            completed: l10n.completedLabel,
            onOpen: _open,
            onActiveIndexChanged: (idx) =>
                setState(() => _deckActiveIndex = idx),
          ),
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

  void _open(LessonSummary lesson) =>
      context.push('/learn/${lesson.id}', extra: lesson);

  Future<void> _showFilters(LessonCatalogState state) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) {
          final l10n = AppLocalizations.of(sheetContext)!;
          return FilterBottomSheet(
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

class _Header extends StatelessWidget {
  const _Header({
    required this.streak,
    required this.streakLoading,
    required this.filterCount,
    required this.onFilter,
    required this.onStreak,
  });
  final int? streak;
  final bool streakLoading;
  final int filterCount;
  final VoidCallback onFilter;
  final VoidCallback? onStreak;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          Text(
            'Learn',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 50,
              fontWeight: FontWeight.w900,
              color: palette.ink,
              letterSpacing: -1.3,
            ),
          ),
          Positioned(
            top: 66,
            left: 0,
            child: Text(
              'Grow a little every day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 19,
                color: palette.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                _HeaderButton(
                  onTap: onFilter,
                  child: const Icon(Icons.search_rounded, size: 26),
                ),
                const SizedBox(width: 10),
                _HeaderButton(
                  onTap: onFilter,
                  child: Badge(
                    isLabelVisible: filterCount > 0,
                    label: Text('$filterCount'),
                    child: const Icon(Icons.tune_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: palette.saffronSoft,
                  borderRadius: BorderRadius.circular(19),
                  child: InkWell(
                    onTap: onStreak,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 25,
                                color: palette.saffron,
                              ),
                              const SizedBox(width: 3),
                              streakLoading
                                  ? const SizedBox.square(
                                      dimension: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      '${streak ?? 0}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                            ],
                          ),
                          const Text(
                            'Day streak',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(99),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(width: 66, height: 66, child: Center(child: child)),
    ),
  );
}

class _DeckProgress extends StatelessWidget {
  const _DeckProgress({required this.activeIndex, required this.count});
  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        '${activeIndex + 1} of $count lessons',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.riksa.inkMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) => Container(
            width: 22,
            height: 5,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
            decoration: BoxDecoration(
              color: index <= activeIndex
                  ? context.riksa.jadeStrong
                  : context.riksa.jadeSoft,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    ],
  );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.lesson,
    required this.subject,
    required this.duration,
    required this.difficulty,
    required this.onTap,
  });
  final LessonSummary lesson;
  final String subject;
  final String duration;
  final String difficulty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return SizedBox(
      height: 344,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withValues(alpha: .88),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: palette.jade.withValues(alpha: .06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Chemistry illustration on right background
              Positioned(
                right: -6,
                bottom: 2,
                width: 172,
                height: 250,
                child: CustomPaint(
                  painter: _ChemistryPainter(color: palette.jadeStrong),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: palette.jade.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "TODAY'S MISSION",
                            style: TextStyle(
                              color: palette.jadeStrong,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.saffronSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 12,
                                color: palette.saffron,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+20 XP',
                                style: TextStyle(
                                  color: palette.ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lesson.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _MiniMeta(Icons.category_outlined, subject),
                        _MiniMeta(Icons.schedule_outlined, duration),
                        _MiniMeta(Icons.bolt_rounded, difficulty),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 58,
                      width: 284,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.ink,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                        label: const Text(
                          'Start lesson',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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

class _MiniMeta extends StatelessWidget {
  const _MiniMeta(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: context.riksa.inkMuted),
      const SizedBox(width: 3),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

/// A vertical swipe deck. The page scroll stays outside this controlled area.
class _LessonDeck extends StatefulWidget {
  const _LessonDeck({
    required this.lessons,
    required this.subject,
    required this.duration,
    required this.difficulty,
    required this.exercises,
    required this.completed,
    required this.onOpen,
    this.onActiveIndexChanged,
  });
  final List<LessonSummary> lessons;
  final String Function(LessonSummary) subject;
  final String Function(LessonSummary) duration;
  final String Function(LessonSummary) difficulty;
  final String Function(LessonSummary) exercises;
  final String completed;
  final ValueChanged<LessonSummary> onOpen;
  final ValueChanged<int>? onActiveIndexChanged;
  @override
  State<_LessonDeck> createState() => _LessonDeckState();
}

class _LessonDeckState extends State<_LessonDeck> {
  static const _layerHeight = 88.0;
  static const _layerStride = 70.0;
  static const _cardOverlap = 16.0;
  static const _swipeThreshold = 112.0;
  static const _maxVisibleLayers = 3;
  int _activeIndex = 0;
  int? _prevIndex;
  double _dragOffset = 0;

  int _wrap(int i) => i % widget.lessons.length;

  void _endDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final moveForward = _dragOffset < -_swipeThreshold || velocity < -480;
    final moveBack = _dragOffset > _swipeThreshold || velocity > 480;
    setState(() {
      if (moveForward) {
        _prevIndex = _activeIndex;
        _activeIndex = _wrap(_activeIndex + 1);
        widget.onActiveIndexChanged?.call(_activeIndex);
      } else if (moveBack) {
        _prevIndex = _activeIndex;
        _activeIndex = _wrap(_activeIndex - 1 + widget.lessons.length);
        widget.onActiveIndexChanged?.call(_activeIndex);
      }
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Leave enough room for two inviting previews without turning the card
    // into a full-screen colour block on compact phones.
    final cardHeight = (MediaQuery.sizeOf(context).height * .55)
        .clamp(420.0, 500.0)
        .toDouble();
    final totalLessons = widget.lessons.length;
    final visibleLayers = totalLessons > 1
        ? math.min(_maxVisibleLayers, totalLessons - 1)
        : 0;
    // This is the exact bottom edge of the last absolutely-positioned preview
    // (the first layer starts 2px beneath the active card). No hidden lesson
    // is built in normal flow, so it cannot reserve vertical scroll extent.
    final previewExtent = visibleLayers == 0
        ? 0.0
        : (_layerHeight - _cardOverlap) +
              ((visibleLayers - 1) * _layerStride);
    final deckHeight = cardHeight + previewExtent + 12;
    return SizedBox(
      height: deckHeight,
      child: ClipRect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) => setState(
            () => _dragOffset = (_dragOffset + details.delta.dy).clamp(
              -100.0,
              100.0,
            ),
          ),
          onVerticalDragEnd: _endDrag,
          onVerticalDragCancel: () => setState(() => _dragOffset = 0),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Compact lesson posters peeking from beneath the active card.
              for (var layer = visibleLayers; layer >= 1; layer--)
                _underLayer(_wrap(_activeIndex + layer), layer, cardHeight),
              if (_dragOffset > 0 && totalLessons > 1)
                _previousIncomingCard(cardHeight),
              // Leaving card (previous active)
              if (_prevIndex != null) _leavingCard(_prevIndex!, cardHeight),
              // Active card
              _activeCard(cardHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _underLayer(int index, int layer, double cardHeight) {
    final lesson = widget.lessons[index];
    final horizontalInset = layer * 5.0;
    final forwardProgress =
        (-_dragOffset / _swipeThreshold).clamp(0.0, 1.0).toDouble();
    final isIncoming = layer == 1 && forwardProgress > 0;
    final collapsedTop = cardHeight - _cardOverlap +
        ((layer - 1) * _layerStride);
    return AnimatedPositioned(
      key: ValueKey('layer-${lesson.id}'),
      duration: RiksaMotion.resolve(
        context,
        isIncoming ? Duration.zero : RiksaMotion.emphasis,
      ),
      curve: Curves.easeOutBack,
      // Keep the incoming card's header at the active card's lower edge while
      // it grows. This exposes its artwork and title during the drag instead
      // of waiting for the outgoing card to disappear.
      top: isIncoming
          ? collapsedTop - (forwardProgress * (_cardOverlap + 12))
          : collapsedTop,
      left: isIncoming ? horizontalInset * (1 - forwardProgress) : horizontalInset,
      right: isIncoming ? horizontalInset * (1 - forwardProgress) : horizontalInset,
      height: isIncoming
          ? _layerHeight + ((cardHeight - _layerHeight) * forwardProgress)
          : _layerHeight,
      child: isIncoming
          ? ClipRect(
              child: OverflowBox(
                minHeight: cardHeight,
                maxHeight: cardHeight,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: cardHeight,
                  child: _DeckCard(
                    lesson: lesson,
                    subject: widget.subject(lesson),
                    duration: widget.duration(lesson),
                    difficulty: widget.difficulty(lesson),
                    exercises: widget.exercises(lesson),
                    completed: widget.completed,
                    index: index,
                    active: true,
                    totalLessons: widget.lessons.length,
                    interactionProgress: forwardProgress,
                    onTap: () => widget.onOpen(lesson),
                  ),
                ),
              ),
            )
          : _DeckHeader(
              lesson: lesson,
              subject: widget.subject(lesson),
              index: index,
              totalLessons: widget.lessons.length,
              onTap: () => widget.onOpen(lesson),
            ),
    );
  }

  Widget _previousIncomingCard(double cardHeight) {
    final progress =
        (_dragOffset / _swipeThreshold).clamp(0.0, 1.0).toDouble();
    final index = _wrap(_activeIndex - 1 + widget.lessons.length);
    final lesson = widget.lessons[index];
    return Positioned(
      key: ValueKey('previous-${lesson.id}'),
      top: -cardHeight + (cardHeight * progress),
      left: 0,
      right: 0,
      height: cardHeight,
      child: Transform.scale(
        scale: .97 + (.03 * progress),
        alignment: Alignment.bottomCenter,
        child: _DeckCard(
          lesson: lesson,
          subject: widget.subject(lesson),
          duration: widget.duration(lesson),
          difficulty: widget.difficulty(lesson),
          exercises: widget.exercises(lesson),
          completed: widget.completed,
          index: index,
          active: true,
          totalLessons: widget.lessons.length,
          interactionProgress: progress,
          onTap: () => widget.onOpen(lesson),
        ),
      ),
    );
  }

  Widget _leavingCard(int index, double cardHeight) {
    final lesson = widget.lessons[index];
    return AnimatedPositioned(
      key: ValueKey('leaving-${lesson.id}'),
      duration: RiksaMotion.resolve(context, RiksaMotion.standard),
      curve: Curves.easeInOutCubic,
      top: -cardHeight - 32,
      left: 0,
      right: 0,
      height: cardHeight,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: RiksaMotion.resolve(context, RiksaMotion.standard),
          opacity: 0.0,
          child: Transform.scale(
            scale: .94,
            alignment: Alignment.topCenter,
            child: _DeckCard(
            lesson: lesson,
            subject: widget.subject(lesson),
            duration: widget.duration(lesson),
            difficulty: widget.difficulty(lesson),
            exercises: widget.exercises(lesson),
            completed: widget.completed,
            index: index,
            active: false,
            totalLessons: widget.lessons.length,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeCard(double cardHeight) {
    final lesson = widget.lessons[_activeIndex];
    return AnimatedPositioned(
      key: ValueKey('active-${lesson.id}'),
      duration: RiksaMotion.resolve(context, RiksaMotion.standard),
      curve: Curves.easeOutBack,
      top: _dragOffset,
      left: 0,
      right: 0,
      height: cardHeight,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('reveal-${lesson.id}'),
        duration: RiksaMotion.resolve(context, RiksaMotion.emphasis),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: .965, end: 1),
        builder: (context, value, child) => Transform.rotate(
          angle: _dragOffset * .00008,
          alignment: Alignment.topCenter,
          child: Transform.scale(
            scale: value * (1 - (_dragOffset.abs() / 12000)),
            alignment: Alignment.topCenter,
            child: Opacity(opacity: .86 + (value * .14), child: child),
          ),
        ),
        child: _DeckCard(
          lesson: lesson,
          subject: widget.subject(lesson),
          duration: widget.duration(lesson),
          difficulty: widget.difficulty(lesson),
          exercises: widget.exercises(lesson),
          completed: widget.completed,
          index: _activeIndex,
          active: true,
          totalLessons: widget.lessons.length,
          interactionProgress: (_dragOffset.abs() / _swipeThreshold)
              .clamp(0.0, 1.0)
              .toDouble(),
          onTap: () => widget.onOpen(lesson),
        ),
      ),
    );
  }
}

class _DeckHeader extends StatelessWidget {
  const _DeckHeader({
    required this.lesson,
    required this.subject,
    required this.index,
    required this.totalLessons,
    required this.onTap,
  });
  final LessonSummary lesson;
  final String subject;
  final int index;
  final int totalLessons;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final tone = _tone(context, lesson, index);
    return Container(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -16,
                width: 112,
                height: 112,
                child: IgnorePointer(
                  child: _SubjectBackgroundArtwork(
                    subject: subject,
                    color: tone.accent,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .58),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(tone.icon, size: 18, color: tone.ink),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subject.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tone.ink.withValues(alpha: .8),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${index + 1} / $totalLessons',
                        style: TextStyle(
                          color: tone.ink.withValues(alpha: .72),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(
                      lesson.completed
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_border_rounded,
                      size: 19,
                      color: tone.ink.withValues(alpha: .62),
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

class _DeckSwipeHint extends StatelessWidget {
  const _DeckSwipeHint();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.keyboard_arrow_up_rounded, size: 23),
        SizedBox(height: 1),
        Text(
          'Swipe up or down to explore',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.lesson,
    required this.subject,
    required this.duration,
    required this.difficulty,
    required this.exercises,
    required this.completed,
    required this.index,
    required this.active,
    required this.totalLessons,
    required this.onTap,
    this.interactionProgress = 0,
  });
  final LessonSummary lesson;
  final String subject;
  final String duration;
  final String difficulty;
  final String exercises;
  final String completed;
  final int index;
  final bool active;
  final int totalLessons;
  final VoidCallback onTap;
  final double interactionProgress;
  @override
  Widget build(BuildContext context) {
    final tone = _tone(context, lesson, index);
    return AnimatedContainer(
      duration: RiksaMotion.resolve(context, RiksaMotion.standard),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.background, tone.background.withValues(alpha: .9)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .48)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: active ? .10 + (interactionProgress * .04) : .06,
            ),
            blurRadius: active ? 24 + (interactionProgress * 5) : 10,
            offset: Offset(0, active ? 10 + (interactionProgress * 3) : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // Subject-specific decorative artwork background (Requirement 4)
                Positioned.fill(
                  child: _SubjectBackgroundArtwork(
                    subject: subject,
                    color: tone.accent,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: [icon] SUBJECT                      4 / 8
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .62),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(tone.icon, color: tone.ink, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              subject.toUpperCase(),
                              style: TextStyle(
                                color: tone.ink.withValues(alpha: .65),
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (active)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .65),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${index + 1} / $totalLessons',
                                style: TextStyle(
                                  color: tone.ink.withValues(alpha: .75),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else if (lesson.completed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .5),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                completed,
                                style: TextStyle(
                                  color: tone.ink.withValues(alpha: .6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 116,
                        width: double.infinity,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 174,
                            height: 116,
                            child: _SubjectBackgroundArtwork(
                              subject: subject,
                              color: tone.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Title
                      Text(
                        lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: tone.ink,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -.3,
                            ),
                      ),
                      if (lesson.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          lesson.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tone.ink.withValues(alpha: .65),
                                height: 1.4,
                              ),
                        ),
                      ],
                      const Spacer(),
                      // Bottom Row: Meta chips + CTA Arrow
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MetaChip(
                                  Icons.schedule_rounded,
                                  duration,
                                  tone.ink,
                                ),
                                _MetaChip(
                                  Icons.bolt_rounded,
                                  difficulty,
                                  tone.ink,
                                ),
                                _MetaChip(
                                  Icons.edit_note_rounded,
                                  exercises,
                                  tone.ink,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _DeckContinueButton(
                            onTap: onTap,
                            foreground: tone.ink,
                            background: tone.background,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withValues(alpha: .6)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: .7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DeckContinueButton extends StatefulWidget {
  const _DeckContinueButton({
    required this.onTap,
    required this.foreground,
    required this.background,
  });

  final VoidCallback onTap;
  final Color foreground;
  final Color background;

  @override
  State<_DeckContinueButton> createState() => _DeckContinueButtonState();
}

class _DeckContinueButtonState extends State<_DeckContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: (_) => setState(() => _pressed = true),
    onTapCancel: () => setState(() => _pressed = false),
    onTapUp: (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      duration: RiksaMotion.resolve(context, RiksaMotion.fast),
      scale: _pressed ? .92 : 1,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: widget.foreground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.foreground.withValues(alpha: .18),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_forward_rounded,
          color: widget.background,
          size: 23,
        ),
      ),
    ),
  );
}

class _Tone {
  const _Tone(this.background, this.ink, this.icon, this.accent);
  final Color background;
  final Color ink;
  final IconData icon;
  final Color accent;
}

_Tone _tone(BuildContext context, LessonSummary lesson, int index) {
  final p = context.riksa;
  final subject = lesson.categoryName.toLowerCase();
  Color accent = [
    p.science,
    p.language,
    p.math,
    p.saffron,
    p.technology,
    p.jade,
  ][index % 6];
  IconData icon = [
    Icons.science_rounded,
    Icons.menu_book_rounded,
    Icons.auto_stories_rounded,
    Icons.calculate_rounded,
    Icons.lightbulb_rounded,
    Icons.eco_rounded,
  ][index % 6];
  if (subject.contains('chem') || subject.contains('science')) {
    accent = p.science;
    icon = Icons.science_rounded;
  }
  if (subject.contains('english') || subject.contains('language')) {
    accent = p.language;
    icon = Icons.menu_book_rounded;
  }
  if (subject.contains('khmer') || subject.contains('literature')) {
    accent = p.math;
    icon = Icons.auto_stories_rounded;
  }
  if (subject.contains('phys')) {
    accent = p.saffron;
    icon = Icons.blur_on_rounded;
  }
  if (subject.contains('tech') ||
      subject.contains('code') ||
      subject.contains('computer')) {
    accent = p.technology;
    icon = Icons.terminal_rounded;
  }
  if (subject.contains('math')) {
    accent = p.saffron;
    icon = Icons.calculate_rounded;
  }
  if (subject.contains('biology')) {
    accent = p.jade;
    icon = Icons.eco_rounded;
  }
  if (subject.contains('general')) {
    accent = p.technology;
    icon = Icons.lightbulb_rounded;
  }
  return _Tone(Color.lerp(accent, Colors.white, .82)!, p.ink, icon, accent);
}

class _MissionPlaceholder extends StatelessWidget {
  const _MissionPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 205,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFE5F1E8),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
  );
}

class _DeckPlaceholder extends StatelessWidget {
  const _DeckPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 336,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFF0EDE7),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
    ),
  );
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

class _SubjectBackgroundArtwork extends StatelessWidget {
  const _SubjectBackgroundArtwork({required this.subject, required this.color});

  final String subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = subject.toLowerCase();
    if (s.contains('chem') || s.contains('science')) {
      return CustomPaint(painter: _ChemistryPainter(color: color));
    } else if (s.contains('phys')) {
      return CustomPaint(painter: _PhysicsPainter(color: color));
    } else if (s.contains('math')) {
      return CustomPaint(painter: _MathPainter(color: color));
    } else if (s.contains('tech') ||
        s.contains('code') ||
        s.contains('computer')) {
      return CustomPaint(painter: _TechPainter(color: color));
    } else if (s.contains('khmer') || s.contains('lit')) {
      return CustomPaint(painter: _KhmerPainter(color: color));
    } else if (s.contains('eng') || s.contains('lang')) {
      return CustomPaint(painter: _LanguagePainter(color: color));
    } else if (s.contains('bio')) {
      return CustomPaint(painter: _BiologyPainter(color: color));
    }
    return CustomPaint(painter: _GeneralPainter(color: color));
  }
}

class _ChemistryPainter extends CustomPainter {
  _ChemistryPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: .06)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.78;
    final cy = size.height * 0.52;

    final path = Path()
      ..moveTo(cx - 12, cy - 45)
      ..lineTo(cx + 12, cy - 45)
      ..moveTo(cx - 8, cy - 45)
      ..lineTo(cx - 8, cy - 20)
      ..lineTo(cx - 35, cy + 30)
      ..cubicTo(cx - 40, cy + 40, cx - 30, cy + 48, cx - 20, cy + 48)
      ..lineTo(cx + 20, cy + 48)
      ..cubicTo(cx + 30, cy + 48, cx + 40, cy + 40, cx + 35, cy + 30)
      ..lineTo(cx + 8, cy - 20)
      ..lineTo(cx + 8, cy - 45);

    canvas.drawPath(path, paint);

    final liquidPath = Path()
      ..moveTo(cx - 24, cy + 10)
      ..quadraticBezierTo(cx, cy + 18, cx + 24, cy + 10)
      ..lineTo(cx + 32, cy + 28)
      ..cubicTo(cx + 38, cy + 38, cx + 28, cy + 46, cx + 18, cy + 46)
      ..lineTo(cx - 18, cy + 46)
      ..cubicTo(cx - 28, cy + 46, cx - 38, cy + 38, cx - 32, cy + 28)
      ..close();
    canvas.drawPath(liquidPath, fillPaint);

    canvas.drawCircle(Offset(cx - 6, cy - 5), 4, paint);
    canvas.drawCircle(Offset(cx + 8, cy - 12), 3, paint);
    canvas.drawCircle(Offset(cx + 2, cy - 28), 2.5, paint);

    final mx = size.width * 0.90;
    final my = size.height * 0.25;
    canvas.drawCircle(Offset(mx, my), 14, paint);
    canvas.drawCircle(Offset(mx + 22, my + 10), 8, paint);
    canvas.drawLine(Offset(mx + 12, my + 5), Offset(mx + 16, my + 7), paint);
  }

  @override
  bool shouldRepaint(covariant _ChemistryPainter oldDelegate) => false;
}

class _PhysicsPainter extends CustomPainter {
  _PhysicsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: .08)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.75;
    final cy = size.height * 0.45;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.3);
    final rect = Rect.fromCenter(center: Offset.zero, width: 110, height: 50);
    canvas.drawOval(rect, paint);
    canvas.drawCircle(Offset.zero, 12, fillPaint);
    canvas.drawCircle(Offset.zero, 12, paint);
    canvas.drawCircle(const Offset(45, -10), 5, fillPaint);
    canvas.restore();

    final ax = size.width * 0.60;
    final ay = size.height * 0.70;
    canvas.drawLine(Offset(ax, ay), Offset(ax + 50, ay - 30), paint);
    canvas.drawLine(Offset(ax + 50, ay - 30), Offset(ax + 38, ay - 28), paint);
    canvas.drawLine(Offset(ax + 50, ay - 30), Offset(ax + 46, ay - 18), paint);
  }

  @override
  bool shouldRepaint(covariant _PhysicsPainter oldDelegate) => false;
}

class _MathPainter extends CustomPainter {
  _MathPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.70;
    final cy = size.height * 0.50;

    canvas.drawLine(Offset(cx - 40, cy), Offset(cx + 70, cy), paint);
    canvas.drawLine(Offset(cx, cy + 40), Offset(cx, cy - 40), paint);

    final path = Path()..moveTo(cx - 35, cy + 30);
    for (double x = -35; x <= 65; x += 2) {
      final y = -25 * math.sin(x * 0.08);
      path.lineTo(cx + x, cy + y);
    }
    canvas.drawPath(path, paint);

    final tx = size.width * 0.88;
    final ty = size.height * 0.22;
    final triPath = Path()
      ..moveTo(tx, ty - 18)
      ..lineTo(tx + 22, ty + 18)
      ..lineTo(tx - 22, ty + 18)
      ..close();
    canvas.drawPath(triPath, paint);
  }

  @override
  bool shouldRepaint(covariant _MathPainter oldDelegate) => false;
}

class _TechPainter extends CustomPainter {
  _TechPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: .05)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.76;
    final cy = size.height * 0.48;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 100, height: 70),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, paint);

    canvas.drawLine(Offset(cx - 50, cy - 18), Offset(cx + 50, cy - 18), paint);
    canvas.drawCircle(Offset(cx - 38, cy - 26), 2.5, paint);
    canvas.drawCircle(Offset(cx - 30, cy - 26), 2.5, paint);
    canvas.drawCircle(Offset(cx - 22, cy - 26), 2.5, paint);

    final bPath = Path()
      ..moveTo(cx - 25, cy - 5)
      ..lineTo(cx - 35, cy + 5)
      ..lineTo(cx - 25, cy + 15)
      ..moveTo(cx - 10, cy + 18)
      ..lineTo(cx + 5, cy - 8)
      ..moveTo(cx + 15, cy - 5)
      ..lineTo(cx + 25, cy + 5)
      ..lineTo(cx + 15, cy + 15);
    canvas.drawPath(bPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TechPainter oldDelegate) => false;
}

class _KhmerPainter extends CustomPainter {
  _KhmerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.75;
    final cy = size.height * 0.50;

    final book = Path()
      ..moveTo(cx, cy + 20)
      ..quadraticBezierTo(cx - 25, cy + 10, cx - 50, cy + 18)
      ..lineTo(cx - 50, cy - 22)
      ..quadraticBezierTo(cx - 25, cy - 30, cx, cy - 20)
      ..quadraticBezierTo(cx + 25, cy - 30, cx + 50, cy - 22)
      ..lineTo(cx + 50, cy + 18)
      ..quadraticBezierTo(cx + 25, cy + 10, cx, cy + 20)
      ..moveTo(cx, cy - 20)
      ..lineTo(cx, cy + 20);

    canvas.drawPath(book, paint);

    final swirl = Path()
      ..moveTo(cx + 25, cy - 38)
      ..cubicTo(cx + 45, cy - 50, cx + 55, cy - 25, cx + 35, cy - 20);
    canvas.drawPath(swirl, paint);
  }

  @override
  bool shouldRepaint(covariant _KhmerPainter oldDelegate) => false;
}

class _LanguagePainter extends CustomPainter {
  _LanguagePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: .05)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.72;
    final cy = size.height * 0.42;

    final bubble1 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 15, cy - 10), width: 70, height: 50),
      const Radius.circular(14),
    );
    canvas.drawRRect(bubble1, fillPaint);
    canvas.drawRRect(bubble1, paint);

    final bubble2 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 20, cy + 15), width: 60, height: 42),
      const Radius.circular(12),
    );
    canvas.drawRRect(bubble2, fillPaint);
    canvas.drawRRect(bubble2, paint);

    canvas.drawLine(Offset(cx - 35, cy - 16), Offset(cx - 5, cy - 16), paint);
    canvas.drawLine(Offset(cx - 35, cy - 6), Offset(cx - 15, cy - 6), paint);
  }

  @override
  bool shouldRepaint(covariant _LanguagePainter oldDelegate) => false;
}

class _BiologyPainter extends CustomPainter {
  _BiologyPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: .05)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.75;
    final cy = size.height * 0.48;

    final leaf = Path()
      ..moveTo(cx - 40, cy + 30)
      ..quadraticBezierTo(cx - 45, cy - 25, cx, cy - 40)
      ..quadraticBezierTo(cx + 45, cy - 25, cx + 40, cy + 30)
      ..quadraticBezierTo(cx, cy + 45, cx - 40, cy + 30);

    canvas.drawPath(leaf, fillPaint);
    canvas.drawPath(leaf, paint);

    canvas.drawLine(Offset(cx, cy - 40), Offset(cx - 40, cy + 30), paint);
    canvas.drawLine(Offset(cx - 10, cy - 20), Offset(cx + 10, cy - 15), paint);
    canvas.drawLine(Offset(cx - 20, cy), Offset(cx + 5, cy + 5), paint);
    canvas.drawLine(Offset(cx - 30, cy + 18), Offset(cx - 10, cy + 22), paint);
  }

  @override
  bool shouldRepaint(covariant _BiologyPainter oldDelegate) => false;
}

class _GeneralPainter extends CustomPainter {
  _GeneralPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.78;
    final cy = size.height * 0.45;

    canvas.drawCircle(Offset(cx, cy), 28, paint);
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      final p1 = Offset(cx + 36 * math.cos(angle), cy + 36 * math.sin(angle));
      final p2 = Offset(cx + 46 * math.cos(angle), cy + 46 * math.sin(angle));
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GeneralPainter oldDelegate) => false;
}
