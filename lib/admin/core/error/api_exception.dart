import 'package:dio/dio.dart';
import 'api_error.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      try {
        final err = ApiError.fromJson(data);
        return ApiException(err.status, err.message);
      } catch (_) {
        // response wasn't in the expected shape — fall through to generic
      }
    }
    return ApiException(
      e.response?.statusCode ?? 0,
      'Something went wrong. Please try again.',
    );
  }

  @override
  String toString() => message;
}