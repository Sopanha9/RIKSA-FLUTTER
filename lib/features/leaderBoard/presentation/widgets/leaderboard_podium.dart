import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
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
      return ProfilePanel(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 36, color: context.riksa.inkMuted),
            const SizedBox(height: 8),
            Text(
              'No ranked scholars in this scope yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.riksa.inkMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final rank1 = podium.isNotEmpty ? podium.firstWhere((r) => r.rank == 1, orElse: () => podium[0]) : null;
    final rank2 = podium.length > 1 ? podium.firstWhere((r) => r.rank == 2, orElse: () => podium[1]) : null;
    final rank3 = podium.length > 2 ? podium.firstWhere((r) => r.rank == 3, orElse: () => podium[2]) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank #2 (Left)
        Expanded(
          child: rank2 != null
              ? LeaderboardPodiumCard(
                  row: rank2,
                  ringColor: const Color(0xFFA39A8C),
                  isCurrentUser: currentUserId != null && rank2.userId == currentUserId,
                  onTap: () => _openProfile(context, rank2.userId),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        // Rank #1 (Center, elevated as a whole block)
        Expanded(
          child: rank1 != null
              ? LeaderboardPodiumCard(
                  row: rank1,
                  ringColor: const Color(0xFFE69A18),
                  isElevated: true,
                  hasCrown: true,
                  isCurrentUser: currentUserId != null && rank1.userId == currentUserId,
                  onTap: () => _openProfile(context, rank1.userId),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        // Rank #3 (Right)
        Expanded(
          child: rank3 != null
              ? LeaderboardPodiumCard(
                  row: rank3,
                  ringColor: const Color(0xFFB87824),
                  isCurrentUser: currentUserId != null && rank3.userId == currentUserId,
                  onTap: () => _openProfile(context, rank3.userId),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _openProfile(BuildContext context, String userId) {
    final path = publicProfilePath(userId);
    if (path != null) context.push(path);
  }
}

class LeaderboardPodiumCard extends StatelessWidget {
  const LeaderboardPodiumCard({
    super.key,
    required this.row,
    required this.ringColor,
    required this.onTap,
    this.isElevated = false,
    this.hasCrown = false,
    this.isCurrentUser = false,
  });

  final LeaderboardRow row;
  final Color ringColor;
  final VoidCallback onTap;
  final bool isElevated;
  final bool hasCrown;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = row.fallbackName;
    final tierLabel = row.rankingTier != null ? readableProfileName(row.rankingTier!) : 'Scholar';

    final cardContent = Material(
      color: palette.surface,
      borderRadius: AppRadii.largeBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.largeBorder,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.largeBorder,
            border: Border.all(
              color: isCurrentUser
                  ? AppColors.editorialPink
                  : (isElevated
                      ? AppColors.editorialPink.withValues(alpha: 0.8)
                      : palette.outline.withValues(alpha: 0.5)),
              width: (isElevated || isCurrentUser) ? 1.5 : 1.0,
            ),
            boxShadow: isElevated
                ? [
                    BoxShadow(
                      color: AppColors.editorialPink.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : RiksaElevation.low(Theme.of(context).brightness),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crown on top of #1
              if (hasCrown) ...[
                const Text('👑', style: TextStyle(fontSize: 18, height: 1)),
                const SizedBox(height: 2),
              ] else ...[
                const SizedBox(height: 20),
              ],

              // Avatar with rank badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 2.5),
                    ),
                    child: RiksaAvatarImage(
                      value: row.avatarUrl,
                      label: displayName,
                      size: 47,
                      backgroundColor: palette.surfaceRaised,
                      foregroundColor: palette.ink,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: row.rank == 1 ? AppColors.achievementSaffron : AppColors.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.surface, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${row.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Name
              SizedBox(
                height: 18,
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              // Subtitle / Tier
              SizedBox(
                height: 16,
                child: Text(
                  tierLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isElevated ? AppColors.editorialPink : palette.inkMuted,
                    fontSize: 10.5,
                    fontWeight: isElevated ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // XP pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.editorialPink
                      : (isDark ? palette.surfaceRaised : AppColors.ink),
                  borderRadius: AppRadii.fullBorder,
                ),
                child: Text(
                  '${row.score} XP',
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppColors.ink
                        : (isDark ? palette.ink : Colors.white),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isElevated) {
      return Transform.translate(
        offset: const Offset(0, -14),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
