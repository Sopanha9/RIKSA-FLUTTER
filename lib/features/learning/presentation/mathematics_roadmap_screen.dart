import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../data/learning_models.dart';
import '../providers/learning_roadmap_provider.dart';
import '../providers/lesson_catalog_provider.dart';

class LearningRoadmapScreen extends ConsumerWidget {
  const LearningRoadmapScreen({
    super.key,
    required this.categoryId,
    this.currentLesson,
  });

  final String categoryId;
  final LessonSummary? currentLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId.isEmpty) {
      return _RoadmapFailure(
        message: 'This lesson is not connected to a roadmap yet.',
        onRetry: context.pop,
        actionLabel: 'Back to learning',
      );
    }

    final roadmap = ref.watch(learningRoadmapProvider(categoryId));
    return roadmap.when(
      loading: () => const _RoadmapLoading(),
      error: (error, _) => _RoadmapFailure(
        message: 'We couldn’t load your roadmap. ${_friendlyError(error)}',
        onRetry: () => ref.invalidate(learningRoadmapProvider(categoryId)),
      ),
      data: (data) => _RoadmapContent(
        roadmap: data,
        onRefresh: () =>
            ref.refresh(learningRoadmapProvider(categoryId).future),
        onOpenLesson: (lesson) =>
            _openLesson(context, ref, roadmap: data, lesson: lesson),
        onSkipUnit: (unit) =>
            _skipUnit(context, ref, categoryId: categoryId, unit: unit),
        onResumeUnit: (unit) =>
            _resumeUnit(context, ref, categoryId: categoryId, unit: unit),
      ),
    );
  }

  Future<void> _openLesson(
    BuildContext context,
    WidgetRef ref, {
    required LearningRoadmap roadmap,
    required RoadmapLesson lesson,
  }) async {
    try {
      await ref.read(learningApiProvider).startLesson(lesson.id);
      ref.invalidate(learningRoadmapProvider(roadmap.categoryId));
      if (!context.mounted) return;
      await context.push(
        '/learn/${lesson.id}',
        extra: lesson.toSummary(
          categoryId: roadmap.categoryId,
          categoryName: roadmap.categoryName,
        ),
      );
      ref.invalidate(learningRoadmapProvider(roadmap.categoryId));
      await ref.read(lessonCatalogProvider.notifier).load();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _skipUnit(
    BuildContext context,
    WidgetRef ref, {
    required String categoryId,
    required RoadmapUnit unit,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Skip ${unit.title}?'),
        content: const Text(
          'You will not earn XP for skipped lessons. The next unit will unlock, and you can resume this unit later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep learning'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(learningApiProvider).skipRoadmapUnit(unit.id);
      ref.invalidate(learningRoadmapProvider(categoryId));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _resumeUnit(
    BuildContext context,
    WidgetRef ref, {
    required String categoryId,
    required RoadmapUnit unit,
  }) async {
    try {
      await ref.read(learningApiProvider).resumeRoadmapUnit(unit.id);
      ref.invalidate(learningRoadmapProvider(categoryId));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }
}

class _RoadmapContent extends StatelessWidget {
  const _RoadmapContent({
    required this.roadmap,
    required this.onRefresh,
    required this.onOpenLesson,
    required this.onSkipUnit,
    required this.onResumeUnit,
  });

  final LearningRoadmap roadmap;
  final Future<void> Function() onRefresh;
  final ValueChanged<RoadmapLesson> onOpenLesson;
  final ValueChanged<RoadmapUnit> onSkipUnit;
  final ValueChanged<RoadmapUnit> onResumeUnit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.riksa.canvas,
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: context.riksa.math,
        onRefresh: onRefresh,
        child: ListView(
          key: const PageStorageKey('mathematics-roadmap-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            _RoadmapHeader(title: roadmap.categoryName, onBack: context.pop),
            const SizedBox(height: 14),
            _SubjectRoadmapHero(roadmap: roadmap),
            const SizedBox(height: 12),
            _WeeklyLearningStrip(activeDates: roadmap.activeDates),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Your path',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.riksa.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < roadmap.units.length; index++)
              _RoadmapUnitItem(
                unit: roadmap.units[index],
                isFirst: index == 0,
                isLast: index == roadmap.units.length - 1,
                onOpenLesson: onOpenLesson,
                onSkip: () => onSkipUnit(roadmap.units[index]),
                onResume: () => onResumeUnit(roadmap.units[index]),
              ),
          ],
        ),
      ),
    ),
  );
}

class _RoadmapHeader extends StatelessWidget {
  const _RoadmapHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Material(
        color: context.riksa.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        child: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          letterSpacing: 1.25,
          fontWeight: FontWeight.w900,
          color: context.riksa.ink,
        ),
      ),
    ],
  );
}

