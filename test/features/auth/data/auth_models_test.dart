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

    test('Telegram signup completion payload', () {
      expect(
        const TelegramCompleteRequest(
          signupToken: 'signup-1',
          username: 'sophea',
          displayName: 'Sok Sophea',
        ).toJson(),
        {
          'signupToken': 'signup-1',
          'username': 'sophea',
          'displayName': 'Sok Sophea',
        },
      );
    });
  });

  group('Telegram authorization responses', () {
    test('challenge parses and clamps server timings', () {
      final challenge = TelegramAuthChallenge.fromJson({
        'requestToken': 'secret-token',
        'botUrl':
            'https://t.me/riksa_bot?start=login_841f6cb4701d56f61cd1b2fea1f133f8',
        'botAppUrl':
            'tg://resolve?domain=riksa_bot&start=login_841f6cb4701d56f61cd1b2fea1f133f8',
        'expiresInSeconds': 5,
        'pollIntervalSeconds': 60,
      });
      expect(
        challenge.botUrl.queryParameters['start'],
        'login_841f6cb4701d56f61cd1b2fea1f133f8',
      );
      expect(challenge.botAppUrl!.scheme, 'tg');
      expect(challenge.expiresIn, const Duration(seconds: 30));
      expect(challenge.pollInterval, const Duration(seconds: 10));
    });

    test('challenge without a usable link is rejected', () {
      expect(
        () => TelegramAuthChallenge.fromJson({
          'requestToken': 'secret-token',
          'botUrl': '',
        }),
        throwsFormatException,
      );
    });

    test('bot info exposes the handle for the code screen', () {
      final info = TelegramBotInfo.fromJson({
        'available': true,
        'botUsername': 'riksa_bot',
        'botUrl': 'https://t.me/riksa_bot?start=code',
        'codeLength': 8,
      });
      expect(info.handle, '@riksa_bot');
      expect(info.botAppUrl, isNull);
      expect(TelegramBotInfo.fromJson({'available': false}).handle, isNull);
    });

    test('poll result parses each status', () {
      expect(
        TelegramAuthPoll.fromJson({'status': 'PENDING'}).status,
        TelegramAuthStatus.pending,
      );
      final signedIn = TelegramAuthPoll.fromJson({
        'status': 'AUTHENTICATED',
        'auth': {
          'userId': 'user-1',
          'accessToken': 'a',
          'refreshToken': 'r',
          'username': 'sophea',
          'role': 'USER',
        },
      });
      expect(signedIn.auth!.accessToken, 'a');
      final newUser = TelegramAuthPoll.fromJson({
        'status': 'PROFILE_REQUIRED',
        'signupToken': 'signup-1',
        'telegram': {'displayName': ' Sok Sophea ', 'username': 'sophea'},
      });
      expect(newUser.profile!.displayName, 'Sok Sophea');
      expect(
        TelegramAuthPoll.fromJson({'status': 'DENIED'}).status,
        TelegramAuthStatus.denied,
      );
    });

    test('incomplete or unknown poll results are rejected', () {
      expect(
        () => TelegramAuthPoll.fromJson({'status': 'AUTHENTICATED'}),
        throwsFormatException,
      );
      expect(
        () => TelegramAuthPoll.fromJson({'status': 'PROFILE_REQUIRED'}),
        throwsFormatException,
      );
      expect(
        () => TelegramAuthPoll.fromJson({'status': 'SOMETHING'}),
        throwsFormatException,
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
