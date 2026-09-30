import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import 'profile_models.dart';

class ProfileApi {
  ProfileApi(this._client);

  final DioClient _client;

  Future<GamificationProfile> gamificationProfile() async {
    final response = await _client.dio.get('/gamification/me');
    return GamificationProfile.fromJson(jsonMap(response));
  }

  Future<List<ProfileAchievement>> achievements() async {
    final response = await _client.dio.get('/gamification/achievements');
    final values = jsonListOrEmpty(response);
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
    return XpActivityPage.fromJson(jsonMap(response));
  }

  Future<List<RankHistoryEntry>> rankHistory({int limit = 50}) async {
    final response = await _client.dio.get(
      '/gamification/rank-history',
      queryParameters: {'limit': limit},
    );
    final data = jsonMap(response);
    return ((data['edges'] as List?) ?? const [])
        .map(
          (item) =>
              RankHistoryEntry.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<LeaderboardRank> leaderboardRank({String? provinceId}) async {
    final queryParameters = <String, dynamic>{};
    if (provinceId != null) queryParameters['scopeId'] = provinceId;
    final response = await _client.dio.get(
      '/leaderboard/me',
      queryParameters: queryParameters,
    );
    return LeaderboardRank.fromJson(jsonMap(response));
  }

  /// Fetches the full ranked board for a scope.
  ///
  /// Mirrors `GET /leaderboard?scope=&scopeId=&date=`. Rows arrive ordered by
  /// rank and carry `displayName`/`avatarUrl` for direct rendering.
  Future<List<LeaderboardRow>> leaderboard({
    required LeaderboardScope scope,
    required String scopeId,
  }) async {
    final response = await _client.dio.get(
      '/leaderboard',
      queryParameters: {'scope': scope.apiName, 'scopeId': scopeId},
    );
    final values = jsonListOrEmpty(response);
    return values
        .map(
          (item) =>
              LeaderboardRow.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }
}
