import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/social/data/social_api.dart';
import 'package:riksa_app/features/social/data/social_models.dart';
import 'package:riksa_app/features/social/presentation/communities_screen.dart';
import 'package:riksa_app/features/social/presentation/create_community_screen.dart';
import 'package:riksa_app/features/social/providers/social_feed_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

import 'golden_fonts.dart';

SocialCategory _community(
  String id,
  String name,
  String description,
  int members, {
  bool joined = false,
}) => SocialCategory(
  id: id,
  name: name,
  slug: id,
  description: description,
  memberCount: members,
  joined: joined,
);

final _communities = [
  _community(
    'biology',
    'Biology',
    'Living systems, cells, heredity and ecosystems.',
    2,
    joined: true,
  ),
  _community(
    'chemistry',
    'Chemistry',
    'Organic and inorganic chemistry, and lab science.',
    1,
    joined: true,
  ),
  _community(
    'computer-science',
    'Computer Science',
    'Algorithms, Flutter and software engineering in Khmer.',
    6,
    joined: true,
  ),
  _community(
    'history',
    'History & Heritage',
    'Angkorian civilization and Cambodian culture.',
    1200,
  ),
  _community(
    'khmer-literature',
    'Khmer Literature',
    'Khmer grammar, classical poetry and novels.',
    842,
  ),
  _community(
    'mathematics',
    'Mathematics',
    'Algebra, geometry and exam problems.',
    0,
  ),
];

class _FakeSocialApi extends SocialApi {
  _FakeSocialApi(super.client);

  final List<String> joinedIds = [];
  final List<String> createdNames = [];
  String? createError;

  @override
  Future<SocialCategory> createCommunity({
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    if (createError != null) throw SocialApiException(createError!);
    createdNames.add(name);
    return _community('robotics', name, description ?? '', 1, joined: true);
  }

  @override
  Future<List<SocialCategory>> categories() async => _communities;

  @override
  Future<SocialCategory> setCategoryJoined(
    String categoryId, {
    required bool joined,
  }) async {
    joinedIds.add(categoryId);
    final item = _communities.firstWhere((entry) => entry.id == categoryId);
    return _community(
      item.id,
      item.name,
      item.description!,
      item.memberCount + 1,
      joined: joined,
    );
  }
}

Future<_FakeSocialApi> _pump(
  WidgetTester tester, {
  bool dark = false,
  double height = 1500,
}) async {
  tester.view.physicalSize = Size(393, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  FlutterSecureStorage.setMockInitialValues({});
  final client = DioClient(
    SessionStore(const FlutterSecureStorage()),
    baseUrl: 'http://riksa.test/api/v1',
  );
  addTearDown(client.dispose);
  final api = _FakeSocialApi(client);
  final router = GoRouter(
    initialLocation: '/communities',
    routes: [
      GoRoute(
        path: '/communities',
        builder: (_, _) => const CommunitiesScreen(),
      ),
      GoRoute(
        path: '/communities/create',
        builder: (_, _) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: '/communities/:id',
        builder: (_, state) =>
            Scaffold(body: Text('community-${state.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [socialApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Asset images decode off the fake clock; wait for them before capturing.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
  return api;
}

void main() {
  setUpAll(loadRiksaGoldenFonts);

  for (final dark in [false, true]) {
    testWidgets('communities directory ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      await _pump(tester, dark: dark);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/communities_directory_en_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });
  }

  testWidgets('features the biggest community the reader has not joined', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.byKey(const ValueKey('communities-featured-history')),
      findsOneWidget,
    );
    // The featured community is not repeated in the list below it.
    expect(find.byKey(const ValueKey('community-history')), findsNothing);
    expect(find.text('No members yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('community-toggle-history')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('communities-joined-history')),
      findsOneWidget,
    );
  });

  testWidgets('topic chips narrow the list and hide the featured card', (
    tester,
  ) async {
    await _pump(tester);
    // No community is about tech-free general chat, so that chip is absent.
    expect(
      find.byKey(const ValueKey('communities-filter-general')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('communities-filter-science')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('communities-featured-history')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('community-mathematics')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-khmer-literature')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('community-computer-science')),
      findsNothing,
    );
  });

  testWidgets('search shows matching rows and opens a community', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'poetry');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('community-khmer-literature')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('community-biology')), findsNothing);

    await tester.tap(find.text('Khmer Literature'));
    await tester.pumpAndSettle();
    expect(find.text('community-khmer-literature'), findsOneWidget);
  });

  testWidgets('create community form', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('communities-create')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateCommunityScreen), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/create_community_en_light.png'),
    );
  });

  testWidgets('blocked names never reach the server', (tester) async {
    final api = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('communities-create')));
    await tester.pumpAndSettle();

    final name = find.byKey(const ValueKey('create-community-name'));
    final submit = find.byKey(const ValueKey('create-community-submit'));
    for (final (value, message) in [
      ('ab', 'Use 3 to 50 characters.'),
      ('Robotics <b>', "Use only letters, numbers, spaces and & ' . , ( ) + # -"),
      ('2026', 'The name needs at least one letter.'),
      ('Riksa Official', 'This name is reserved. Try another one.'),
      ('M o d s', 'This name is reserved. Try another one.'),
    ]) {
      await tester.enterText(name, value);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget, reason: value);
    }
    expect(api.createdNames, isEmpty);
  });

  testWidgets('shows the server refusal and stays on the form', (
    tester,
  ) async {
    final api = await _pump(tester);
    api.createError = 'You can create at most 3 communities a day.';
    await tester.tap(find.byKey(const ValueKey('communities-create')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('create-community-name')),
      'Robotics Club',
    );
    final submit = find.byKey(const ValueKey('create-community-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.text('You can create at most 3 communities a day.'),
      findsOneWidget,
    );
    expect(find.byType(CreateCommunityScreen), findsOneWidget);
  });

  testWidgets('a created community opens straight away', (tester) async {
    final api = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('communities-create-card')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('create-community-name')),
      '  Robotics    Club ',
    );
    final submit = find.byKey(const ValueKey('create-community-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(api.createdNames, ['Robotics Club']);
    expect(find.text('community-robotics'), findsOneWidget);
  });
}
