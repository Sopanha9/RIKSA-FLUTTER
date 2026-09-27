import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';
import 'package:riksa_app/features/mascot/domain/mascot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BuddyMe accepts older payloads without equipped or chosen', () {
    final buddy = BuddyMe.fromJson({'species': 'capybara', 'name': 'Mochi'});

    expect(buddy.species, MascotSpecies.capybara);
    expect(buddy.equipped, isEmpty);
    expect(buddy.chosen, isTrue);
    expect(buddy.balance, isNull);
  });

  test('BuddyMe parses both equipped slots, balance, and chosen', () {
    final buddy = BuddyMe.fromJson({
      'species': 'capybara',
      'name': 'Mochi',
      'equipped': {
        'HAT': {'itemId': 'item-hat', 'assetKey': 'hat_straw'},
        'EYEWEAR': {'itemId': 'item-glasses', 'assetKey': 'glasses_round'},
      },
      'balance': 230,
      'chosen': false,
    });

    expect(buddy.equipped[BuddyItemSlot.hat]?.itemId, 'item-hat');
    expect(buddy.equipped[BuddyItemSlot.hat]?.assetKey, 'hat_straw');
    expect(buddy.equipped[BuddyItemSlot.eyewear]?.assetKey, 'glasses_round');
    expect(buddy.balance, 230);
    expect(buddy.chosen, isFalse);
  });

  test('equip sends the selected slot and nullable item id', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _RecordingAdapter({
      'species': 'crocodile',
      'name': 'Croco',
      'chosen': true,
      'equipped': <String, Object?>{},
    });
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'http://riksa.test/api/v1',
      httpClientAdapter: adapter,
    );
    addTearDown(client.dispose);

    await BuddyApi(client).equip(BuddyItemSlot.eyewear, null);

    expect(adapter.request?.method, 'PUT');
    expect(adapter.request?.path, '/buddy/me/equipped');
    expect(adapter.request?.data, {'slot': 'EYEWEAR', 'itemId': null});
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final Map<String, Object?> body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
