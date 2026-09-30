import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/resources/data/resource_models.dart';
import 'package:riksa_app/features/resources/data/resources_api.dart';
import 'package:riksa_app/features/resources/presentation/lesson_resources_sheet.dart';
import 'package:riksa_app/features/resources/providers/lesson_resources_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('lists resources with kind, author and domain', (tester) async {
    final repository = _FakeResourcesRepository();
    await _mount(tester, repository);
    await _openResources(tester);

    expect(find.text('Chemistry paper'), findsOneWidget);
    expect(find.textContaining('example.edu'), findsOneWidget);
    expect(find.textContaining('Dara'), findsOneWidget);
  });

  testWidgets('guest can browse and is sent to sign in before saving', (
    tester,
  ) async {
    final repository = _FakeResourcesRepository();
    await _mount(tester, repository, authenticated: false);
    await _openResources(tester);
    await tester.tap(find.byKey(const ValueKey('resource-save-resource-1')));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 0);
    expect(find.text('Sign in route'), findsOneWidget);
  });

  testWidgets('share form validates title and URL before sending', (
    tester,
  ) async {
    final repository = _FakeResourcesRepository()..empty = true;
    await _mount(tester, repository);
    await _openResources(tester);
    await tester.tap(find.byKey(const ValueKey('resource-empty-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resource-share-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Use a title from 3 to 120 characters.'), findsOneWidget);
    expect(find.text('Enter a valid http or https address.'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('save button reflects its optimistic state while the API waits', (
    tester,
  ) async {
    final repository = _FakeResourcesRepository();
    final save = Completer<LessonResource>();
    repository.pendingSave = save;
    await _mount(tester, repository);
    await _openResources(tester);
    await tester.tap(find.byKey(const ValueKey('resource-save-resource-1')));
    await tester.pump();

    expect(find.byTooltip('Remove saved resource'), findsOneWidget);
    expect(repository.saveCalls, 1);
    save.complete(_resource(saved: true, saveCount: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('resource sheet remains scrollable in Khmer at 200% scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeResourcesRepository(longTitle: true);
    await _mount(tester, repository, locale: const Locale('km'), textScale: 2);
    await _openResources(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('lesson-resource-list')), findsOneWidget);
  });
}

Future<void> _mount(
  WidgetTester tester,
  _FakeResourcesRepository repository, {
  bool authenticated = true,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/lesson',
    routes: [
      GoRoute(
        path: '/lesson',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const ValueKey('open-resources'),
              onPressed: () => showLessonResourcesSheet(
                context,
                lessonId: 'lesson-1',
                lessonTitle: 'Chemistry',
              ),
              child: const Text('Open resources'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Sign in route'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        resourcesRepositoryProvider.overrideWithValue(repository),
        authProvider.overrideWith(() => _FakeAuthNotifier(authenticated)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
}

Future<void> _openResources(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open-resources')));
  await tester.pumpAndSettle();
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.authenticated);
  final bool authenticated;

  @override
  AuthState build() => authenticated
      ? Authenticated(
          const AuthUser(
            id: 'learner-1',
            username: 'learner',
            displayName: 'Learner',
            emailVerified: true,
            phoneVerified: true,
            role: 'USER',
          ),
        )
      : const Unauthenticated();
}

class _FakeResourcesRepository implements ResourcesRepository {
  _FakeResourcesRepository({this.longTitle = false});

  bool empty = false;
  final bool longTitle;
  int saveCalls = 0;
  int createCalls = 0;
  Completer<LessonResource>? pendingSave;

  @override
  Future<LessonResourcePage> list(
    String lessonId, {
    String? cursor,
  }) async => LessonResourcePage(
    edges: empty
        ? const []
        : [
            _resource(
              title: longTitle
                  ? 'សន្លឹកលំហាត់គីមីវិទ្យា សម្រាប់ត្រៀមប្រឡងបាក់ឌុបឆ្នាំ២០២៦ និងមេរៀនបន្ថែម'
                  : 'Chemistry paper',
            ),
          ],
    hasNextPage: false,
  );

  @override
  Future<LessonResource> create(
    String lessonId, {
    required String title,
    required String url,
    required LessonResourceKind kind,
  }) async {
    createCalls++;
    return _resource(title: title, url: url, kind: kind);
  }

  @override
  Future<LessonResource> save(String id) {
    saveCalls++;
    return pendingSave?.future ??
        Future.value(_resource(saved: true, saveCount: 1));
  }

  @override
  Future<LessonResource> unsave(String id) async => _resource();

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> report(String id) async {}
}

LessonResource _resource({
  String id = 'resource-1',
  String title = 'Chemistry paper',
  String url = 'https://www.example.edu/paper.pdf',
  LessonResourceKind kind = LessonResourceKind.pdf,
  bool saved = false,
  int saveCount = 4,
}) => LessonResource(
  id: id,
  lessonId: 'lesson-1',
  title: title,
  url: url,
  kind: kind,
  author: const ResourceAuthor(id: 'author-1', displayName: 'Dara'),
  saveCount: saveCount,
  savedByMe: saved,
  createdAt: DateTime(2026, 9, 24),
);
