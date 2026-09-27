import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/ai_chat_api.dart';
import '../data/ai_chat_cache.dart';
import '../data/ai_chat_models.dart';

final aiChatApiProvider = Provider<AiChatApi>((ref) {
  final userId = watchCurrentUserId(ref);
  unawaited(AiChatCache.clearLegacyKeysOnce());
  return AiChatApi(ref.watch(dioClientProvider), AiChatCache(userId));
});

final aiChatSessionsProvider = FutureProvider<List<AiChatSession>>((ref) {
  watchCurrentUserId(ref);
  return ref.watch(aiChatApiProvider).sessions();
});

final aiChatSessionProvider = FutureProvider.family<AiChatSession, String>((
  ref,
  id,
) {
  watchCurrentUserId(ref);
  return ref.watch(aiChatApiProvider).session(id);
});
