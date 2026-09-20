import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
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
    final actions = [
      (
        'lessons',
        l10n.homeLessons,
        l10n.homeLessonsCaption,
        'assets/images/lessonsCard/home-lessons-3d.png',
        AppColors.limeSoft,
        '/learn',
      ),
      (
        'community',
        l10n.community,
        l10n.homeCommunityCaption,
        'assets/images/lessonsCard/home-community-3d.png',
        AppColors.violetSoft,
        '/communities',
      ),

      (
        'leaderboard',
        l10n.leaderboard,
        l10n.homeLeaderboardCaption,
        'assets/images/lessonsCard/home-leaderboard-3d.png',
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
                color: Colors.transparent,
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
                        _HomeActionLogo(assetPath: action.$4),
                        const SizedBox(height: 4),
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

class _HomeActionLogo extends StatelessWidget {
  const _HomeActionLogo({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    if (kIsWeb) {
      final cacheBustedUrl = 'assets/$assetPath?v=riksa-home-3d-2';
      return Image.network(
        cacheBustedUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: l10n.todaysLearning,
          onViewAll: () => context.go('/learn'),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('todays-learning-card'),
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.push('/learn/resume'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: -8,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE64E55),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFEF5862,
                            ).withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 118),
                    padding: const EdgeInsets.fromLTRB(18, 18, 128, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF767D), Color(0xFFF4535E)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFEF5862,
                          ).withValues(alpha: 0.26),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RiksaTypography.bodyStyleFor(
                            lesson.title,
                            theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFFFFEFF0),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: DefaultTextStyle.merge(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: Text(
                                  lesson.durationMinutes != null
                                      ? '${lesson.durationMinutes} minutes'
                                      : lesson.categoryName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFFFFF7F7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: -3,
                    child: IgnorePointer(
                      child: _TodaysLearningBooksImage(
                        width: 112,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodaysLearningBooksImage extends StatelessWidget {
  const _TodaysLearningBooksImage({
    this.width,
    this.fit,
    this.alignment = Alignment.center,
  });

  static const _assetPath =
      'assets/images/lessonsCard/todays-learning-books-3d.png';

  final double? width;
  final BoxFit? fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        '$_assetPath?v=riksa-todays-learning-books-1',
        width: width,
        fit: fit,
        alignment: alignment,
      );
    }

    return Image.asset(
      _assetPath,
      width: width,
      fit: fit,
      alignment: alignment,
    );
  }
}
