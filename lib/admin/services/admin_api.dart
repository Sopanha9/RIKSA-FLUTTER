import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';

class AdminApi {
  AdminApi(this._client);

  final DioClient _client;

  Map<String, dynamic> _extractData(Response res) =>
      res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {};

  List<dynamic> _extractList(Response res) =>
      res.data is List ? res.data as List : (res.data is Map ? [] : []);

  // ── Dashboard ──

  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _client.dio.get('/admin/dashboard/stats');
    return _extractData(res);
  }

  // ── Users ──

  Future<List<dynamic>> getUsers({int page = 0, int size = 20}) async {
    final res = await _client.dio.get('/admin/users', queryParameters: {
      'page': page,
      'size': size,
    });
    return _extractList(res);
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    final res = await _client.dio.get('/admin/users/$userId');
    return _extractData(res);
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _client.dio.put('/admin/users/$userId/role', data: {'role': role});
  }

  Future<void> deleteUser(String userId) async {
    await _client.dio.delete('/admin/users/$userId');
  }

  // ── Lessons ──

  Future<List<dynamic>> getLessons({int page = 0, int size = 20}) async {
    final res = await _client.dio.get('/admin/lessons', queryParameters: {
      'page': page,
      'size': size,
    });
    return _extractList(res);
  }

  Future<Map<String, dynamic>> getLessonById(String lessonId) async {
    final res = await _client.dio.get('/admin/lessons/$lessonId');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> createLesson(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/admin/lessons', data: data);
    return _extractData(res);
  }

  Future<Map<String, dynamic>> updateLesson(String lessonId, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/admin/lessons/$lessonId', data: data);
    return _extractData(res);
  }

  Future<void> deleteLesson(String lessonId) async {
    await _client.dio.delete('/admin/lessons/$lessonId');
  }

  // ── Exercises ──

  Future<List<dynamic>> getExercises({int page = 0, int size = 20}) async {
    final res = await _client.dio.get('/admin/exercises', queryParameters: {
      'page': page,
      'size': size,
    });
    return _extractList(res);
  }

  Future<Map<String, dynamic>> getExerciseById(String exerciseId) async {
    final res = await _client.dio.get('/admin/exercises/$exerciseId');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/admin/exercises', data: data);
    return _extractData(res);
  }

  Future<Map<String, dynamic>> updateExercise(String exerciseId, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/admin/exercises/$exerciseId', data: data);
    return _extractData(res);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _client.dio.delete('/admin/exercises/$exerciseId');
  }

  // ── Blog Posts ──

  Future<List<dynamic>> getBlogPosts({int page = 0, int size = 20}) async {
    final res = await _client.dio.get('/admin/blog-posts', queryParameters: {
      'page': page,
      'size': size,
    });
    return _extractList(res);
  }

  Future<Map<String, dynamic>> getBlogPostById(String postId) async {
    final res = await _client.dio.get('/admin/blog-posts/$postId');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> createBlogPost(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/admin/blog-posts', data: data);
    return _extractData(res);
  }

  Future<Map<String, dynamic>> updateBlogPost(String postId, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/admin/blog-posts/$postId', data: data);
    return _extractData(res);
  }

  Future<void> deleteBlogPost(String postId) async {
    await _client.dio.delete('/admin/blog-posts/$postId');
  }
}
