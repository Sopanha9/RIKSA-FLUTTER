import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_components.dart';
import '../../../auth/data/auth_models.dart';
import '../../../userProfile/data/profile_models.dart';
import '../../../userProfile/presentation/public_profile_navigation.dart';
import '../../../userProfile/presentation/widgets/profile_ui.dart';
import 'ranking_list_row.dart';

class RankingsSheet extends StatelessWidget {
  const RankingsSheet({
    super.key,
    required this.listRows,
    required this.currentUser,
  });

  final List<LeaderboardRow> listRows;
  final AuthUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey('leaderboard-rankings-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rankings',
              style: TextStyle(
                color: isDark
                    ? context.riksa.ink
                    : AppColors.editorialAubergine,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
              ),
            ),
            if (listRows.isNotEmpty)
              Text(
                'Top ${listRows.length + 3}',
                style: TextStyle(
                  color: isDark
                      ? context.riksa.inkMuted
                      : AppColors.editorialMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? context.riksa.surface
                : AppColors.editorialNeutralSurface,
            borderRadius: AppRadii.extraLargeBorder,
          ),
          clipBehavior: Clip.antiAlias,
          child: listRows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Center(
                    child: Text(
                      'No other rankings to show.',
                      style: TextStyle(color: context.riksa.inkMuted),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < listRows.length; index++) ...[
                      RiksaEntrance(
                        index: index,
                        child: RankingListRow(
                          rank: listRows[index].rank,
                          tier: listRows[index].rankingTier,
                          name: listRows[index].fallbackName,
                          subtitle: listRows[index].rankingTier == null
                              ? 'Scholar'
                              : readableProfileName(
                                  listRows[index].rankingTier!,
                                ),
                          xp: listRows[index].score,
                          avatarUrl: listRows[index].avatarUrl,
                          avatarLabel: listRows[index].fallbackName,
                          isCurrentUser:
                              currentUser != null &&
                              listRows[index].userId == currentUser!.id,
                          onTap: () {
                            final path = publicProfilePath(
                              listRows[index].userId,
                            );
                            if (path != null) context.push(path);
                          },
                        ),
                      ),
                      if (index != listRows.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: isDark
                              ? context.riksa.outline
                              : AppColors.editorialOutline,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
