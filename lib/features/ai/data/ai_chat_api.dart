import '../../../core/network/dio_client.dart';
import 'ai_chat_models.dart';

class AiChatApi {
  AiChatApi(this._client);
  final DioClient _client;
  Future<List<AiChatSession>> sessions() async {
    final response = await _client.dio.get('/ai/chats');
    return (response.data as List? ?? const [])
        .map(
          (item) =>
              AiChatSession.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<AiChatSession> session(String id) async {
    final response = await _client.dio.get('/ai/chats/$id');
    return AiChatSession.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
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

  Future<void> delete(String id) => _client.dio.delete<void>('/ai/chats/$id');
}
