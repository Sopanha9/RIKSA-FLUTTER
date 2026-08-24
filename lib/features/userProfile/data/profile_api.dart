import '../../../core/network/dio_client.dart';
import 'profile_models.dart';

class ProfileApi {
  ProfileApi(this._client);

  final DioClient _client;

  Future<GamificationProfile> gamificationProfile() async {
    final response = await _client.dio.get('/gamification/me');
    return GamificationProfile.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<ProfileAchievement>> achievements() async {
    final response = await _client.dio.get('/gamification/achievements');
    final values = response.data as List? ?? const [];
    return values
        .map(
          (item) => ProfileAchievement.fromJson(
            (item as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<XpActivityPage> xpActivity({int limit = 8}) async {
    final response = await _client.dio.get(
      '/gamification/xp',
      queryParameters: {'limit': limit},
    );
    return XpActivityPage.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<LeaderboardRank> leaderboardRank({String? provinceId}) async {
    final queryParameters = <String, dynamic>{};
    if (provinceId != null) queryParameters['scopeId'] = provinceId;
    final response = await _client.dio.get(
      '/leaderboard/me',
      queryParameters: queryParameters,
    );
    return LeaderboardRank.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
}
