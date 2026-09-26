import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/ai/data/ai_chat_api.dart';
import 'package:riksa_app/features/ai/data/ai_chat_models.dart';
import 'package:riksa_app/features/ai/presentation/ai_chat_screen.dart';
import 'package:riksa_app/features/ai/presentation/ai_tutor_screen.dart';
import 'package:riksa_app/features/ai/providers/ai_chat_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final redditSans = FontLoader(RiksaTypography.latinFamily)
    ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
  final khmer = FontLoader(RiksaTypography.khmerFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Variable.ttf'));
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot =
      configuredRoot ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView),
    );
  await Future.wait([redditSans.load(), khmer.load(), materialIcons.load()]);
}

Widget _localizedApp(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en'), Locale('km')],
  home: home,
);

class _PreviewChatApi implements AiChatApi {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<AiChatSession>> sessions() async => _sessions;

  @override
  Future<AiChatSession> session(String id) async => _sessions.first;

  @override
  Future<AiChatTurn> send({
    String? sessionId,
    required String message,
    String? learningContext,
  }) async => const AiChatTurn(
    sessionId: 'a',
    message: AiChatMessage(id: 'x', role: 'assistant', content: 'Yes.'),
  );
}

/// Relative to the run so the rendered stamps stay `12m`, `40m`, `3d`.
final _now = DateTime.now();

final _sessions = [
  AiChatSession(
    id: 'a',
    title: 'New learning chat',
    updatedAt: _now.subtract(const Duration(minutes: 12)),
    messages: const [
      AiChatMessage(
        id: '1',
        role: 'user',
        content: 'Why does the limit not exist at x = 0?',
      ),
      AiChatMessage(
        id: '2',
        role: 'assistant',
        content:
            'Look at the two one-sided limits separately. They disagree, so '
            'the two-sided limit cannot exist.',
      ),
    ],
  ),
  AiChatSession(
    id: 'b',
    title: 'New learning chat',
    updatedAt: _now.subtract(const Duration(minutes: 40)),
    messages: const [
      AiChatMessage(
        id: '3',
        role: 'user',
        content: 'Explain conservation of momentum in a collision',
      ),
      AiChatMessage(
        id: '4',
        role: 'assistant',
        content: 'No external force acts, so the total stays the same.',
      ),
    ],
  ),
  AiChatSession(
    id: 'c',
    title: 'Balancing redox equations',
    updatedAt: _now.subtract(const Duration(days: 3)),
    messages: const [
      AiChatMessage(
        id: '5',
        role: 'assistant',
        content: 'Start by splitting the reaction into two half equations.',
      ),
    ],
  ),
];

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ai tutor chat list', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatApiProvider.overrideWithValue(_PreviewChatApi()),
          aiChatSessionsProvider.overrideWith((ref) async => _sessions),
        ],
        child: _localizedApp(const AiTutorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiTutorScreen),
      matchesGoldenFile('goldens/ai_tutor_list_en_light.png'),
    );
  });

  testWidgets('ai tutor first run', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatApiProvider.overrideWithValue(_PreviewChatApi()),
          aiChatSessionsProvider.overrideWith((ref) async => const []),
        ],
        child: _localizedApp(const AiTutorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiTutorScreen),
      matchesGoldenFile('goldens/ai_tutor_empty_en_light.png'),
    );
  });

  testWidgets('ai tutor conversation', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiChatApiProvider.overrideWithValue(_PreviewChatApi())],
        child: _localizedApp(
          const AiChatScreen(
            sessionId: 'a',
            lessonTitle: 'Limits and continuity',
            learningContext: 'Mathematics, Section 2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiChatScreen),
      matchesGoldenFile('goldens/ai_tutor_chat_en_light.png'),
    );
  });
}
