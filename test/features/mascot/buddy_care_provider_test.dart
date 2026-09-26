import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/auth/data/auth_models.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/domain/buddy_care.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';
import 'package:riksa_app/features/mascot/providers/buddy_care_provider.dart';
import 'package:riksa_app/features/mascot/providers/mascot_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBuddyApi implements BuddyApi {
  BuddyMe me = BuddyMe(
    care: BuddyCare.initial(DateTime.now()),
    species: MascotSpecies.crocodile,
    name: 'Server buddy',
    today: const [],
  );
  int getCalls = 0;
  int updateCalls = 0;
  int? mergedEnergy;
  int? mergedBond;

  @override
  Future<BuddyMe> getMe() async {
    getCalls++;
    return me;
  }

  @override
  Future<BuddyMe> updateMe({
    MascotSpecies? species,
    String? name,
    int? guestEnergy,
    int? guestBond,
  }) async {
    updateCalls++;
    mergedEnergy = guestEnergy;
    mergedBond = guestBond;
    me = BuddyMe(
      care: BuddyCare(
        energy: max(me.care.energy, guestEnergy ?? 0).toInt(),
        bond: max(me.care.bond, guestBond ?? 0).toInt(),
        updatedAt: DateTime.now(),
        careDay: phnomPenhCareDay(DateTime.now()),
      ),
      // The server decides the canonical profile during the merge.
      species: MascotSpecies.crocodile,
      name: 'Server buddy',
      today: const [],
    );
    return me;
  }

  @override
  Future<void> readComplete(String blogId) async {}
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Unauthenticated();

  void signIn() {
    state = const Authenticated(
      AuthUser(
        id: 'learner-1',
        username: 'learner',
        displayName: 'Learner',
        emailVerified: true,
        phoneVerified: false,
        role: 'USER',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guest care is restored and saved locally after a lesson', () async {
    final api = _FakeBuddyApi();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_TestAuthNotifier.new),
        buddyApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    container.read(buddyCareProvider);
    await _flushAsyncWork();
    await container
        .read(buddyCareProvider.notifier)
        .recordLocalGain(BuddyCareSource.lesson, sourceId: 'lesson-1');

    expect(container.read(buddyCareProvider).care.energy, 95);
    expect(container.read(buddyCareProvider).care.bond, 10);
    expect(api.getCalls, 0);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('riksa_buddy_guest_care')!) as Map;
    expect(saved['energy'], 95);
    expect(saved['bond'], 10);
  });

  test(
    'sign-in merges guest maxima once and adopts server buddy profile',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'riksa_buddy_guest_care': jsonEncode(
          BuddyCare(
            energy: 90,
            bond: 24,
            updatedAt: now,
            careDay: phnomPenhCareDay(now),
          ).toJson(),
        ),
        'riksa_mascot_species': 'capybara',
        'riksa_mascot_name': 'Mochi',
      });
      final api = _FakeBuddyApi();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
          buddyApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      container.read(buddyCareProvider);
      await _flushAsyncWork();

      final authNotifier =
          container.read(authProvider.notifier) as _TestAuthNotifier;
      authNotifier.signIn();
      await _flushAsyncWork();
      authNotifier.signIn();
      await _flushAsyncWork();

      expect(api.updateCalls, 1);
      expect(api.mergedEnergy, 90);
      expect(api.mergedBond, 24);
      expect(container.read(buddyCareProvider).care.energy, 90);
      expect(container.read(buddyCareProvider).care.bond, 24);
      expect(container.read(buddyCareProvider).name, 'Server buddy');
      expect(
        container.read(mascotProvider).profile?.species,
        MascotSpecies.crocodile,
      );
      expect(container.read(mascotProvider).profile?.name, 'Server buddy');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('riksa_buddy_guest_care'), isNull);
    },
  );
}

Future<void> _flushAsyncWork() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
