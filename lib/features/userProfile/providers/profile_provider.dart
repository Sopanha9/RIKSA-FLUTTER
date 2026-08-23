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
