import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riksa_app/core/network/dio_client.dart';
import 'package:riksa_app/core/storage/session_store.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/auth/data/external_link_opener.dart';
import 'package:riksa_app/features/auth/presentation/auth_switcher_screen.dart';
import 'package:riksa_app/features/auth/presentation/telegram_auth_screen.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

const nonce = '841f6cb4701d56f61cd1b2fea1f133f8';
const botUrl = 'https://t.me/riksa_bot?start=login_$nonce';
const botAppUrl = 'tg://resolve?domain=riksa_bot&start=login_$nonce';
const codeBotUrl = 'https://t.me/riksa_bot?start=code';
const codeBotAppUrl = 'tg://resolve?domain=riksa_bot&start=code';
const requestToken = 'request-token-1';

const sessionJson = {
  'userId': 'user-1',
  'username': 'sophea',
  'role': 'USER',
  'accessToken': 'test-access',
  'refreshToken': 'test-refresh',
};

const pending = {'status': 'PENDING'};
const authenticated = {'status': 'AUTHENTICATED', 'auth': sessionJson};
const profileRequired = {
  'status': 'PROFILE_REQUIRED',
  'signupToken': 'signup-1',
  'telegram': {'displayName': 'Sok Sophea', 'username': 'sophea_tg'},
};

