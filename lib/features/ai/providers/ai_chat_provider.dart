import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/ai_chat_api.dart';
import '../data/ai_chat_models.dart';

final aiChatApiProvider = Provider<AiChatApi>(
  (ref) => AiChatApi(ref.watch(dioClientProvider)),
);
final aiChatSessionsProvider = FutureProvider<List<AiChatSession>>(
  (ref) => ref.watch(aiChatApiProvider).sessions(),
);
final aiChatSessionProvider = FutureProvider.family<AiChatSession, String>(
  (ref, id) => ref.watch(aiChatApiProvider).session(id),
);
