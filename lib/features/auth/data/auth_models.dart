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
    this.shareMilestones = true,
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
  final bool shareMilestones;

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
      shareMilestones: json['shareMilestones'] as bool? ?? true,
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
    this.shareMilestones,
  });

  final String? displayName;
  final String? bio;
  final String? gender;
  final String? provinceId;
  final String? avatarUrl;
  final bool? shareMilestones;

  Map<String, dynamic> toJson() => {
    if (displayName != null) 'displayName': displayName,
    if (bio != null) 'bio': bio,
    if (gender != null) 'gender': gender,
    if (provinceId != null) 'provinceId': provinceId,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (shareMilestones != null) 'shareMilestones': shareMilestones,
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

Uri? _telegramUri(Object? value) {
  final uri = Uri.tryParse(value as String? ?? '');
  return uri != null && uri.hasScheme ? uri : null;
}

/// A pending one-tap "Open Telegram" request.
///
/// The app opens [botAppUrl] (falling back to [botUrl]), a one-time
/// `t.me/<bot>?start=login_<nonce>` link, then polls with [requestToken] until
/// the user taps Confirm in the bot. [requestToken] is a secret: it never
/// appears in the link and only travels in request bodies.
class TelegramAuthChallenge {
  const TelegramAuthChallenge({
    required this.requestToken,
    required this.botUrl,
    this.botAppUrl,
    required this.expiresIn,
    required this.pollInterval,
  });

  final String requestToken;
  final Uri botUrl;
  final Uri? botAppUrl;
  final Duration expiresIn;
  final Duration pollInterval;

  factory TelegramAuthChallenge.fromJson(Map<String, dynamic> json) {
    final requestToken = json['requestToken'] as String? ?? '';
    final botUrl = _telegramUri(json['botUrl']);
    if (requestToken.isEmpty || botUrl == null) {
      throw const FormatException('Incomplete Telegram authorization request');
    }
    final expiresIn = (json['expiresInSeconds'] as num?)?.toInt() ?? 600;
    final interval = (json['pollIntervalSeconds'] as num?)?.toInt() ?? 3;
    return TelegramAuthChallenge(
      requestToken: requestToken,
      botUrl: botUrl,
      botAppUrl: _telegramUri(json['botAppUrl']),
      expiresIn: Duration(seconds: expiresIn.clamp(30, 900)),
      pollInterval: Duration(seconds: interval.clamp(1, 10)),
    );
  }
}

/// Public bot details for the "Log in with code" screen.
class TelegramBotInfo {
  const TelegramBotInfo({
    required this.available,
    this.botUsername,
    this.botUrl,
    this.botAppUrl,
    this.codeLength = 8,
  });

  final bool available;
  final String? botUsername;
  final Uri? botUrl;
  final Uri? botAppUrl;
  final int codeLength;

  /// `@riksa_bot`, or null when the server did not provide one.
  String? get handle =>
      botUsername == null || botUsername!.isEmpty ? null : '@$botUsername';

  factory TelegramBotInfo.fromJson(Map<String, dynamic> json) =>
      TelegramBotInfo(
        available: json['available'] as bool? ?? false,
        botUsername: json['botUsername'] as String?,
        botUrl: _telegramUri(json['botUrl']),
        botAppUrl: _telegramUri(json['botAppUrl']),
        codeLength: ((json['codeLength'] as num?)?.toInt() ?? 8).clamp(4, 16),
      );
}

/// Public Telegram profile fields the bot saw when the user confirmed.
class TelegramProfile {
  const TelegramProfile({this.displayName, this.username});

  final String? displayName;
  final String? username;

  factory TelegramProfile.fromJson(Map<String, dynamic> json) =>
      TelegramProfile(
        displayName: (json['displayName'] as String?)?.trim(),
        username: json['username'] as String?,
      );
}

enum TelegramAuthStatus {
  pending,
  authenticated,
  profileRequired,
  expired,
  denied,
}

/// Result of polling a [TelegramAuthChallenge] or redeeming a bot code.
///
/// - [TelegramAuthStatus.authenticated]: existing account, [auth] is set.
/// - [TelegramAuthStatus.profileRequired]: new account, [signupToken] and
///   [profile] are set; finish with [TelegramCompleteRequest].
class TelegramAuthPoll {
  const TelegramAuthPoll({
    required this.status,
    this.auth,
    this.signupToken,
    this.profile,
  });

  final TelegramAuthStatus status;
  final AuthResponse? auth;
  final String? signupToken;
  final TelegramProfile? profile;

  factory TelegramAuthPoll.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'AUTHENTICATED' => TelegramAuthStatus.authenticated,
      'PROFILE_REQUIRED' => TelegramAuthStatus.profileRequired,
      'EXPIRED' => TelegramAuthStatus.expired,
      'DENIED' => TelegramAuthStatus.denied,
      'PENDING' => TelegramAuthStatus.pending,
      _ => throw const FormatException('Unknown Telegram authorization status'),
    };
    final auth = json['auth'];
    final profile = json['telegram'];
    final poll = TelegramAuthPoll(
      status: status,
      auth: auth is Map
          ? AuthResponse.fromJson(Map<String, dynamic>.from(auth))
          : null,
      signupToken: json['signupToken'] as String?,
      profile: profile is Map
          ? TelegramProfile.fromJson(Map<String, dynamic>.from(profile))
          : null,
    );
    if (status == TelegramAuthStatus.authenticated && poll.auth == null ||
        status == TelegramAuthStatus.profileRequired &&
            (poll.signupToken?.isEmpty ?? true)) {
      throw const FormatException('Incomplete Telegram authorization result');
    }
    return poll;
  }
}

/// Creates the Riksa account for a Telegram user who confirmed in the bot but
/// has no account yet.
class TelegramCompleteRequest {
  const TelegramCompleteRequest({
    required this.signupToken,
    required this.username,
    required this.displayName,
  });

  final String signupToken;
  final String username;
  final String displayName;

  Map<String, dynamic> toJson() => {
    'signupToken': signupToken,
    'username': username,
    'displayName': displayName,
  };
}
