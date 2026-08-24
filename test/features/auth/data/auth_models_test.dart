import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';

void main() {
  group('auth request contracts', () {
    test('registration omits absent optional values', () {
      final json = RegisterRequest(
        username: 'sophea',
        displayName: 'Sok Sophea',
        email: 'sophea@example.com',
        password: 'StrongPass1',
      ).toJson();

      expect(json, {
        'username': 'sophea',
        'displayName': 'Sok Sophea',
        'email': 'sophea@example.com',
        'password': 'StrongPass1',
      });
      expect(json, isNot(contains('provinceId')));
    });

    test('OTP payload matches backend and contains no channel field', () {
      expect(OtpSendRequest(identifier: '1081239995').toJson(), {
        'identifier': '1081239995',
      });
      expect(
        OtpVerifyRequest(identifier: '1081239995', code: '931293').toJson(),
        {'identifier': '1081239995', 'code': '931293'},
      );
    });

    test('Telegram login and registration payloads match backend', () {
      expect(
        TelegramAuthRequest(identifier: '1081239995', code: '931293').toJson(),
        {'identifier': '1081239995', 'code': '931293'},
      );
      expect(
        TelegramAuthRequest(
          identifier: '1081239995',
          code: '931293',
          username: 'sophea',
          displayName: 'Sok Sophea',
        ).toJson(),
        {
          'identifier': '1081239995',
          'code': '931293',
          'username': 'sophea',
          'displayName': 'Sok Sophea',
        },
      );
    });
  });

  test('AuthUser parses the current /auth/me response', () {
    final user = AuthUser.fromJson({
      'id': '93f4b90a-fb38-4c4e-b8b8-f490aa686cdd',
      'username': 'sophea',
      'displayName': 'Sok Sophea',
      'email': 'sophea@example.com',
      'emailVerified': false,
      'avatarUrl': '/avatars/avatar-17.png',
      'bio': null,
      'gender': null,
      'phoneNumber': null,
      'phoneVerified': true,
      'role': 'USER',
      'countryId': 'KH',
      'provinceId': '00000000-0000-0000-0000-000000000015',
      'createdAt': '2026-08-16T10:00:00+07:00',
    });

    expect(user.username, 'sophea');
    expect(user.phoneVerified, isTrue);
    expect(user.provinceId, '00000000-0000-0000-0000-000000000015');
    expect(user.createdAt, DateTime.utc(2026, 8, 16, 3));
  });

  test('ProvinceOption parses Khmer and Latin province names', () {
    final province = ProvinceOption.fromJson({
      'id': '00000000-0000-0000-0000-000000000015',
      'nameKhmer': 'ភ្នំពេញ',
      'nameLatin': 'Phnom Penh',
    });

    expect(province.id, '00000000-0000-0000-0000-000000000015');
    expect(province.nameKhmer, 'ភ្នំពេញ');
    expect(province.nameLatin, 'Phnom Penh');
  });
}
