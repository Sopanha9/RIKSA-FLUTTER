import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import 'quest_models.dart';

abstract interface class QuestsRepository {
  Future<TodayQuests> today();
  Future<DailyQuest> claim(String id);
}

class QuestsApi implements QuestsRepository {
  QuestsApi(this._client);

  final DioClient _client;

  @override
  Future<TodayQuests> today() async {
    final response = await _client.dio.get('/quests/today');
    return TodayQuests.fromJson(jsonMap(response));
  }

  @override
  Future<DailyQuest> claim(String id) async {
    final response = await _client.dio.post('/quests/$id/claim');
    return DailyQuest.fromJson(jsonMap(response));
  }
}
