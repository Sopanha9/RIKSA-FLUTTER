import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/features/market/presentation/market_screen.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('purchase error codes have friendly localized messages', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    final expected = {
      'INSUFFICIENT_BALANCE': strings.marketErrorInsufficientBalance,
      'ALREADY_OWNED': strings.marketErrorAlreadyOwned,
      'NOT_AVAILABLE': strings.marketErrorNotAvailable,
      'LOCKED': strings.marketErrorLocked,
    };

    for (final entry in expected.entries) {
      final request = RequestOptions(path: '/market/items/item/purchase');
      final error = DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: switch (entry.key) {
            'INSUFFICIENT_BALANCE' || 'ALREADY_OWNED' => 409,
            'NOT_AVAILABLE' => 410,
            _ => 403,
          },
          data: {'code': entry.key, 'message': 'server detail'},
        ),
      );

      expect(marketErrorMessage(error, strings), entry.value);
    }

    expect(
      marketErrorMessage(StateError('offline'), strings),
      strings.marketErrorNetwork,
    );
  });
}
