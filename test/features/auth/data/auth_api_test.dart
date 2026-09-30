import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/auth/data/auth_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the province catalog without an auth token', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _ProvinceAdapter();
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);

    final provinces = await AuthApi(client).listProvinces();

    expect(adapter.path, '/auth/provinces');
    expect(adapter.authorization, isNull);
    expect(provinces, hasLength(1));
    expect(provinces.single.nameLatin, 'Phnom Penh');
    expect(provinces.single.nameKhmer, 'ភ្នំពេញ');
  });

  test('falls back to defaultProvinces when network request fails', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _ErrorAdapter();
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);

    final provinces = await AuthApi(client).listProvinces();

    expect(provinces, isNotEmpty);
    expect(provinces.any((p) => p.nameLatin == 'Phnom Penh'), isTrue);
  });
}

class _ErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'Connection refused',
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ProvinceAdapter implements HttpClientAdapter {
  String? path;
  Object? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    authorization = options.headers['Authorization'];
    return ResponseBody.fromString(
      jsonEncode([
        {
          'id': '00000000-0000-0000-0000-000000000011',
          'nameKhmer': 'ភ្នំពេញ',
          'nameLatin': 'Phnom Penh',
        },
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
