import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: onTap != null,
      label: 'Your rank is $rank. $name, $scopeLabel, $tier, $xp XP.',
      child: Material(
        color: isDark
            ? AppColors.editorialAubergineRaised
            : AppColors.editorialPinkSoft.withValues(alpha: .34),
        borderRadius: AppRadii.extraLargeBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.extraLargeBorder,
          child: Container(
            key: const ValueKey('current-user-rank-card'),
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              borderRadius: AppRadii.extraLargeBorder,
              border: Border.all(
                color: AppColors.editorialPink.withValues(alpha: .78),
                width: 1.25,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your rank',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.editorialPink
                        : AppColors.editorialAubergine,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.editorialPink,
                          width: 2,
                        ),
                      ),
                      child: RiksaAvatarImage(
                        value: avatarUrl,
                        label: avatarLabel,
                        size: 36,
                        backgroundColor: AppColors.editorialPinkSoft,
                        foregroundColor: AppColors.editorialAubergine,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Center(
                        child: Text(
                          '#$rank',
                          key: const ValueKey('current-user-rank-number'),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.editorialAubergine,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.editorialPink.withValues(alpha: .65),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '$xp XP',
                      style: const TextStyle(
                        color: AppColors.editorialPink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
