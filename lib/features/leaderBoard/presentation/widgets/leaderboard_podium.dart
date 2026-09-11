import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../core/widgets/riksa_interactions.dart';
import '../../../../core/widgets/riksa_rank_badge.dart';
import '../../../userProfile/data/profile_models.dart';
import '../../../userProfile/presentation/public_profile_navigation.dart';

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
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
      decoration: BoxDecoration(
        color: isDark
            ? context.riksa.surface
            : AppColors.editorialNeutralSurface,
        borderRadius: AppRadii.extraLargeBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .18 : .045),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Left, Saffron)
              Expanded(
                child: rank2 == null
                    ? const SizedBox.shrink()
                    : _PodiumColumn(
                        row: rank2,
                        ringColor: AppColors.achievementSaffron,
                        pillarColor: isDark
                            ? AppColors.achievementSaffron.withValues(alpha: 0.22)
                            : AppColors.achievementSaffronSoft,
                        pillarTopColor: isDark
                            ? AppColors.achievementSaffron.withValues(alpha: 0.35)
                            : const Color(0xFFFDE8C0),
                        pillarTextColor: isDark
                            ? AppColors.achievementSaffron
                            : const Color(0xFFB87824),
                        pillarHeight: 78,
                        avatarSize: 52,
                        isCurrentUser: rank2.userId == currentUserId,
                        onTap: () => _openProfile(context, rank2.userId),
                      ),
              ),
              const SizedBox(width: 8),
              // 1st Place (Center, Jade) - Tallest
              Expanded(
                child: _PodiumColumn(
                  row: rank1,
                  ringColor: context.riksa.jade,
                  pillarColor: isDark
                      ? context.riksa.jade.withValues(alpha: 0.25)
                      : context.riksa.jadeSoft,
                  pillarTopColor: isDark
                      ? context.riksa.jade.withValues(alpha: 0.4)
                      : const Color(0xFFC7E6D4),
                  pillarTextColor: isDark
                      ? context.riksa.jade
                      : context.riksa.jadeStrong,
                  pillarHeight: 110,
                  avatarSize: 62,
                  isWinner: true,
                  isCurrentUser: rank1.userId == currentUserId,
                  onTap: () => _openProfile(context, rank1.userId),
                ),
              ),
              const SizedBox(width: 8),
              // 3rd Place (Right, Pink) - Shorter
              Expanded(
                child: rank3 == null
                    ? const SizedBox.shrink()
                    : _PodiumColumn(
                        row: rank3,
                        ringColor: AppColors.editorialPink,
                        pillarColor: isDark
                            ? AppColors.editorialPink.withValues(alpha: 0.22)
                            : AppColors.editorialPinkSoft,
                        pillarTopColor: isDark
                            ? AppColors.editorialPink.withValues(alpha: 0.35)
                            : const Color(0xFFF8D2EC),
                        pillarTextColor: isDark
                            ? AppColors.editorialPink
                            : const Color(0xFFB54C8E),
                        pillarHeight: 58,
                        avatarSize: 48,
                        isCurrentUser: rank3.userId == currentUserId,
                        onTap: () => _openProfile(context, rank3.userId),
                      ),
              ),
            ],
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

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.row,
    required this.ringColor,
    required this.pillarColor,
    required this.pillarTopColor,
    required this.pillarTextColor,
    required this.pillarHeight,
    required this.avatarSize,
    required this.isCurrentUser,
    required this.onTap,
    this.isWinner = false,
  });

  final LeaderboardRow row;
  final Color ringColor;
  final Color pillarColor;
  final Color pillarTopColor;
  final Color pillarTextColor;
  final double pillarHeight;
  final double avatarSize;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.riksa;
    final displayName = row.fallbackName;
    final hasFrame = riksaAvatarFrameAssetPath(row.rankingTier) != null;

    return Semantics(
      button: true,
      label: 'Rank ${row.rank}, $displayName, ${row.score} XP',
      child: RiksaTapFeedback(
        child: InkWell(
          key: ValueKey('podium-place-${row.rank}'),
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar + Badges Zone
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (isWinner)
                    Positioned(
                      top: -18,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        key: const ValueKey('podium-crown-icon'),
                        size: 24,
                        color: AppColors.achievementSaffron,
                      ),
                    ),
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: hasFrame
                          ? null
                          : Border.all(color: ringColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: ringColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: RiksaAvatarImage(
                      value: row.avatarUrl,
                      label: displayName,
                      size: avatarSize - 5,
                      backgroundColor: isDark
                          ? palette.surfaceRaised
                          : AppColors.editorialField,
                      foregroundColor: palette.ink,
                      frameTier: row.rankingTier,
                    ),
                  ),
                  // Rank number medal badge pinned at bottom-right (matching inspiration)
                  Positioned(
                    bottom: -5,
                    right: -4,
                    child: _RankMedalBadge(
                      rank: row.rank,
                      color: ringColor,
                      isDark: isDark,
                      surfaceColor: isDark
                          ? palette.surface
                          : AppColors.editorialNeutralSurface,
                    ),
                  ),
                  if (row.rankingTier != null && !isWinner)
                    Positioned(
                      bottom: -4,
                      left: -8,
                      child: RiksaRankBadge(tier: row.rankingTier, size: 24),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: isWinner ? 13 : 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Score Pill Badge with Diamond Icon (matching inspiration)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isWinner
                      ? (isDark
                            ? context.riksa.jade.withValues(alpha: 0.3)
                            : context.riksa.jadeSoft)
                      : (isDark
                            ? palette.surfaceRaised
                            : AppColors.editorialField),
                  borderRadius: AppRadii.fullBorder,
                  border: Border.all(
                    color: isWinner
                        ? context.riksa.jade.withValues(alpha: 0.5)
                        : palette.outline.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '💎',
                      style: TextStyle(fontSize: isWinner ? 11 : 9.5),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${row.score}',
                      maxLines: 1,
                        style: TextStyle(
                          color: isWinner
                            ? (isDark ? context.riksa.jade : context.riksa.jadeStrong)
                            : palette.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              if (isCurrentUser) ...[
                const SizedBox(height: 4),
                Container(
                  key: const ValueKey('podium-current-user-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: context.riksa.jade.withValues(alpha: 0.15),
                    borderRadius: AppRadii.fullBorder,
                    border: Border.all(
                      color: context.riksa.jade.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'km'
                        ? 'អ្នក'
                        : 'You',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: context.riksa.jade,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // 3D Stepped Podium Pillar Block (matching inspiration)
              Container(
                height: pillarHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: pillarColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Top facet highlight (gives 3D bevel look)
                    Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: pillarTopColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                    ),
                    // Large watermark rank numeral with elongated styling
                    Center(
                      child: Transform.scale(
                        scaleY: 1.32,
                        scaleX: 0.92,
                        child: Text(
                          '${row.rank}',
                          style: TextStyle(
                            fontSize: isWinner ? 46 : 34,
                            fontWeight: FontWeight.w900,
                            color: pillarTextColor.withValues(alpha: 0.35),
                            fontFamily: RiksaTypography.latinFamily,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankMedalBadge extends StatelessWidget {
  const _RankMedalBadge({
    required this.rank,
    required this.color,
    required this.isDark,
    required this.surfaceColor,
  });

  final int rank;
  final Color color;
  final bool isDark;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25,
      height: 29,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Ribbon tails hanging down (matching inspiration)
          Positioned(
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -0.26,
                  child: Container(
                    width: 5,
                    height: 8.5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3.5),
                Transform.rotate(
                  angle: 0.26,
                  child: Container(
                    width: 5,
                    height: 8.5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Circular Medal Disc with elongated rank numeral
          Container(
            width: 22.5,
            height: 22.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: surfaceColor, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Transform.scale(
              scaleY: 1.25, // Elongated / longer font aspect ratio
              scaleX: 0.92,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: RiksaTypography.latinFamily,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPodium extends StatelessWidget {
  const _EmptyPodium();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? context.riksa.surface
            : AppColors.editorialNeutralSurface,
        borderRadius: AppRadii.extraLargeBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .18 : .045),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 3 Miniature podium steps with trophy
          SizedBox(
            height: 64,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.achievementSaffronSoft,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 32,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.riksa.jadeSoft,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 28,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.editorialPinkSoft,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 26,
                    color: AppColors.achievementSaffron,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isKhmer
                ? 'វេទិកាកំពុងរង់ចាំអ្នក! 🏆'
                : 'The podium is waiting for you! 🏆',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? context.riksa.ink : AppColors.editorialAubergine,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isKhmer
                ? 'ក្លាយជាអ្នករៀនដំបូងគេដែលឡើងតារាងពិន្ទុសប្តាហ៍នេះ។'
                : 'Be the first to earn XP this week and claim the crown.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.riksa.inkMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          RiksaTapFeedback(
            child: FilledButton.tonal(
              onPressed: () => context.go('/learn'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: Text(
                isKhmer ? 'ចាប់ផ្តើមរៀន 🚀' : 'Start a 5-Min Lesson 🚀',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
