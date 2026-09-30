import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/app/riksa_app.dart';
import 'package:riksa_app/app/router/app_router.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/features/auth/data/external_link_opener.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_riksa_server.dart';

/// The whole app, signed in, onboarding done, talking to [server].
class CrawlerApp {
  CrawlerApp._(this.container, this.server);

  final ProviderContainer container;
  final FakeRiksaServer server;
  final openedLinks = <Uri>[];

  GoRouter get router => container.read(goRouterProvider);

  static Future<CrawlerApp> mount(
    WidgetTester tester,
    FakeRiksaServer server, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    FlutterSecureStorage.setMockInitialValues({
      SessionStore.accessTokenKey: 'crawler-access',
      SessionStore.refreshTokenKey: 'crawler-refresh',
    });
    SharedPreferences.setMockInitialValues({
      'riksa_locale': locale.languageCode,
      'riksa_locale_selected': true,
      'riksa_onboarding_viewed': true,
      'riksa_onboarding_completed': true,
    });
    final client = DioClient(
      SessionStore(const FlutterSecureStorage()),
      baseUrl: 'https://crawler.test/api/v1',
      httpClientAdapter: server,
    );
    late CrawlerApp app;
    final container = ProviderContainer(
      overrides: [
        dioClientProvider.overrideWithValue(client),
        externalLinkOpenerProvider.overrideWithValue((uri) async {
          app.openedLinks.add(uri);
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    app = CrawlerApp._(container, server);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(393, 852),
            disableAnimations: true,
          ),
          child: const RiksaApp(),
        ),
      ),
    );
    await settle(tester);
    return app;
  }

  /// Pumps until quiet or [max] passes. Screens with looping animations
  /// (the buddy, Rive) never settle, so a plain pumpAndSettle would time out.
  static Future<void> settle(
    WidgetTester tester, {
    Duration max = const Duration(seconds: 3),
  }) async {
    var elapsed = Duration.zero;
    const step = Duration(milliseconds: 100);
    await tester.pump();
    while (elapsed < max) {
      await tester.pump(step);
      elapsed += step;
      if (!tester.binding.hasScheduledFrame) break;
    }
  }
}
