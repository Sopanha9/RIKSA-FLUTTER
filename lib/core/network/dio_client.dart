import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

/// Keys used to persist auth tokens in secure storage.
class StorageKeys {
  StorageKeys._();
  static const String accessToken = 'riksa_access_token';
  static const String refreshToken = 'riksa_refresh_token';
  static const String userId = 'riksa_user_id';
  static const String username = 'riksa_username';
  static const String role = 'riksa_role';
}

/// Dio instance configured for the Riksa API, with a single-flight refresh
/// interceptor that:
///   1. Attaches the access token to every protected request.
///   2. On 401, refreshes once (single-flight) and retries the original call.
class DioClient {
  DioClient(this._storage);

  final FlutterSecureStorage _storage;
  late final Dio dio = _build();

  Dio _build() {
    final d = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl + ApiConfig.apiPrefix,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Don't attach token to auth endpoints
          if (options.path.startsWith('/auth/')) {
            return handler.next(options);
          }
          final token = await _storage.read(key: StorageKeys.accessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }
          // Single-flight refresh
          if (_refreshing) {
            try {
              await _refreshCompleter?.future;
              return handler.resolve(await _retry(e.requestOptions));
            } catch (_) {
              return handler.next(e);
            }
          }
          final refreshed = await _refresh();
          if (!refreshed) {
            await _clearSession();
            return handler.next(e);
          }
          try {
            handler.resolve(await _retry(e.requestOptions));
          } catch (err) {
            handler.next(err as DioException);
          }
        },
      ),
    );

    if (kDebugMode) {
      d.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }

    return d;
  }

  bool _refreshing = false;
  Completer<bool>? _refreshCompleter;

  Future<bool> _refresh() async {
    _refreshing = true;
    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }
      // Use a bare dio for refresh so we don't recurse into the interceptor
      final raw = Dio(
        BaseOptions(baseUrl: ApiConfig.baseUrl + ApiConfig.apiPrefix),
      );
      final res = await raw.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data as Map<String, dynamic>;
      await _persistSession(data);
      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<Response> _retry(RequestOptions opts) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    opts.headers['Authorization'] = 'Bearer $token';
    final raw = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl + ApiConfig.apiPrefix,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ),
    );
    return raw.fetch(opts);
  }

  Future<void> persistSession(Map<String, dynamic> authResponse) =>
      _persistSession(authResponse);

  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _storage.write(
      key: StorageKeys.accessToken,
      value: data['accessToken'] as String?,
    );
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: data['refreshToken'] as String?,
    );
    await _storage.write(
      key: StorageKeys.userId,
      value: data['userId']?.toString() ?? '',
    );
    await _storage.write(
      key: StorageKeys.username,
      value: data['username'] as String? ?? '',
    );
    await _storage.write(
      key: StorageKeys.role,
      value: data['role'] as String? ?? '',
    );
  }

  Future<void> clearSession() => _clearSession();
  Future<void> _clearSession() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);
  Future<String?> getUserId() => _storage.read(key: StorageKeys.userId);
  Future<String?> getUsername() => _storage.read(key: StorageKeys.username);
}