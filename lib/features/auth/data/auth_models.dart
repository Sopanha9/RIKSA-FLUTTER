/// Authentication data models for the Riksa API.
///
/// Plain Dart classes (no codegen) to keep things simple. The backend returns
/// `AuthResponse { userId, accessToken, refreshToken, tokenType, username, role }`.
library;

class AuthResponse {
  AuthResponse({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.username,
    required this.role,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String username;
  final String role;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    userId: json['userId']?.toString() ?? '',
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    tokenType: json['tokenType'] as String? ?? 'Bearer',
    username: json['username'] as String? ?? '',
    role: json['role'] as String? ?? 'USER',
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenType': tokenType,
    'username': username,
    'role': role,
  };
}

/// The signed-in user's profile returned by `GET /auth/me`.
///
/// Province intentionally is not represented yet because the current backend
/// response does not expose it. Province onboarding remains feature-gated until
/// that contract is added.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.emailVerified,
    required this.phoneVerified,
    required this.role,
    this.email,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.phoneNumber,
    this.countryId,
    this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String? email;
  final bool emailVerified;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String? phoneNumber;
  final bool phoneVerified;
  final String role;
  final String? countryId;
  final DateTime? createdAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      role: json['role'] as String? ?? 'USER',
      countryId: json['countryId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class LoginRequest {
  LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class RegisterRequest {
  RegisterRequest({
    required this.username,
    required this.displayName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.gender,
    this.provinceId,
  });

  final String username;
  final String displayName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? gender;
  final String? provinceId;

  Map<String, dynamic> toJson() => {
    'username': username,
    'displayName': displayName,
    'email': email,
    'password': password,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (gender != null) 'gender': gender,
    if (provinceId != null) 'provinceId': provinceId,
  };
}

class GoogleAuthRequest {
  GoogleAuthRequest({
    required this.idToken,
    this.username,
    this.displayName,
    this.provinceId,
  });

  final String idToken;
  final String? username;
  final String? displayName;
  final String? provinceId;

  Map<String, dynamic> toJson() => {
    'idToken': idToken,
    if (username != null) 'username': username,
    if (displayName != null) 'displayName': displayName,
    if (provinceId != null) 'provinceId': provinceId,
  };
}

class OtpSendRequest {
  OtpSendRequest({required this.identifier});

  final String identifier;

  Map<String, dynamic> toJson() => {'identifier': identifier};
}

class OtpVerifyRequest {
  OtpVerifyRequest({required this.identifier, required this.code});

  final String identifier;
  final String code;

  Map<String, dynamic> toJson() => {'identifier': identifier, 'code': code};
}

/// Result of an OTP send/verify call.
class OtpResult {
  OtpResult({required this.success, this.message, this.channel});

  final bool success;
  final String? message;
  final String? channel;

  factory OtpResult.fromJson(
    Map<String, dynamic> json, {
    bool? successOverride,
  }) {
    final verified = json['verified'] as bool?;
    return OtpResult(
      success: successOverride ?? verified ?? true,
      message: json['message'] as String?,
      channel: json['channel'] as String?,
    );
  }
}
