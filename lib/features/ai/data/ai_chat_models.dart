class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
  });
  final String id;
  final String role;
  final String content;
  final DateTime? createdAt;
  bool get isUser => role == 'user';
  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
    id: json['id']?.toString() ?? '',
    role: json['role'] as String? ?? 'assistant',
    content: json['content'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.title,
    required this.messages,
    this.updatedAt,
  });
  final String id;
  final String title;
  final List<AiChatMessage> messages;
  final DateTime? updatedAt;
  factory AiChatSession.fromJson(Map<String, dynamic> json) => AiChatSession(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? 'Learning chat',
    messages: ((json['messages'] as List?) ?? const [])
        .map(
          (item) =>
              AiChatMessage.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
  );
}

class AiChatTurn {
  const AiChatTurn({required this.sessionId, required this.message});
  final String sessionId;
  final AiChatMessage message;
  factory AiChatTurn.fromJson(Map<String, dynamic> json) => AiChatTurn(
    sessionId: json['sessionId']?.toString() ?? '',
    message: AiChatMessage.fromJson(
      (json['message'] as Map).cast<String, dynamic>(),
    ),
  );
}
