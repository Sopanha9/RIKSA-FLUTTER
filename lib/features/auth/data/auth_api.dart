import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import 'auth_models.dart';

/// Wraps the `/api/v1/auth` endpoints.
class AuthApi {
  AuthApi(this._client);

  final DioClient _client;

  Future<AuthResponse> login(LoginRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/login', data: req.toJson());
      return AuthResponse.fromJson(jsonMap(res));
    });
  }

  Future<AuthResponse> register(RegisterRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/register', data: req.toJson());
      return AuthResponse.fromJson(jsonMap(res));
    });
  }

  Future<AuthResponse> googleAuth(GoogleAuthRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/google', data: req.toJson());
      return AuthResponse.fromJson(jsonMap(res));
    });
  }

  /// Bot handle and links for the "Log in with code" option. See
  /// `docs/TELEGRAM_AUTH_FLOW.md` for the server contract.
  Future<TelegramBotInfo> telegramBotInfo() async {
    return _guard(() async {
      final res = await _client.dio.get('/auth/telegram/bot');
      return TelegramBotInfo.fromJson(jsonMap(res));
    });
  }

  /// Starts a one-tap "Open Telegram" authorization.
  Future<TelegramAuthChallenge> startTelegramAuth() async {
    return _guard(() async {
      final res = await _client.dio.post('/auth/telegram/start');
      return TelegramAuthChallenge.fromJson(jsonMap(res));
    });
  }

  Future<TelegramAuthPoll> pollTelegramAuth(
    TelegramAuthChallenge challenge,
  ) async {
    return _guard(() async {
      final res = await _client.dio.post(
        '/auth/telegram/status',
        data: {'requestToken': challenge.requestToken},
      );
      return TelegramAuthPoll.fromJson(jsonMap(res));
    });
  }

  /// Exchanges the code the bot sent after /start or /code.
  Future<TelegramAuthPoll> redeemTelegramCode(String code) async {
    return _guard(() async {
      final res = await _client.dio.post(
        '/auth/telegram/code',
        data: {'code': code},
      );
      return TelegramAuthPoll.fromJson(jsonMap(res));
    });
  }

  Future<AuthResponse> completeTelegramAuth(TelegramCompleteRequest req) async {
    return _guard(() async {
      final res = await _client.dio.post(
        '/auth/telegram/complete',
        data: req.toJson(),
      );
      return AuthResponse.fromJson(jsonMap(res));
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
      return AuthUser.fromJson(jsonMap(res));
    });
  }

  /// Public province catalog used before authentication during first run.
  Future<List<ProvinceOption>> listProvinces() async {
    try {
      return await _guard(() async {
        final res = await _client.dio.get('/auth/provinces');
        final values = res.data;
        if (values is! List) {
          throw const FormatException('Expected a province list');
        }
        final list = values
            .map(
              (value) => ProvinceOption.fromJson(
                (value as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
        if (list.isEmpty) return defaultProvinces;
        return list;
      });
    } catch (_) {
      return defaultProvinces;
    }
  }

  /// Saves a province on the authenticated user profile.
  Future<AuthUser> updateProvince(String provinceId) async {
    return _guard(() async {
      final res = await _client.dio.put(
        '/auth/me',
        data: {'provinceId': provinceId},
      );
      return AuthUser.fromJson(jsonMap(res));
    });
  }

  Future<AuthUser> updateProfile(UpdateProfileRequest request) async {
    return _guard(() async {
      final res = await _client.dio.put('/auth/me', data: request.toJson());
      return AuthUser.fromJson(jsonMap(res));
    });
  }

  Future<String> forgotPassword(String identifier) async => _guard(() async {
    final res = await _client.dio.post(
      '/auth/forgot-password',
      data: {'identifier': identifier},
    );
    return jsonMap(res)['message'] as String? ??
        'A verification code has been sent.';
  });

  Future<String> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async => _guard(() async {
    final res = await _client.dio.post(
      '/auth/reset-password',
      data: {
        'identifier': identifier,
        'code': code,
        'newPassword': newPassword,
      },
    );
    return jsonMap(res)['message'] as String? ?? 'Password reset successfully.';
  });

  Future<bool> verifyEmail(String token) async => _guard(() async {
    final res = await _client.dio.post(
      '/auth/verify-email',
      data: {'token': token},
    );
    return jsonMap(res)['verified'] as bool? ?? false;
  });

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
