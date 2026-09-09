import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import 'learning_design.dart';
import 'widgets/learning_atoms.dart';
import 'widgets/lesson_search_delegate.dart';

/// The learning tab's home.
///
/// It answers one question before any other: what should I study next. So the
/// screen is a single resumable lesson, the subject index, and the syllabus the
/// learner is working towards. Browsing a flat lesson list is gone; search
/// remains as a shortcut rather than the way in.
class LessonCatalogScreen extends ConsumerWidget {
  const LessonCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final home = ref.watch(learningHomeProvider);

    return Scaffold(
      backgroundColor: context.riksa.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: learningAnchor(context),
          onRefresh: () async => ref.invalidate(learningHomeProvider),
          child: home.when(
            loading: () => const _HomeSkeleton(),
            error: (_, _) => _HomeMessage(
              title: l10n.lessonLoadFailed,
              body: l10n.noLessonsForFilters,
              actionLabel: l10n.tryAgain,
              onAction: () => ref.invalidate(learningHomeProvider),
            ),
            data: (data) => _HomeBody(data: data),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.data});

  final LearningHomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (data.subjects.isEmpty) {
      return _HomeMessage(
        title: l10n.noSubjectsYet,
        body: l10n.noSubjectsYetBody,
        actionLabel: l10n.tryAgain,
        onAction: () => ref.invalidate(learningHomeProvider),
      );
    }

    return Stack(
      children: [
        ListView(
          key: const PageStorageKey('learning-home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 196),
          children: [
            const _GreetingRow(),
            const SizedBox(height: RiksaSpacing.lg),
            if (data.resumeLesson case final lesson?)
              _ContinueCard(
                lesson: lesson,
                subject: data.resumeSubject!,
                onTap: () => _openLesson(context, lesson),
              )
            else
              _AllDoneCard(),
            const SizedBox(height: RiksaSpacing.lg + RiksaSpacing.xxs),
            Text(
              l10n.yourSubjects,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: RiksaSpacing.sm),
            _SubjectGrid(subjects: data.subjects),
          ],
        ),
        if (data.hasCounts) ...[
          // The destination bar is pinned, so content passes underneath it.
          // Fade the canvas in behind it rather than letting a subject tile be
          // sliced in half by an opaque bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      context.riksa.canvas,
                      context.riksa.canvas,
                      context.riksa.canvas.withValues(alpha: 0),
                    ],
                    stops: const [0, .55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 108,
            child: _DestinationBar(data: data),
          ),
        ],
      ],
    );
  }
}

void _openLesson(BuildContext context, LessonSummary lesson) =>
    context.push('/learn/${lesson.id}', extra: lesson);

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

class _GreetingRow extends ConsumerWidget {
  const _GreetingRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final name = user?.displayName.trim().isNotEmpty ?? false
        ? user!.displayName.trim()
        : user?.username ?? '';
    final tone = subjectTone(context, StemSubject.mathematics);
    final openDrawer = AppShellScope.maybeOf(context)?.openDrawer;

