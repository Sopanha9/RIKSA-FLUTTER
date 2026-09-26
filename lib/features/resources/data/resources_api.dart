import '../../../core/network/dio_client.dart';
import 'resource_models.dart';

abstract interface class ResourcesRepository {
  Future<LessonResourcePage> list(String lessonId, {String? cursor});
  Future<LessonResource> create(
    String lessonId, {
    required String title,
    required String url,
    required LessonResourceKind kind,
  });
  Future<LessonResource> save(String id);
  Future<LessonResource> unsave(String id);
  Future<void> delete(String id);
  Future<void> report(String id);
}

class ResourcesApi implements ResourcesRepository {
  ResourcesApi(this._client);

  final DioClient _client;

  @override
  Future<LessonResourcePage> list(String lessonId, {String? cursor}) async {
    final response = await _client.dio.get(
      '/learning/lessons/$lessonId/resources',
      queryParameters: {'limit': 20, 'cursor': ?cursor},
    );
    return LessonResourcePage.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<LessonResource> create(
    String lessonId, {
    required String title,
    required String url,
    required LessonResourceKind kind,
  }) async {
    final response = await _client.dio.post(
      '/learning/lessons/$lessonId/resources',
      data: {'title': title.trim(), 'url': url.trim(), 'kind': kind.wire},
    );
    return LessonResource.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<LessonResource> save(String id) async {
    final response = await _client.dio.post('/resources/$id/save');
    return LessonResource.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<LessonResource> unsave(String id) async {
    final response = await _client.dio.delete('/resources/$id/save');
    return LessonResource.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _client.dio.delete('/resources/$id');
  }

  @override
  Future<void> report(String id) async {
    await _client.dio.post(
      '/reports',
      data: {'targetType': 'RESOURCE', 'targetId': id, 'reason': 'OTHER'},
    );
  }
}
