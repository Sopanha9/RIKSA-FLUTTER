import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores only the access and refresh token pair', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final client = DioClient(
      SessionStore(storage),
      baseUrl: 'http://riksa.test/api/v1',
    );
    addTearDown(client.dispose);

    await client.persistSession({
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'userId': 'must-not-be-cached',
      'username': 'must-not-be-cached',
    });

    expect(await client.getAccessToken(), 'access-token');
    expect(await client.getRefreshToken(), 'refresh-token');
    expect(await storage.read(key: 'riksa_user_id'), isNull);
    expect(await storage.read(key: 'riksa_username'), isNull);
  });

  test(
    'attaches bearer to /auth/me and refreshes concurrent 401s once',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'expired-access',
        StorageKeys.refreshToken: 'valid-refresh',
      });
      final adapter = _AuthAdapter();
      final client = DioClient(
        SessionStore(const FlutterSecureStorage()),
        baseUrl: 'http://riksa.test/api/v1',
        httpClientAdapter: adapter,
      );
      addTearDown(client.dispose);

      final responses = await Future.wait([
        client.dio.get<Map<String, dynamic>>('/auth/me'),
        client.dio.get<Map<String, dynamic>>('/protected'),
      ]);

      expect(
        responses.every((response) => response.data?['ok'] == true),
        isTrue,
      );
      expect(adapter.refreshCalls, 1);
      expect(await client.getAccessToken(), 'fresh-access');
      expect(await client.getRefreshToken(), 'fresh-refresh');
    },
  );

  test('a 401 after the single retry clears the session', () async {
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'expired-access',
      StorageKeys.refreshToken: 'valid-refresh',
    });
    final adapter = _AuthAdapter()..acceptFreshAccess = false;
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);
    final expired = expectLater(client.sessionExpired.first, completes);

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    await expired;

    expect(adapter.refreshCalls, 1);
    expect(await client.getAccessToken(), isNull);
    expect(await client.getRefreshToken(), isNull);
  });

  test(
    'a refresh timeout keeps the session and surfaces the original 401',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'expired-access',
        StorageKeys.refreshToken: 'valid-refresh',
      });
      final adapter = _AuthAdapter()..refreshTimeout = true;
      final client = DioClient(
        SessionStore(const FlutterSecureStorage()),
        baseUrl: 'http://riksa.test/api/v1',
        httpClientAdapter: adapter,
      );
      addTearDown(client.dispose);
      var sessionExpired = false;
      final subscription = client.sessionExpired.listen((_) {
        sessionExpired = true;
      });
      addTearDown(subscription.cancel);

      await expectLater(
        client.dio.get<Map<String, dynamic>>('/protected'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'original response status',
            401,
          ),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(adapter.refreshCalls, 1);
      expect(await client.getAccessToken(), 'expired-access');
      expect(await client.getRefreshToken(), 'valid-refresh');
      expect(sessionExpired, isFalse);
    },
  );

  test(
    'a rejected refresh clears the session and emits session-expired',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'expired-access',
        StorageKeys.refreshToken: 'revoked-refresh',
      });
      final adapter = _AuthAdapter()..refreshStatusCode = 401;
      final client = DioClient(
        SessionStore(const FlutterSecureStorage()),
        baseUrl: 'http://riksa.test/api/v1',
        httpClientAdapter: adapter,
      );
      addTearDown(client.dispose);
      final expired = expectLater(client.sessionExpired.first, completes);

      await expectLater(
        client.dio.get<Map<String, dynamic>>('/protected'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'original response status',
            401,
          ),
        ),
      );
      await expired;

      expect(adapter.refreshCalls, 1);
      expect(await client.getAccessToken(), isNull);
      expect(await client.getRefreshToken(), isNull);
    },
  );

  test('an HTML page from refresh keeps the session', () async {
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.accessToken: 'expired-access',
      StorageKeys.refreshToken: 'valid-refresh',
    });
    final adapter = _AuthAdapter()..refreshHtml = true;
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);
    var sessionExpired = false;
    final subscription = client.sessionExpired.listen((_) {
      sessionExpired = true;
    });
    addTearDown(subscription.cancel);

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(await client.getRefreshToken(), 'valid-refresh');
    expect(sessionExpired, isFalse);
  });

  test(
    'a 503 from refresh keeps the session and emits no expiration',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.accessToken: 'expired-access',
        StorageKeys.refreshToken: 'valid-refresh',
      });
      final adapter = _AuthAdapter()..refreshStatusCode = 503;
      final client = DioClient(
        SessionStore(const FlutterSecureStorage()),
        baseUrl: 'http://riksa.test/api/v1',
        httpClientAdapter: adapter,
      );
      addTearDown(client.dispose);
      var sessionExpired = false;
      final subscription = client.sessionExpired.listen((_) {
        sessionExpired = true;
      });
      addTearDown(subscription.cancel);

      await expectLater(
        client.dio.get<Map<String, dynamic>>('/protected'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'original response status',
            401,
          ),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(adapter.refreshCalls, 1);
      expect(await client.getAccessToken(), 'expired-access');
      expect(await client.getRefreshToken(), 'valid-refresh');
      expect(sessionExpired, isFalse);
    },
  );
}

class _AuthAdapter implements HttpClientAdapter {
  int refreshCalls = 0;
  bool acceptFreshAccess = true;
  bool refreshTimeout = false;
  bool refreshHtml = false;
  int refreshStatusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    const jsonHeaders = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (options.path == '/auth/refresh') {
      refreshCalls++;
      if (refreshTimeout) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (refreshHtml) {
        return ResponseBody.fromString(
          '<html>Sign in to the Wi-Fi</html>',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        );
      }
      if (refreshStatusCode != 200) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'refresh failed'}),
          refreshStatusCode,
          headers: jsonHeaders,
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'userId': 'user-id',
          'accessToken': 'fresh-access',
          'refreshToken': 'fresh-refresh',
          'tokenType': 'Bearer',
          'username': 'sophea',
          'role': 'USER',
        }),
        200,
        headers: jsonHeaders,
      );
    }

    final authorization = options.headers['Authorization'];
    if ((options.path == '/auth/me' || options.path == '/protected') &&
        authorization == 'Bearer fresh-access' &&
        acceptFreshAccess) {
      return ResponseBody.fromString(
        jsonEncode({'ok': true}),
        200,
        headers: jsonHeaders,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'expired'}),
      401,
      headers: jsonHeaders,
    );
  }

  @override
  void close({bool force = false}) {}
}
