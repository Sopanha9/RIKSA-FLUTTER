import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/blog/data/blog_api.dart';
import 'package:riksa_app/features/blog/data/blog_models.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

/// Contract for the author-owned writes. The moderation lifecycle means an
/// edit can come back as PENDING, and the UI reads that off the response.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DioClient clientWith(_RecordingAdapter adapter) {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);
    return client;
  }

  test('updatePost puts the full body to the post id', () async {
    final adapter = _RecordingAdapter(
      body: _postJson(status: 'PENDING', title: 'Edited title'),
    );
    final api = BlogApi(clientWith(adapter));

    final updated = await api.updatePost(
      'post-1',
      BlogPostRequest(
        title: 'Edited title',
        content: 'Rewritten body',
        coverUrl: 'https://riksa.test/cover.jpg',
        categoryId: 'category-1',
      ),
    );

    expect(adapter.method, 'PUT');
    expect(adapter.path, '/blog/post-1');
    expect(adapter.requestBody, {
      'title': 'Edited title',
      'content': 'Rewritten body',
      'coverUrl': 'https://riksa.test/cover.jpg',
      'categoryId': 'category-1',
    });
    expect(updated.title, 'Edited title');
    expect(updated.status, BlogStatus.pending);
  });

  test('updatePost omits a cover that was cleared', () async {
    final adapter = _RecordingAdapter(body: _postJson());
    final api = BlogApi(clientWith(adapter));

    await api.updatePost(
      'post-1',
      BlogPostRequest(
        title: 'Title',
        content: 'Body',
        categoryId: 'category-1',
      ),
    );

    expect(adapter.requestBody, isNot(contains('coverUrl')));
  });

  test('deletePost deletes the post id', () async {
    final adapter = _RecordingAdapter(body: null, statusCode: 204);
    final api = BlogApi(clientWith(adapter));

    await api.deletePost('post-1');

    expect(adapter.method, 'DELETE');
    expect(adapter.path, '/blog/post-1');
  });

  test('an HTML response body throws a friendly DioException', () async {
    final adapter = _RecordingAdapter(
      body: '<html><body>Bad Gateway</body></html>',
    );
    final api = BlogApi(clientWith(adapter));

    await expectLater(
      api.listPosts(),
      throwsA(
        isA<DioException>()
            .having(
              (error) => error.type,
              'exception type',
              DioExceptionType.badResponse,
            )
            .having(
              (error) => error.message,
              'message',
              'The server returned an unexpected response. Please try again.',
            ),
      ),
    );
  });

  test('a rejected write surfaces an actionable message', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    DioException failure(int status) => DioException(
      requestOptions: RequestOptions(path: '/blog/post-1'),
      response: Response(
        requestOptions: RequestOptions(path: '/blog/post-1'),
        statusCode: status,
      ),
    );

    expect(
      blogOwnerActionError(failure(403), BlogOwnerAction.delete, l10n: l10n),
      'You can only delete your own posts',
    );
    expect(
      blogOwnerActionError(failure(404), BlogOwnerAction.edit, l10n: l10n),
      'This post no longer exists',
    );
    expect(
      blogOwnerActionError(failure(405), BlogOwnerAction.edit, l10n: l10n),
      'Something went wrong',
    );
  });
}

Map<String, dynamic> _postJson({
  String status = 'APPROVED',
  String title = 'Title',
}) => {
  'id': 'post-1',
  'authorId': 'author-1',
  'title': title,
  'content': 'Rewritten body',
  'coverUrl': null,
  'status': status,
  'viewCount': 12,
  'likeCount': 3,
  'categoryId': 'category-1',
  'liked': false,
  'createdAt': '2026-08-24T10:00:00Z',
  'updatedAt': '2026-09-05T10:00:00Z',
};

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required this.body, this.statusCode = 200});

  final Object? body;
  final int statusCode;

  String? method;
  String? path;
  Map<String, dynamic>? requestBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    final data = options.data;
    requestBody = data is Map ? data.cast<String, dynamic>() : null;
    return ResponseBody.fromString(
      switch (body) {
        null => '',
        String value => value,
        _ => jsonEncode(body),
      },
      statusCode,
      headers: {
        Headers.contentTypeHeader: [
          if (body is String)
            'text/html; charset=utf-8'
          else
            Headers.jsonContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
