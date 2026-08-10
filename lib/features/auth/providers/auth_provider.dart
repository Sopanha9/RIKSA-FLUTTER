import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart';
import '../data/auth_api.dart';
import '../data/auth_models.dart';

/// Provides a singleton [FlutterSecureStorage].
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provides the singleton [DioClient].
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(storage);
});

/// Provides the singleton [AuthApi].
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioClientProvider));
});

/// Auth state as a simple sealed union via a base class.
@immutable
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated({required this.userId, required this.username, required this.role});
  final String userId;
  final String username;
  final String role;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Restored after re-login flow (e.g. after Telegram OTP verification).
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

/// Session info loaded from secure storage on app start.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthInitial();
  }

  Future<void> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: StorageKeys.accessToken);
    final userId = await storage.read(key: StorageKeys.userId);
    final username = await storage.read(key: StorageKeys.username);
    final role = await storage.read(key: StorageKeys.role);
    if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
      state = Authenticated(
        userId: userId,
        username: username ?? '',
        role: role != null && role.isNotEmpty ? role : 'USER',
      );
    } else {
      state = const Unauthenticated();
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = const AuthLoading();
    try {
      final api = ref.read(authApiProvider);
      final res = await api.login(LoginRequest(username: username, password: password));
      await ref.read(dioClientProvider).persistSession(res.toJson());
      state = Authenticated(userId: res.userId, username: res.username, role: res.role);
    } catch (e) {
      state = AuthError(_msg(e));
    }
  }

  Future<void> register(RegisterRequest req) async {
    state = const AuthLoading();
    try {
      final api = ref.read(authApiProvider);
      final res = await api.register(req);
      await ref.read(dioClientProvider).persistSession(res.toJson());
      state = Authenticated(userId: res.userId, username: res.username, role: res.role);
    } catch (e) {
      state = AuthError(_msg(e));
    }
  }

  Future<void> googleSignIn({required String idToken}) async {
    state = const AuthLoading();
    try {
      final api = ref.read(authApiProvider);
      final res = await api.googleAuth(GoogleAuthRequest(idToken: idToken));
      await ref.read(dioClientProvider).persistSession(res.toJson());
      state = Authenticated(userId: res.userId, username: res.username, role: res.role);
    } catch (e) {
      state = AuthError(_msg(e));
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.read(key: StorageKeys.refreshToken);
    if (refreshToken != null) {
      try {
        await ref.read(authApiProvider).logout(refreshToken);
      } catch (_) {
        // Best effort; clear local session regardless.
      }
    }
    await ref.read(dioClientProvider).clearSession();
    state = const Unauthenticated();
  }

  /// After successful Telegram OTP verification, we still need a session.
  /// The backend's verify endpoint returns `{verified, message}` — not an
  /// AuthResponse. For now, users must set a password after OTP-only login
  /// (a follow-up backend endpoint). This method is a hook for that flow.
  void setAuthenticated(AuthResponse res) {
    ref.read(dioClientProvider).persistSession(res.toJson());
    state = Authenticated(userId: res.userId, username: res.username, role: res.role);
  }

  void reset() {
    state = const Unauthenticated();
  }

  String _msg(Object e) {
    if (e is AuthFailure) return e.message;
    if (kDebugMode) {
      debugPrint('Auth error: $e');
    }
    return 'Something went wrong';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);