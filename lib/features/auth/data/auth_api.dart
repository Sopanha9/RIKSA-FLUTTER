import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'auth_models.dart';

/// Wraps the `/api/v1/auth` endpoints.
class AuthApi {
  AuthApi(this._client);

  final DioClient _client;

  Future<AuthResponse> login(LoginRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/login', data: req.toJson());
      return AuthResponse.fromJson(_json(res.data));
    });
  }

  Future<AuthResponse> register(RegisterRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/register', data: req.toJson());
      return AuthResponse.fromJson(_json(res.data));
    });
  }

  Future<AuthResponse> googleAuth(GoogleAuthRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/google', data: req.toJson());
      return AuthResponse.fromJson(_json(res.data));
    });
  }

  Future<OtpResult> sendOtp(OtpSendRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/otp/send', data: req.toJson());
      return OtpResult.fromJson(_json(res.data), successOverride: true);
    });
  }

  Future<OtpResult> verifyOtp(OtpVerifyRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post(
        '/auth/otp/verify',
        data: req.toJson(),
      );
      return OtpResult.fromJson(_json(res.data));
    });
  }

  Future<void> logout(String refreshToken) async {
    await _guard(
      () => _client.dio.post<void>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      ),
    );
  }

  /// Fetch current user profile. Requires bearer token.
  Future<AuthUser> getProfile() async {
    return _guard(() async {
      final res = await _client.dio.get('/auth/me');
      return AuthUser.fromJson(_json(res.data));
    });
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AuthFailure.fromDio(error);
    } on FormatException catch (error) {
      throw AuthFailure(
        'The server returned an invalid response.',
        kind: AuthFailureKind.server,
        cause: error,
      );
    } on TypeError catch (error) {
      throw AuthFailure(
        'The server returned an invalid response.',
        kind: AuthFailureKind.server,
        cause: error,
      );
    }
  }

  Map<String, dynamic> _json(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object');
  }
}

/// Typed auth failure.
enum AuthFailureKind {
  validation,
  unauthorized,
  forbidden,
  rateLimited,
  network,
  server,
}

class AuthFailure implements Exception {
  AuthFailure(
    this.message, {
    this.statusCode,
    this.kind = AuthFailureKind.server,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final AuthFailureKind kind;
  final Object? cause;

  factory AuthFailure.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final message = dioErrorMessage(error);
    final kind = switch (status) {
      400 || 409 || 422 => AuthFailureKind.validation,
      401 => AuthFailureKind.unauthorized,
      403 => AuthFailureKind.forbidden,
      429 => AuthFailureKind.rateLimited,
      int code when code >= 500 => AuthFailureKind.server,
      _
          when error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError =>
        AuthFailureKind.network,
      _ => AuthFailureKind.server,
    };
    return AuthFailure(message, statusCode: status, kind: kind, cause: error);
  }

  @override
  String toString() => 'AuthFailure($statusCode): $message';
}

/// Extract a human-readable message from a DioException.
String dioErrorMessage(DioException e) {
  final body = e.response?.data;
  if (body is Map) {
    final msg = body['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    return 'Can\'t reach Riksa right now. Check your connection and try again.';
  }
  return switch (e.response?.statusCode) {
    401 => 'Your session is no longer valid. Please sign in again.',
    403 => 'This account cannot sign in right now.',
    429 => 'Too many attempts. Please wait a minute and try again.',
    int code when code >= 500 =>
      'Riksa is having trouble right now. Please try again shortly.',
    _ => 'Something went wrong. Please try again.',
  };
}
