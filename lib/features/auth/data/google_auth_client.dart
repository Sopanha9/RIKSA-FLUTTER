import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Runtime OAuth client IDs supplied through `--dart-define`.
///
/// The server and Android both use the Web OAuth client ID as the token
/// audience. iOS additionally needs its platform-specific OAuth client ID.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static String get effectiveWebClientId =>
      webClientId.isNotEmpty ? webClientId : serverClientId;

  static bool get isConfigured {
    if (kIsWeb) return effectiveWebClientId.isNotEmpty;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => serverClientId.isNotEmpty,
      TargetPlatform.iOS => serverClientId.isNotEmpty && iosClientId.isNotEmpty,
      _ => false,
    };
  }
}

sealed class GoogleAuthEvent {
  const GoogleAuthEvent();
}

class GoogleAuthToken extends GoogleAuthEvent {
  const GoogleAuthToken(this.idToken);

  final String idToken;
}

class GoogleAuthProblem extends GoogleAuthEvent {
  const GoogleAuthProblem(this.kind);

  final GoogleAuthProblemKind kind;
}

enum GoogleAuthProblemKind { notConfigured, unsupported, failed }

class GoogleAuthClientException implements Exception {
  const GoogleAuthClientException(this.kind);

  final GoogleAuthProblemKind kind;
}

/// Small adapter around google_sign_in 7.x.
///
/// It emits only ID tokens (never provider access tokens) for immediate
/// exchange with the Riksa backend.
class GoogleAuthClient {
  GoogleAuthClient._();

  static final instance = GoogleAuthClient._();

  final _events = StreamController<GoogleAuthEvent>.broadcast();
  Future<void>? _initialization;

  Stream<GoogleAuthEvent> get events => _events.stream;
  bool get isConfigured => GoogleAuthConfig.isConfigured;
  bool get usesProviderButton => kIsWeb;

  Future<void> prepare() {
    if (!isConfigured) {
      return Future<void>.error(
        const GoogleAuthClientException(GoogleAuthProblemKind.notConfigured),
      );
    }
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      clientId: kIsWeb
          ? GoogleAuthConfig.effectiveWebClientId
          : defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleAuthConfig.iosClientId
          : null,
      serverClientId: GoogleAuthConfig.serverClientId,
    );
    signIn.authenticationEvents.listen(
      (event) {
        if (event is! GoogleSignInAuthenticationEventSignIn) return;
        final idToken = event.user.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          _events.add(const GoogleAuthProblem(GoogleAuthProblemKind.failed));
          return;
        }
        _events.add(GoogleAuthToken(idToken));
      },
      onError: (Object error) {
        if (error is GoogleSignInException &&
            (error.code == GoogleSignInExceptionCode.canceled ||
                error.code == GoogleSignInExceptionCode.interrupted)) {
          return;
        }
        _events.add(const GoogleAuthProblem(GoogleAuthProblemKind.failed));
      },
    );
  }

  Future<void> authenticate() async {
    await prepare();
    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw const GoogleAuthClientException(GoogleAuthProblemKind.unsupported);
    }
    try {
      await signIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      throw const GoogleAuthClientException(GoogleAuthProblemKind.failed);
    }
  }
}
