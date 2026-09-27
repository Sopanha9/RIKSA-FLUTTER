import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/market/data/market_api.dart';
import 'package:riksa_app/features/mascot/data/buddy_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lists items with an API slot filter', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _RecordingAdapter(
      (request) => {
        'balance': 800,
        'items': [
          {
            'id': 'round-glasses',
            'slot': 'EYEWEAR',
            'name': 'Round glasses',
            'nameKm': 'វ៉ែនតាមូល',
            'price': 240,
            'rarity': 'RARE',
            'assetKey': 'glasses_round',
            'owned': true,
            'equipped': false,
            'locked': false,
          },
        ],
      },
    );
    final client = _client(adapter);
    addTearDown(client.dispose);

    final page = await MarketApi(client).items(BuddyItemSlot.eyewear);

    expect(adapter.request?.queryParameters['slot'], 'EYEWEAR');
    expect(page.balance, 800);
    expect(page.items.single.nameKm, 'វ៉ែនតាមូល');
    expect(page.items.single.owned, isTrue);
  });

  test(
    'purchase sends the provided idempotency key and parses receipt',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final adapter = _RecordingAdapter(
        (request) => {
          'item': {
            'id': 'straw-hat',
            'slot': 'HAT',
            'name': 'Straw hat',
            'nameKm': 'មួកចំបើង',
            'price': 300,
            'rarity': 'COMMON',
            'assetKey': 'hat_straw',
            'owned': true,
            'equipped': false,
            'locked': false,
          },
          'balance': 940,
        },
      );
      final client = _client(adapter);
      addTearDown(client.dispose);

      final receipt = await MarketApi(
        client,
      ).purchase('straw-hat', idempotencyKey: 'attempt-uuid');

      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.path, '/market/items/straw-hat/purchase');
      expect(adapter.request?.headers['Idempotency-Key'], 'attempt-uuid');
      expect(receipt.balance, 940);
      expect(receipt.item.owned, isTrue);
    },
  );
}

DioClient _client(_RecordingAdapter adapter) => DioClient(
  SessionStore(const FlutterSecureStorage()),
  baseUrl: 'http://riksa.test/api/v1',
  httpClientAdapter: adapter,
);

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.bodyFor);

  final Map<String, Object?> Function(RequestOptions request) bodyFor;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(bodyFor(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
