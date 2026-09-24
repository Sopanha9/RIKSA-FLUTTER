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

  factory DailyQuest.preview(DailyQuestType type, {required String title}) =>
      DailyQuest(
        id: '',
        type: type,
        title: title,
        titleKm: '',
        target: switch (type) {
          DailyQuestType.completeLesson => 1,
          DailyQuestType.correctAnswers => 3,
          DailyQuestType.socialAction => 1,
        },
        progress: 0,
        xpReward: switch (type) {
          DailyQuestType.completeLesson => 20,
          DailyQuestType.correctAnswers => 15,
          DailyQuestType.socialAction => 10,
        },
        completed: false,
        claimed: false,
      );
}

class TodayQuests {
  const TodayQuests({
    required this.date,
    required this.quests,
    required this.allClaimedBonusXp,
  });

  final DateTime? date;
  final List<DailyQuest> quests;
  final int allClaimedBonusXp;

  factory TodayQuests.fromJson(Map<String, dynamic> json) => TodayQuests(
    date: DateTime.tryParse(json['date']?.toString() ?? ''),
    quests: (json['quests'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => DailyQuest.fromJson(row.cast<String, dynamic>()))
        .toList(growable: false),
    allClaimedBonusXp: (json['allClaimedBonusXp'] as num?)?.toInt() ?? 0,
  );

  int get claimableCount => quests.where((quest) => quest.claimable).length;
  bool get allClaimed =>
      quests.isNotEmpty && quests.every((quest) => quest.claimed);

  static TodayQuests guestPreview({required List<String> titles}) =>
      TodayQuests(
        date: null,
        allClaimedBonusXp: 30,
        quests: [
          DailyQuest.preview(DailyQuestType.completeLesson, title: titles[0]),
          DailyQuest.preview(DailyQuestType.correctAnswers, title: titles[1]),
          DailyQuest.preview(DailyQuestType.socialAction, title: titles[2]),
        ],
      );
}
