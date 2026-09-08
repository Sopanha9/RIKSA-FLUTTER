import '../../../core/network/dio_client.dart';
import 'ai_chat_cache.dart';
import 'ai_chat_models.dart';

class AiChatApi {
  AiChatApi(this._client, [AiChatCache? cache])
      : _cache = cache ?? AiChatCache();

  final DioClient _client;
  final AiChatCache _cache;

  Future<List<AiChatSession>> sessions() async {
    try {
      final response = await _client.dio.get('/ai/chats');
      final list = (response.data as List? ?? const [])
          .map(
            (item) =>
                AiChatSession.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList();
      await _cache.saveSessions(list);
      return list;
    } catch (e) {
      final cached = await _cache.loadSessions();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<AiChatSession> session(String id) async {
    try {
      final response = await _client.dio.get('/ai/chats/$id');
      final item = AiChatSession.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
      await _cache.saveSession(item);
      return item;
    } catch (e) {
      final cached = await _cache.loadSession(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<AiChatTurn> send({
    String? sessionId,
    required String message,
    String? learningContext,
  }) async {
    final response = await _client.dio.post(
      '/ai/chats/messages',
      data: {
        // ignore: use_null_aware_elements
        if (sessionId != null) 'sessionId': sessionId,
        'message': message,
        if (learningContext != null && learningContext.trim().isNotEmpty)
          'learningContext': learningContext.trim(),
      },
    );
    return AiChatTurn.fromJson((response.data as Map).cast<String, dynamic>());
  }

  Future<void> delete(String id) async {
    await _client.dio.delete<void>('/ai/chats/$id');
    await _cache.removeSession(id);
  }
}