// Only external HTTP, the link opener, and platform storage are substituted.
// Screens, notifier, API serialization, and session handling run unchanged.
class AuthServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  /// Successive `/auth/telegram/status` bodies; the last one repeats. A map
  /// with `httpStatus` is returned as an error response.
  List<Map<String, Object?>> statuses = [authenticated];
  int _statusIndex = 0;
  int pollIntervalSeconds = 1;
  int expiresInSeconds = 300;
  bool failStart = false;
  int? loginErrorStatus;
  String loginErrorMessage = 'Wrong password';

  /// Body returned by `/auth/telegram/code`, or an error when [codeErrorStatus] is set.
  Map<String, Object?> codeResult = authenticated;
  int? codeErrorStatus;
  int? completeErrorStatus;
  String completeErrorMessage = 'Username is already taken';

  Iterable<RequestOptions> requestsTo(String path) =>
      requests.where((r) => r.path == path);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    var status = 200;
    Object? body = <String, Object>{};
    switch (options.path) {
      case '/auth/telegram/bot':
        body = {
          'available': true,
          'botUsername': 'riksa_bot',
          'botUrl': codeBotUrl,
          'botAppUrl': codeBotAppUrl,
          'codeLength': 8,
        };
      case '/auth/telegram/start':
        if (failStart) {
          status = 503;
          body = {'message': 'Telegram is unavailable right now.'};
        } else {
          body = {
            'requestToken': requestToken,
            'botUrl': botUrl,
            'botAppUrl': botAppUrl,
            'botUsername': 'riksa_bot',
            'expiresInSeconds': expiresInSeconds,
            'pollIntervalSeconds': pollIntervalSeconds,
          };
        }
      case '/auth/telegram/code':
        if (codeErrorStatus case final int code) {
          status = code;
          body = {'message': 'This code is invalid or has expired.'};
        } else {
          body = codeResult;
        }
      case '/auth/telegram/status':
        final next = statuses[_statusIndex.clamp(0, statuses.length - 1)];
        _statusIndex++;
        if (next['httpStatus'] case final int code) {
          status = code;
          body = {'message': 'Temporary failure'};
        } else {
          body = next;
        }
      case '/auth/telegram/complete':
        if (completeErrorStatus case final int code) {
          status = code;
          body = {'message': completeErrorMessage};
        } else {
          body = sessionJson;
        }
      case '/auth/login':
        if (loginErrorStatus case final int code) {
          status = code;
          body = {'message': loginErrorMessage};
        } else {
          body = sessionJson;
        }
      case '/auth/register':
        body = sessionJson;
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

class LinkRecorder {
  final opened = <Uri>[];

  /// Whether `tg://` links open (the Telegram app is installed).
  bool appInstalled = true;

  /// Whether `https://t.me` links open.
  bool result = true;

  Future<bool> call(Uri uri) async {
    opened.add(uri);
    return uri.scheme == 'tg' ? appInstalled : result;
  }
}

/// Makes [Clipboard.getData] return [text] and records [Clipboard.setData].
void mockClipboard(
  WidgetTester tester, {
  String? text,
  void Function(String?)? onCopy,
}) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        onCopy?.call((call.arguments as Map)['text'] as String?);
      }
      if (call.method == 'Clipboard.getData') {
        return text == null ? null : {'text': text};
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

Future<ProviderContainer> mountAuth(
  WidgetTester tester,
  AuthServer server, {
  LinkRecorder? links,
  bool startAtLogin = false,
  String? loginReason,
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
  final recorder = links ?? LinkRecorder();
  final container = ProviderContainer(
    overrides: [
      dioClientProvider.overrideWithValue(client),
      externalLinkOpenerProvider.overrideWithValue(recorder.call),
    ],
  );
  container.read(authProvider);
  final router = GoRouter(
    initialLocation: startAtLogin
        ? Uri(
            path: '/auth/login',
            queryParameters: loginReason == null
                ? null
                : {'reason': loginReason},
          ).toString()
        : '/auth/telegram',
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const AuthSwitcherScreen(),
      ),
      GoRoute(
        path: '/auth/telegram',
        builder: (_, _) => const TelegramAuthScreen(),
      ),
      GoRoute(
        path: '/learn',
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
          data:
              MediaQuery.of(
                context,
                // The buddy on the auth screens animates forever; still it so
                // pumpAndSettle can settle.
              ).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  if (startAtLogin) {
    // The login buddy is intentionally always alive, so wait for startup
    // work without asking the frame scheduler to become permanently idle.
    await pumpFor(tester, const Duration(milliseconds: 600));
  } else {
    await tester.pumpAndSettle();
  }
  return container;
}

/// Pumps in small steps. The waiting step shows an indeterminate spinner, so
/// `pumpAndSettle` would never return there.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await pumpFor(tester, const Duration(milliseconds: 300));
}

/// Taps "Open Telegram" and lets the start request complete.
Future<void> authorize(WidgetTester tester) =>
    tapKey(tester, 'telegram_authorize');

/// Opens "Log in with code" and lets the bot details load.
Future<void> openCodeStep(WidgetTester tester) async {
  await tapKey(tester, 'telegram_use_code');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login explains the action that needs an account', (
    tester,
  ) async {
    await mountAuth(
      tester,
      AuthServer(),
      startAtLogin: true,
      loginReason: 'save_lesson',
    );
    expect(
      find.text('Sign in to save this lesson to your library.'),
      findsOneWidget,
    );
  });

  testWidgets('offers Open Telegram and Log in with code, asking for no ID', (
    tester,
  ) async {
    final server = AuthServer();
    await mountAuth(tester, server);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Open Telegram'), findsOneWidget);
    expect(find.text('Log in with code'), findsOneWidget);
    expect(server.requests, isEmpty);
  });

  testWidgets(
    'existing account: opens the bot, signs in once confirmed, restores, logs out',
    (tester) async {
      final server = AuthServer()..statuses = [pending, authenticated];
      final links = LinkRecorder();
      final container = await mountAuth(
        tester,
        server,
        links: links,
        startAtLogin: true,
      );
      await tapKey(tester, 'telegram_auth_button');
      await tester.pumpAndSettle();
      await authorize(tester);

      expect(links.opened, [Uri.parse(botAppUrl)]);
      expect(find.text('Waiting for Telegram'), findsOneWidget);

      await pumpFor(tester, const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Signed in destination'), findsOneWidget);
      expect(container.read(authProvider), isA<Authenticated>());
      expect(server.requestsTo('/auth/telegram/status').first.data, {
        'requestToken': requestToken,
      });
      expect(server.requestsTo('/auth/telegram/complete'), isEmpty);

      final restored = container
          .read(authProvider.notifier)
          .bootstrap(force: true);
      await tester.pumpAndSettle();
      await restored;
      expect(container.read(authProvider), isA<Authenticated>());
      final logout = container.read(authProvider.notifier).logout();
      await tester.pumpAndSettle();
      await logout;
      expect(await container.read(dioClientProvider).hasSession(), isFalse);
    },
  );

  testWidgets('returning from Telegram checks status immediately', (
    tester,
  ) async {
    final server = AuthServer()
      ..pollIntervalSeconds = 10
      ..statuses = [authenticated];
    await mountAuth(tester, server);
    await authorize(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Signed in destination'), findsOneWidget);
  });

  testWidgets(
    'new Telegram user chooses username and display name after authorizing',
    (tester) async {
      final server = AuthServer()..statuses = [profileRequired];
      await mountAuth(tester, server);
      await authorize(tester);
      await pumpFor(tester, const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Set up your Riksa profile'), findsOneWidget);
      expect(find.text('Connected as Sok Sophea'), findsOneWidget);
      final username = find.byKey(const Key('telegram_profile_username'));
      final displayName = find.byKey(
        const Key('telegram_profile_display_name'),
      );
      expect(
        tester.widget<TextFormField>(username).controller!.text,
        'sophea_tg',
      );
      expect(
        tester.widget<TextFormField>(displayName).controller!.text,
        'Sok Sophea',
      );

      await tester.enterText(username, 'sophea');
      await tapKey(tester, 'telegram_create_account');
      await tester.pumpAndSettle();

      expect(find.text('Signed in destination'), findsOneWidget);
      expect(server.requestsTo('/auth/telegram/complete').single.data, {
        'signupToken': 'signup-1',
        'username': 'sophea',
        'displayName': 'Sok Sophea',
      });
    },
  );

  testWidgets('taken username stays on the form with an inline error', (
    tester,
  ) async {
    final server = AuthServer()
      ..statuses = [profileRequired]
      ..completeErrorStatus = 409;
    await mountAuth(tester, server);
    await authorize(tester);
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tapKey(tester, 'telegram_create_account');
    await tester.pumpAndSettle();
    expect(find.text('Username is already taken'), findsOneWidget);
    expect(find.byKey(const Key('telegram_profile_username')), findsOneWidget);

    server.completeErrorStatus = null;
    await tester.enterText(
      find.byKey(const Key('telegram_profile_username')),
      'sophea_2',
    );
    await tester.pump();
    expect(find.text('Username is already taken'), findsNothing);
    await tapKey(tester, 'telegram_create_account');
    await tester.pumpAndSettle();
    expect(find.text('Signed in destination'), findsOneWidget);
  });

  testWidgets('invalid profile values never reach the API', (tester) async {
    final server = AuthServer()
      ..statuses = [
        {
          'status': 'PROFILE_REQUIRED',
          'signupToken': 'signup-1',
          'telegram': {'displayName': 'Sok'},
        },
      ];
    await mountAuth(tester, server);
    await authorize(tester);
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('telegram_profile_username')),
      'ab',
    );
    await tapKey(tester, 'telegram_create_account');
    await tester.pumpAndSettle();
    expect(server.requestsTo('/auth/telegram/complete'), isEmpty);
  });

  testWidgets('expired signup token sends the user back to authorize', (
    tester,
  ) async {
    final server = AuthServer()
      ..statuses = [profileRequired]
      ..completeErrorStatus = 401;
    final container = await mountAuth(tester, server);
    await authorize(tester);
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tapKey(tester, 'telegram_create_account');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Your Telegram approval expired'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('telegram_authorize')), findsOneWidget);
    expect(await container.read(dioClientProvider).hasSession(), isFalse);
  });

  for (final (status, message) in [
    ('EXPIRED', 'This request expired'),
    ('DENIED', 'The request was declined'),
  ]) {
    testWidgets('$status request returns to start with an explanation', (
      tester,
    ) async {
      final server = AuthServer()
        ..statuses = [
          {'status': status},
        ];
      await mountAuth(tester, server);
      await authorize(tester);
      await pumpFor(tester, const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.textContaining(message), findsOneWidget);
      expect(find.byKey(const Key('telegram_authorize')), findsOneWidget);
    });
  }

  testWidgets('request expires locally when the countdown ends', (
    tester,
  ) async {
    final server = AuthServer()
      ..statuses = [pending]
      ..expiresInSeconds = 30;
    await mountAuth(tester, server);
    await authorize(tester);
    expect(find.textContaining('0:29'), findsOneWidget);
    await pumpFor(tester, const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.textContaining('This request expired'), findsOneWidget);
  });

  testWidgets('temporary server errors while waiting keep polling', (
    tester,
  ) async {
    final server = AuthServer()
      ..statuses = [
        {'httpStatus': 503},
        {'httpStatus': 429},
        authenticated,
      ];
    await mountAuth(tester, server);
    await authorize(tester);
    // 1s, then 1s after the 503, then 2s backoff after the 429.
    await pumpFor(tester, const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Signed in destination'), findsOneWidget);
    expect(server.requestsTo('/auth/telegram/status'), hasLength(3));
  });

  testWidgets('without the Telegram app the https link is used as a fallback', (
    tester,
  ) async {
    final links = LinkRecorder()..appInstalled = false;
    await mountAuth(tester, AuthServer()..statuses = [pending], links: links);
    await authorize(tester);
    expect(links.opened, [Uri.parse(botAppUrl), Uri.parse(botUrl)]);
    expect(find.textContaining("Couldn't open Telegram"), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('when no link opens, the link can be copied instead', (
    tester,
  ) async {
    final links = LinkRecorder()
      ..appInstalled = false
      ..result = false;
    String? copied;
    mockClipboard(tester, onCopy: (text) => copied = text);
    await mountAuth(tester, AuthServer()..statuses = [pending], links: links);
    await authorize(tester);
    expect(find.textContaining("Couldn't open Telegram"), findsOneWidget);

    await tapKey(tester, 'telegram_copy_link');
    expect(copied, botUrl);
    expect(find.textContaining('Link copied'), findsOneWidget);

    links.result = true;
    await tapKey(tester, 'telegram_open_again');
    expect(find.textContaining("Couldn't open Telegram"), findsNothing);
    expect(links.opened, hasLength(4));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('waiting screen can switch to Log in with code', (tester) async {
    final server = AuthServer()..statuses = [pending];
    await mountAuth(tester, server);
    await authorize(tester);
    await tapKey(tester, 'telegram_switch_to_code');
    await tester.pumpAndSettle();
    final polls = server.requestsTo('/auth/telegram/status').length;
    await tester.pump(const Duration(seconds: 5));
    expect(server.requestsTo('/auth/telegram/status'), hasLength(polls));
    expect(find.byKey(const Key('telegram_code_input')), findsOneWidget);
  });

  // ------------------------------------------------------------ code option

  testWidgets('code option names the bot and opens it for a code', (
    tester,
  ) async {
    final links = LinkRecorder();
    await mountAuth(tester, AuthServer(), links: links);
    await openCodeStep(tester);

    expect(
      find.text('Paste the code from @riksa_bot to sign in.'),
      findsOneWidget,
    );
    await tapKey(tester, 'telegram_open_bot');
    expect(links.opened, [Uri.parse(codeBotAppUrl)]);
  });

  testWidgets('typed code is normalized and signs an existing account in', (
    tester,
  ) async {
    final server = AuthServer();
    await mountAuth(tester, server);
    await openCodeStep(tester);

    await tester.enterText(
      find.byKey(const Key('telegram_code_input')),
      've9b-lz8j',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('telegram_code_input')))
          .controller!
          .text,
      'VE9BLZ8J',
    );
    await tapKey(tester, 'telegram_code_submit');
    await tester.pumpAndSettle();

    expect(find.text('Signed in destination'), findsOneWidget);
    expect(server.requestsTo('/auth/telegram/code').single.data, {
      'code': 'VE9BLZ8J',
    });
  });

  testWidgets('paste button finds the code in a copied bot message', (
    tester,
  ) async {
    final server = AuthServer();
    mockClipboard(
      tester,
      text:
          '👋 Welcome back, Sok!\n🔑 Your sign-in code\nVE9BLZ8J\n⏱ Expires in 5 minutes',
    );
    await mountAuth(tester, server);
    await openCodeStep(tester);

    await tapKey(tester, 'telegram_paste_code');
    await tester.pumpAndSettle();

    expect(find.text('Signed in destination'), findsOneWidget);
    expect(server.requestsTo('/auth/telegram/code').single.data, {
      'code': 'VE9BLZ8J',
    });
  });

  testWidgets('clipboard without a code explains instead of submitting', (
    tester,
  ) async {
    final server = AuthServer();
    mockClipboard(tester, text: 'hello there');
    await mountAuth(tester, server);
    await openCodeStep(tester);

    await tapKey(tester, 'telegram_paste_code');
    expect(
      find.text('No sign-in code found in your clipboard.'),
      findsOneWidget,
    );
    expect(server.requestsTo('/auth/telegram/code'), isEmpty);
  });

  testWidgets('incomplete codes never reach the API', (tester) async {
    final server = AuthServer();
    await mountAuth(tester, server);
    await openCodeStep(tester);

    await tester.enterText(find.byKey(const Key('telegram_code_input')), 'VE9');
    await tapKey(tester, 'telegram_code_submit');
    expect(
      find.text('Enter the 8-character code from the bot'),
      findsOneWidget,
    );
    expect(server.requestsTo('/auth/telegram/code'), isEmpty);
  });

  testWidgets('rejected code shows guidance and a new code can be tried', (
    tester,
  ) async {
    final server = AuthServer()..codeErrorStatus = 400;
    await mountAuth(tester, server);
    await openCodeStep(tester);

    await tester.enterText(
      find.byKey(const Key('telegram_code_input')),
      'VE9BLZ8J',
    );
    await tapKey(tester, 'telegram_code_submit');
    await tester.pumpAndSettle();
    expect(find.textContaining('Send /code to the bot'), findsOneWidget);

    server.codeErrorStatus = null;
    await tester.enterText(
      find.byKey(const Key('telegram_code_input')),
      'KQ7MHX2P',
    );
    await tapKey(tester, 'telegram_code_submit');
    await tester.pumpAndSettle();
    expect(find.text('Signed in destination'), findsOneWidget);
  });

  testWidgets('code for a new Telegram user continues to the profile step', (
    tester,
  ) async {
    final server = AuthServer()..codeResult = profileRequired;
    await mountAuth(tester, server);
    await openCodeStep(tester);

    // A full code submits itself.
    await tester.enterText(
      find.byKey(const Key('telegram_code_input')),
      'VE9BLZ8J',
    );
    await tester.pumpAndSettle();
    expect(find.text('Set up your Riksa profile'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('telegram_profile_username')),
      'sophea',
    );
    await tapKey(tester, 'telegram_create_account');
    await tester.pumpAndSettle();
    expect(find.text('Signed in destination'), findsOneWidget);
    expect(server.requestsTo('/auth/telegram/complete').single.data, {
      'signupToken': 'signup-1',
      'username': 'sophea',
      'displayName': 'Sok Sophea',
    });
  });

  testWidgets('cancel abandons the request and stops polling', (tester) async {
    final server = AuthServer()..statuses = [pending];
    await mountAuth(tester, server);
    await authorize(tester);
    await pumpFor(tester, const Duration(milliseconds: 1500));
    await tapKey(tester, 'telegram_cancel');
    await tester.pumpAndSettle();
    final polls = server.requestsTo('/auth/telegram/status').length;
    await tester.pump(const Duration(seconds: 10));
    expect(server.requestsTo('/auth/telegram/status'), hasLength(polls));
    expect(find.byKey(const Key('telegram_authorize')), findsOneWidget);
  });

  testWidgets('start failure is shown and Telegram is not opened', (
    tester,
  ) async {
    final links = LinkRecorder();
    await mountAuth(tester, AuthServer()..failStart = true, links: links);
    await authorize(tester);
    await tester.pumpAndSettle();
    expect(find.text('Telegram is unavailable right now.'), findsOneWidget);
    expect(links.opened, isEmpty);
  });

  testWidgets('direct Telegram route can return safely to login', (
    tester,
  ) async {
    await mountAuth(tester, AuthServer());
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_username')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Telegram steps fit in Khmer at 200 percent text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mountAuth(
      tester,
      AuthServer()..statuses = [profileRequired],
      locale: const Locale('km'),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await authorize(tester);
    expect(tester.takeException(), isNull);
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('telegram_create_account')),
    );
    expect(tester.takeException(), isNull);

    await tapKey(tester, 'telegram_use_another_account');
    await tester.pumpAndSettle();
    await openCodeStep(tester);
    await tester.ensureVisible(find.byKey(const Key('telegram_code_submit')));
    expect(tester.takeException(), isNull);
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
      await tester.pumpAndSettle();
      expect(find.text('Signed in destination'), findsOneWidget);
      expect(container.read(authProvider), isA<Authenticated>());
    },
  );

  testWidgets('auth error appears in the buddy bubble and error banner', (
    tester,
  ) async {
    final server = AuthServer()
      ..loginErrorStatus = 401
      ..loginErrorMessage = 'Wrong password';
    await mountAuth(tester, server, startAtLogin: true);
    await tester.enterText(find.byKey(const Key('login_username')), 'sophea');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'WrongPassword123',
    );
    await tapKey(tester, 'login_submit');
    await pumpFor(tester, const Duration(milliseconds: 700));

    expect(find.text('Wrong password'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('auth_buddy_bubble')),
        matching: find.text('Oh no! Wrong password'),
      ),
      findsWidgets,
    );
  });

  testWidgets('validation failure gives a hint in the buddy bubble', (
    tester,
  ) async {
    await mountAuth(tester, AuthServer(), startAtLogin: true);
    await tapKey(tester, 'login_submit');

    expect(
      find.descendant(
        of: find.byKey(const Key('auth_buddy_bubble')),
        matching: find.text('Oops! Check the highlighted fields.'),
      ),
      findsWidgets,
    );
    expect(find.text('This field is required'), findsNWidgets(2));
  });

  testWidgets('password registration submits valid details and signs in', (
    tester,
  ) async {
    final server = AuthServer();
    await mountAuth(tester, server, startAtLogin: true);
    await tapKey(tester, 'register_toggle');
    await pumpFor(tester, const Duration(milliseconds: 350));
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
    await tester.pumpAndSettle();
    expect(find.text('Signed in destination'), findsOneWidget);
    expect(server.requestsTo('/auth/register'), isNotEmpty);
  });
}
