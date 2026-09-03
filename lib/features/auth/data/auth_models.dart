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
    this.provinceId,
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
  final String? provinceId;
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
      provinceId: json['provinceId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.displayName,
    this.bio,
    this.gender,
    this.provinceId,
    this.avatarUrl,
  });

  final String? displayName;
  final String? bio;
  final String? gender;
  final String? provinceId;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
    if (displayName != null) 'displayName': displayName,
    if (bio != null) 'bio': bio,
    if (gender != null) 'gender': gender,
    if (provinceId != null) 'provinceId': provinceId,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };
}

class ProvinceOption {
  const ProvinceOption({
    required this.id,
    required this.nameKhmer,
    required this.nameLatin,
  });

  final String id;
  final String nameKhmer;
  final String nameLatin;

  factory ProvinceOption.fromJson(Map<String, dynamic> json) => ProvinceOption(
    id: json['id']?.toString() ?? '',
    nameKhmer: json['nameKhmer'] as String? ?? '',
    nameLatin: json['nameLatin'] as String? ?? '',
  );
}

const List<ProvinceOption> defaultProvinces = [
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000011',
    nameKhmer: 'ភ្នំពេញ',
    nameLatin: 'Phnom Penh',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000012',
    nameKhmer: 'សៀមរាប',
    nameLatin: 'Siem Reap',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000013',
    nameKhmer: 'បាត់ដំបង',
    nameLatin: 'Battambang',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000014',
    nameKhmer: 'កណ្តាល',
    nameLatin: 'Kandal',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000015',
    nameKhmer: 'កំពង់ចាម',
    nameLatin: 'Kampong Cham',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000016',
    nameKhmer: 'ព្រះសីហនុ',
    nameLatin: 'Preah Sihanouk',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000017',
    nameKhmer: 'កំពត',
    nameLatin: 'Kampot',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000018',
    nameKhmer: 'កំពង់ស្ពឺ',
    nameLatin: 'Kampong Speu',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000019',
    nameKhmer: 'តាកែវ',
    nameLatin: 'Takeo',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000020',
    nameKhmer: 'ព្រៃវែង',
    nameLatin: 'Prey Veng',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000021',
    nameKhmer: 'ស្វាយរៀង',
    nameLatin: 'Svay Rieng',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000022',
    nameKhmer: 'កំពង់ឆ្នាំង',
    nameLatin: 'Kampong Chhnang',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000023',
    nameKhmer: 'កំពង់ធំ',
    nameLatin: 'Kampong Thom',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000024',
    nameKhmer: 'ក្រចេះ',
    nameLatin: 'Kratie',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000025',
    nameKhmer: 'ស្ទឹងត្រែង',
    nameLatin: 'Stung Treng',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000026',
    nameKhmer: 'រតនគិរី',
    nameLatin: 'Ratanakiri',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000027',
    nameKhmer: 'មណ្ឌលគិរី',
    nameLatin: 'Mondulkiri',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000028',
    nameKhmer: 'ព្រះវិហារ',
    nameLatin: 'Preah Vihear',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000029',
    nameKhmer: 'ឧត្តរមានជ័យ',
    nameLatin: 'Oddar Meanchey',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000030',
    nameKhmer: 'បន្ទាយមានជ័យ',
    nameLatin: 'Banteay Meanchey',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000031',
    nameKhmer: 'ប៉ៃលិន',
    nameLatin: 'Pailin',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000032',
    nameKhmer: 'ពោធិ៍សាត់',
    nameLatin: 'Pursat',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000033',
    nameKhmer: 'កោះកុង',
    nameLatin: 'Koh Kong',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000034',
    nameKhmer: 'ត្បូងឃ្មុំ',
    nameLatin: 'Tboung Khmum',
  ),
  ProvinceOption(
    id: '00000000-0000-0000-0000-000000000035',
    nameKhmer: 'កែប',
    nameLatin: 'Kep',
  ),
];

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

/// Exchanges a Telegram-delivered one-time code for a Riksa session.
///
/// Registration details are supplied only from the Telegram registration
/// route. Returning users need only their Telegram chat ID and OTP.
class TelegramAuthRequest {
  TelegramAuthRequest({
    required this.identifier,
    required this.code,
    this.username,
    this.displayName,
  });

  final String identifier;
  final String code;
  final String? username;
  final String? displayName;

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'code': code,
    if (username != null) 'username': username,
    if (displayName != null) 'displayName': displayName,
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
