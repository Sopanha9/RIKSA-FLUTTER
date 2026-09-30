import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/moderation_error.dart';

void main() {
  test('parses a blocked REST response and its reasons', () {
    final requestOptions = RequestOptions(path: '/blog');
    final rejection = fromDio(
      DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 422,
          data: {
            'code': 'CONTENT_BLOCKED',
            'message': 'Blocked',
            'reasons': ['PROFANITY', 'UNKNOWN_LINK'],
          },
        ),
      ),
    );

    expect(rejection?.kind, ModerationRejectionKind.blocked);
    expect(rejection?.reasons, ['PROFANITY', 'UNKNOWN_LINK']);
  });

  test('parses a rate-limited REST response', () {
    final requestOptions = RequestOptions(path: '/blog');
    final rejection = fromDio(
      DioException(
        requestOptions: requestOptions,
        response: Response<Map<String, dynamic>>(
          requestOptions: requestOptions,
          statusCode: 429,
          data: {'code': 'RATE_LIMITED', 'message': 'Slow down'},
        ),
      ),
    );

    expect(rejection?.kind, ModerationRejectionKind.rateLimited);
    expect(rejection?.reasons, isEmpty);
  });

  test('ignores unrelated REST errors', () {
    final requestOptions = RequestOptions(path: '/blog');
    expect(
      fromDio(
        DioException(
          requestOptions: requestOptions,
          response: Response<Map<String, dynamic>>(
            requestOptions: requestOptions,
            statusCode: 400,
            data: {'code': 'VALIDATION_ERROR'},
          ),
        ),
      ),
      isNull,
    );
  });

  test('parses GraphQL moderation extensions', () {
    final rejection = fromGraphQlErrors([
      {
        'message': 'Content was blocked',
        'extensions': {
          'code': 'CONTENT_BLOCKED',
          'reasons': ['DUPLICATE'],
        },
      },
    ]);

    expect(rejection?.kind, ModerationRejectionKind.blocked);
    expect(rejection?.reasons, ['DUPLICATE']);
  });

  test('finds a moderation error after unrelated GraphQL errors', () {
    final rejection = fromGraphQlErrors([
      {
        'message': 'A different field failed',
        'extensions': {'code': 'OTHER'},
      },
      {
        'message': 'Rate limited',
        'extensions': {'code': 'RATE_LIMITED'},
      },
    ]);

    expect(rejection?.kind, ModerationRejectionKind.rateLimited);
  });
}
