import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'auth_models.dart';

/// Wraps the `/api/v1/auth` endpoints.
class AuthApi {
  AuthApi(this._client);

  final DioClient _client;

  Future<AuthResponse> login(LoginRequest req) async {
    final res = await _client.dio.post('/auth/login', data: req.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register(RegisterRequest req) async {
    final res = await _client.dio.post('/auth/register', data: req.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthResponse> googleAuth(GoogleAuthRequest req) async {
    final res = await _client.dio.post('/auth/google', data: req.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OtpResult> sendOtp(OtpSendRequest req) async {
    final res = await _client.dio.post('/auth/otp/send', data: req.toJson());
    return OtpResult.fromJson(res.data as Map<String, dynamic>, successOverride: true);
  }

  Future<OtpResult> verifyOtp(OtpVerifyRequest req) async {
    final res = await _client.dio.post('/auth/otp/verify', data: req.toJson());
    return OtpResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _client.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
  }

  /// Fetch current user profile. Requires bearer token.
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _client.dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }
}

/// Typed auth failure.
class AuthFailure implements Exception {
  AuthFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthFailure($statusCode): $message';
}

/// Extract a human-readable message from a DioException.
String dioErrorMessage(DioException e) {
  if (e.response?.data case Map<String, dynamic> data) {
    final msg = data['message'] as String?;
    if (msg != null && msg.isNotEmpty) return msg;
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    return 'Network error. Please check your connection.';
  }
  return e.message ?? 'Unexpected error';
}