enum DailyQuestType { completeLesson, correctAnswers, socialAction }

DailyQuestType dailyQuestTypeFromJson(Object? value) => switch (value) {
  'COMPLETE_LESSON' => DailyQuestType.completeLesson,
  'CORRECT_ANSWERS' => DailyQuestType.correctAnswers,
  'SOCIAL_ACTION' => DailyQuestType.socialAction,
  _ => DailyQuestType.completeLesson,
};

String dailyQuestTypeToJson(DailyQuestType value) => switch (value) {
  DailyQuestType.completeLesson => 'COMPLETE_LESSON',
  DailyQuestType.correctAnswers => 'CORRECT_ANSWERS',
  DailyQuestType.socialAction => 'SOCIAL_ACTION',
};

int _dailyTarget(DailyQuestType type) => switch (type) {
  DailyQuestType.completeLesson => 1,
  DailyQuestType.correctAnswers => 3,
  DailyQuestType.socialAction => 1,
};

class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.titleKm,
    required this.target,
    required this.progress,
    required this.xpReward,
    required this.completed,
    required this.claimed,
  });

  final String id;
  final DailyQuestType type;
  final String title;
  final String titleKm;
  final int target;
  final int progress;
  final int xpReward;
  final bool completed;
  final bool claimed;

  bool get claimable => completed && !claimed;

  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
    id: json['id']?.toString() ?? '',
    type: dailyQuestTypeFromJson(json['type']),
    title: json['title'] as String? ?? '',
    titleKm: json['titleKm'] as String? ?? '',
    target: (json['target'] as num?)?.toInt() ?? 1,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
    completed: json['completed'] as bool? ?? false,
    claimed: json['claimed'] as bool? ?? false,
  );

  factory DailyQuest.preview(
    DailyQuestType type, {
    required String title,
    bool completed = false,
  }) => DailyQuest(
    id: '',
    type: type,
    title: title,
    titleKm: '',
    target: _dailyTarget(type),
    progress: completed ? _dailyTarget(type) : 0,
    xpReward: switch (type) {
      DailyQuestType.completeLesson => 20,
      DailyQuestType.correctAnswers => 15,
      DailyQuestType.socialAction => 10,
    },
    completed: completed,
    claimed: false,
  );
}

class TodayQuests {
  const TodayQuests({
    required this.date,
    this.resetsAt,
    required this.quests,
    required this.allClaimedBonusXp,
  });

  final DateTime? date;
  final DateTime? resetsAt;
  final List<DailyQuest> quests;
  final int allClaimedBonusXp;

  factory TodayQuests.fromJson(Map<String, dynamic> json) => TodayQuests(
    date: DateTime.tryParse(json['date']?.toString() ?? ''),
    resetsAt: DateTime.tryParse(json['resetsAt']?.toString() ?? ''),
    quests: (json['quests'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => DailyQuest.fromJson(row.cast<String, dynamic>()))
        .toList(growable: false),
    allClaimedBonusXp: (json['allClaimedBonusXp'] as num?)?.toInt() ?? 0,
  );

  int get claimableCount => quests.where((quest) => quest.claimable).length;
  bool get allClaimed =>
      quests.isNotEmpty && quests.every((quest) => quest.claimed);

  static TodayQuests guestPreview({
    required List<String> titles,
    bool showLockedActions = true,
  }) => TodayQuests(
    date: null,
    resetsAt: null,
    allClaimedBonusXp: 30,
    quests: [
      DailyQuest.preview(
        DailyQuestType.completeLesson,
        title: titles[0],
        completed: showLockedActions,
      ),
      DailyQuest.preview(DailyQuestType.correctAnswers, title: titles[1]),
      DailyQuest.preview(DailyQuestType.socialAction, title: titles[2]),
    ],
  );
}

enum WeeklyQuestType { lessons, correctAnswers, activeDays, social }

WeeklyQuestType weeklyQuestTypeFromJson(Object? value) => switch (value) {
  'WEEKLY_LESSONS' => WeeklyQuestType.lessons,
  'WEEKLY_CORRECT_ANSWERS' => WeeklyQuestType.correctAnswers,
  'WEEKLY_ACTIVE_DAYS' => WeeklyQuestType.activeDays,
  'WEEKLY_SOCIAL' => WeeklyQuestType.social,
  _ => WeeklyQuestType.lessons,
};

String weeklyQuestTypeToJson(WeeklyQuestType value) => switch (value) {
  WeeklyQuestType.lessons => 'WEEKLY_LESSONS',
  WeeklyQuestType.correctAnswers => 'WEEKLY_CORRECT_ANSWERS',
  WeeklyQuestType.activeDays => 'WEEKLY_ACTIVE_DAYS',
  WeeklyQuestType.social => 'WEEKLY_SOCIAL',
};

class WeeklyQuest {
  const WeeklyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.titleKm,
    required this.target,
    required this.progress,
    required this.xpReward,
    required this.completed,
    required this.claimed,
  });

  final String id;
  final WeeklyQuestType type;
  final String title;
  final String titleKm;
  final int target;
  final int progress;
  final int xpReward;
  final bool completed;
  final bool claimed;

  bool get claimable => completed && !claimed;

  factory WeeklyQuest.fromJson(Map<String, dynamic> json) => WeeklyQuest(
    id: json['id']?.toString() ?? '',
    type: weeklyQuestTypeFromJson(json['type']),
    title: json['title'] as String? ?? '',
    titleKm: json['titleKm'] as String? ?? '',
    target: (json['target'] as num?)?.toInt() ?? 1,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
    completed: json['completed'] as bool? ?? false,
    claimed: json['claimed'] as bool? ?? false,
  );
}

