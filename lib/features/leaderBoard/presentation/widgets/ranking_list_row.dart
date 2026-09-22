import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// One ranked learner. The top three get a medal-coloured rank number and the
/// signed-in learner's row is lime, as on the reference board.
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
  final String name, subtitle, avatarLabel;
  final int xp;
  final String? avatarUrl, tier;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  static const _medals = {
    1: Color(0xFFF6C744),
    2: Color(0xFFC9CED8),
    3: Color(0xFFE0A071),
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final textTheme = Theme.of(context).textTheme;
    final medal = _medals[rank];
    return Semantics(
      label: AppLocalizations.of(context)!.leaderboardRowLabel(rank, name, xp),
      button: onTap != null,
      child: Material(
        color: isCurrentUser ? palette.rewardSoft : palette.surface,
        borderRadius: AppRadii.mediumBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mediumBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                MediaQuery.withNoTextScaling(
                  child: Container(
                    key: medal == null ? null : ValueKey('rank-medal-$rank'),
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: medal == null
                        ? null
                        : BoxDecoration(
                            shape: BoxShape.circle,
                            color: medal.withValues(alpha: .35),
                          ),
                    child: Text(
                      '$rank',
                      style: textTheme.labelMedium?.copyWith(
                        color: medal == null ? palette.inkMuted : palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                RiksaAvatarImage(
                  value: avatarUrl,
                  label: avatarLabel,
                  size: 36,
                  backgroundColor: palette.brandSoft,
                  foregroundColor: palette.brand,
                  frameTier: tier,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.bodyStyleFor(
                      name,
                      textTheme.bodyMedium?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 6),
                  Container(
                    key: const ValueKey('ranking-row-you'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadii.fullBorder,
                    ),
                    child: Text(
                      'You',
                      style: textTheme.labelSmall?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  '$xp XP',
                  style: textTheme.labelMedium?.copyWith(
                    color: palette.inkMuted,
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