    return Row(
      children: [
        Semantics(
          button: true,
          label: l10n.openProfileMenu,
          child: Tooltip(
            message: l10n.openProfileMenu,
            child: InkWell(
              key: const ValueKey('home-avatar-button'),
              onTap: openDrawer,
              customBorder: const CircleBorder(),
              child: RiksaAvatarImage(
                value: user?.avatarUrl,
                label: name.isEmpty ? '?' : name,
                size: 44,
                backgroundColor: tone.surface,
                foregroundColor: tone.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: RiksaSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isEmpty ? l10n.learningTitle : l10n.greetingNamed(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.titleStyleFor(
                  name,
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
              ),
              Text(
                l10n.gradeStemLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: RiksaSpacing.xs),
        const _StreakChip(),
        const SizedBox(width: RiksaSpacing.xs),
        const _SearchButton(),
      ],
    );
  }
}

/// Reads the same streak the social tab shows, so the number never disagrees
/// between tabs. Renders nothing at all rather than a zero while it loads.
class _StreakChip extends ConsumerWidget {
  const _StreakChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final streak = ref.watch(communityStreakProvider);
    final days = streak.asData?.value.current ?? 0;
    if (days <= 0) return const SizedBox.shrink();

    final tone = statusTone(context, LearningStatus.current);
    return Semantics(
      label: l10n.streakDays(days),
      child: Container(
        key: const ValueKey('learning-streak-chip'),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: AppRadii.fullBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: tone.accent,
            ),
            const SizedBox(width: RiksaSpacing.xxs + 2),
            Text(
              '$days',
              style: TextStyle(
                color: tone.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search survived the redesign as a shortcut, not as the way in. Filtering by
/// grade or difficulty moved with it: those only make sense over results, not
/// over a four subject index.
class _SearchButton extends ConsumerWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.searchLessons,
      child: Material(
        color: context.riksa.surface,
        shape: const CircleBorder(),
        child: InkWell(
          key: const ValueKey('learning-search-button'),
          customBorder: const CircleBorder(),
          onTap: () => _openSearch(context, ref),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: context.riksa.ink,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final lessons = [
      for (final subject in ref.read(learningHomeProvider).asData?.value.subjects ??
          const <SubjectProgress>[])
        ...subject.lessons,
    ];
    final selected = await showSearch<LessonSummary?>(
      context: context,
      delegate: LessonSearchDelegate(
        lessons: lessons,
        hint: l10n.searchLessons,
        emptyLabel: l10n.noLessonsFound,
      ),
    );
    if (selected != null && context.mounted) _openLesson(context, selected);
  }
}

// ---------------------------------------------------------------------------
// Continue
// ---------------------------------------------------------------------------

/// The one focal surface on the screen. Pink means "resume this now", which is
/// why nothing else on the home screen is allowed to be pink.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.lesson,
    required this.subject,
    required this.onTap,
  });

  final LessonSummary lesson;
  final SubjectProgress subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = statusTone(context, LearningStatus.current);
    final theme = Theme.of(context);
    final minutes = lesson.durationMinutes;
    final progress = lesson.progress ?? 0;

    return Material(
      color: tone.surface,
      borderRadius: AppRadii.featureBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('continue-lesson-${lesson.id}'),
        onTap: onTap,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -44,
              end: -48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone.accent.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 152),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      LearningBadge(
                        icon: stemSubjectIcon(subject.subject),
                        foreground: tone.accent,
                        background: context.riksa.surface,
                      ),
                      const SizedBox(width: RiksaSpacing.sm - 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subject.category.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: tone.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .9,
                                fontSize: 10.5,
                              ),
                            ),
                            Text(
                              l10n.continueLearning,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: context.riksa.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RiksaSpacing.md - 2),
                  Text(
                    lesson.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.titleStyleFor(
                      lesson.title,
                      theme.textTheme.headlineSmall?.copyWith(
                        color: tone.ink,
                        fontSize: 24,
                        height: 1.16,
                        letterSpacing: -.6,
                        fontWeight: FontWeight.w700,
                      ),
                      khmerHeight: 1.3,
                    ),
                  ),
                  const SizedBox(height: RiksaSpacing.md - 2),
                  Wrap(
                    spacing: RiksaSpacing.xs - 1,
                    runSpacing: RiksaSpacing.xs - 1,
                    children: [
                      if (minutes != null)
                        LearningPill(
                          icon: Icons.schedule_rounded,
                          label: l10n.minutesShort(minutes),
                          accent: tone.accent,
                        ),
                      if (lesson.baseXp > 0)
                        LearningPill(
                          icon: Icons.auto_awesome_rounded,
                          label: l10n.xpRewardAmount(lesson.baseXp),
                          accent: tone.accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: RiksaSpacing.md + 2),
                  Row(
                    children: [
                      Expanded(
                        child: LearningTrack(
                          key: ValueKey('continue-progress-${lesson.id}'),
                          value: progress,
                          color: tone.accent,
                          background: tone.accent.withValues(alpha: .22),
                        ),
                      ),
                      const SizedBox(width: RiksaSpacing.md),
                      _AnchorCircle(
                        icon: Icons.arrow_forward_rounded,
                        semanticLabel: l10n.continueReading,
                      ),
                    ],
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

class _AnchorCircle extends StatelessWidget {
  const _AnchorCircle({required this.icon, required this.semanticLabel});

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: learningAnchor(context),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: onLearningAnchor(context)),
    ),
  );
}

/// Shown in place of the continue card once no subject has an open lesson.
class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = statusTone(context, LearningStatus.done);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: AppRadii.featureBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LearningBadge(
            icon: Icons.check_rounded,
            foreground: tone.accent,
            background: context.riksa.surface,
          ),
          const SizedBox(height: RiksaSpacing.md),
          Text(
            l10n.everySubjectFinished,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              letterSpacing: -.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RiksaSpacing.xs - 2),
          Text(
            l10n.everySubjectFinishedBody,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.riksa.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subject index
// ---------------------------------------------------------------------------

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({required this.subjects});

  final List<SubjectProgress> subjects;

  @override
  Widget build(BuildContext context) {
    // A fixed aspect ratio would clip Khmer subject names, which run taller
    // than their English equivalents, so the tiles size to their content.
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 11.0;
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final subject in subjects)
              SizedBox(
                width: width,
                child: _SubjectTile(subject: subject),
              ),
          ],
        );
      },
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject});

