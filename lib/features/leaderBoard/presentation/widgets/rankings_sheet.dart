import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_models.dart';
import '../../../userProfile/data/profile_models.dart';
import '../../../userProfile/presentation/public_profile_navigation.dart';
import '../../../userProfile/presentation/widgets/profile_ui.dart';
import 'leaderboard_states.dart';
import 'ranking_list_row.dart';

class RankingsSheet extends StatelessWidget {
  const RankingsSheet({
    super.key,
    required this.listRows,
    required this.currentUser,
    required this.userRankData,
    required this.scope,
    required this.hasTotalRows,
  });

  final List<LeaderboardRow> listRows;
  final AuthUser? currentUser;
  final LeaderboardRank? userRankData;
  final LeaderboardScope scope;
  final bool hasTotalRows;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark
        ? AppColors.editorialAubergineRaised
        : AppColors.editorialAubergine;

    // Resolve current user rank info from /leaderboard/me
    final userRankNumber = scope == LeaderboardScope.province
        ? (userRankData?.provinceRank ?? 0)
        : (userRankData?.countryRank ?? 0);
    final userScore = scope == LeaderboardScope.province
        ? (userRankData?.provinceScore ?? 0)
        : (userRankData?.countryScore ?? 0);
    final userTierName = scope == LeaderboardScope.province
        ? (userRankData?.provinceTier ?? 'Scholar')
        : (userRankData?.countryTier ?? 'Scholar');

    final userName = currentUser != null
        ? (currentUser!.displayName.trim().isNotEmpty
            ? '${currentUser!.displayName.trim()} (You)'
            : '${currentUser!.username} (You)')
        : 'You';

    // Check if the current user is already shown in the displayed rows
    final userInList = currentUser != null && listRows.any((r) => r.userId == currentUser!.id);

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        RiksaSpacing.md,
        RiksaSpacing.md,
        RiksaSpacing.md,
        RiksaSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Grab Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF48464C),
                borderRadius: AppRadii.fullBorder,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sheet Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rankings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (listRows.isNotEmpty)
                Text(
                  'Top ${listRows.length + 3}',
                  style: const TextStyle(
                    color: Color(0xFFCAC4D0),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Render live list rows (#4+)
          for (final row in listRows) ...[
            RankingListRow(
              rank: row.rank,
              name: row.fallbackName,
              subtitle: row.rankingTier != null ? readableProfileName(row.rankingTier!) : 'Scholar',
              xp: row.score,
              avatarUrl: row.avatarUrl,
              avatarLabel: row.fallbackName,
              isCurrentUser: currentUser != null && row.userId == currentUser!.id,
              onTap: () {
                final path = publicProfilePath(row.userId);
                if (path != null) context.push(path);
              },
            ),
            const SizedBox(height: 10),
          ],

          // If current user is not in the list and has a rank, show gap indicator + user rank row
          if (!userInList && currentUser != null && userRankNumber > 0) ...[
            const RankGapIndicator(),
            const SizedBox(height: 8),
            RankingListRow(
              rank: userRankNumber,
              name: userName,
              subtitle: '${readableProfileName(userTierName)} • ${scope == LeaderboardScope.province ? "Province" : "National"}',
              xp: userScore,
              avatarUrl: currentUser!.avatarUrl,
              avatarLabel: userName,
              isCurrentUser: true,
              onTap: () => context.push('/profile'),
            ),
          ],
        ],
      ),
    );
  }
}
