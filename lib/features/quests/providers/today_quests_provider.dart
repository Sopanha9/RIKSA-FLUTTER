import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/quest_models.dart';
import '../data/quests_api.dart';

final questsRepositoryProvider = Provider<QuestsRepository>((ref) {
  return QuestsApi(ref.watch(dioClientProvider));
});

class TodayQuestsNotifier extends AsyncNotifier<TodayQuests> {
  int _requestVersion = 0;

  @override
  Future<TodayQuests> build() async {
    watchCurrentUserId(ref);
    _requestVersion++;
    return ref.watch(questsRepositoryProvider).today();
  }

  Future<void> refresh() async {
    final requestVersion = _requestVersion;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      return ref.read(questsRepositoryProvider).today();
    });
    if (requestVersion == _requestVersion) state = result;
  }

  Future<void> claim(String id) async {
    final repository = ref.read(questsRepositoryProvider);
    final before = state.value;
    if (before == null) return;
    final requestVersion = _requestVersion;
    state = AsyncData(
      TodayQuests(
        date: before.date,
        quests: before.quests
            .map((quest) => quest.id == id ? _claiming(quest) : quest)
            .toList(growable: false),
        allClaimedBonusXp: before.allClaimedBonusXp,
      ),
    );
    try {
      final claimed = await repository.claim(id);
      if (requestVersion != _requestVersion) return;
      final current = state.value ?? before;
      final quests = current.quests
          .map((quest) => quest.id == id ? claimed : quest)
          .toList(growable: false);
      state = AsyncData(
        TodayQuests(
          date: current.date,
          quests: quests,
          allClaimedBonusXp: current.allClaimedBonusXp,
        ),
      );
      ref.invalidate(profileDashboardProvider);
    } catch (_) {
      if (requestVersion == _requestVersion) state = AsyncData(before);
      rethrow;
    }
  }

  DailyQuest _claiming(DailyQuest quest) => DailyQuest(
    id: quest.id,
    type: quest.type,
    title: quest.title,
    titleKm: quest.titleKm,
    target: quest.target,
    progress: quest.progress,
    xpReward: quest.xpReward,
    completed: quest.completed,
    claimed: true,
  );
}

final todayQuestsProvider =
    AsyncNotifierProvider<TodayQuestsNotifier, TodayQuests>(
      TodayQuestsNotifier.new,
    );
