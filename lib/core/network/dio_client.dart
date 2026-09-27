import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/session_store.dart';
import 'api_config.dart';
import 'json_response.dart';

enum RefreshOutcome { refreshed, rejected, unavailable }

/// Keys used to persist auth tokens in secure storage.
class StorageKeys {
  StorageKeys._();
  static const String accessToken = SessionStore.accessTokenKey;
  static const String refreshToken = SessionStore.refreshTokenKey;
}

/// Dio instance configured for the Riksa API, with a single-flight refresh
/// interceptor that:
///   1. Attaches the access token to every protected request.
///   2. On 401, refreshes once (single-flight) and retries the original call.
class DioClient {
  DioClient(this._sessionStore, {String? baseUrl, this.httpClientAdapter})
    : _baseUrl = baseUrl ?? ApiConfig.baseUrl + ApiConfig.apiPrefix;

  final SessionStore _sessionStore;
  final String _baseUrl;
  final HttpClientAdapter? httpClientAdapter;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  late final Dio dio = _build();

  Stream<void> get sessionExpired => _sessionExpiredController.stream;

  static const Set<String> _publicAuthPaths = {
    '/auth/register',
    '/auth/login',
    '/auth/refresh',
    '/auth/logout',
    '/auth/google',
    '/auth/telegram/bot',
    '/auth/telegram/start',
    '/auth/telegram/status',
    '/auth/telegram/code',
    '/auth/telegram/complete',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/verify-email',
    '/auth/provinces',
  };

  Dio _build() {
    final d = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (httpClientAdapter != null) d.httpClientAdapter = httpClientAdapter!;

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // `/auth/me` is protected even though it lives below `/auth`.
          if (!_publicAuthPaths.contains(options.path)) {
            final token = await getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final request = e.requestOptions;
          final isPublic = _publicAuthPaths.contains(request.path);
          final wasRetried = request.extra['riksaAuthRetried'] == true;
          if (e.response?.statusCode != 401 || isPublic || wasRetried) {
            return handler.next(e);
          }

          final refreshOutcome = await _refreshSingleFlight();
          if (refreshOutcome == RefreshOutcome.unavailable) {
            return handler.next(e);
          }
          if (refreshOutcome == RefreshOutcome.rejected) {
            await _clearSession();
            _sessionExpiredController.add(null);
            return handler.next(e);
          }
          try {
            handler.resolve(await _retry(request));
          } on DioException catch (retryError) {
            if (retryError.response?.statusCode == 401) {
              await _clearSession();
              _sessionExpiredController.add(null);
            }
            handler.next(retryError);
          }
        },
      ),
    );

    if (kDebugMode) {
      // Never print auth bodies or headers: they contain passwords and tokens.
      d.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
        ),
      );
    }

    return d;
  }

  Future<RefreshOutcome>? _refreshOperation;

  Future<RefreshOutcome> _refreshSingleFlight() {
    final active = _refreshOperation;
    if (active != null) return active;

    late final Future<RefreshOutcome> operation;
    operation = _performRefresh().whenComplete(() {
      if (identical(_refreshOperation, operation)) {
        _refreshOperation = null;
      }
    });
    _refreshOperation = operation;
    return operation;
  }

  Future<RefreshOutcome> _performRefresh() async {
    final String? refreshToken;
    try {
      refreshToken = await getRefreshToken();
    } catch (_) {
      return RefreshOutcome.unavailable;
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      return RefreshOutcome.rejected;
    }

    // Use a bare dio for refresh so we don't recurse into the interceptor.
    final raw = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (httpClientAdapter != null) raw.httpClientAdapter = httpClientAdapter!;

    late final Response<dynamic> response;
    try {
      response = await raw.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (error) {
      if (const {400, 401, 403}.contains(error.response?.statusCode)) {
        return RefreshOutcome.rejected;
      }
      return RefreshOutcome.unavailable;
    } catch (_) {
      return RefreshOutcome.unavailable;
    }

    // A body that is not JSON (a captive portal or proxy error page) says
    // nothing about the refresh token, so it must not end the session.
    late final Map<String, dynamic> data;
    try {
      data = jsonMap(response);
    } on DioException {
      return RefreshOutcome.unavailable;
    }
    if (!_hasValidTokenPair(data)) return RefreshOutcome.rejected;

    try {
      await _persistSession(data);
      return RefreshOutcome.refreshed;
    } catch (_) {
      return RefreshOutcome.unavailable;
    }
  }

  Future<Response> _retry(RequestOptions opts) async {
    final token = await _sessionStore.readAccessToken();
    opts.headers['Authorization'] = 'Bearer $token';
    opts.extra['riksaAuthRetried'] = true;
    final raw = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (httpClientAdapter != null) raw.httpClientAdapter = httpClientAdapter!;
    return raw.fetch(opts);
  }

  Future<void> persistSession(Map<String, dynamic> authResponse) =>
      _persistSession(authResponse);

  Future<void> _persistSession(Map<String, dynamic> data) async {
    if (!_hasValidTokenPair(data)) {
      throw const FormatException('Auth response did not contain both tokens');
    }
    await _sessionStore.writeTokens(
      SessionTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      ),
    );
  }

  bool _hasValidTokenPair(Map<String, dynamic> data) {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    return access is String &&
        access.isNotEmpty &&
        refresh is String &&
        refresh.isNotEmpty;
  }

  Future<void> clearSession() => _clearSession();
  Future<void> _clearSession() => _sessionStore.clear();

  Future<String?> getAccessToken() => _sessionStore.readAccessToken();
  Future<String?> getRefreshToken() => _sessionStore.readRefreshToken();

  Future<bool> hasSession() async => await _sessionStore.readTokens() != null;

  void dispose() {
    dio.close(force: true);
    _sessionExpiredController.close();
  }
}
