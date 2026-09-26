import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/resources/data/resource_models.dart';
import 'package:riksa_app/features/resources/data/resources_api.dart';
import 'package:riksa_app/features/resources/providers/lesson_resources_provider.dart';

void main() {
  test('loads the first page and appends the next cursor page', () async {
    final repository = _FakeResourcesRepository()..twoPages = true;
    final container = ProviderContainer(
      overrides: [resourcesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(lessonResourcesProvider('lesson-1').future);
    await container
        .read(lessonResourcesProvider('lesson-1').notifier)
        .loadMore();

    final state = container.read(lessonResourcesProvider('lesson-1')).value!;
    expect(state.resources.map((resource) => resource.id), [
      'resource-1',
      'resource-2',
    ]);
    expect(repository.cursors, [null, 'cursor-1']);
    expect(state.hasNextPage, isFalse);
  });

  test(
    'save updates optimistically and rolls back when the API fails',
    () async {
      final repository = _FakeResourcesRepository()..failSave = true;
      final container = ProviderContainer(
        overrides: [resourcesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(lessonResourcesProvider('lesson-1').future);
      final operation = container
          .read(lessonResourcesProvider('lesson-1').notifier)
          .toggleSave(_resource());
      expect(
        container
            .read(lessonResourcesProvider('lesson-1'))
            .value!
            .resources
            .single
            .savedByMe,
        isTrue,
      );
      await expectLater(operation, throwsStateError);
      expect(
        container
            .read(lessonResourcesProvider('lesson-1'))
            .value!
            .resources
            .single
            .savedByMe,
        isFalse,
      );
    },
  );

  test('guest lesson resources load without requiring an account', () async {
    final repository = _FakeResourcesRepository();
    final container = ProviderContainer(
      overrides: [resourcesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final page = await container.read(
      lessonResourcesProvider('lesson-1').future,
    );

    expect(page.resources, hasLength(1));
    expect(repository.listCalls, 1);
  });
}

class _FakeResourcesRepository implements ResourcesRepository {
  int listCalls = 0;
  bool twoPages = false;
  bool failSave = false;
  final List<String?> cursors = [];

  @override
  Future<LessonResourcePage> list(String lessonId, {String? cursor}) async {
    listCalls++;
    cursors.add(cursor);
    if (cursor != null) {
      return LessonResourcePage(
        edges: [_resource(id: 'resource-2')],
        hasNextPage: false,
      );
    }
    return LessonResourcePage(
      edges: [_resource()],
      hasNextPage: twoPages,
      endCursor: twoPages ? 'cursor-1' : null,
    );
  }

  @override
  Future<LessonResource> create(
    String lessonId, {
    required String title,
    required String url,
    required LessonResourceKind kind,
  }) async => _resource(id: 'created', title: title, url: url, kind: kind);

  @override
  Future<LessonResource> save(String id) async {
    if (failSave) throw StateError('save failed');
    return _resource(saved: true, saveCount: 1);
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
  String title = 'Chemistry notes',
  String url = 'https://example.edu/notes',
  LessonResourceKind kind = LessonResourceKind.link,
  bool saved = false,
  int saveCount = 0,
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
