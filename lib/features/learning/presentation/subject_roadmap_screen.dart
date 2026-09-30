import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../data/learning_models.dart';
import '../providers/learning_roadmap_provider.dart';
import 'learning_design.dart';
import 'roadmap_stones.dart';
import 'subject_map.dart';
import 'widgets/learning_atoms.dart';
import 'widgets/learning_status_bar.dart';

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
      // The loaded roadmap draws its own header with a back button.
      appBar: roadmap.hasValue ? null : const LearningStatusBar(),
      body: roadmap.when(
        loading: () => const _RoadmapSkeleton(),
        error: (_, _) => SafeArea(
          top: false,
          child: IllustratedEmptyState(
            title: l10n.roadmapLoadFailed,
            body: l10n.loadFailedCheckConnection,
            actionLabel: l10n.tryAgain,
            onAction: () => ref.invalidate(learningRoadmapProvider(categoryId)),
            secondaryLabel: l10n.backToSubjects,
            onSecondary: () => context.go('/learn'),
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

class _RoadmapBody extends StatefulWidget {
  const _RoadmapBody({required this.roadmap});

  final LearningRoadmap roadmap;

  @override
  State<_RoadmapBody> createState() => _RoadmapBodyState();
}

class _RoadmapBodyState extends State<_RoadmapBody> {
  final _headerKey = GlobalKey();

  /// Bottom edge of the floating header, measured after it lays out. The
  /// first guess is close enough that the map barely moves when it lands.
  double _headerBottom = 170;

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !mounted) return;
    final bottom = box.size.height;
    if ((bottom - _headerBottom).abs() > 1) {
      setState(() => _headerBottom = bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = widget.roadmap;
    final l10n = AppLocalizations.of(context)!;
    final stones = buildRoadmapStones(roadmap);
    final summary = RoadmapSummary.of(roadmap, stones);
    final subject = stemSubjectFor(roadmap.categoryName);
    final mapArt = subjectMapArtFor(subject);
    final mapLessons = [for (final unit in stones) ...unit.lessons];

    // The map runs to the top of the screen and the header floats over it as
    // frosted glass, pinned, so progress stays in view along the whole road.
    if (mapArt != null && mapLessons.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
      return Stack(
        children: [
          CustomScrollView(
            key: const PageStorageKey('subject-roadmap-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SubjectMap(
                  art: mapArt,
                  lessons: mapLessons,
                  // Room for the buddy, who stands above the first stop.
                  topInset: _headerBottom + 64,
                  // Clears the floating navigation bar below the goal, with
                  // scenery rather than a blank strip.
                  bottomExtension: 132 + MediaQuery.paddingOf(context).bottom,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: KeyedSubtree(
              key: _headerKey,
              child: _RoadmapHeader(
                name: roadmap.categoryName,
                subject: subject,
                summary: summary,
                floating: true,
                // On the map the buddy stands at the current lesson instead.
                showBuddy: false,
              ),
            ),
          ),
        ],
      );
    }

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
              itemBuilder: (context, index) => RiksaEntrance(
                index: index,
                child: index == stones.length
                    ? _GoalStone(units: stones.length, lessons: summary.total)
                    : _Stone(
                        stone: stones[index],
                        completedOutOfOrder:
                            stones[index].status == LearningStatus.done &&
                            stones
                                .take(index)
                                .any(
                                  (earlier) =>
                                      earlier.status != LearningStatus.done,
                                ),
                      ),
              ),
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
    this.showBuddy = true,
    this.floating = false,
  });

  final String name;
  final StemSubject subject;
  final RoadmapSummary summary;
  final bool showBuddy;

  /// Frosted glass over the map instead of a solid band above the list.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = subjectTone(context, subject);
    final theme = Theme.of(context);
    final palette = context.riksa;
    const radius = BorderRadius.all(Radius.circular(AppRadii.feature));

    final content = Row(
      children: [
        LearningCircleButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => leaveLearningScreen(context),
        ),
        const SizedBox(width: RiksaSpacing.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(stemSubjectIcon(subject), size: 14, color: tone.accent),
                  const SizedBox(width: RiksaSpacing.xxs + 1),
                  Flexible(
                    child: Text(
                      l10n.gradeStemLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tone.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.titleStyleFor(
                  name,
                  theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    height: 1.15,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                  ),
                  khmerHeight: 1.3,
                ),
              ),
              const SizedBox(height: RiksaSpacing.xxs),
              Text(
                summary.total == 0
                    ? l10n.roadmapEmpty
                    : '${l10n.lessonsDoneOfTotal(summary.completed, summary.total)}'
                          ' · '
                          '${l10n.unitOfTotal(summary.currentUnit, summary.totalUnits)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (summary.total > 0) ...[
          const SizedBox(width: RiksaSpacing.sm),
          if (showBuddy) ...[
            BuddyFaceReaction(
              face: summary.completed > 0
                  ? MascotFace.proud
                  : MascotFace.determined,
              size: 36,
              loops: 1,
            ),
            const SizedBox(width: RiksaSpacing.xs),
          ],
          _ProgressRing(
            fraction: summary.fraction,
            color: tone.accent,
            background: tone.accent.withValues(alpha: .18),
          ),
        ],
      ],
    );

    if (!floating) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadii.feature + 2),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: content,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Keeps the status bar readable over bright scenery.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.canvas.withValues(alpha: .75),
                    palette.canvas.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.surface.withValues(alpha: .9),
                          Color.alphaBlend(
                            tone.surface.withValues(alpha: .55),
                            palette.surface,
                          ).withValues(alpha: .86),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .55),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
        dimension: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 58,
              // The ring sweeps to the learner's position instead of being
              // painted there, so the year's progress reads as ground covered.
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: fraction.clamp(0, 1).toDouble(),
                ),
                duration: RiksaMotion.resolve(
                  context,
                  RiksaMotion.emphasisLong,
                ),
                curve: RiksaMotion.standardCurve,
                builder: (context, animated, _) => CircularProgressIndicator(
                  key: const ValueKey('roadmap-progress-ring'),
                  value: animated,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: background,
                ),
              ),
            ),
            RiksaCountUp(
              value: percent,
              format: (value) => '$value%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stones
// ---------------------------------------------------------------------------

/// The connector, node and card for one step of the path.
///
/// The connector is drawn by the row itself rather than by a shared painter, so
/// a stone of any height stays joined to the next one.
class _Stone extends StatelessWidget {
  const _Stone({required this.stone, required this.completedOutOfOrder});

  static const _nodeSize = 36.0;
  static const _gutter = 48.0;

  final RoadmapStone stone;
  final bool completedOutOfOrder;

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
              child: _StoneCard(
                stone: stone,
                tone: tone,
                elevated: isCurrent,
                completedOutOfOrder: completedOutOfOrder,
              ),
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
        border:
            stone.status == LearningStatus.todo ||
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
    required this.completedOutOfOrder,
  });

  final RoadmapStone stone;
  final LearningTone tone;
  final bool elevated;
  final bool completedOutOfOrder;

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
            padding: EdgeInsets.fromLTRB(
              16,
              _expanded ? 16 : 14,
              16,
              _expanded ? 16 : 15,
            ),
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
                                letterSpacing: 0,
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
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
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
    LearningStatus.done =>
      widget.completedOutOfOrder
          ? l10n.roadmapCompletedEarlier
          : l10n.completedLabel,
    LearningStatus.current => l10n.unitProgressShort(
      widget.stone.completedLessons,
      widget.stone.totalLessons,
    ),
    LearningStatus.locked =>
      widget.stone.index > 1
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
                  decoration: BoxDecoration(
                    color: marker,
                    shape: BoxShape.circle,
                  ),
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
                    letterSpacing: 0,
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
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
