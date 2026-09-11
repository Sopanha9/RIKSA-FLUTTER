import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../core/widgets/riksa_interactions.dart';
import '../../../../core/widgets/riksa_rank_badge.dart';

class RankingListRow extends StatelessWidget {
  const RankingListRow({
    super.key,
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.xp,
    required this.avatarLabel,
    this.avatarUrl,
    this.tier,
    this.isCurrentUser = false,
    this.onTap,
  });

  final int rank;
  final String name;
  final String subtitle;
  final int xp;
  final String avatarLabel;
  final String? avatarUrl;
  final String? tier;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.riksa;
    final ink = isDark ? palette.ink : AppColors.editorialInk;

    // Movement trend indicator matching inspiration image (green ▲ for top tiers, neutral for others)
    final isRising = rank <= 6 || (tier?.toLowerCase().contains('gold') ?? false);

    return Semantics(
      button: true,
      label: 'Rank $rank, $name, $xp XP',
      child: RiksaTapFeedback(
        child: Material(
          color: isCurrentUser
              ? (isDark
                    ? palette.surfaceRaised
                    : AppColors.editorialPinkSoft.withValues(alpha: .32))
              : (isDark ? palette.surface : AppColors.editorialNeutralSurface),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCurrentUser
                      ? AppColors.editorialPink
                      : palette.outline.withValues(alpha: 0.3),
                  width: isCurrentUser ? 1.5 : 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .12 : .03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Rank number (#4, #5, #6...)
                  SizedBox(
                    width: 36,
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: isCurrentUser
                            ? AppColors.editorialPink
                            : (isDark ? palette.inkMuted : AppColors.editorialAubergine),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrentUser
                            ? AppColors.editorialPink
                            : palette.outline.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: RiksaAvatarImage(
                      value: avatarUrl,
                      label: avatarLabel,
                      size: 39,
                      backgroundColor: isDark
                          ? palette.surfaceRaised
                          : AppColors.editorialField,
                      foregroundColor: ink,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + Score Pill (below name, matching inspiration)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.2,
                                ),
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.editorialPink.withValues(alpha: 0.2),
                                  borderRadius: AppRadii.fullBorder,
                                ),
                                child: const Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: AppColors.editorialPink,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Score Pill Badge with Diamond Icon (matching inspiration)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? palette.surfaceRaised
                                : AppColors.editorialField,
                            borderRadius: AppRadii.fullBorder,
                            border: Border.all(
                              color: palette.outline.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('💎', style: TextStyle(fontSize: 9.5)),
                              const SizedBox(width: 4),
                              Text(
                                '$xp XP',
                                style: TextStyle(
                                  color: palette.ink,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right side: Tier badge or movement trend arrow
                  if (tier != null) ...[
                    RiksaRankBadge(tier: tier, size: 28),
                    const SizedBox(width: 6),
                  ],

                  // Trend Arrow (green ▲ or orange ▼ matching inspiration)
                  Icon(
                    isRising
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: isRising
                        ? context.riksa.jade
                        : AppColors.achievementSaffron,
                    size: 24,
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

