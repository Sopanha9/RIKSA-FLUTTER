import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/storage/session_store.dart';
import '../data/auth_api.dart';
import '../data/google_auth_client.dart';
import '../data/auth_models.dart';

final googleAuthClientProvider = Provider<GoogleAuthClient>((ref) {
  return GoogleAuthClient.instance;
});

/// Provides the platform-backed encrypted token store.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore(ref.watch(secureStorageProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  final client = DioClient(ref.watch(sessionStoreProvider));
  ref.onDispose(client.dispose);
  return client;
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioClientProvider));
});

final provinceOptionsProvider = FutureProvider<List<ProvinceOption>>((ref) {
  return ref.watch(authApiProvider).listProvinces();
});

@immutable
sealed class AuthState {
  const AuthState();
}

/// The app is checking secure storage and, when needed, validating `/auth/me`.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A user-triggered login or registration request is in flight.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AuthUser user;
  String get userId => user.id;
  String get username => user.username;
  String get role => user.role;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// A form request failed. The user stays on the current auth screen.
class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

/// A saved session exists, but it could not be checked because the service or
/// connection is temporarily unavailable. Tokens are deliberately retained.
class AuthUnavailable extends AuthState {
  const AuthUnavailable(this.message);

  final String message;
}

class AuthNotifier extends Notifier<AuthState> {
  static const _minimumAuthenticationLoading = Duration(milliseconds: 1200);

  StreamSubscription<void>? _sessionExpiredSubscription;
  StreamSubscription<GoogleAuthEvent>? _googleAuthSubscription;
  Future<void>? _bootstrapOperation;

  @override
  AuthState build() {
    final client = ref.read(dioClientProvider);
    _sessionExpiredSubscription = client.sessionExpired.listen((_) {
      state = const Unauthenticated();
    });
    _googleAuthSubscription = ref.read(googleAuthClientProvider).events.listen((
      event,
    ) {
      if (event is GoogleAuthToken) {
        unawaited(googleSignIn(idToken: event.idToken));
      }
    });
    ref.onDispose(() {
      _sessionExpiredSubscription?.cancel();
      _googleAuthSubscription?.cancel();
    });
    unawaited(bootstrap());
    return const AuthInitial();
  }

  Future<void> bootstrap({bool force = false}) {
    if (!force && _bootstrapOperation != null) return _bootstrapOperation!;

    late final Future<void> operation;
    operation = _performBootstrap().whenComplete(() {
      if (identical(_bootstrapOperation, operation)) {
        _bootstrapOperation = null;
      }
    });
    _bootstrapOperation = operation;
    return operation;
  }

