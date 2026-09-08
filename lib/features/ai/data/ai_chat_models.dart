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

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}

/// Titles the server hands back before a conversation has been named. They are
/// indistinguishable from each other in a list, so the UI derives a real title
/// from the first question instead.
const _placeholderTitles = {
  'new learning chat',
  'learning chat',
  'new chat',
  'untitled',
};

class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.title,
    required this.messages,
    this.updatedAt,
    this.lastMessage,
    this.messageCount,
  });
  final String id;
  final String title;
  final List<AiChatMessage> messages;
  final DateTime? updatedAt;

  /// Preview supplied by the list endpoint, when it sends one. The list of
  /// sessions does not always carry full message bodies.
  final String? lastMessage;
  final int? messageCount;

  factory AiChatSession.fromJson(Map<String, dynamic> json) {
    final messages = ((json['messages'] as List?) ?? const [])
        .map(
          (item) =>
              AiChatMessage.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
    return AiChatSession(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      messages: messages,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      lastMessage: _readPreview(json),
      messageCount: (json['messageCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (lastMessage != null) 'lastMessage': lastMessage,
    if (messageCount != null) 'messageCount': messageCount,
  };

  static String? _readPreview(Map<String, dynamic> json) {
    for (final key in const ['preview', 'lastMessage', 'lastMessagePreview']) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value;
      if (value is Map) {
        final content = value['content'];
        if (content is String && content.trim().isNotEmpty) return content;
      }
    }
    return null;
  }

  bool get hasPlaceholderTitle =>
      title.trim().isEmpty ||
      _placeholderTitles.contains(title.trim().toLowerCase());

  /// The student's own first question, which names the chat far better than a
  /// server default. Null when the list endpoint sent no message bodies.
  String? get firstQuestion {
    for (final message in messages) {
      if (message.isUser && message.content.trim().isNotEmpty) {
        return flattenChatText(message.content);
      }
    }
    return null;
  }

  /// Title to show in the chat list. [fallback] is the localized placeholder,
  /// used only when there is genuinely nothing to name the chat with.
  String displayTitle(String fallback) {
    if (!hasPlaceholderTitle) return title.trim();
    final question = firstQuestion;
    if (question != null && question.isNotEmpty) return question;
    return fallback;
  }

  /// One line of the most recent exchange, or null when nothing is known.
  String? get previewText {
    final explicit = lastMessage;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return flattenChatText(explicit);
    }
    for (final message in messages.reversed) {
      if (message.content.trim().isNotEmpty) {
        return flattenChatText(message.content);
      }
    }
    return null;
  }
}

/// Collapses markdown and line breaks into a single readable line for previews
/// and derived titles.
String flattenChatText(String raw) {
  final stripped = raw
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'[#>*_`~]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return stripped;
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
