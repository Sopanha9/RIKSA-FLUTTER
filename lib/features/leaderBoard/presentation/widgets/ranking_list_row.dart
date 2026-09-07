import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
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
    final ink = isDark ? context.riksa.ink : AppColors.editorialInk;
    final muted = isDark ? context.riksa.inkMuted : AppColors.editorialMuted;

    return Material(
      color: isCurrentUser
          ? AppColors.editorialPinkSoft.withValues(alpha: isDark ? .12 : .32)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: isCurrentUser ? AppColors.editorialPink : ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser
                        ? AppColors.editorialPink
                        : AppColors.editorialOutline,
                    width: 1.5,
                  ),
                ),
                child: RiksaAvatarImage(
                  value: avatarUrl,
                  label: avatarLabel,
                  size: 37,
                  backgroundColor: isDark
                      ? context.riksa.surfaceRaised
                      : AppColors.editorialField,
                  foregroundColor: ink,
                ),
              ),
              const SizedBox(width: 11),
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
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 5),
                          const Text(
                            'YOU',
                            style: TextStyle(
                              color: AppColors.editorialPink,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .4,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (tier != null) ...[
                RiksaRankBadge(tier: tier, size: 32),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.editorialPinkSoft,
                  borderRadius: AppRadii.fullBorder,
                ),
                child: Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: AppColors.editorialAubergine,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
