import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/presentation/auth_switcher_screen.dart';
import 'package:riksa_app/features/auth/presentation/telegram_otp_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

// Only external HTTP and platform storage are substituted. Forms, notifier,
// API serialization, profile hydration, and session handling run unchanged.
class AuthServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool rejectCode = false;
  bool failSend = false;
  Completer<void>? sendGate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    var status = 200;
    Object body = <String, Object>{};
    switch (options.path) {
      case '/auth/otp/send':
        await sendGate?.future;
        status = failSend ? 429 : 200;
        body = {
          'message': failSend
              ? 'Too many OTP requests. Try again later.'
              : 'Code sent',
          'channel': 'TELEGRAM',
        };
      case '/auth/telegram':
      case '/auth/login':
      case '/auth/register':
        if (rejectCode) {
          status = 400;
          body = {'message': 'Invalid or expired code'};
        } else {
          body = {
            'userId': 'user-1',
            'username': 'sophea',
            'role': 'USER',
            'accessToken': 'test-access',
            'refreshToken': 'test-refresh',
          };
        }
      case '/auth/me':
        expectSync(options.headers['Authorization'], 'Bearer test-access');
        body = {
          'id': 'user-1',
          'username': 'sophea',
          'displayName': 'Sophea',
          'role': 'USER',
        };
      case '/auth/logout':
        body = {'message': 'Logged out'};
      default:
        throw StateError('Unexpected auth request: ${options.path}');
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> mountAuth(
  WidgetTester tester,
  AuthServer server, {
  bool registration = false,
  bool startAtLogin = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});
  final client = DioClient(
    SessionStore(const FlutterSecureStorage()),
    baseUrl: 'https://auth.test/api/v1',
    httpClientAdapter: server,
  );
  final container = ProviderContainer(
    overrides: [dioClientProvider.overrideWithValue(client)],
  );
  container.read(authProvider);
  final router = GoRouter(
    initialLocation: startAtLogin ? '/auth/login' : '/auth/telegram',
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const AuthSwitcherScreen(),
      ),
      GoRoute(
        path: '/auth/telegram',
        builder: (_, _) => TelegramOtpScreen(isRegistration: registration),
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
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> sendCode(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('telegram_identifier')),
    '123456789',
  );
  await tapKey(tester, 'telegram_send_code');
}

