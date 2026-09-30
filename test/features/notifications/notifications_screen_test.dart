import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/features/notifications/data/notification_models.dart';
import 'package:riksa_app/features/notifications/data/notifications_api.dart';
import 'package:riksa_app/features/notifications/presentation/notifications_screen.dart';
import 'package:riksa_app/features/notifications/providers/notifications_provider.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';

class _FakeNotifications implements NotificationsRepository {
  _FakeNotifications(this.items, {this.fail = false});

  final List<AppNotification> items;
  bool fail;
  final marked = <String>[];
  var markedAll = false;

  int get _unread =>
      items.where((i) => !i.read && !marked.contains(i.id)).length;

  @override
  Future<NotificationPage> list({String? cursor, int limit = 20}) async {
    if (fail) throw Exception('offline');
    return NotificationPage(items: items, unreadCount: _unread);
  }

  @override
  Future<int> unreadCount() async => _unread;

  @override
  Future<int> markRead(String id) async {
    marked.add(id);
    return _unread;
  }

  @override
  Future<void> markAllRead() async => markedAll = true;
}

AppNotification _row(
  String id,
  NotificationKind kind, {
  bool read = false,
  String? preview,
  String targetType = 'COMMENT',
  String? postId = 'post-1',
  NotificationActor? actor = const NotificationActor(
    id: 'u1',
    username: 'dara',
    displayName: 'Dara',
  ),
}) => AppNotification(
  id: id,
  kind: kind,
  actor: actor,
  targetType: targetType,
  targetId: 'target-$id',
  postId: postId,
  preview: preview,
  read: read,
  createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
);

Future<GoRouter> _pump(WidgetTester tester, _FakeNotifications repo) async {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/community/posts/:id',
        builder: (_, state) =>
            Scaffold(body: Text('post ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/blog/:id',
        builder: (_, state) =>
            Scaffold(body: Text('blog ${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('en'),
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('km')],
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('shows who did what, with a dot on unread rows', (tester) async {
    final repo = _FakeNotifications([
      _row('1', NotificationKind.postComment, preview: 'Nice explanation!'),
      _row('2', NotificationKind.postReaction, read: true, targetType: 'POST'),
      _row(
        '3',
        NotificationKind.blogApproved,
        actor: null,
        targetType: 'BLOG',
        postId: null,
        preview: 'Newton’s laws',
      ),
    ]);
    await _pump(tester, repo);

    expect(find.text('Dara commented on your post'), findsOneWidget);
    expect(find.text('Nice explanation!'), findsOneWidget);
    expect(find.text('Dara reacted to your post'), findsOneWidget);
    expect(find.text('Your article was published'), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-unread-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-unread-2')), findsNothing);
    expect(find.text('Mark all as read'), findsOneWidget);
  });

  testWidgets('tapping a comment row marks it read and opens the post', (
    tester,
  ) async {
    final repo = _FakeNotifications([
      _row('1', NotificationKind.postComment, postId: 'abc'),
    ]);
    await _pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('notification-1')));
    await tester.pumpAndSettle();

    expect(repo.marked, ['1']);
    expect(find.text('post abc'), findsOneWidget);
  });

  testWidgets('tapping an article review opens the article', (tester) async {
    final repo = _FakeNotifications([
      _row(
        '9',
        NotificationKind.blogRejected,
        actor: null,
        targetType: 'BLOG',
        postId: null,
      ),
    ]);
    await _pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('notification-9')));
    await tester.pumpAndSettle();

    expect(find.text('blog target-9'), findsOneWidget);
  });

  testWidgets('mark all as read clears every dot and the badge count', (
    tester,
  ) async {
    final repo = _FakeNotifications([
      _row('1', NotificationKind.postComment),
      _row('2', NotificationKind.commentReply),
    ]);
    await _pump(tester, repo);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotificationsScreen)),
    );
    expect(container.read(unreadNotificationCountProvider), 2);

    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();

    expect(repo.markedAll, isTrue);
    expect(find.byKey(const ValueKey('notification-unread-1')), findsNothing);
    expect(find.byKey(const ValueKey('notification-unread-2')), findsNothing);
    expect(container.read(unreadNotificationCountProvider), 0);
    expect(find.text('Mark all as read'), findsNothing);
  });

  testWidgets('an empty inbox says so', (tester) async {
    await _pump(tester, _FakeNotifications([]));

    expect(find.text('Nothing new yet'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry that recovers', (tester) async {
    final repo = _FakeNotifications([
      _row('1', NotificationKind.blogLike, targetType: 'BLOG', postId: null),
    ], fail: true);
    await _pump(tester, repo);

    expect(find.text("Couldn't load notifications"), findsOneWidget);

    repo.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Dara liked your article'), findsOneWidget);
  });
}
