import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import 'quest_models.dart';

abstract interface class QuestsRepository {
  Future<TodayQuests> today();
  Future<DailyQuest> claim(String id);
}

abstract interface class WeeklyQuestsRepository {
  Future<WeeklyQuests> week();
  Future<WeeklyQuest> claimWeekly(String id);
  Future<WeeklyChest> openChest();
}

class QuestsApi implements QuestsRepository, WeeklyQuestsRepository {
  QuestsApi(this._client);

  final DioClient _client;

  @override
  Future<TodayQuests> today() async {
    final response = await _client.dio.get('/quests/today');
    return TodayQuests.fromJson(jsonMap(response));
  }

  @override
  Future<WeeklyQuests> week() async {
    final response = await _client.dio.get('/quests/week');
    return WeeklyQuests.fromJson(jsonMap(response));
  }

  @override
  Future<DailyQuest> claim(String id) async {
    final response = await _client.dio.post('/quests/$id/claim');
    return DailyQuest.fromJson(jsonMap(response));
  }

  @override
  Future<WeeklyQuest> claimWeekly(String id) async {
    final response = await _client.dio.post('/quests/$id/claim');
    return WeeklyQuest.fromJson(jsonMap(response));
  }

  @override
  Future<WeeklyChest> openChest() async {
    final response = await _client.dio.post('/quests/chest/open');
    final json = jsonMap(response);
    return WeeklyChest.fromJson(
      (json['chest'] as Map?)?.cast<String, dynamic>() ?? json,
    );
  }
}