class WeeklyRewardItem {
  const WeeklyRewardItem({
    required this.id,
    required this.slot,
    required this.assetKey,
    required this.name,
    required this.nameKm,
  });

  final String id;
  final String slot;
  final String assetKey;
  final String name;
  final String nameKm;

  factory WeeklyRewardItem.fromJson(Map<String, dynamic> json) =>
      WeeklyRewardItem(
        id: json['id']?.toString() ?? '',
        slot: json['slot'] as String? ?? '',
        assetKey: json['assetKey'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nameKm: json['nameKm'] as String? ?? '',
      );
}

class WeeklyChest {
  const WeeklyChest({
    required this.id,
    required this.points,
    required this.target,
    required this.maxPoints,
    required this.opened,
    required this.xpReward,
    this.rewardItem,
  });

  final String id;
  final int points;
  final int target;
  final int maxPoints;
  final bool opened;
  final int xpReward;
  final WeeklyRewardItem? rewardItem;

  bool get openable => !opened && points >= target;

  factory WeeklyChest.fromJson(Map<String, dynamic> json) => WeeklyChest(
    id: json['id']?.toString() ?? '',
    points: (json['points'] as num?)?.toInt() ?? 0,
    target: (json['target'] as num?)?.toInt() ?? 0,
    maxPoints: (json['maxPoints'] as num?)?.toInt() ?? 0,
    opened: json['opened'] as bool? ?? false,
    xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
    rewardItem: json['rewardItem'] is Map
        ? WeeklyRewardItem.fromJson(
            (json['rewardItem'] as Map).cast<String, dynamic>(),
          )
        : null,
  );
}

class WeeklyQuests {
  const WeeklyQuests({
    required this.weekStart,
    required this.resetsAt,
    required this.quests,
    required this.chest,
  });

  final DateTime? weekStart;
  final DateTime? resetsAt;
  final List<WeeklyQuest> quests;
  final WeeklyChest chest;

  int get claimableCount => quests.where((quest) => quest.claimable).length;

  factory WeeklyQuests.fromJson(Map<String, dynamic> json) => WeeklyQuests(
    weekStart: DateTime.tryParse(json['weekStart']?.toString() ?? ''),
    resetsAt: DateTime.tryParse(json['resetsAt']?.toString() ?? ''),
    quests: (json['quests'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => WeeklyQuest.fromJson(row.cast<String, dynamic>()))
        .toList(growable: false),
    chest: json['chest'] is Map
        ? WeeklyChest.fromJson((json['chest'] as Map).cast<String, dynamic>())
        : const WeeklyChest(
            id: '',
            points: 0,
            target: 0,
            maxPoints: 0,
            opened: false,
            xpReward: 0,
          ),
  );

  static WeeklyQuests guestPreview({
    required List<String> titles,
    bool showLockedActions = true,
  }) => WeeklyQuests(
    weekStart: null,
    resetsAt: null,
    quests: [
      WeeklyQuest(
        id: '',
        type: WeeklyQuestType.lessons,
        title: titles[0],
        titleKm: '',
        target: 5,
        progress: showLockedActions ? 5 : 2,
        xpReward: 35,
        completed: showLockedActions,
        claimed: false,
      ),
      WeeklyQuest(
        id: '',
        type: WeeklyQuestType.correctAnswers,
        title: titles[1],
        titleKm: '',
        target: 15,
        progress: 4,
        xpReward: 30,
        completed: false,
        claimed: false,
      ),
      WeeklyQuest(
        id: '',
        type: WeeklyQuestType.activeDays,
        title: titles[2],
        titleKm: '',
        target: 5,
        progress: 2,
        xpReward: 40,
        completed: false,
        claimed: false,
      ),
      WeeklyQuest(
        id: '',
        type: WeeklyQuestType.social,
        title: titles[3],
        titleKm: '',
        target: 3,
        progress: 1,
        xpReward: 25,
        completed: false,
        claimed: false,
      ),
    ],
    chest: WeeklyChest(
      id: '',
      points: showLockedActions ? 15 : 7,
      target: 15,
      maxPoints: 15,
      opened: false,
      xpReward: 50,
    ),
  );
}
