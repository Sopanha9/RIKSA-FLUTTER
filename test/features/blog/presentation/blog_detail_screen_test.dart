import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/blog/data/blog_api.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/features/blog/presentation/blog_detail_screen.dart';
import 'package:riksa_app/features/blog/providers/blog_provider.dart';
import 'package:riksa_app/features/userProfile/data/public_profile.dart';
import 'package:riksa_app/features/userProfile/data/public_profile_api.dart';
import 'package:riksa_app/features/userProfile/providers/public_profile_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _MockBlogApi extends Mock implements BlogApi {}

class _Profiles implements PublicProfileRepository {
  @override
  Future<PublicProfile> fetch(String userId) async => PublicProfile(
    id: userId,
    username: 'author',
    displayName: 'Author Name',
    isVerified: false,
    totalXp: 100,
    currentTier: 'BRONZE',
    achievements: const [],
  );
}

void main() {
  final testPost = BlogPost(
    id: 'post-1',
    authorId: 'author-1',
    title: 'How to Solve Complex Limits in Calculus',
    content: 'Long form content explaining the fundamentals of epsilon-delta definition and practical tricks.',
    status: BlogStatus.approved,
    viewCount: 150,
    likeCount: 24,
    categoryId: 'math',
    liked: false,
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 1),
  );

  testWidgets(
    'renders reading progress indicator and cycles text size on button tap',
    (tester) async {
      final api = _MockBlogApi();
      when(() => api.getPost('post-1')).thenAnswer((_) async => testPost);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blogApiProvider.overrideWithValue(api),
            publicProfileRepositoryProvider.overrideWithValue(_Profiles()),
            currentUserIdProvider.overrideWithValue('reader-1'),
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
            home: const BlogDetailScreen(id: 'post-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Post title and content should render
      expect(
        find.text('How to Solve Complex Limits in Calculus'),
        findsWidgets,
      );

      // Reading progress indicator should exist
      expect(
        find.byKey(const ValueKey('blog-reading-progress')),
        findsOneWidget,
      );

      // Font size toggle button should exist
      final fontToggle = find.byKey(const ValueKey('blog-font-size-toggle'));
      expect(fontToggle, findsOneWidget);

      // Tap font size toggle once: cycles to Large (1.18x)
      await tester.tap(fontToggle);
      await tester.pump();
      expect(find.text('Text size: Large (1.18x)'), findsOneWidget);

      // Tap again: cycles to Extra Large (1.35x)
      await tester.tap(fontToggle);
      await tester.pump();
      expect(find.text('Text size: Extra Large (1.35x)'), findsOneWidget);

      // Tap again: cycles back to Default (1.0x)
      await tester.tap(fontToggle);
      await tester.pump();
      expect(find.text('Text size: Default (1.0x)'), findsOneWidget);
    },
  );
}
