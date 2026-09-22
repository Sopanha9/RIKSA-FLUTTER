import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_components.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../core/widgets/riksa_rank_badge.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// The learner's own standing, on the accent surface: the rank
/// leads, XP follows, and the framed avatar carries the tier badge.
class CurrentUserRankCard extends StatelessWidget {
  const CurrentUserRankCard({
    super.key,
    required this.rank,
    required this.name,
    required this.tier,
    required this.scopeLabel,
    required this.xp,
    required this.avatarLabel,
    this.avatarUrl,
    this.onTap,
  });

  final int rank;
  final String name;
  final String tier;
  final String scopeLabel;
  final int xp;
  final String avatarLabel;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.riksa.reward;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      label: AppLocalizations.of(
        context,
      )!.leaderboardYourRankLabel(rank, name, scopeLabel, tier, xp),
      child: Material(
        color: context.riksa.rewardSoft,
        borderRadius: AppRadii.largeBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.largeBorder,
          child: Padding(
            key: const ValueKey('current-user-rank-card'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.leaderboardYourRank,
                        style: textTheme.labelMedium?.copyWith(
                          color: ink.withValues(alpha: .75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // The learner's own two numbers are the one place on
                      // this screen worth animating; every other row's XP is
                      // reference data.
                      RiksaCountUp(
                        value: rank,
                        format: (value) => '#$value',
                        key: const ValueKey('current-user-rank-number'),
                        style: textTheme.headlineSmall?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RiksaCountUp(
                        value: xp,
                        format: (value) => '$value XP',
                        style: textTheme.labelMedium?.copyWith(
                          color: ink.withValues(alpha: .8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: RiksaAvatarImage(
                          value: avatarUrl,
                          label: avatarLabel,
                          size: 56,
                          backgroundColor: AppColors.editorialPinkSoft,
                          foregroundColor: AppColors.editorialAubergine,
                          frameTier: tier,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: RiksaRankBadge(tier: tier, size: 26),
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