class _SubjectRoadmapHero extends StatelessWidget {
  const _SubjectRoadmapHero({required this.roadmap});

  final LearningRoadmap roadmap;

  @override
  Widget build(BuildContext context) {
    final kind = subjectKindFor(roadmap.categoryName);
    final color = subjectColor(context, kind);
    final surface = context.riksa.surface;
    return Container(
      height: 188,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(color.withValues(alpha: .2), surface),
            Color.alphaBlend(color.withValues(alpha: .08), surface),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.riksa.outline),
        boxShadow: RiksaElevation.low(Theme.of(context).brightness),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: 22,
              top: 40,
              child: SubjectArtwork(kind: kind, color: color, size: 104),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roadmap.categoryName.toUpperCase(),
                    style: TextStyle(
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Learning\nRoadmap',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      height: 1.1,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: context.riksa.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${roadmap.completedLessons} of ${roadmap.totalLessons} lessons completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.riksa.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: 190,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: roadmap.progress,
                        minHeight: 7,
                        backgroundColor: context.riksa.outline,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyLearningStrip extends StatelessWidget {
  const _WeeklyLearningStrip({required this.activeDates});

  final List<DateTime> activeDates;

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: context.riksa.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: RiksaElevation.low(Theme.of(context).brightness),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = monday.add(Duration(days: index));
          final complete = activeDates.any((value) => _sameDate(value, date));
          final isToday = _sameDate(today, date);
          final fill = complete
              ? context.riksa.jade
              : isToday
              ? context.riksa.math
              : context.riksa.creamSoft;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday ? context.riksa.math : context.riksa.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                child: Icon(
                  complete
                      ? Icons.check_rounded
                      : isToday
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: isToday ? 8 : 14,
                  color: complete || isToday
                      ? Colors.white
                      : context.riksa.inkMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RoadmapUnitItem extends StatelessWidget {
  const _RoadmapUnitItem({
    required this.unit,
    required this.isFirst,
    required this.isLast,
    required this.onOpenLesson,
    required this.onSkip,
    required this.onResume,
  });

  final RoadmapUnit unit;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<RoadmapLesson> onOpenLesson;
  final VoidCallback onSkip;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final completed = unit.status == RoadmapUnitStatus.completed;
    final current = unit.status == RoadmapUnitStatus.current;
    final skipped = unit.status == RoadmapUnitStatus.skipped;
    final color = completed
        ? context.riksa.jade
        : current
        ? context.riksa.math
        : skipped
        ? context.riksa.saffron
        : context.riksa.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: color)),
                _RoadmapNode(unit: unit, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: completed || skipped
                          ? color
                          : context.riksa.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _RoadmapUnitCard(
                unit: unit,
                onOpenLesson: onOpenLesson,
                onSkip: onSkip,
                onResume: onResume,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapNode extends StatelessWidget {
  const _RoadmapNode({required this.unit, required this.color});

  final RoadmapUnit unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('roadmap-node-${unit.id}'),
    width: unit.status == RoadmapUnitStatus.current ? 40 : 34,
    height: unit.status == RoadmapUnitStatus.current ? 40 : 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: unit.status == RoadmapUnitStatus.current
          ? [
              BoxShadow(
                color: color.withValues(alpha: .3),
                blurRadius: 8,
                spreadRadius: 4,
              ),
            ]
          : null,
    ),
    child: Text(
      unit.position.toString().padLeft(2, '0'),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _RoadmapUnitCard extends StatefulWidget {
  const _RoadmapUnitCard({
    required this.unit,
    required this.onOpenLesson,
    required this.onSkip,
    required this.onResume,
  });

  final RoadmapUnit unit;
  final ValueChanged<RoadmapLesson> onOpenLesson;
  final VoidCallback onSkip;
  final VoidCallback onResume;

  @override
  State<_RoadmapUnitCard> createState() => _RoadmapUnitCardState();
}

class _RoadmapUnitCardState extends State<_RoadmapUnitCard> {
  late bool _expanded;

  RoadmapUnit get unit => widget.unit;

  @override
  void initState() {
    super.initState();
    _expanded = unit.status == RoadmapUnitStatus.current;
  }

  @override
  void didUpdateWidget(covariant _RoadmapUnitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit.status != unit.status &&
        unit.status == RoadmapUnitStatus.current) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = unit.status == RoadmapUnitStatus.completed;
    final current = unit.status == RoadmapUnitStatus.current;
    final skipped = unit.status == RoadmapUnitStatus.skipped;
    final locked = unit.status == RoadmapUnitStatus.locked;
    final background = current
        ? Color.alphaBlend(
            context.riksa.math.withValues(alpha: .14),
            context.riksa.surface,
          )
        : completed
        ? Color.alphaBlend(
            context.riksa.jade.withValues(alpha: .1),
            context.riksa.surface,
          )
        : skipped
        ? Color.alphaBlend(
            context.riksa.saffron.withValues(alpha: .1),
            context.riksa.surface,
          )
        : context.riksa.surface;
    final border = current
        ? context.riksa.math.withValues(alpha: .35)
        : completed
        ? context.riksa.jade.withValues(alpha: .35)
        : skipped
        ? context.riksa.saffron.withValues(alpha: .35)
        : context.riksa.outline;

    return Material(
      key: ValueKey('roadmap-unit-${unit.id}'),
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: border, width: current ? 1.5 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: PageStorageKey('roadmap-unit-expansion-${unit.id}'),
            onTap: locked ? null : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (current) ...[
                    _StatusPill(
                      label: 'YOU ARE HERE',
                      color: context.riksa.math,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit.title,
                          style: RiksaTypography.titleStyleFor(
                            unit.title,
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: locked
                                  ? context.riksa.inkMuted
                                  : context.riksa.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                            khmerHeight: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : skipped
                            ? Icons.fast_forward_rounded
                            : locked
                            ? Icons.lock_outline_rounded
                            : _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: completed
                            ? context.riksa.jade
                            : skipped
                            ? context.riksa.saffron
                            : locked
                            ? context.riksa.inkFaint
                            : context.riksa.math,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locked
                        ? unit.description
                        : '${unit.completedLessons} of ${unit.totalLessons} lessons • ${unit.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.riksa.inkMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final lesson in unit.lessons)
                    _RoadmapLessonTile(
                      lesson: lesson,
                      onTap:
                          lesson.status == RoadmapLessonStatus.locked ||
                              lesson.status == RoadmapLessonStatus.skipped
                          ? null
                          : () => widget.onOpenLesson(lesson),
                    ),
                  const SizedBox(height: 6),
                  if (unit.skippable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: ValueKey('skip-roadmap-unit-${unit.id}'),
                        onPressed: widget.onSkip,
                        icon: const Icon(Icons.fast_forward_rounded, size: 18),
                        label: const Text('Skip this unit'),
                      ),
                    ),
                  if (skipped)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: ValueKey('resume-roadmap-unit-${unit.id}'),
                        onPressed: widget.onResume,
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: const Text('Resume this unit'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: context.riksa.surfaceRaised,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 8,
        letterSpacing: .4,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _RoadmapLessonTile extends StatelessWidget {
  const _RoadmapLessonTile({required this.lesson, this.onTap});

  final RoadmapLesson lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final complete = lesson.status == RoadmapLessonStatus.completed;
    final active =
        lesson.status == RoadmapLessonStatus.inProgress ||
        lesson.status == RoadmapLessonStatus.available;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? context.riksa.surfaceRaised : context.riksa.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: ValueKey('roadmap-lesson-${lesson.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  complete
                      ? Icons.check_circle_rounded
                      : active
                      ? Icons.play_circle_fill_rounded
                      : Icons.lock_outline_rounded,
                  color: complete
                      ? context.riksa.jade
                      : active
                      ? context.riksa.math
                      : context.riksa.inkFaint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: RiksaTypography.titleStyleFor(
                          lesson.title,
                          TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: onTap == null
                                ? context.riksa.inkMuted
                                : context.riksa.ink,
                          ),
                          khmerHeight: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _LessonMeta(
                            icon: Icons.schedule_rounded,
                            label: '${lesson.estimatedMinutes} min',
                          ),
                          _LessonMeta(
                            icon: Icons.edit_note_rounded,
                            label: '${lesson.exerciseCount} exercises',
                          ),
                          _LessonMeta(
                            icon: Icons.bolt_rounded,
                            label: '+${lesson.rewardXp} XP',
                          ),
                        ],
                      ),
                      if (lesson.progress > 0 && !complete) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: lesson.progress,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(99),
                          color: context.riksa.math,
                          backgroundColor: context.riksa.outline,
                        ),
                      ],
                    ],
                  ),
                ),
                if (active) const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: context.riksa.inkMuted),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          color: context.riksa.inkMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _RoadmapLoading extends StatelessWidget {
  const _RoadmapLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.riksa.canvas,
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: const Center(child: CircularProgressIndicator()),
  );
}

class _RoadmapFailure extends StatelessWidget {
  const _RoadmapFailure({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Try again',
  });

  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(actionLabel)),
          ],
        ),
      ),
    ),
  );
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('404')) {
    return 'No roadmap is published for this subject yet.';
  }
  if (text.contains('401')) return 'Please sign in again.';
  return 'Please check your connection and try again.';
}