  Future<void> _performBootstrap() async {
    state = const AuthInitial();
    final client = ref.read(dioClientProvider);
    if (!await client.hasSession()) {
      // Remove a half-written session if only one token survived.
      await client.clearSession();
      state = const Unauthenticated();
      return;
    }

    try {
      final user = await _hydrateProfile();
      _requireProfile(user);
      state = Authenticated(user);
    } on AuthFailure catch (failure) {
      if (failure.kind == AuthFailureKind.network ||
          failure.kind == AuthFailureKind.rateLimited ||
          failure.kind == AuthFailureKind.server) {
        state = AuthUnavailable(failure.message);
      } else {
        await client.clearSession();
        state = const Unauthenticated();
      }
    } on FormatException {
      await client.clearSession();
      state = const Unauthenticated();
    } catch (error) {
      if (kDebugMode) debugPrint('Auth bootstrap failed: $error');
      state = const AuthUnavailable(
        'We could not check your saved session. Please try again.',
      );
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    final minimumLoading = Future<void>.delayed(_minimumAuthenticationLoading);
    try {
      final response = await ref
          .read(authApiProvider)
          .login(LoginRequest(username: username, password: password));
      await _completeAuthentication(response, minimumLoading: minimumLoading);
    } catch (error) {
      await _handleAuthenticationFailure(error);
    }
  }

  Future<void> register(RegisterRequest request) async {
    state = const AuthLoading();
    final minimumLoading = Future<void>.delayed(_minimumAuthenticationLoading);
    try {
      final response = await ref.read(authApiProvider).register(request);
      await _completeAuthentication(response, minimumLoading: minimumLoading);
    } catch (error) {
      await _handleAuthenticationFailure(error);
    }
  }

  Future<void> googleSignIn({required String idToken}) async {
    state = const AuthLoading();
    try {
      final response = await ref
          .read(authApiProvider)
          .googleAuth(GoogleAuthRequest(idToken: idToken));
      await _completeAuthentication(response);
    } catch (error) {
      await _handleAuthenticationFailure(error);
    }
  }

  Future<void> telegramSignIn(TelegramAuthRequest request) async {
    state = const AuthLoading();
    try {
      final response = await ref.read(authApiProvider).telegramAuth(request);
      await _completeAuthentication(response);
    } catch (error) {
      await _handleAuthenticationFailure(error);
    }
  }

  Future<void> _completeAuthentication(
    AuthResponse response, {
    Future<void>? minimumLoading,
  }) async {
    final client = ref.read(dioClientProvider);
    try {
      await client.persistSession(response.toJson());
      final user = await _hydrateProfile();
      _requireProfile(user);
      await minimumLoading;
      state = Authenticated(user);
    } on AuthFailure catch (failure) {
      if (failure.kind == AuthFailureKind.network ||
          failure.kind == AuthFailureKind.rateLimited ||
          failure.kind == AuthFailureKind.server) {
        // Keep the freshly issued token pair. Splash can retry profile
        // hydration without forcing the user to submit credentials again.
        state = AuthUnavailable(failure.message);
        return;
      }
      await client.clearSession();
      rethrow;
    } catch (error) {
      // An issued session that cannot hydrate a valid profile must not leave the
      // app in an ambiguous partially signed-in state.
      await client.clearSession();
      rethrow;
    }
  }

  void _requireProfile(AuthUser user) {
    if (user.id.isEmpty || user.username.isEmpty) {
      throw const FormatException('The server returned an incomplete profile.');
    }
  }

  Future<AuthUser> _hydrateProfile() async {
    final api = ref.read(authApiProvider);
    var user = await api.getProfile();
    final pendingProvinceId = ref.read(localeProvider).pendingProvinceId;
    if (pendingProvinceId != null && pendingProvinceId.isNotEmpty) {
      user = await api.updateProvince(pendingProvinceId);
      await ref.read(localeProvider.notifier).completeOnboarding();
    }
    return user;
  }

  Future<bool> saveProvinceSelection(String provinceId) async {
    final current = state;
    await ref.read(localeProvider.notifier).savePendingProvince(provinceId);
    if (current is! Authenticated) return true;

    state = const AuthLoading();
    try {
      final user = await ref.read(authApiProvider).updateProvince(provinceId);
      _requireProfile(user);
      await ref.read(localeProvider.notifier).completeOnboarding();
      state = Authenticated(user);
      return true;
    } catch (error) {
      state = current;
      return false;
    }
  }

  Future<bool> updateProfile(UpdateProfileRequest request) async {
    final current = state;
    if (current is! Authenticated) return false;
    try {
      final user = await ref.read(authApiProvider).updateProfile(request);
      _requireProfile(user);
      state = Authenticated(user);
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Profile update failed: $error');
      return false;
    }
  }

  Future<void> _handleAuthenticationFailure(Object error) async {
    if (error is AuthFailure) {
      state = AuthError(error.message);
      return;
    }
    if (kDebugMode) debugPrint('Auth request failed: $error');
    state = const AuthError('Something went wrong. Please try again.');
  }

  Future<void> logout() async {
    final client = ref.read(dioClientProvider);
    final refreshToken = await client.getRefreshToken();
    await client.clearSession();
    state = const Unauthenticated();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ref.read(authApiProvider).logout(refreshToken);
      }
    } catch (_) {
      // Server revocation is best-effort. Local logout must always finish.
    }
  }

  void clearError() {
    if (state is AuthError) state = const Unauthenticated();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
