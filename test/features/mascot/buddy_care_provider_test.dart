import 'dart:convert';
import 'dart:math';
import 'dart:async';

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
  int equipCalls = 0;
  Completer<BuddyMe>? getReply;
  bool failEquip = false;
  int? mergedEnergy;
  int? mergedBond;
  MascotSpecies? submittedSpecies;
  String? submittedName;

  @override
  Future<BuddyMe> getMe() async {
    getCalls++;
    if (getReply != null) return getReply!.future;
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
    submittedSpecies = species;
    submittedName = name;
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
      equipped: me.equipped,
      balance: me.balance,
      chosen: true,
    );
    return me;
  }

  @override
  Future<BuddyMe> equip(BuddyItemSlot slot, String? itemId) async {
    equipCalls++;
    if (failEquip) throw StateError('equip failed');
    final equipped = Map<BuddyItemSlot, BuddyEquipped>.of(me.equipped);
    if (itemId == null) {
      equipped.remove(slot);
    } else {
      equipped[slot] = BuddyEquipped(
        slot: slot,
        itemId: itemId,
        assetKey: 'server_$itemId',
      );
    }
    me = BuddyMe(
      care: me.care,
      species: me.species,
      name: me.name,
      today: me.today,
      equipped: Map.unmodifiable(equipped),
      balance: me.balance,
      chosen: me.chosen,
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
        'riksa_mascot_species_guest': 'capybara',
        'riksa_mascot_name_guest': 'Mochi',
        MascotNotifier.guestChoicePendingKey: true,
      });
      final api = _FakeBuddyApi();
      api.me = _withChosen(api.me, false);
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

  test('a guest buddy chosen before signup is submitted once', () async {
    final api = _FakeBuddyApi();
    api.me = _withChosen(api.me, false);
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
        .read(mascotProvider.notifier)
        .choose(MascotSpecies.capybara, 'Mochi');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(MascotNotifier.guestChoicePendingKey), isTrue);

    final authNotifier =
        container.read(authProvider.notifier) as _TestAuthNotifier;
    authNotifier.signIn();
    await _flushAsyncWork();
    authNotifier.signIn();
    await _flushAsyncWork();

    expect(api.updateCalls, 1);
    expect(api.submittedSpecies, MascotSpecies.capybara);
    expect(api.submittedName, 'Mochi');
    expect(preferences.getBool(MascotNotifier.guestChoicePendingKey), isNull);
    expect(container.read(mascotProvider).profile?.name, 'Server buddy');
  });

  test(
    'cached look is visible first and is replaced by the server look',
    () async {
      final cached = BuddyMe(
        care: BuddyCare.initial(DateTime.now()),
        species: MascotSpecies.capybara,
        name: 'Cached buddy',
        today: const [],
        equipped: const {
          BuddyItemSlot.hat: BuddyEquipped(
            slot: BuddyItemSlot.hat,
            itemId: 'cached-id',
            assetKey: 'hat_cached',
          ),
        },
      );
      SharedPreferences.setMockInitialValues({
        'riksa_buddy_care_user_learner-1': jsonEncode(cached.toJson()),
      });
      final api = _FakeBuddyApi()..getReply = Completer<BuddyMe>();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
          buddyApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      container.read(buddyCareProvider);
      final authNotifier =
          container.read(authProvider.notifier) as _TestAuthNotifier;
      authNotifier.signIn();
      await _flushAsyncWork();

      expect(container.read(buddyCareProvider).name, 'Cached buddy');
      expect(
        container.read(buddyLookProvider).equipped[BuddyItemSlot.hat],
        'hat_cached',
      );
      api.getReply!.complete(
        BuddyMe(
          care: BuddyCare.initial(DateTime.now()),
          species: MascotSpecies.crocodile,
          name: 'Server buddy',
          today: const [],
          equipped: const {
            BuddyItemSlot.eyewear: BuddyEquipped(
              slot: BuddyItemSlot.eyewear,
              itemId: 'server-glasses',
              assetKey: 'glasses_server',
            ),
          },
        ),
      );
      await _flushAsyncWork();

      expect(container.read(buddyCareProvider).name, 'Server buddy');
      expect(
        container.read(buddyLookProvider).species,
        MascotSpecies.crocodile,
      );
      expect(
        container.read(buddyLookProvider).equipped[BuddyItemSlot.eyewear],
        'glasses_server',
      );
      expect(
        container.read(buddyLookProvider).equipped,
        isNot(contains(BuddyItemSlot.hat)),
      );
    },
  );

  test(
    'an unchosen server default without a guest choice stays unchosen',
    () async {
      final api = _FakeBuddyApi()..me = _withChosen(_FakeBuddyApi().me, false);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
          buddyApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      container.read(buddyCareProvider);
      await _flushAsyncWork();
      (container.read(authProvider.notifier) as _TestAuthNotifier).signIn();
      await _flushAsyncWork();

      expect(api.getCalls, 1);
      expect(api.updateCalls, 0);
      expect(container.read(buddyCareProvider).serverSynced, isTrue);
      expect(container.read(buddyCareProvider).chosen, isFalse);
    },
  );

  test(
    'a saved server choice is never overwritten by a guest choice',
    () async {
      SharedPreferences.setMockInitialValues({
        'riksa_mascot_species_guest': 'capybara',
        'riksa_mascot_name_guest': 'Guest buddy',
        MascotNotifier.guestChoicePendingKey: true,
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
      (container.read(authProvider.notifier) as _TestAuthNotifier).signIn();
      await _flushAsyncWork();

      expect(api.updateCalls, 0);
      expect(
        container.read(buddyCareProvider).species,
        MascotSpecies.crocodile,
      );
      expect(container.read(buddyCareProvider).name, 'Server buddy');
    },
  );

  test(
    'equip updates optimistically and rolls back after server failure',
    () async {
      final previous = BuddyEquipped(
        slot: BuddyItemSlot.hat,
        itemId: 'old-hat',
        assetKey: 'hat_old',
      );
      final api = _FakeBuddyApi()
        ..me = BuddyMe(
          care: BuddyCare.initial(DateTime.now()),
          species: MascotSpecies.crocodile,
          name: 'Server buddy',
          today: const [],
          equipped: {BuddyItemSlot.hat: previous},
        )
        ..failEquip = true;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
          buddyApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      container.read(buddyCareProvider);
      await _flushAsyncWork();
      (container.read(authProvider.notifier) as _TestAuthNotifier).signIn();
      await _flushAsyncWork();

      final request = container
          .read(buddyCareProvider.notifier)
          .equip(BuddyItemSlot.hat, 'new-hat', assetKey: 'hat_new');
      expect(
        container.read(buddyLookProvider).equipped[BuddyItemSlot.hat],
        'hat_new',
      );
      await expectLater(request, throwsA(isA<StateError>()));

      expect(api.equipCalls, 1);
      expect(
        container.read(buddyLookProvider).equipped[BuddyItemSlot.hat],
        'hat_old',
      );
    },
  );

  test(
    'unequip updates optimistically and rolls back after server failure',
    () async {
      final previous = BuddyEquipped(
        slot: BuddyItemSlot.hat,
        itemId: 'old-hat',
        assetKey: 'hat_old',
      );
      final api = _FakeBuddyApi()
        ..me = BuddyMe(
          care: BuddyCare.initial(DateTime.now()),
          species: MascotSpecies.crocodile,
          name: 'Server buddy',
          today: const [],
          equipped: {BuddyItemSlot.hat: previous},
        )
        ..failEquip = true;
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
          buddyApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      container.read(buddyCareProvider);
      await _flushAsyncWork();
      (container.read(authProvider.notifier) as _TestAuthNotifier).signIn();
      await _flushAsyncWork();

      final request = container
          .read(buddyCareProvider.notifier)
          .equip(BuddyItemSlot.hat, null);
      expect(
        container.read(buddyLookProvider).equipped,
        isNot(contains(BuddyItemSlot.hat)),
      );
      await expectLater(request, throwsA(isA<StateError>()));

      expect(api.equipCalls, 1);
      expect(
        container.read(buddyLookProvider).equipped[BuddyItemSlot.hat],
        'hat_old',
      );
    },
  );

  test('unequip success leaves the slot empty', () async {
    final api = _FakeBuddyApi()
      ..me = BuddyMe(
        care: BuddyCare.initial(DateTime.now()),
        species: MascotSpecies.crocodile,
        name: 'Server buddy',
        today: const [],
        equipped: const {
          BuddyItemSlot.hat: BuddyEquipped(
            slot: BuddyItemSlot.hat,
            itemId: 'old-hat',
            assetKey: 'hat_old',
          ),
        },
      );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_TestAuthNotifier.new),
        buddyApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.read(buddyCareProvider);
    await _flushAsyncWork();
    (container.read(authProvider.notifier) as _TestAuthNotifier).signIn();
    await _flushAsyncWork();

    await container
        .read(buddyCareProvider.notifier)
        .equip(BuddyItemSlot.hat, null);

    expect(api.equipCalls, 1);
    expect(container.read(buddyLookProvider).equipped, isEmpty);
  });
}

BuddyMe _withChosen(BuddyMe me, bool chosen) => BuddyMe(
  care: me.care,
  species: me.species,
  name: me.name,
  today: me.today,
  equipped: me.equipped,
  balance: me.balance,
  chosen: chosen,
);

Future<void> _flushAsyncWork() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