  final SubjectProgress subject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = subjectTone(context, subject.subject);
    final name = subject.category.name;

    return Material(
      color: tone.surface,
      borderRadius: AppRadii.panelBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('subject-tile-${subject.category.id}'),
        onTap: () => context.push('/learn/roadmap/${subject.category.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LearningBadge(
                icon: stemSubjectIcon(subject.subject),
                foreground: tone.accent,
                background: context.riksa.surface.withValues(alpha: .72),
              ),
              const SizedBox(height: RiksaSpacing.lg + RiksaSpacing.xxs),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.titleStyleFor(
                  name,
                  Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.25,
                    height: 1.2,
                  ),
                  khmerHeight: 1.35,
                ),
              ),
              const SizedBox(height: RiksaSpacing.xs + 1),
              if (subject.unavailable)
                Text(
                  l10n.subjectUnavailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: context.riksa.inkMuted),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.subjectCountShort(subject.completed, subject.total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tone.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: RiksaSpacing.xs),
                    SizedBox(
                      width: 42,
                      child: LearningTrack(
                        key: ValueKey('subject-progress-${subject.category.id}'),
                        value: subject.fraction,
                        color: tone.accent,
                        background: tone.accent.withValues(alpha: .2),
                        height: 5,
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

// ---------------------------------------------------------------------------
// Destination
// ---------------------------------------------------------------------------

/// Pinned above the bottom navigation because it is the one thing that should
/// never scroll away: progress is only meaningful against a visible end.
class _DestinationBar extends StatelessWidget {
  const _DestinationBar({required this.data});

  final LearningHomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final anchor = learningAnchor(context);
    final onAnchor = onLearningAnchor(context);
    final days = data.examDate?.difference(DateTime.now()).inDays;

    return Container(
      key: const ValueKey('learning-destination-bar'),
      height: 68,
      padding: const EdgeInsets.fromLTRB(13, 0, 14, 0),
      decoration: BoxDecoration(
        color: anchor,
        borderRadius: AppRadii.panelBorder,
        boxShadow: RiksaElevation.low(Theme.of(context).brightness),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: onAnchor.withValues(alpha: .14),
              borderRadius: AppRadii.rowBorder,
            ),
            child: Icon(Icons.flag_rounded, size: 20, color: onAnchor),
          ),
          const SizedBox(width: RiksaSpacing.sm + 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.examDestination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: onAnchor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  l10n.lessonsDoneOfTotal(
                    data.completedLessons,
                    data.totalLessons,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: onAnchor.withValues(alpha: .64),
                  ),
                ),
              ],
            ),
          ),
          if (days != null && days > 0) ...[
            const SizedBox(width: RiksaSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusTone(context, LearningStatus.current).surface,
                borderRadius: AppRadii.fullBorder,
              ),
              child: Text(
                l10n.daysRemaining(days),
                style: TextStyle(
                  color: AppColors.editorialAubergine,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading and messages
// ---------------------------------------------------------------------------

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 196),
    children: [
      Row(
        children: [
          const RiksaSkeleton(width: 44, height: 44, radius: AppRadii.full),
          const SizedBox(width: RiksaSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              RiksaSkeleton(width: 120, height: 14),
              SizedBox(height: 6),
              RiksaSkeleton(width: 80, height: 10),
            ],
          ),
        ],
      ),
      const SizedBox(height: RiksaSpacing.lg),
      const RiksaSkeleton(height: 232, radius: AppRadii.feature),
      const SizedBox(height: RiksaSpacing.lg + RiksaSpacing.xxs),
      const RiksaSkeleton(width: 130, height: 18),
      const SizedBox(height: RiksaSpacing.sm),
      Row(
        children: const [
          Expanded(child: RiksaSkeleton(height: 132, radius: AppRadii.panel)),
          SizedBox(width: 11),
          Expanded(child: RiksaSkeleton(height: 132, radius: AppRadii.panel)),
        ],
      ),
      const SizedBox(height: 11),
      Row(
        children: const [
          Expanded(child: RiksaSkeleton(height: 132, radius: AppRadii.panel)),
          SizedBox(width: 11),
          Expanded(child: RiksaSkeleton(height: 132, radius: AppRadii.panel)),
        ],
      ),
    ],
  );
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 40, 20, 160),
    children: [
      IllustratedEmptyState(
        title: title,
        body: body,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    ],
  );
}
