import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import 'notification_models.dart';

abstract interface class NotificationsRepository {
  Future<NotificationPage> list({String? cursor, int limit = 20});
  Future<int> unreadCount();

  /// Returns the unread count after marking.
  Future<int> markRead(String id);
  Future<void> markAllRead();
}

class NotificationsApi implements NotificationsRepository {
  NotificationsApi(this._client);

  final DioClient _client;

  @override
  Future<NotificationPage> list({String? cursor, int limit = 20}) async {
    final response = await _client.dio.get(
      '/notifications',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    );
    return NotificationPage.fromJson(jsonMap(response));
  }

  @override
  Future<int> unreadCount() async {
    final response = await _client.dio.get('/notifications/unread-count');
    return (jsonMap(response)['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> markRead(String id) async {
    final response = await _client.dio.post('/notifications/$id/read');
    return (jsonMap(response)['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markAllRead() async {
    await _client.dio.post('/notifications/read-all');
  }
}
