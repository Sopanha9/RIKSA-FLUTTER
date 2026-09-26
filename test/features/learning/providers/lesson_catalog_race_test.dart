import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/learning/data/learning_api.dart';
import 'package:riksa_app/features/learning/data/learning_models.dart';
import 'package:riksa_app/features/learning/providers/lesson_catalog_provider.dart';

class _ControlledLearningApi extends LearningApi {
  _ControlledLearningApi()
    : super(DioClient(SessionStore(const FlutterSecureStorage())));

  final requests = <Completer<LessonPage>>[];

  @override
  Future<LessonPage> listLessons({
    String? categoryId,
    LessonDifficulty? difficulty,
    int? grade,
    int page = 0,
    int size = 20,
  }) {
    final request = Completer<LessonPage>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<List<LearningCategory>> categories() async => const [];
}

LessonPage _page(int totalPages) => LessonPage(
  content: const [],
  page: 0,
  size: 20,
  totalElements: 0,
  totalPages: totalPages,
);

void main() {
  test('older catalog response cannot replace a newer filter result', () async {
    final api = _ControlledLearningApi();
    final container = ProviderContainer(
      overrides: [learningApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    container.read(lessonCatalogProvider);
    await Future<void>.delayed(Duration.zero);

    final newer = container
        .read(lessonCatalogProvider.notifier)
        .selectGrade(10);
    expect(api.requests, hasLength(2));
    api.requests[1].complete(_page(2));
    await newer;
    api.requests[0].complete(_page(3));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(lessonCatalogProvider);
    expect(state.selectedGrade, 10);
    expect(state.totalPages, 2);
  });
}
