import 'package:dio/dio.dart';

const invalidJsonResponseMessage =
    'The server returned an unexpected response. Please try again.';

/// Returns a response body as a JSON object, or a friendly Dio error if it is
/// empty or has a different top-level shape.
Map<String, dynamic> jsonMap(Response<dynamic> response) {
  final data = response.data;
  if (data is Map && data.keys.every((key) => key is String)) {
    return Map<String, dynamic>.from(data);
  }

  throw _invalidJsonResponse(response);
}

/// Returns a response body as a list, preserving APIs that treat an empty
/// response as an empty collection.
List<dynamic> jsonListOrEmpty(Response<dynamic> response) {
  final data = response.data;
  if (data == null) return const [];
  if (data is List) return data;

  throw _invalidJsonResponse(response);
}

DioException _invalidJsonResponse(Response<dynamic> response) => DioException(
  requestOptions: response.requestOptions,
  response: response,
  type: DioExceptionType.badResponse,
  message: invalidJsonResponseMessage,
);
