import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/learning_models.dart';
import '../providers/learning_roadmap_provider.dart';
import 'learning_design.dart';
import 'roadmap_stones.dart';
import 'widgets/learning_atoms.dart';

/// A subject's Grade 12 path, drawn as a spine of stones.
///
/// Every STEM subject uses this screen. It is deliberately not a list: the
/// syllabus is strictly ordered, so the ordering has to be visible, and the
/// path has to end somewhere the learner is aiming for.
class LearningRoadmapScreen extends ConsumerWidget {
  const LearningRoadmapScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roadmap = ref.watch(learningRoadmapProvider(categoryId));

    return Scaffold(
      backgroundColor: context.riksa.canvas,
      body: roadmap.when(
        loading: () => const _RoadmapSkeleton(),
        error: (_, _) => SafeArea(
          child: IllustratedEmptyState(
            title: l10n.roadmapLoadFailed,
            body: l10n.noLessonsForFilters,
            actionLabel: l10n.tryAgain,
            onAction: () =>
                ref.invalidate(learningRoadmapProvider(categoryId)),
          ),
        ),
        data: (data) => RefreshIndicator(
          color: learningAnchor(context),
          onRefresh: () =>
              ref.refresh(learningRoadmapProvider(categoryId).future),
          child: _RoadmapBody(roadmap: data),
        ),
      ),
    );
  }
}

class _RoadmapBody extends StatelessWidget {
  const _RoadmapBody({required this.roadmap});

  final LearningRoadmap roadmap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stones = buildRoadmapStones(roadmap);
    final summary = RoadmapSummary.of(roadmap, stones);
    final subject = stemSubjectFor(roadmap.categoryName);

    return CustomScrollView(
      key: const PageStorageKey('subject-roadmap-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _RoadmapHeader(
            name: roadmap.categoryName,
            subject: subject,
            summary: summary,
          ),
        ),
        if (stones.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: RiksaSpacing.xl),
              child: IllustratedEmptyState(
                title: l10n.roadmapEmpty,
                body: l10n.roadmapEmptyBody,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 132),
            sliver: SliverList.builder(
              // One extra row for the goal stone that closes the path.
              itemCount: stones.length + 1,
              itemBuilder: (context, index) => index == stones.length
                  ? _GoalStone(units: stones.length, lessons: summary.total)
                  : _Stone(stone: stones[index]),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _RoadmapHeader extends StatelessWidget {
  const _RoadmapHeader({
    required this.name,
    required this.subject,
    required this.summary,
  });

  final String name;
  final StemSubject subject;
  final RoadmapSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = subjectTone(context, subject);
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.feature + 2),
      ),
      child: ColoredBox(
        color: tone.surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).backButtonTooltip,
                  onTap: context.pop,
                ),
                const SizedBox(height: RiksaSpacing.md + 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: RiksaTypography.titleStyleFor(
                              name,
                              theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 27,
                                height: 1.12,
                                letterSpacing: -.7,
                                fontWeight: FontWeight.w700,
                              ),
                              khmerHeight: 1.28,
                            ),
                          ),
                          const SizedBox(height: RiksaSpacing.xxs + 1),
                          Text(
                            l10n.gradeStemLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tone.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: RiksaSpacing.xs + 1),
                          Text(
                            summary.total == 0
                                ? l10n.roadmapEmpty
                                : '${l10n.lessonsDoneOfTotal(summary.completed, summary.total)}'
                                      ' · '
                                      '${l10n.unitOfTotal(summary.currentUnit, summary.totalUnits)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: context.riksa.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (summary.total > 0) ...[
                      const SizedBox(width: RiksaSpacing.md),
                      _ProgressRing(
                        fraction: summary.fraction,
                        color: context.riksa.ink,
                        background: tone.accent.withValues(alpha: .25),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.fraction,
    required this.color,
    required this.background,
  });

  final double fraction;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction.clamp(0, 1) * 100).round();
    return Semantics(
      label: '$percent%',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 78,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 78,
              child: CircularProgressIndicator(
                key: const ValueKey('roadmap-progress-ring'),
                value: fraction.clamp(0, 1).toDouble(),
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: background,
              ),
            ),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: context.riksa.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: context.riksa.ink),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Stones
// ---------------------------------------------------------------------------

