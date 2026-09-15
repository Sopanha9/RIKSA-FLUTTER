import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_brand.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../learning/presentation/learning_design.dart';
import '../../../learning/providers/learning_home_provider.dart';

/// A section title with an optional "View all" link on the right.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.actionLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 12, 4),
  });

  final String title;
  final VoidCallback? onViewAll;
  final String? actionLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: RiksaTypography.titleStyleFor(
                title,
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: theme.textTheme.labelMedium,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel ?? l10n.viewAllShort),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Reference-board destinations share the same compact tile and icon treatment.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final actions = [
      (
        'lessons',
        l10n.homeLessons,
        l10n.homeLessonsCaption,
        Icons.menu_book_outlined,
        AppColors.limeSoft,
        '/learn',
      ),
      (
        'community',
        l10n.community,
        l10n.homeCommunityCaption,
        Icons.groups_outlined,
        AppColors.violetSoft,
        '/communities',
      ),
      (
        'ai',
        l10n.aiTutor,
        l10n.homeAiCaption,
        Icons.smart_toy_outlined,
        AppColors.tileMint,
        '/ai',
      ),
      (
        'leaderboard',
        l10n.leaderboard,
        l10n.homeLeaderboardCaption,
        Icons.emoji_events_outlined,
        AppColors.tileYellow,
        '/leaderboard',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, action) in actions.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Color.lerp(action.$5, palette.surface, .86)
                    : action.$5,
                borderRadius: AppRadii.mediumBorder,
                child: InkWell(
                  key: ValueKey('home-action-${action.$1}'),
                  borderRadius: AppRadii.mediumBorder,
                  onTap: () => action.$1 == 'community'
                      ? context.push(action.$6)
                      : context.go(action.$6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Icon(action.$4, size: 25, color: palette.ink),
                        const SizedBox(height: 8),
                        Text(
                          action.$2,
                          textAlign: TextAlign.center,
                          style: RiksaTypography.bodyStyleFor(
                            action.$2,
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          action.$3,
                          textAlign: TextAlign.center,
                          style: RiksaTypography.bodyStyleFor(
                            action.$3,
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Today's learning": the one lesson the learner can pick up right now.
///
/// Hidden while loading, on failure, and once nothing is left to resume, so
/// the home screen never shows an empty promise.
class TodaysLearningSection extends ConsumerWidget {
  const TodaysLearningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(learningHomeProvider).value;
    final subject = data?.resumeSubject;
    final lesson = data?.resumeLesson;
    if (subject == null || lesson == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final palette = context.riksa;
    final tone = subjectTone(context, subject.subject);
    final total = subject.total;
    final done = subject.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: l10n.todaysLearning,
          onViewAll: () => context.go('/learn'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? palette.surfaceRaised
                : AppColors.limeSoft,
            borderRadius: AppRadii.largeBorder,
            child: InkWell(
              key: const ValueKey('todays-learning-card'),
              borderRadius: AppRadii.largeBorder,
              onTap: () => context.push('/learn/resume'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(borderRadius: AppRadii.largeBorder),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            RiksaIconTile(
                              icon: stemSubjectIcon(subject.subject),
                              background: tone.surface,
                              foreground: tone.accent,
                              size: 40,
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: RiksaDoodle(
                                RiksaDoodleKind.sparkle,
                                size: 14,
                                color: AppColors.lime,
                              ),
                            ),
                          ],
                        ),
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
                                lesson.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: RiksaTypography.bodyStyleFor(
                                  lesson.categoryName,
                                  theme.textTheme.bodySmall?.copyWith(
                                    color: palette.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: palette.brandSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: palette.brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: AppRadii.fullBorder,
                            child: LinearProgressIndicator(
                              value: subject.fraction,
                              minHeight: 5,
                              color: AppColors.progressGreen,
                              backgroundColor: palette.surfaceRaised,
                            ),
                          ),
                        ),
                        if (total > 0) ...[
                          const SizedBox(width: 10),
                          Text(
                            '$done/$total',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => context.push('/learn/resume'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            textStyle: theme.textTheme.labelMedium,
                          ),
                          child: Text(l10n.continueLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
