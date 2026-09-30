import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/json_response.dart';
import '../../mascot/data/buddy_api.dart';
import 'market_models.dart';

class MarketApi {
  MarketApi(this._client);

  final DioClient _client;

  Future<MarketItemsPage> items(BuddyItemSlot slot) async {
    final response = await _client.dio.get(
      '/market/items',
      queryParameters: {'slot': slot.apiName},
    );
    return MarketItemsPage.fromJson(jsonMap(response));
  }

  Future<MarketPurchaseReceipt> purchase(
    String itemId, {
    required String idempotencyKey,
  }) async {
    final response = await _client.dio.post(
      '/market/items/$itemId/purchase',
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return MarketPurchaseReceipt.fromJson(jsonMap(response));
  }
}
