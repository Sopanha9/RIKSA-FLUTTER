import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/ai/data/ai_chat_models.dart';
import 'package:riksa_app/features/ai/presentation/widgets/ai_tutor_ui.dart';

/// A chat list is only useful if each row says something different. These are
/// the rules that make that true.
void main() {
  group('displayTitle', () {
    test('keeps a real server title', () {
      final chat = _session(title: 'Limits of a function', messages: const []);
      expect(chat.displayTitle('Learning chat'), 'Limits of a function');
    });

    test(
      'falls back to the first question when the title is a placeholder',
      () {
        final chat = _session(
          title: 'New learning chat',
          messages: const [
            AiChatMessage(
              id: '1',
              role: 'user',
              content: 'Why does **momentum** stay constant?',
            ),
            AiChatMessage(id: '2', role: 'assistant', content: 'Because ...'),
          ],
        );
        expect(
          chat.displayTitle('Learning chat'),
          'Why does momentum stay constant?',
        );
      },
    );

    test('uses the localized fallback when nothing names the chat', () {
      final chat = _session(title: '', messages: const []);
      expect(chat.displayTitle('Learning chat'), 'Learning chat');
    });
  });

  group('previewText', () {
    test('prefers a preview sent by the list endpoint', () {
      final chat = AiChatSession.fromJson({
        'id': '1',
        'title': 'New chat',
        'preview': 'Try differentiating both sides.',
      });
      expect(chat.previewText, 'Try differentiating both sides.');
      expect(chat.lastMessage, 'Try differentiating both sides.');
    });

    test('reads a lastMessage object when that is what the server sends', () {
      final chat = AiChatSession.fromJson({
        'id': '1',
        'title': 'New chat',
        'lastMessage': {'content': 'Start from Newton\'s second law.'},
      });
      expect(chat.previewText, "Start from Newton's second law.");
    });

    test('falls back to the last message body, flattened to one line', () {
      final chat = _session(
        title: 'x',
        messages: const [
          AiChatMessage(id: '1', role: 'user', content: 'Hello'),
          AiChatMessage(
            id: '2',
            role: 'assistant',
            content: '# Heading\n\nA line\nand another.',
          ),
        ],
      );
      expect(chat.previewText, 'Heading A line and another.');
    });

    test('is null when the server sent no bodies at all', () {
      expect(_session(title: 'x', messages: const []).previewText, isNull);
    });
  });

  group('groupAiChats', () {
    final now = DateTime(2026, 9, 5, 14);

    test('sorts newest first and splits into dated sections', () {
      final sections = groupAiChats([
        _session(
          title: 'old',
          messages: const [],
          updatedAt: DateTime(2026, 7, 1),
        ),
        _session(
          title: 'today',
          messages: const [],
          updatedAt: DateTime(2026, 9, 5, 9),
        ),
        _session(
          title: 'week',
          messages: const [],
          updatedAt: DateTime(2026, 9, 2),
        ),
        _session(
          title: 'later today',
          messages: const [],
          updatedAt: DateTime(2026, 9, 5, 13),
        ),
      ], now: now);

      expect(sections.map((s) => s.group), [
        AiChatGroup.today,
        AiChatGroup.thisWeek,
        AiChatGroup.earlier,
      ]);
      expect(sections.first.chats.map((c) => c.title), [
        'later today',
        'today',
      ]);
      expect(sections[1].chats.single.title, 'week');
      expect(sections.last.chats.single.title, 'old');
    });

    test('chats with no timestamp sink to the earlier group', () {
      final sections = groupAiChats([
        _session(title: 'undated', messages: const []),
      ], now: now);
      expect(sections.single.group, AiChatGroup.earlier);
    });
  });
}

AiChatSession _session({
  required String title,
  required List<AiChatMessage> messages,
  DateTime? updatedAt,
}) => AiChatSession(
  id: title,
  title: title,
  messages: messages,
  updatedAt: updatedAt,
);