void main() {
  testWidgets('OTP delivery shows destination and prevents immediate resend', (
    tester,
  ) async {
    await mountAuth(tester, AuthServer());
    await sendCode(tester);
    expect(find.textContaining('123456789'), findsOneWidget);
    final resend = tester.widget<TextButton>(
      find.byKey(const Key('telegram_resend_code')),
    );
    expect(resend.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'login opens Telegram and verifies a code, restores session, logs out',
    (tester) async {
      final server = AuthServer();
      final container = await mountAuth(tester, server, startAtLogin: true);
      await tapKey(tester, 'telegram_auth_button');
      await sendCode(tester);
      await tester.enterText(
        find.byKey(const Key('telegram_otp_code')),
        '123456',
      );
      await tapKey(tester, 'telegram_verify_code');
      expect(find.text('Signed in destination'), findsOneWidget);
      expect(container.read(authProvider), isA<Authenticated>());
      final restored = container
          .read(authProvider.notifier)
          .bootstrap(force: true);
      await tester.pumpAndSettle();
      await restored;
      expect(container.read(authProvider), isA<Authenticated>());
      final logout = container.read(authProvider.notifier).logout();
      await tester.pumpAndSettle();
      await logout;
      expect(container.read(authProvider), isA<Unauthenticated>());
      expect(await container.read(dioClientProvider).hasSession(), isFalse);
      expect(
        server.requests.where((r) => r.path == '/auth/telegram').single.data,
        {'identifier': '123456789', 'code': '123456'},
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Telegram registration carries the chosen names to verification',
    (tester) async {
      final server = AuthServer();
      await mountAuth(tester, server, registration: true);
      await tester.enterText(
        find.byKey(const Key('telegram_register_username')),
        'sophea',
      );
      await tester.enterText(
        find.byKey(const Key('telegram_register_display_name')),
        'Sophea',
      );
      await sendCode(tester);
      await tester.enterText(
        find.byKey(const Key('telegram_otp_code')),
        '123456',
      );
      await tapKey(tester, 'telegram_verify_code');
      expect(find.text('Signed in destination'), findsOneWidget);
      expect(
        server.requests.where((r) => r.path == '/auth/telegram').single.data,
        {
          'identifier': '123456789',
          'code': '123456',
          'username': 'sophea',
          'displayName': 'Sophea',
        },
      );
    },
  );

  testWidgets('wrong code stays on OTP and successful retry signs in', (
    tester,
  ) async {
    final server = AuthServer()..rejectCode = true;
    final container = await mountAuth(tester, server);
    await sendCode(tester);
    await tester.enterText(
      find.byKey(const Key('telegram_otp_code')),
      '123456',
    );
    await tapKey(tester, 'telegram_verify_code');
    expect(find.text('Invalid or expired code'), findsOneWidget);
    expect(await container.read(dioClientProvider).hasSession(), isFalse);
    server.rejectCode = false;
    await tester.enterText(
      find.byKey(const Key('telegram_otp_code')),
      '654321',
    );
    await tapKey(tester, 'telegram_verify_code');
    expect(find.text('Signed in destination'), findsOneWidget);
  });

  testWidgets(
    'resend failure is visible and resend success clears the old code',
    (tester) async {
      final server = AuthServer();
      await mountAuth(tester, server);
      await sendCode(tester);
      await tester.enterText(
        find.byKey(const Key('telegram_otp_code')),
        '123456',
      );
      await tester.pump(const Duration(seconds: 61));
      server.failSend = true;
      await tapKey(tester, 'telegram_resend_code');
      expect(
        find.text('Too many OTP requests. Try again later.'),
        findsOneWidget,
      );
      server.failSend = false;
      await tapKey(tester, 'telegram_resend_code');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('telegram_otp_code')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('telegram_resend_code')))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('invalid identifiers and incomplete codes never reach the API', (
    tester,
  ) async {
    final server = AuthServer();
    await mountAuth(tester, server);
    await tester.enterText(
      find.byKey(const Key('telegram_identifier')),
      'invalid',
    );
    await tapKey(tester, 'telegram_send_code');
    expect(server.requests, isEmpty);
    await sendCode(tester);
    await tester.enterText(find.byKey(const Key('telegram_otp_code')), '12');
    await tapKey(tester, 'telegram_verify_code');
    expect(server.requests.where((r) => r.path == '/auth/telegram'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('direct OTP route can return safely to login', (tester) async {
    await mountAuth(tester, AuthServer());
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_username')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP remains usable in Khmer at 200 percent text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountAuth(
      tester,
      AuthServer(),
      locale: const Locale('km'),
      textScale: 2,
    );
    await sendCode(tester);
    await tester.ensureVisible(find.byKey(const Key('telegram_otp_code')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'password login hydrates profile and reaches signed-in destination',
    (tester) async {
      final container = await mountAuth(
        tester,
        AuthServer(),
        startAtLogin: true,
      );
      await tester.enterText(find.byKey(const Key('login_username')), 'sophea');
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'TestPassword123',
      );
      await tapKey(tester, 'login_submit');
      expect(find.text('Signed in destination'), findsOneWidget);
      expect(container.read(authProvider), isA<Authenticated>());
    },
  );

  testWidgets('password registration submits valid details and signs in', (
    tester,
  ) async {
    final server = AuthServer();
    await mountAuth(tester, server, startAtLogin: true);
    await tapKey(tester, 'register_toggle');
    await tester.enterText(
      find.byKey(const Key('register_username')),
      'sophea',
    );
    await tester.enterText(
      find.byKey(const Key('register_email')),
      'sophea@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password')),
      'TestPassword123',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password')),
      'TestPassword123',
    );
    await tapKey(tester, 'register_submit');
    expect(find.text('Signed in destination'), findsOneWidget);
    expect(server.requests.any((r) => r.path == '/auth/register'), isTrue);
  });

  testWidgets('verification is disabled while a resend is in flight', (
    tester,
  ) async {
    final server = AuthServer();
    await mountAuth(tester, server);
    await sendCode(tester);
    await tester.enterText(
      find.byKey(const Key('telegram_otp_code')),
      '123456',
    );
    await tester.pump(const Duration(seconds: 61));
    server.sendGate = Completer<void>();
    await tapKey(tester, 'telegram_resend_code');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('telegram_verify_code')))
          .onPressed,
      isNull,
    );
    server.sendGate!.complete();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('telegram_verify_code')))
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
