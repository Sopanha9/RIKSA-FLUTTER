import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/notification_models.dart';
import '../data/notifications_api.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsApi(ref.watch(dioClientProvider));
});

/// The number on the bell. Zero when signed out. Realtime pushes set it
/// directly (see `realtime_sync.dart`); the inbox updates it as rows are read.
class UnreadNotificationCountNotifier extends Notifier<int> {
  @override
  int build() {
    final userId = watchCurrentUserId(ref);
    if (userId == null) return 0;
    unawaited(_load());
    return 0;
  }

  Future<void> _load() async {
    try {
      final count = await ref
          .read(notificationsRepositoryProvider)
          .unreadCount();
      if (ref.mounted) state = count;
    } catch (_) {
      // A missing badge is not worth an error; the inbox shows real failures.
    }
  }

  void set(int count) => state = count < 0 ? 0 : count;

  Future<void> reload() => _load();
}

final unreadNotificationCountProvider =
    NotifierProvider<UnreadNotificationCountNotifier, int>(
      UnreadNotificationCountNotifier.new,
    );

class NotificationInbox {
  const NotificationInbox({
    required this.items,
    this.nextCursor,
    this.loadingMore = false,
  });

  final List<AppNotification> items;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasMore => nextCursor != null;
  bool get hasUnread => items.any((item) => !item.read);

  NotificationInbox copyWith({
    List<AppNotification>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
  }) => NotificationInbox(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// The inbox, newest first, one page at a time.
class NotificationInboxNotifier extends AsyncNotifier<NotificationInbox> {
  @override
  Future<NotificationInbox> build() async {
    watchCurrentUserId(ref);
    final page = await ref.watch(notificationsRepositoryProvider).list();
    ref.read(unreadNotificationCountProvider.notifier).set(page.unreadCount);
    return NotificationInbox(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> refresh() async {
    final result = await AsyncValue.guard(() async {
      final page = await ref.read(notificationsRepositoryProvider).list();
      ref.read(unreadNotificationCountProvider.notifier).set(page.unreadCount);
      return NotificationInbox(items: page.items, nextCursor: page.nextCursor);
    });
    if (ref.mounted) state = result;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(notificationsRepositoryProvider)
          .list(cursor: current.nextCursor);
      if (!ref.mounted) return;
      final known = {for (final item in current.items) item.id};
      state = AsyncData(
        NotificationInbox(
          items: [
            ...current.items,
            ...page.items.where((item) => !known.contains(item.id)),
          ],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      if (ref.mounted) state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Marks a row read straight away and tells the server in the background.
  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    final index = current.items.indexWhere((item) => item.id == id);
    if (index < 0 || current.items[index].read) return;
    final items = [...current.items]
      ..[index] = current.items[index].markedRead();
    state = AsyncData(current.copyWith(items: items));
    final badge = ref.read(unreadNotificationCountProvider.notifier);
    badge.set(ref.read(unreadNotificationCountProvider) - 1);
    try {
      final unread = await ref
          .read(notificationsRepositoryProvider)
          .markRead(id);
      if (ref.mounted) badge.set(unread);
    } catch (_) {
      // The row stays read on screen; the next refresh reconciles it.
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || !current.hasUnread) return;
    state = AsyncData(
      current.copyWith(
        items: [for (final item in current.items) item.markedRead()],
      ),
    );
    ref.read(unreadNotificationCountProvider.notifier).set(0);
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } catch (_) {
      if (ref.mounted) unawaited(refresh());
    }
  }
}

final notificationInboxProvider =
    AsyncNotifierProvider<NotificationInboxNotifier, NotificationInbox>(
      NotificationInboxNotifier.new,
    );