/// The connector, node and card for one step of the path.
///
/// The connector is drawn by the row itself rather than by a shared painter, so
/// a stone of any height stays joined to the next one.
class _Stone extends StatelessWidget {
  const _Stone({required this.stone});

  static const _nodeSize = 36.0;
  static const _gutter = 48.0;

  final RoadmapStone stone;

  @override
  Widget build(BuildContext context) {
    final tone = statusTone(context, stone.status);
    final isCurrent = stone.status == LearningStatus.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _gutter,
            child: Column(
              children: [
                _StoneNode(stone: stone),
                // The connector fills whatever height the card next to it
                // ends up needing, so a three line Khmer title cannot break
                // the spine. It is drawn even on the last stone, because the
                // goal always follows.
                Expanded(
                  child: Center(
                    child: Container(
                      width: 3,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: stone.status == LearningStatus.done
                            ? statusTone(
                                context,
                                LearningStatus.done,
                              ).accent.withValues(alpha: .4)
                            : context.riksa.outline,
                        borderRadius: AppRadii.fullBorder,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StoneCard(stone: stone, tone: tone, elevated: isCurrent),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoneNode extends StatelessWidget {
  const _StoneNode({required this.stone});

  final RoadmapStone stone;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final done = stone.status == LearningStatus.done;
    final current = stone.status == LearningStatus.current;
    final tone = statusTone(context, stone.status);

    final background = current
        ? learningAnchor(context)
        : done
        ? tone.surface
        : palette.surface;
    final foreground = current
        ? onLearningAnchor(context)
        : done
        ? tone.accent
        : palette.inkFaint;

    return Container(
      width: _Stone._nodeSize,
      height: _Stone._nodeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: stone.status == LearningStatus.todo ||
                stone.status == LearningStatus.locked
            ? Border.all(color: palette.outline, width: 2)
            : null,
        boxShadow: current
            ? [
                BoxShadow(
                  color: statusTone(context, LearningStatus.current).surface,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: done
          ? Icon(Icons.check_rounded, size: 17, color: foreground)
          : Text(
              '${stone.index}',
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _StoneCard extends StatefulWidget {
  const _StoneCard({
    required this.stone,
    required this.tone,
    required this.elevated,
  });

  final RoadmapStone stone;
  final LearningTone tone;
  final bool elevated;

  @override
  State<_StoneCard> createState() => _StoneCardState();
}

class _StoneCardState extends State<_StoneCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.elevated;
  }

  @override
  void didUpdateWidget(covariant _StoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elevated != widget.elevated) {
      _expanded = widget.elevated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locked = widget.stone.status == LearningStatus.locked;
    final resume = widget.stone.resumableLesson?.lesson;
    final isOpenable = widget.stone.isOpenable;

    return Material(
      color: widget.tone.surface,
      borderRadius: AppRadii.panelBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOpenable ? () => setState(() => _expanded = !_expanded) : null,
        child: Semantics(
          container: true,
          enabled: isOpenable,
          hint: locked ? l10n.lessonLocked : null,
          child: Padding(
            key: ValueKey('roadmap-unit-${widget.stone.id}'),
            padding: EdgeInsets.fromLTRB(16, _expanded ? 16 : 14, 16, _expanded ? 16 : 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stone.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: RiksaTypography.titleStyleFor(
                              widget.stone.title,
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: widget.tone.ink,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.25,
                                height: 1.25,
                              ),
                              khmerHeight: 1.35,
                            ),
                          ),
                          const SizedBox(height: RiksaSpacing.xxs),
                          Text(
                            _subtitle(l10n),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: widget.tone.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOpenable && widget.stone.lessons.isNotEmpty)
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: widget.tone.accent,
                        size: 22,
                      ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: RiksaSpacing.sm + 1),
                  for (final lesson in widget.stone.lessons) ...[
                    _LessonRow(stone: lesson),
                    const SizedBox(height: RiksaSpacing.xs - 1),
                  ],
                  if (resume != null) ...[
                    const SizedBox(height: RiksaSpacing.xxs),
                    LearningPrimaryButton(
                      key: ValueKey('roadmap-continue-${widget.stone.id}'),
                      label: l10n.continueReading,
                      icon: Icons.arrow_forward_rounded,
                      background: learningAnchor(context),
                      foreground: onLearningAnchor(context),
                      onPressed: () =>
                          context.push('/learn/${resume.id}', extra: resume),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) => switch (widget.stone.status) {
    LearningStatus.done => l10n.completedLabel,
    LearningStatus.current => l10n.unitProgressShort(
      widget.stone.completedLessons,
      widget.stone.totalLessons,
    ),
    LearningStatus.locked => widget.stone.index > 1
        ? l10n.opensAfterUnit(widget.stone.index - 1)
        : l10n.lessonLockedShort,
    LearningStatus.goal => l10n.readyForExam,
    LearningStatus.todo => l10n.lessonCountLabel(widget.stone.totalLessons),
  };
}

/// A lesson inside the open unit. White pill on the unit's pastel ground, which
/// is the one level of nesting the design system allows.
class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.stone});

  final RoadmapStone stone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lesson = stone.lesson!;
    final palette = context.riksa;
    final done = stone.status == LearningStatus.done;
    final current = stone.status == LearningStatus.current;
    final locked = stone.status == LearningStatus.locked;
    final doneTone = statusTone(context, LearningStatus.done);

    final marker = done
        ? doneTone.surface
        : current
        ? learningAnchor(context)
        : palette.surfaceRaised;
    final markerIcon = done
        ? Icons.check_rounded
        : current
        ? Icons.play_arrow_rounded
        : locked
        ? Icons.lock_outline_rounded
        : null;

    return Material(
      color: palette.surface.withValues(alpha: current ? 1 : .62),
      borderRadius: AppRadii.rowBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('roadmap-lesson-${stone.id}'),
        onTap: locked
            ? null
            : () => context.push('/learn/${lesson.id}', extra: lesson),
        child: Semantics(
          button: !locked,
          enabled: !locked,
          hint: locked ? l10n.lessonLocked : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: current ? 12 : 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: marker, shape: BoxShape.circle),
                  child: markerIcon == null
                      ? null
                      : Icon(
                          markerIcon,
                          size: 12,
                          color: done
                              ? doneTone.accent
                              : current
                              ? onLearningAnchor(context)
                              : palette.inkFaint,
                        ),
                ),
                const SizedBox(width: RiksaSpacing.sm - 2),
                Expanded(
                  child: Text(
                    stone.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.titleStyleFor(
                      stone.title,
                      TextStyle(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                        color: locked ? palette.inkFaint : palette.ink,
                      ),
                      khmerHeight: 1.4,
                    ),
                  ),
                ),
                if (!done && lesson.durationMinutes != null) ...[
                  const SizedBox(width: RiksaSpacing.xs),
                  Text(
                    l10n.minutesShort(lesson.durationMinutes!),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: locked ? palette.inkFaint : palette.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Closes the path. Not a lesson: the reason the path exists.
class _GoalStone extends StatelessWidget {
  const _GoalStone({required this.units, required this.lessons});

  final int units;
  final int lessons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = statusTone(context, LearningStatus.goal);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _Stone._gutter,
          child: Center(
            child: Container(
              width: _Stone._nodeSize,
              height: _Stone._nodeSize,
              decoration: BoxDecoration(
                color: learningAnchor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: onLearningAnchor(context),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            key: const ValueKey('roadmap-goal'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
            decoration: BoxDecoration(
              color: tone.surface,
              borderRadius: AppRadii.panelBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.readyForExam,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: RiksaSpacing.xxs),
                Text(
                  l10n.wholeSyllabusSummary(units, lessons),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tone.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoadmapSkeleton extends StatelessWidget {
  const _RoadmapSkeleton();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RiksaSkeleton(width: 44, height: 44, radius: AppRadii.full),
          const SizedBox(height: RiksaSpacing.md),
          const RiksaSkeleton(width: 180, height: 26),
          const SizedBox(height: RiksaSpacing.xs),
          const RiksaSkeleton(width: 120, height: 12),
          const SizedBox(height: RiksaSpacing.xl),
          for (var index = 0; index < 5; index++) ...[
            Row(
              children: const [
                RiksaSkeleton(width: 36, height: 36, radius: AppRadii.full),
                SizedBox(width: 12),
                Expanded(
                  child: RiksaSkeleton(height: 64, radius: AppRadii.panel),
                ),
              ],
            ),
            const SizedBox(height: RiksaSpacing.md - 2),
          ],
        ],
      ),
    ),
  );
}
