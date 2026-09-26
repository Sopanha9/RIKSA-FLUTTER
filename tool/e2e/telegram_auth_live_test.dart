// Live end-to-end test: the real TelegramAuthScreen against a running API.
//
// Requires the API on localhost:8080 configured with
//   TELEGRAM_API_BASE_URL=http://localhost:8099  TELEGRAM_WEBHOOK_SECRET=e2e-local-secret
// and a fake Telegram Bot API on localhost:8099 that exposes GET /calls.
// Run:  flutter test tool/e2e/telegram_auth_live_test.dart --dart-define=RIKSA_LIVE_E2E=true
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/external_link_opener.dart';
import 'package:riksa_app/features/auth/presentation/telegram_auth_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const _enabled = bool.fromEnvironment('RIKSA_LIVE_E2E');
const _api = 'http://localhost:8080/api/v1';
const _fake = 'http://localhost:8099';
const _secret = 'e2e-local-secret';

final _run = Random().nextInt(900000) + 100000;
var _updateId = 50000;

Future<Object?> _http(
  String method,
  String url, {
  Object? body,
  Map<String, String> headers = const {},
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse(url));
    headers.forEach(req.headers.set);
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode(body)));
    }
    final res = await req.close();
    final text = await utf8.decodeStream(res);
    return text.isEmpty ? null : jsonDecode(text);
  } finally {
    client.close();
  }
}

Map<String, Object?> _from(int id) => {
  'id': id,
  'is_bot': false,
  'first_name': 'Live',
  'last_name': 'Tester',
  'username': 'live_$id',
};

Future<void> _botText(int id, String text) => _http(
  'POST',
  '$_api/auth/telegram/webhook',
  headers: {'X-Telegram-Bot-Api-Secret-Token': _secret},
  body: {
    'update_id': _updateId++,
    'message': {
      'message_id': _updateId,
      'chat': {'id': id, 'type': 'private'},
      'from': _from(id),
      'text': text,
    },
  },
);

Future<void> _botTap(int id, String data) => _http(
  'POST',
  '$_api/auth/telegram/webhook',
  headers: {'X-Telegram-Bot-Api-Secret-Token': _secret},
  body: {
    'update_id': _updateId++,
    'callback_query': {
      'id': 'cb-$_updateId',
      'from': _from(id),
      'message': {
        'message_id': 1,
        'chat': {'id': id, 'type': 'private'},
      },
      'data': data,
    },
  },
);

Future<String> _latestCode() async {
  final calls = (await _http('GET', '$_fake/calls'))! as List;
  final texts = calls
      .where((c) => c['method'] == 'sendMessage')
      .map((c) => '${c['body']['text']}');
  return RegExp(
    r'<pre>([A-Z0-9]{8})</pre>',
  ).allMatches(texts.join('\n')).last.group(1)!;
}

