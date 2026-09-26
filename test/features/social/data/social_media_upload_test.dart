import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/social/data/social_api.dart';

/// Post images are uploaded to the API, which stores the bytes and returns a
/// link; the client's job is to send one multipart part and read the URL back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late File image;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('riksa-upload');
    image = File('${temp.path}/photo.png')
      ..writeAsBytesSync(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  });

  tearDown(() {
    try {
      temp.deleteSync(recursive: true);
    } catch (_) {}
  });

  SocialApi apiWith(_UploadAdapter adapter) {
    FlutterSecureStorage.setMockInitialValues({});
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);
    return SocialApi(client);
  }

  test('uploadMedia posts the file and returns the stored link', () async {
    final adapter = _UploadAdapter(
      body: {'id': 'abc.png', 'url': 'http://riksa.test/api/v1/media/abc.png'},
    );

    final url = await apiWith(adapter).uploadMedia(image.path);

    expect(url, 'http://riksa.test/api/v1/media/abc.png');
    expect(adapter.path, endsWith('/media'));
    expect(adapter.method, 'POST');
    expect(adapter.contentType, contains('multipart/form-data'));
  });

  test('uploadMedia surfaces the reason the server refused the file', () async {
    final adapter = _UploadAdapter(
      status: 400,
      body: {'message': 'File must be a JPEG, PNG, GIF or WebP image'},
    );

    await expectLater(
      () => apiWith(adapter).uploadMedia(image.path),
      throwsA(
        isA<SocialApiException>().having(
          (e) => e.message,
          'message',
          'File must be a JPEG, PNG, GIF or WebP image',
        ),
      ),
    );
  });

  test('uploadMedia rejects a response with no link in it', () async {
    final adapter = _UploadAdapter(body: {'id': 'abc.png'});

    await expectLater(
      () => apiWith(adapter).uploadMedia(image.path),
      throwsA(isA<SocialApiException>()),
    );
  });
}

class _UploadAdapter implements HttpClientAdapter {
  _UploadAdapter({required this.body, this.status = 200});

  final Map<String, dynamic> body;
  final int status;
  String? path;
  String? method;
  String? contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    method = options.method;
    contentType = options.contentType;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
