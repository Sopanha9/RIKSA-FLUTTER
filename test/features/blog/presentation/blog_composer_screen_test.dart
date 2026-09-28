import 'package:dio/dio.dart';
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
import 'package:riksa_app/features/blog/data/blog_models.dart';
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

    expect(tester.widget<TextField>(body).controller!.text, 'first\n> second');
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

  testWidgets('an approved post shows the published state', (tester) async {
    final api = _FakeBlogApi(response: _blogPost(BlogStatus.approved));
    await _pumpComposer(tester, api: api, categories: [_science]);
    await _fillDraft(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Open post'), findsOneWidget);
    expect(api.createdRequest?.title, 'Draft title');
  });

  testWidgets('an approved edit shows the published state', (tester) async {
    final api = _FakeBlogApi(response: _blogPost(BlogStatus.approved));
    await _pumpComposer(
      tester,
      api: api,
      categories: [_science],
      post: _blogPost(BlogStatus.pending),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Updated title');
    await tester.enterText(fields.at(1), 'Updated body');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Open post'), findsOneWidget);
  });

  testWidgets('a pending post shows the review state', (tester) async {
    await _pumpComposer(
      tester,
      api: _FakeBlogApi(response: _blogPost(BlogStatus.pending)),
      categories: [_science],
    );
    await _fillDraft(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    expect(find.text('A quick review'), findsOneWidget);
    expect(
      find.textContaining('take a quick look at this one'),
      findsOneWidget,
    );
  });

  for (final (locale, expected) in [
    (const Locale('en'), 'Please remove offensive words before posting.'),
    (const Locale('km'), 'សូមលុបពាក្យមិនសមរម្យចេញ មុនពេលបង្ហោះ។'),
  ]) {
    testWidgets(
      'a blocked post keeps its draft and shows the localized reason in ${locale.languageCode}',
      (tester) async {
        await _pumpComposer(
          tester,
          api: _FakeBlogApi(createError: _profanityError()),
          categories: [_science],
          locale: locale,
        );
        await _fillDraft(tester);
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            locale.languageCode == 'en' ? 'Post' : 'បង្ហោះ',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(expected), findsOneWidget);
        expect(find.byType(BlogComposerScreen), findsOneWidget);
        final fields = tester.widgetList<TextField>(find.byType(TextField));
        expect(fields.first.controller?.text, 'Draft title');
        expect(fields.elementAt(1).controller?.text, 'Draft body');
      },
    );
  }
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

Future<void> _pumpComposer(
  WidgetTester tester, {
  BlogApi? api,
  List<BlogCategory> categories = const [],
  Locale locale = const Locale('en'),
  BlogPost? post,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        blogApiProvider.overrideWithValue(api ?? _MockBlogApi()),
        blogCategoriesProvider.overrideWith((ref) async => categories),
        blogFeedProvider.overrideWith(_BlogFeedStub.new),
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
        locale: locale,
        home: BlogComposerScreen(post: post),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MockBlogApi extends Mock implements BlogApi {}

class _BlogFeedStub extends BlogFeedNotifier {
  @override
  BlogFeedState build() => const BlogFeedLoading();
}

final _science = BlogCategory(
  id: 'science',
  name: 'Science',
  slug: 'science',
  memberCount: 0,
  joined: false,
);

class _FakeBlogApi implements BlogApi {
  _FakeBlogApi({this.response, this.createError});

  final BlogPost? response;
  final DioException? createError;
  BlogPostRequest? createdRequest;

  @override
  Future<BlogPost> createPost(BlogPostRequest request) async {
    createdRequest = request;
    final error = createError;
    if (error != null) throw error;
    return response!;
  }

  @override
  Future<BlogPost> updatePost(String _, BlogPostRequest _) async => response!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BlogPost _blogPost(BlogStatus status) => BlogPost(
  id: 'blog-1',
  authorId: 'me',
  title: 'Draft title',
  content: 'Draft body',
  status: status,
  viewCount: 0,
  likeCount: 0,
  categoryId: _science.id,
  liked: false,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);

DioException _profanityError() {
  final requestOptions = RequestOptions(path: '/blog');
  return DioException(
    requestOptions: requestOptions,
    response: Response<Map<String, dynamic>>(
      requestOptions: requestOptions,
      statusCode: 422,
      data: {
        'code': 'CONTENT_BLOCKED',
        'message': 'Blocked',
        'reasons': ['PROFANITY'],
      },
    ),
  );
}

Future<void> _fillDraft(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Draft title');
  await tester.enterText(fields.at(1), 'Draft body');
  await tester.tap(find.byType(ActionChip));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Science'));
  await tester.pumpAndSettle();
}

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