class _Links {
  final opened = <Uri>[];
  Future<bool> call(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// Lets real network I/O finish and advances the widget clock in small steps.
Future<void> _settle(WidgetTester tester, {int steps = 10}) async {
  for (var i = 0; i < steps; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 20,
}) async {
  for (var i = 0; i < seconds * 5; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await _settle(tester, steps: 2);
  }
  fail('Timed out waiting for $finder');
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester, steps: 3);
}

Future<(ProviderContainer, _Links)> _mount(WidgetTester tester) async {
  HttpOverrides.global = null; // real HTTP to the local API
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // This file is a test harness outside the conventional test/ directory.
  // ignore: invalid_use_of_visible_for_testing_member
  FlutterSecureStorage.setMockInitialValues({});
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final client = DioClient(
    SessionStore(const FlutterSecureStorage()),
    baseUrl: _api,
  );
  final links = _Links();
  final container = ProviderContainer(
    overrides: [
      dioClientProvider.overrideWithValue(client),
      externalLinkOpenerProvider.overrideWithValue(links.call),
    ],
  );
  container.read(authProvider);
  final router = GoRouter(
    initialLocation: '/auth/telegram',
    routes: [
      GoRoute(
        path: '/auth/telegram',
        builder: (_, _) => const TelegramAuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Signed in destination')),
      ),
    ],
  );
  addTearDown(() {
    router.dispose();
    container.dispose();
    client.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
  return (container, links);
}

void main() {
  final newUserId = 810000 + _run % 99999;
  final username = 'live_app_$_run';

  testWidgets('code option: new Telegram user signs up through the app', (
    tester,
  ) async {
    final (container, _) = await _mount(tester);

    await _tap(tester, 'telegram_use_code');
    await _waitFor(
      tester,
      find.text('Paste the code from @riksa_e2e_bot to sign in.'),
    );

    await tester.runAsync(() => _botText(newUserId, '/start'));
    final code = (await tester.runAsync(_latestCode))!;
    await tester.enterText(
      find.byKey(const Key('telegram_code_input')),
      code.toLowerCase(),
    );
    await _tap(tester, 'telegram_code_submit');

    await _waitFor(tester, find.text('Set up your Riksa profile'));
    expect(find.text('Connected as Live Tester'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('telegram_profile_username')),
          )
          .controller!
          .text,
      'live_$newUserId',
    );

    await tester.enterText(
      find.byKey(const Key('telegram_profile_username')),
      username,
    );
    await _tap(tester, 'telegram_create_account');
    await _waitFor(tester, find.text('Signed in destination'));

    final auth = container.read(authProvider);
    expect(auth, isA<Authenticated>());
    expect((auth as Authenticated).user.username, username);
    expect(auth.user.displayName, 'Live Tester');
    await _finish(tester);
  }, skip: !_enabled);

  testWidgets(
    'Open Telegram: the same Telegram user confirms and is signed in',
    (tester) async {
      final (container, links) = await _mount(tester);

      await _tap(tester, 'telegram_authorize');
      await _waitFor(tester, find.text('Waiting for Telegram'));
      final opened = links.opened.single.toString();
      expect(
        opened,
        startsWith('tg://resolve?domain=riksa_e2e_bot&start=login_'),
      );
      final nonce = RegExp(
        r'login_([a-f0-9]{32})',
      ).firstMatch(opened)!.group(1)!;

      await tester.runAsync(() async {
        await _botText(newUserId, '/start login_$nonce');
        await _botTap(newUserId, 'tga:ok:$nonce');
      });
      // Simulates returning from Telegram: the app checks immediately.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _waitFor(tester, find.text('Signed in destination'));

      final auth = container.read(authProvider);
      expect((auth as Authenticated).user.username, username);
      await _finish(tester);
    },
    skip: !_enabled,
  );

  testWidgets('Open Telegram: "Not me" is shown as declined in the app', (
    tester,
  ) async {
    final (_, links) = await _mount(tester);

    await _tap(tester, 'telegram_authorize');
    await _waitFor(tester, find.text('Waiting for Telegram'));
    final nonce = RegExp(
      r'login_([a-f0-9]{32})',
    ).firstMatch(links.opened.single.toString())!.group(1)!;

    await tester.runAsync(() async {
      await _botText(newUserId + 1, '/start login_$nonce');
      await _botTap(newUserId + 1, 'tga:no:$nonce');
    });
    await _waitFor(tester, find.text('The request was declined in Telegram.'));
    expect(find.byKey(const Key('telegram_authorize')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _finish(tester);
  }, skip: !_enabled);

  testWidgets('code option: a used code is rejected with guidance', (
    tester,
  ) async {
    await _mount(tester);
    await _tap(tester, 'telegram_use_code');
    await _waitFor(tester, find.byKey(const Key('telegram_code_input')));

    await tester.runAsync(() => _botText(newUserId, '/code'));
    final code = (await tester.runAsync(_latestCode))!;
    await tester.runAsync(
      () => _http('POST', '$_api/auth/telegram/code', body: {'code': code}),
    );

    await tester.enterText(find.byKey(const Key('telegram_code_input')), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester, steps: 3);
    await _waitFor(tester, find.textContaining('Send /code to the bot'));
    await _finish(tester);
  }, skip: !_enabled);
}

/// Unmounts and lets the HTTP client's idle keep-alive timers expire so the
/// test binding sees no pending timers.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump(const Duration(seconds: 20));
}
