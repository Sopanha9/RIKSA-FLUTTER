import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/ai/data/ai_chat_api.dart';
import 'package:riksa_app/features/ai/data/ai_chat_models.dart';
import 'package:riksa_app/features/ai/presentation/ai_chat_screen.dart';
import 'package:riksa_app/features/ai/providers/ai_chat_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// A tutor a student can trust means: nothing they typed disappears, and the
/// tutor knows which lesson they came from.
void main() {
  testWidgets('a question cannot be sent until something is typed', (
    tester,
  ) async {
    await _pump(tester, api: _MockAiChatApi());

    IconButton sendButton() => tester.widget<IconButton>(
      find.byKey(const ValueKey('send-ai-message')),
    );
    expect(sendButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('ai-message-input')),
      'Why does a limit exist here?',
    );
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('a failed question stays on screen and can be sent again', (
    tester,
  ) async {
    final api = _MockAiChatApi();
    when(
      () => api.send(
        sessionId: any(named: 'sessionId'),
        message: any(named: 'message'),
        learningContext: any(named: 'learningContext'),
      ),
    ).thenThrow(Exception('offline'));
    await _pump(tester, api: api);

    await tester.enterText(
      find.byKey(const ValueKey('ai-message-input')),
      'Why is momentum conserved?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-ai-message')));
    await tester.pumpAndSettle();

    // The message is still there, marked, with a way to send it again.
    expect(find.text('Why is momentum conserved?'), findsOneWidget);
    expect(find.text('Not sent'), findsOneWidget);

    when(
      () => api.send(
        sessionId: any(named: 'sessionId'),
        message: any(named: 'message'),
        learningContext: any(named: 'learningContext'),
      ),
    ).thenAnswer(
      (_) async => const AiChatTurn(
        sessionId: 'session-1',
        message: AiChatMessage(
          id: 'reply',
          role: 'assistant',
          content: 'Because no external force acts on the system.',
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('retry-ai-message')));
    await tester.pumpAndSettle();

    expect(find.text('Not sent'), findsNothing);
    expect(
      find.text('Because no external force acts on the system.'),
      findsOneWidget,
    );
  });

  testWidgets('the lesson it was opened from is shown and sent along', (
    tester,
  ) async {
    final api = _MockAiChatApi();
    when(
      () => api.send(
        sessionId: any(named: 'sessionId'),
        message: any(named: 'message'),
        learningContext: any(named: 'learningContext'),
      ),
    ).thenAnswer(
      (_) async => const AiChatTurn(
        sessionId: 'session-1',
        message: AiChatMessage(id: 'r', role: 'assistant', content: 'Sure.'),
      ),
    );
    await _pump(
      tester,
      api: api,
      lessonTitle: 'Limits and continuity',
      learningContext: 'Mathematics, Section 2',
    );

    expect(find.text('About Limits and continuity'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('ai-message-input')),
      'Explain step three',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-ai-message')));
    await tester.pumpAndSettle();

    final captured = verify(
      () => api.send(
        sessionId: any(named: 'sessionId'),
        message: 'Explain step three',
        learningContext: captureAny(named: 'learningContext'),
      ),
    ).captured.single;
    expect(captured, 'Lesson: Limits and continuity. Mathematics, Section 2');
  });

  testWidgets('a new chat opens with ways in, not a blank page', (
    tester,
  ) async {
    await _pump(tester, api: _MockAiChatApi());

    expect(find.byKey(const ValueKey('ai-coach-greeting')), findsOneWidget);
    expect(find.textContaining("I'm your AI Study Coach"), findsOneWidget);
    expect(find.text('Try asking about:'), findsOneWidget);
    await tester.tap(find.text('Give me a worked example'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('ai-message-input')),
    );
    expect(field.controller?.text, 'Give me a worked example');
  });

  testWidgets(
    'displays quick follow-up prompt chips after messages exist and tapping populates composer',
    (tester) async {
      final api = _MockAiChatApi();
      when(
        () => api.send(
          sessionId: any(named: 'sessionId'),
          message: any(named: 'message'),
          learningContext: any(named: 'learningContext'),
        ),
      ).thenAnswer(
        (_) async => const AiChatTurn(
          sessionId: 'session-1',
          message: AiChatMessage(
            id: 'tutor-1',
            role: 'assistant',
            content: 'Here is how you solve it: step 1 is factoring.',
          ),
        ),
      );

      await _pump(tester, api: api);

      // Send initial question
      await tester.enterText(
        find.byKey(const ValueKey('ai-message-input')),
        'How do I factor quadratics?',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-ai-message')));
      await tester.pumpAndSettle();

      // Quick follow-up chips bar should now be visible
      final chipsBar = find.byKey(const ValueKey('ai-quick-followup-chips'));
      expect(chipsBar, findsOneWidget);
      expect(find.text('Summarize key points'), findsOneWidget);

      // Tapping a quick follow-up chip populates the composer
      await tester.tap(find.text('Summarize key points'));
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(
        find.byKey(const ValueKey('ai-message-input')),
      );
      expect(input.controller?.text, 'Summarize key points');
    },
  );

  testWidgets('allows copying tutor answer to clipboard from copy button', (
    tester,
  ) async {
    final api = _MockAiChatApi();
    when(
      () => api.send(
        sessionId: any(named: 'sessionId'),
        message: any(named: 'message'),
        learningContext: any(named: 'learningContext'),
      ),
    ).thenAnswer(
      (_) async => const AiChatTurn(
        sessionId: 'session-1',
        message: AiChatMessage(
          id: 'tutor-1',
          role: 'assistant',
          content: 'The quadratic formula is x = (-b +- sqrt(b^2 - 4ac)) / 2a.',
        ),
      ),
    );

    final log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (methodCall) async {
        log.add(methodCall);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await _pump(tester, api: api);

    await tester.enterText(
      find.byKey(const ValueKey('ai-message-input')),
      'What is the formula?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-ai-message')));
    await tester.pumpAndSettle();

    final copyButton = find.byKey(const ValueKey('copy-ai-response'));
    expect(copyButton, findsOneWidget);

    await tester.tap(copyButton);
    await tester.pump();

    // Verify snackbar is shown
    expect(find.text('Copied to clipboard'), findsOneWidget);

    // Verify clipboard call
    expect(
      log.any(
        (call) =>
            call.method == 'Clipboard.setData' &&
            (call.arguments as Map)['text'] ==
                'The quadratic formula is x = (-b +- sqrt(b^2 - 4ac)) / 2a.',
      ),
      isTrue,
    );
  });
}


Future<void> _pump(
  WidgetTester tester, {
  required AiChatApi api,
  String? lessonTitle,
  String? learningContext,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [aiChatApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
        home: AiChatScreen(
          lessonTitle: lessonTitle,
          learningContext: learningContext,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MockAiChatApi extends Mock implements AiChatApi {}
