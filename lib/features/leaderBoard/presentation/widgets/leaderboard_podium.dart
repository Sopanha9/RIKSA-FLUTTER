import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../core/widgets/riksa_rank_badge.dart';
import '../../../userProfile/data/profile_models.dart';
import '../../../userProfile/presentation/public_profile_navigation.dart';
import '../../../userProfile/presentation/widgets/profile_ui.dart';

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.podium,
    required this.currentUserId,
  });

  final List<LeaderboardRow> podium;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (podium.isEmpty) {
      return const _EmptyPodium();
    }

    final rank1 = _rowAtRank(1) ?? podium.first;
    final rank2 = _rowAtRank(2);
    final rank3 = _rowAtRank(3);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('leaderboard-podium'),
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 12),
      decoration: BoxDecoration(
        color: isDark
            ? context.riksa.surface
            : AppColors.editorialNeutralSurface,
        borderRadius: AppRadii.extraLargeBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .18 : .045),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: rank2 == null
                ? const SizedBox.shrink()
                : _PodiumPlace(
                    row: rank2,
                    ringColor: const Color(0xFF9C9CA3),
                    isCurrentUser: rank2.userId == currentUserId,
                    onTap: () => _openProfile(context, rank2.userId),
                  ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -10),
              child: _PodiumPlace(
                row: rank1,
                ringColor: AppColors.achievementSaffron,
                isWinner: true,
                isCurrentUser: rank1.userId == currentUserId,
                onTap: () => _openProfile(context, rank1.userId),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: rank3 == null
                ? const SizedBox.shrink()
                : _PodiumPlace(
                    row: rank3,
                    ringColor: const Color(0xFFB87824),
                    isCurrentUser: rank3.userId == currentUserId,
                    onTap: () => _openProfile(context, rank3.userId),
                  ),
          ),
        ],
      ),
    );
  }

  LeaderboardRow? _rowAtRank(int rank) {
    for (final row in podium) {
      if (row.rank == rank) return row;
    }
    return null;
  }

  void _openProfile(BuildContext context, String userId) {
    final path = publicProfilePath(userId);
    if (path != null) context.push(path);
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.row,
    required this.ringColor,
    required this.isCurrentUser,
    required this.onTap,
    this.isWinner = false,
  });

  final LeaderboardRow row;
  final Color ringColor;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.riksa;
    final displayName = row.fallbackName;
    final tierLabel = row.rankingTier == null
        ? 'Scholar'
        : readableProfileName(row.rankingTier!);
    final avatarSize = isWinner ? 58.0 : 50.0;

    return Semantics(
      button: true,
      label: 'Rank ${row.rank}, $displayName, ${row.score} XP',
      child: Material(
        color: isWinner
            ? (isDark
                  ? AppColors.editorialAubergineRaised
                  : AppColors.achievementSaffronSoft.withValues(alpha: .3))
            : (isCurrentUser
                ? (isDark
                    ? palette.surfaceRaised
                    : context.riksa.jade.withValues(alpha: 0.08))
                : Colors.transparent),
        borderRadius: AppRadii.largeBorder,
        child: InkWell(
          key: ValueKey('podium-place-${row.rank}'),
          onTap: onTap,
          borderRadius: AppRadii.largeBorder,
          child: Container(
            padding: EdgeInsets.fromLTRB(6, isWinner ? 12 : 6, 6, 8),
            decoration: const BoxDecoration(borderRadius: AppRadii.largeBorder),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (isWinner)
                      Positioned(
                        top: -16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            key: const ValueKey('podium-crown-icon'),
                            size: 20,
                            color: AppColors.achievementSaffron,
                          ),
                        ),
                      ),
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ringColor, width: 2.5),
                      ),
                      child: RiksaAvatarImage(
                        value: row.avatarUrl,
                        label: displayName,
                        size: avatarSize - 5,
                        backgroundColor: isDark
                            ? palette.surfaceRaised
                            : AppColors.editorialField,
                        foregroundColor: palette.ink,
                      ),
                    ),
                    Positioned(
                      top: -7,
                      right: -4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: ringColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ringColor.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? palette.surface
                                : AppColors.editorialNeutralSurface,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${row.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (row.rankingTier != null)
                      Positioned(
                        bottom: -4,
                        left: -12,
                        child: RiksaRankBadge(tier: row.rankingTier, size: 28),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: isWinner ? 13 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tierLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isWinner
                        ? AppColors.editorialPink
                        : palette.inkMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isWinner
                        ? AppColors.achievementSaffronSoft
                        : AppColors.editorialPinkSoft,
                    borderRadius: AppRadii.fullBorder,
                  ),
                  child: Text(
                    '${row.score} XP',
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.editorialAubergine,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(height: 4),
                  Container(
                    key: const ValueKey('podium-current-user-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.riksa.jade.withValues(alpha: 0.15),
                      borderRadius: AppRadii.fullBorder,
                      border: Border.all(
                        color: context.riksa.jade.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'km'
                          ? 'អ្នក'
                          : 'You',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: context.riksa.jade,
                      ),
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

class _EmptyPodium extends StatelessWidget {
  const _EmptyPodium();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? context.riksa.surface
            : AppColors.editorialNeutralSurface,
        borderRadius: AppRadii.extraLargeBorder,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 34,
            color: AppColors.editorialPink,
          ),
          const SizedBox(height: 8),
          Text(
            'No ranked learners in this scope yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.riksa.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
