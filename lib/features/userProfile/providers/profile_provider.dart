import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/profile_api.dart';
import '../data/profile_models.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(dioClientProvider));
});

final profileDashboardProvider = FutureProvider<ProfileDashboardData>((
  ref,
) async {
  final api = ref.watch(profileApiProvider);
  final results = await Future.wait<Object>([
    api.gamificationProfile(),
    api.achievements(),
    api.xpActivity(),
  ]);
  final activityPage = results[2] as XpActivityPage;
  return ProfileDashboardData(
    gamification: results[0] as GamificationProfile,
    achievements: results[1] as List<ProfileAchievement>,
    activities: activityPage.activities,
  );
});

final profileRankProvider = FutureProvider<LeaderboardRank>((ref) {
  final auth = ref.watch(authProvider);
  final provinceId = auth is Authenticated ? auth.user.provinceId : null;
  return ref.watch(profileApiProvider).leaderboardRank(provinceId: provinceId);
});

final rankHistoryProvider = FutureProvider<List<RankHistoryEntry>>(
  (ref) => ref.watch(profileApiProvider).rankHistory(),
);

/// Ranked board rows for a scope, sourced from `GET /leaderboard`.
///
/// The country board is scoped to `CAMBODIA`; the province board uses the
/// signed-in user's `provinceId`. Returns an empty list when the province
/// board is requested but the user has no province set.
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardRow>, LeaderboardScope>((ref, scope) {
      final auth = ref.watch(authProvider);
      final provinceId = auth is Authenticated ? auth.user.provinceId : null;

      final String scopeId;
      if (scope == LeaderboardScope.province) {
        if (provinceId == null || provinceId.isEmpty) return const [];
        scopeId = provinceId;
      } else {
        scopeId = 'CAMBODIA';
      }

      return ref
          .watch(profileApiProvider)
          .leaderboard(scope: scope, scopeId: scopeId);
    });
