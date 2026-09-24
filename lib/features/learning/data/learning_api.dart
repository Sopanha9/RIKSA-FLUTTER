import '../../../core/network/api_config.dart';
import '../../../core/network/dio_client.dart';
import 'learning_models.dart';

class LearningApi {
  LearningApi(this._client);

  final DioClient _client;

  Future<LessonPage> listLessons({
    String? categoryId,
    LessonDifficulty? difficulty,
    int? grade,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get(
      '/lessons',
      queryParameters: {
        'page': page,
        'size': size,
        // ignore: use_null_aware_elements
        if (categoryId != null) 'categoryId': categoryId,
        if (difficulty != null) 'difficulty': difficulty.wire,
        // Forward-compatible: Spring currently ignores this parameter. Once
        // the API accepts grade, no Flutter contract change is required.
        // ignore: use_null_aware_elements
        if (grade != null) 'grade': grade,
      },
    );
    return LessonPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<LearningCategory>> categories() async {
    final response = await _client.dio.post(
      '${ApiConfig.baseUrl}/graphql',
      data: const {'query': '{ categories { id name } }'},
    );
    final body = response.data as Map<String, dynamic>;
    final categories =
        (body['data'] as Map<String, dynamic>?)?['categories'] as List? ??
        const [];
    return categories
        .map(
          (item) =>
              LearningCategory.fromJson((item as Map).cast<String, dynamic>()),
        )
        .where((category) => category.id.isNotEmpty)
        .toList();
  }

  /// `GET /lessons/roadmap` returns the syllabus grouped into ordered units,
  /// each carrying its own lessons and the learner's state for them. It is the
  /// only endpoint that knows both the size of a subject and how far into it
  /// the learner is, so the home screen and the roadmap screen share it.
  Future<LearningRoadmap> roadmap(String categoryId) async {
    final response = await _client.dio.get(
      '/lessons/roadmap',
      queryParameters: {'categoryId': categoryId},
    );
    return LearningRoadmap.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<LessonDetail> lesson(String lessonId) async {
    final response = await _client.dio.get('/lessons/$lessonId');
    return LessonDetail.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) async {
    final response = await _client.dio.post(
      '/lessons/$lessonId/exercises/$exerciseId/attempt',
      data: {'answer': answer},
    );
    return LessonAnswerResult.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<LessonAnswerResult> checkAnswer({
    required String lessonId,
    required String exerciseId,
    required String answer,
  }) async {
    final response = await _client.dio.post(
      '/learning/lessons/$lessonId/exercises/$exerciseId/check',
      data: {'answer': answer},
    );
    return LessonAnswerResult.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<LessonCompletionResult> completeLesson({
    required String lessonId,
    required String reflectionText,
  }) async {
    final response = await _client.dio.post(
      '/lessons/$lessonId/complete',
      data: {'reflectionText': reflectionText},
    );
    return LessonCompletionResult.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  Future<ContinueLearningResponse> continueLearning() async {
    final response = await _client.dio.get('/learning/me/continue');
    return ContinueLearningResponse.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
}
