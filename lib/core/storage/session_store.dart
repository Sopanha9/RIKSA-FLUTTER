import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionTokens {
  const SessionTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// The only layer allowed to read or mutate Riksa authentication secrets.
class SessionStore {
  SessionStore(this._storage);

  static const String accessTokenKey = 'riksa_access_token';
  static const String refreshTokenKey = 'riksa_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<SessionTokens?> readTokens() async {
    final values = await Future.wait([readAccessToken(), readRefreshToken()]);
    final accessToken = values[0];
    final refreshToken = values[1];
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }
    return SessionTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> writeTokens(SessionTokens tokens) async {
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      throw const FormatException('Both authentication tokens are required');
    }
    await _storage.write(key: accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: refreshTokenKey, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: accessTokenKey),
      _storage.delete(key: refreshTokenKey),
    ]);
  }
}
