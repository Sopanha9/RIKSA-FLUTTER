import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/ai/data/ai_chat_api.dart';
import 'package:riksa_app/features/ai/data/ai_chat_models.dart';
import 'package:riksa_app/features/ai/presentation/ai_tutor_screen.dart';
import 'package:riksa_app/features/ai/providers/ai_chat_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// The chat list has to answer "which conversation is this?" before anything
/// else, and deleting one must be survivable.
void main() {
  testWidgets('rows carry a real title, a preview and a time', (tester) async {
    await _pump(
      tester,
      chats: [
        _session(
          id: 'a',
          title: 'New learning chat',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          messages: const [
            AiChatMessage(
              id: '1',
              role: 'user',
              content: 'How do I integrate by parts?',
            ),
            AiChatMessage(
              id: '2',
              role: 'assistant',
              content: 'Start by naming u and dv.',
            ),
          ],
        ),
        _session(
          id: 'b',
          title: 'New learning chat',
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          messages: const [
            AiChatMessage(
              id: '3',
              role: 'user',
              content: 'Why is momentum conserved?',
            ),
          ],
        ),
      ],
    );

    // Two chats the server named identically now read as two different things.
    expect(find.text('How do I integrate by parts?'), findsOneWidget);
    expect(find.text('Why is momentum conserved?'), findsOneWidget);
    expect(find.text('New learning chat'), findsNothing);
    expect(find.text('Start by naming u and dv.'), findsOneWidget);
    expect(find.text('5m'), findsOneWidget);
    expect(find.text('2d'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
  });

  testWidgets('deleting offers undo and only then removes the chat', (
    tester,
  ) async {
    final api = _MockAiChatApi();
    when(() => api.delete(any())).thenAnswer((_) async {});
    await _pump(
      tester,
      chats: [_session(id: 'a', title: 'Vectors')],
      api: api,
    );

    await tester.tap(find.byTooltip('Chat options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();

    // Gone from view, but nothing has been deleted yet.
    expect(find.text('Vectors'), findsNothing);
    verifyNever(() => api.delete(any()));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Vectors'), findsOneWidget);
    verifyNever(() => api.delete(any()));

    await tester.tap(find.byTooltip('Chat options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();
    expect(find.text('Vectors'), findsNothing);

    // Letting the undo window close, rather than taking it, commits the delete.
    await tester.drag(find.text('Chat deleted'), const Offset(0, 200));
    await tester.pumpAndSettle();

    verify(() => api.delete('a')).called(1);
    expect(find.text('Vectors'), findsNothing);
  });

  testWidgets('an empty tutor offers openers, not just a blank page', (
    tester,
  ) async {
    await _pump(tester, chats: const []);

    expect(find.text('Ask anything you are learning'), findsOneWidget);
    expect(find.text('Explain this again, more slowly'), findsOneWidget);
    expect(find.text('Give me a worked example'), findsOneWidget);
    expect(find.text('Ask a new question'), findsOneWidget);
  });

  testWidgets('search appears only once the list outgrows a screen', (
    tester,
  ) async {
    await _pump(
      tester,
      chats: [
        for (var index = 0; index < 6; index++)
          _session(id: '$index', title: 'Chat $index'),
      ],
    );

    expect(find.byKey(const ValueKey('ai-chat-search')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('ai-chat-search')),
      'Chat 3',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-chat-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-chat-4')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('ai-chat-search')),
      'trigonometry',
    );
    await tester.pumpAndSettle();
    expect(find.text('No chat matches that.'), findsOneWidget);
  });
  testWidgets('holds on a small screen in Khmer', (tester) async {
    await _pump(
      tester,
      size: const Size(360, 640),
      locale: const Locale('km'),
      chats: [
        _session(
          id: 'a',
          title: 'មេរៀនគណិតវិទ្យា',
          messages: const [
            AiChatMessage(
              id: '1',
              role: 'user',
              content: 'ហេតុអ្វីបានជាលីមីតមិនមាននៅ x = 0?',
            ),
          ],
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('សួរសំណួរថ្មី'), findsOneWidget);
  });

  testWidgets('the empty state fits a small screen', (tester) async {
    await _pump(tester, chats: const [], size: const Size(360, 640));
    expect(tester.takeException(), isNull);
  });
}

AiChatSession _session({
  required String id,
  required String title,
  List<AiChatMessage> messages = const [],
  DateTime? updatedAt,
}) => AiChatSession(
  id: id,
  title: title,
  messages: messages,
  updatedAt: updatedAt ?? DateTime.now(),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<AiChatSession> chats,
  AiChatApi? api,
  Size size = const Size(430, 932),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiChatSessionsProvider.overrideWith((ref) async => chats),
        if (api != null) aiChatApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        locale: locale,
        home: const AiTutorScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MockAiChatApi extends Mock implements AiChatApi {}
