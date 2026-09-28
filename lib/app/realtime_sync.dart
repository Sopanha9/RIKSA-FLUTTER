import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/realtime/realtime_client.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/quests/providers/today_quests_provider.dart';
import '../features/social/providers/social_feed_provider.dart';

/// Widget tests have no server; a socket there would only leave timers
/// running when the test ends.
final bool _inFlutterTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// The live connection for the signed-in learner, or null when signed out.
/// A new account gets a new connection.
final realtimeClientProvider = Provider<RealtimeClient?>((ref) {
  final userId = watchCurrentUserId(ref);
  if (userId == null || _inFlutterTest) return null;
  final client = RealtimeClient(ref.watch(dioClientProvider));
  ref.onDispose(client.dispose);
  client.start();
  return client;
});

/// Every event from the server, for screens that react to their own content
/// (an open post, say) with `ref.listen`.
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return client?.events ?? const Stream<RealtimeEvent>.empty();
});

/// Applies server events to app-wide state: the feed and quests. Watched once
/// from the app root so it runs for the whole session.
final realtimeSyncProvider = Provider<void>((ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) return;
  final subscription = client.events.listen((event) => _apply(ref, event));
  ref.onDispose(subscription.cancel);
});

void _apply(Ref ref, RealtimeEvent event) {
  switch (event.type) {
    case RealtimeTypes.questsChanged:
    case RealtimeEvent.resync:
      ref
        ..invalidate(todayQuestsProvider)
        ..invalidate(weeklyQuestsProvider);
  }

  // Only a feed that is already loaded is updated; asking for its notifier
  // otherwise would start a feed load nobody is looking at.
  if (!ref.exists(socialFeedProvider)) return;
  final feed = ref.read(socialFeedProvider.notifier);
  final postId = event.postId;
  switch (event.type) {
    case RealtimeTypes.postChanged when postId != null:
      unawaited(feed.refreshPost(postId));
    case RealtimeTypes.postCreated when postId != null:
      unawaited(feed.addIncomingPost(postId));
    case RealtimeTypes.postDeleted when postId != null:
      feed.removePost(postId);
  }
}
