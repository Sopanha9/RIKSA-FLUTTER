import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/quest_models.dart';
import '../data/quests_api.dart';

final questsRepositoryProvider = Provider<QuestsRepository>((ref) {
  return QuestsApi(ref.watch(dioClientProvider));
});

final weeklyQuestsRepositoryProvider = Provider<WeeklyQuestsRepository>((ref) {
  final repository = ref.watch(questsRepositoryProvider);
  if (repository case final WeeklyQuestsRepository weekly) return weekly;
  throw StateError('The configured quests repository has no weekly API.');
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
    if (repository is WeeklyQuestsRepository) {
      final weekly = ref.read(weeklyQuestsProvider).value;
      if (weekly?.quests.any((quest) => quest.id == id) == true) {
        await ref.read(weeklyQuestsProvider.notifier).claim(id);
        return;
      }
    }
    final before = state.value;
    if (before == null) return;
    final requestVersion = _requestVersion;
    state = AsyncData(
      TodayQuests(
        date: before.date,
        resetsAt: before.resetsAt,
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
          resetsAt: current.resetsAt,
          quests: quests,
          allClaimedBonusXp: current.allClaimedBonusXp,
        ),
      );
      _refreshQuestData(ref, today: false);
      ref.invalidateSelf();
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

class WeeklyQuestsNotifier extends AsyncNotifier<WeeklyQuests> {
  int _requestVersion = 0;

  @override
  Future<WeeklyQuests> build() async {
    watchCurrentUserId(ref);
    _requestVersion++;
    return ref.watch(weeklyQuestsRepositoryProvider).week();
  }

  Future<void> refresh() async {
    final requestVersion = _requestVersion;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(weeklyQuestsRepositoryProvider).week();
    });
    if (requestVersion == _requestVersion) state = result;
  }

  Future<void> claim(String id) async {
    final before = state.value;
    if (before == null) return;
    final requestVersion = _requestVersion;
    state = AsyncData(
      _copyWeekly(
        before,
        quests: before.quests
            .map(
              (quest) => quest.id == id
                  ? WeeklyQuest(
                      id: quest.id,
                      type: quest.type,
                      title: quest.title,
                      titleKm: quest.titleKm,
                      target: quest.target,
                      progress: quest.progress,
                      xpReward: quest.xpReward,
                      completed: quest.completed,
                      claimed: true,
                    )
                  : quest,
            )
            .toList(growable: false),
      ),
    );
    try {
      final claimed = await ref
          .read(weeklyQuestsRepositoryProvider)
          .claimWeekly(id);
      if (requestVersion != _requestVersion) return;
      final current = state.value ?? before;
      state = AsyncData(
        _copyWeekly(
          current,
          quests: current.quests
              .map((quest) => quest.id == id ? claimed : quest)
              .toList(growable: false),
        ),
      );
      _refreshQuestData(ref, week: false);
      ref.invalidateSelf();
    } catch (_) {
      if (requestVersion == _requestVersion) state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> openChest() async {
    final before = state.value;
    if (before == null || !before.chest.openable) return;
    final requestVersion = _requestVersion;
    final optimistic = WeeklyChest(
      id: before.chest.id,
      points: before.chest.points,
      target: before.chest.target,
      maxPoints: before.chest.maxPoints,
      opened: true,
      xpReward: before.chest.xpReward,
      rewardItem: before.chest.rewardItem,
    );
    state = AsyncData(_copyWeekly(before, chest: optimistic));
    try {
      final opened = await ref.read(weeklyQuestsRepositoryProvider).openChest();
      if (requestVersion != _requestVersion) return;
      final current = state.value ?? before;
      state = AsyncData(_copyWeekly(current, chest: opened));
      _refreshQuestData(ref, week: false);
      ref.invalidateSelf();
    } catch (_) {
      if (requestVersion == _requestVersion) state = AsyncData(before);
      rethrow;
    }
  }
}

final weeklyQuestsProvider =
    AsyncNotifierProvider<WeeklyQuestsNotifier, WeeklyQuests>(
      WeeklyQuestsNotifier.new,
    );

WeeklyQuests _copyWeekly(
  WeeklyQuests source, {
  List<WeeklyQuest>? quests,
  WeeklyChest? chest,
}) => WeeklyQuests(
  weekStart: source.weekStart,
  resetsAt: source.resetsAt,
  quests: quests ?? source.quests,
  chest: chest ?? source.chest,
);

/// A notifier cannot invalidate itself through [Ref.invalidate]; callers pass
/// false for their own provider and call `ref.invalidateSelf()` instead.
void _refreshQuestData(Ref ref, {bool today = true, bool week = true}) {
  if (today) ref.invalidate(todayQuestsProvider);
  if (week) ref.invalidate(weeklyQuestsProvider);
  ref.invalidate(profileDashboardProvider);
}
