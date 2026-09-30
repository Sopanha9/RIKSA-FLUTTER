import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/providers/locale_provider.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/auth/data/auth_api.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InitialAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthInitial();
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    AuthUser(
      id: 'user-1',
      username: 'sophea',
      displayName: 'Sophea',
      emailVerified: true,
      phoneVerified: false,
      role: 'USER',
    ),
  );
}

class _UnreadableSessionClient extends DioClient {
  _UnreadableSessionClient()
    : super(SessionStore(const FlutterSecureStorage()));

  @override
  Future<bool> hasSession() async => throw StateError('storage unavailable');
}

class _FailingProvinceApi extends AuthApi {
  _FailingProvinceApi(super.client);

  @override
  Future<AuthUser> updateProvince(String provinceId) async =>
      throw StateError('network unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'storage read failure leaves bootstrap in a recoverable state',
    () async {
      final client = _UnreadableSessionClient();
      final container = ProviderContainer(
        overrides: [
          dioClientProvider.overrideWithValue(client),
          authProvider.overrideWith(_InitialAuthNotifier.new),
        ],
      );
      addTearDown(() {
        container.dispose();
        client.dispose();
      });

      await container.read(authProvider.notifier).bootstrap();
      expect(container.read(authProvider), isA<AuthUnavailable>());
    },
  );

  test('failed province update retains the pending province', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_SignedInAuthNotifier.new),
        authApiProvider.overrideWith(
          (ref) => _FailingProvinceApi(ref.read(dioClientProvider)),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeProvider);
    await Future<void>.delayed(Duration.zero);

    final saved = await container
        .read(authProvider.notifier)
        .saveProvinceSelection('province-1');

    expect(saved, isFalse);
    expect(container.read(authProvider), isA<Authenticated>());
    expect(container.read(localeProvider).pendingProvinceId, 'province-1');
    expect(container.read(localeProvider).hasCompletedOnboarding, isFalse);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('riksa_pending_province_id'), 'province-1');
  });
}
