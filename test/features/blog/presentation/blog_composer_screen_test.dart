import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/blog/data/blog_api.dart';
import 'package:riksa_app/features/blog/presentation/blog_composer_screen.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// The composer has to make markdown reachable without typing syntax, and
/// show the writer what the syntax turns into.
void main() {
  testWidgets('the formatting toolbar sits on the composer', (tester) async {
    await _pumpComposer(tester);

    expect(find.byKey(const ValueKey('blog-markdown-toolbar')), findsOneWidget);
    for (final action in ['bold', 'italic', 'heading', 'quote']) {
      expect(
        find.byKey(ValueKey('blog-markdown-$action')),
        findsOneWidget,
        reason: '$action should be one tap away',
      );
    }
  });

  testWidgets('bold wraps the selected words in the body', (tester) async {
    await _pumpComposer(tester);
    final body = find.widgetWithText(TextField, _bodyHint);

    await tester.enterText(body, 'photosynthesis matters');
    await tester.pump();
    _select(tester, body, base: 0, extent: 14);

    await tester.tap(find.byKey(const ValueKey('blog-markdown-bold')));
    await tester.pump();

    expect(
      tester.widget<TextField>(body).controller!.text,
      '**photosynthesis** matters',
    );
  });

  testWidgets('quote prefixes the line the caret is on', (tester) async {
    await _pumpComposer(tester);
    final body = find.widgetWithText(TextField, _bodyHint);

    await tester.enterText(body, 'first\nsecond');
    await tester.pump();
    _select(tester, body, base: 8);

    await tester.tap(find.byKey(const ValueKey('blog-markdown-quote')));
    await tester.pump();

    expect(
      tester.widget<TextField>(body).controller!.text,
      'first\n> second',
    );
  });

  testWidgets('preview renders the markdown and hides the toolbar', (
    tester,
  ) async {
    await _pumpComposer(tester);
    final toggle = find.byKey(const ValueKey('blog-preview-toggle'));

    // Nothing written yet, so there is nothing to preview.
    expect(tester.widget<IconButton>(toggle).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, _bodyHint),
      '## Heading\n\n> a quote',
    );
    await tester.pump();

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.byKey(const ValueKey('blog-markdown-toolbar')), findsNothing);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownBody), findsNothing);
    expect(find.byKey(const ValueKey('blog-markdown-toolbar')), findsOneWidget);
  });
}

const _bodyHint = 'Share what you learned. Markdown works here.';

/// Moves the cursor the way a tap or drag in the field would.
void _select(
  WidgetTester tester,
  Finder field, {
  required int base,
  int? extent,
}) {
  final controller = tester.widget<TextField>(field).controller!;
  controller.selection = TextSelection(
    baseOffset: base,
    extentOffset: extent ?? base,
  );
}

Future<void> _pumpComposer(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        blogApiProvider.overrideWithValue(_MockBlogApi()),
        blogCategoriesProvider.overrideWith((ref) async => const []),
        currentUserIdProvider.overrideWithValue('me'),
        authProvider.overrideWith(_AuthStub.new),
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
        home: const BlogComposerScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MockBlogApi extends Mock implements BlogApi {}

class _AuthStub extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'me',
      username: 'sopanha',
      displayName: 'Sopanha',
      emailVerified: true,
      phoneVerified: true,
      role: 'USER',
    ),
  );
}
