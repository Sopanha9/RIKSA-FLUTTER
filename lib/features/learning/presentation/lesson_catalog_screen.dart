import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pixel_fire_icon.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/providers/social_feed_provider.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import '../providers/saved_lessons_provider.dart';
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
              body: l10n.learningLoadErrorBody,
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

    final bottomNavClearance = MediaQuery.paddingOf(context).bottom + 24;

    return ListView(
      key: const PageStorageKey('learning-home-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomNavClearance),
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
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: RiksaSpacing.sm),
        _SubjectGrid(subjects: data.subjects),
        if (data.hasCounts) ...[
          const SizedBox(height: 24),
          _DestinationBar(data: data),
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
    final frameTier = ref
        .watch(profileDashboardProvider)
        .value
        ?.gamification
        .currentTier;

    final avatar = Semantics(
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
                frameTier: frameTier,
              ),
            ),
          ),
        );
    final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isEmpty ? l10n.learningTitle : l10n.greetingNamed(name),
                maxLines: 2,
                style: RiksaTypography.titleStyleFor(
                  name,
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                l10n.gradeStemLabel,
                maxLines: 2,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.inkMuted),
              ),
            ],
          );
    const actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StreakChip(),
        SizedBox(width: RiksaSpacing.xs),
        _SavedLessonsButton(),
        SizedBox(width: RiksaSpacing.xs),
        _SearchButton(),
      ],
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: RiksaSpacing.sm),
              Expanded(child: identity),
            ],
          ),
          const SizedBox(height: RiksaSpacing.xs),
          Align(alignment: AlignmentDirectional.centerEnd, child: actions),
        ],
      );
    }
    return Row(
      children: [
        avatar,
        const SizedBox(width: RiksaSpacing.sm),
        Expanded(child: identity),
        const SizedBox(width: RiksaSpacing.xs),
        actions,
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
      child: ClipRRect(
        key: const ValueKey('learning-streak-chip'),
        borderRadius: AppRadii.fullBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.56),
              borderRadius: AppRadii.fullBorder,
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
              boxShadow: [
                BoxShadow(
                  color: context.riksa.ink.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PixelFireIcon(size: 16),
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
      child: RiksaTapFeedback(
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
      ),
    );
  }

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final lessons = [
      for (final subject
          in ref.read(learningHomeProvider).asData?.value.subjects ??
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

class _SavedLessonsButton extends ConsumerWidget {
  const _SavedLessonsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final savedCount = ref.watch(savedLessonsProvider).length;
    return Semantics(
      button: true,
      label: l10n.savedLessonsLabel,
      child: RiksaTapFeedback(
        child: Material(
          color: context.riksa.surface,
          shape: const CircleBorder(),
          child: InkWell(
            key: const ValueKey('learning-saved-lessons-button'),
            customBorder: const CircleBorder(),
            onTap: () => context.push('/learn/saved'),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 20,
                    color: context.riksa.ink,
                  ),
                  if (savedCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.riksa.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    final subjectIdentity = subjectTone(context, subject.subject);
    final palette = context.riksa;
    final theme = Theme.of(context);
    final minutes = lesson.durationMinutes;
    final progress = lesson.progress ?? 0;
    final actionLabel = progress > 0
        ? l10n.lessonResumeAction
        : l10n.lessonStartAction;

    return RiksaTapFeedback(
      child: Material(
        color: palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.featureBorder,
          side: BorderSide(color: palette.outline),
        ),
        child: InkWell(
          key: ValueKey('continue-lesson-${lesson.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubjectPixelArtwork(subject: subject.subject, size: 52),
                    const SizedBox(width: 8),
                    const BuddyFaceReaction(
                      face: MascotFace.determined,
                      size: 42,
                      loops: 1,
                    ),
                    const SizedBox(width: 12),
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
                              color: subjectIdentity.accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .9,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lesson.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: RiksaTypography.titleStyleFor(
                              lesson.title,
                              theme.textTheme.titleSmall?.copyWith(
                                color: palette.ink,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: 0,
                              ),
                              khmerHeight: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (minutes != null) ...[
                      _ContinueMetric(
                        icon: Icons.schedule_rounded,
                        label: l10n.minutesShort(minutes),
                        accent: subjectIdentity.accent,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (lesson.baseXp > 0)
                      _ContinueMetric(
                        icon: Icons.auto_awesome_rounded,
                        label: l10n.xpRewardAmount(lesson.baseXp),
                        accent: subjectIdentity.accent,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                LearningTrack(
                  key: ValueKey('continue-progress-${lesson.id}'),
                  value: progress,
                  color: subjectIdentity.accent,
                  background: palette.surfaceRaised,
                  height: 5,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    key: ValueKey('resume-lesson-${lesson.id}'),
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(
                      actionLabel,
                      style: RiksaTypography.bodyStyleFor(
                        actionLabel,
                        const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _ContinueMetric extends StatelessWidget {
  const _ContinueMetric({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? palette.surface.withValues(alpha: .42)
        : Colors.white.withValues(alpha: .58);
    final border = isDark
        ? Colors.white.withValues(alpha: .12)
        : Colors.white.withValues(alpha: .72);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.fullBorder,
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: isDark ? .14 : .06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppRadii.fullBorder,
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              fontSize: 20,
              letterSpacing: 0,
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
    // A vertical editorial list gives each subject illustration enough room to
    // act as a recognition cue. It also leaves a reliable text column for tall
    // Khmer titles instead of squeezing both into a small grid tile.
    return Column(
      children: [
        for (var index = 0; index < subjects.length; index++) ...[
          _SubjectTile(subject: subjects[index]),
          if (index != subjects.length - 1)
            const SizedBox(height: RiksaSpacing.sm + 2),
        ],
      ],
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject});
  final SubjectProgress subject;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final l10n = AppLocalizations.of(context)!;
    final name = subject.category.name;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.mediumBorder,
        side: BorderSide(color: palette.outline),
      ),
      child: InkWell(
        key: ValueKey('subject-tile-${subject.category.id}'),
        borderRadius: AppRadii.mediumBorder,
        onTap: () => context.push('/learn/roadmap/${subject.category.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SubjectPixelArtwork(subject: subject.subject),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: RiksaTypography.titleStyleFor(
                        name,
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subjectDescription(l10n, subject.subject),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject.unavailable
                          ? l10n.subjectUnavailable
                          : l10n.subjectCountShort(
                              subject.completed,
                              subject.total,
                            ),
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: palette.inkMuted),
                    ),
                    if (!subject.unavailable) ...[
                      const SizedBox(height: 5),
                      LearningTrack(
                        key: ValueKey(
                          'subject-progress-${subject.category.id}',
                        ),
                        value: subject.fraction,
                        color: AppColors.progressGreen,
                        background: palette.surfaceRaised,
                        height: 4,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.inkMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _subjectDescription(AppLocalizations l10n, StemSubject subject) =>
    switch (subject) {
      StemSubject.mathematics => l10n.mathematicsSubjectDescription,
      StemSubject.physics => l10n.physicsSubjectDescription,
      StemSubject.chemistry => l10n.chemistrySubjectDescription,
      StemSubject.biology => l10n.biologySubjectDescription,
      StemSubject.technology => l10n.technologySubjectDescription,
      StemSubject.other => l10n.generalSubjectDescription,
    };

// ---------------------------------------------------------------------------
// Destination
// ---------------------------------------------------------------------------

/// Overall progress follows the subjects in the same scroll view.
class _DestinationBar extends StatelessWidget {
  const _DestinationBar({required this.data});

  final LearningHomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final anchor = context.riksa.surface;
    final onAnchor = context.riksa.ink;
    final days = data.examDate?.difference(DateTime.now()).inDays;

    return Container(
      key: const ValueKey('learning-destination-bar'),
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: anchor,
        borderRadius: AppRadii.panelBorder,
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
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
