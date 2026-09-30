import 'dart:math' as math;

import 'mascot.dart';

/// An action that restores energy and strengthens the learner's bond.
enum BuddyCareSource {
  lesson('LESSON', energyGain: 35, bondGain: 10),
  blogRead('BLOG_READ', energyGain: 10, bondGain: 3, dailyCap: 2),
  post('POST', energyGain: 10, bondGain: 3, dailyCap: 1),
  blogPublished('BLOG_PUBLISHED', energyGain: 20, bondGain: 8, dailyCap: 1);

  const BuddyCareSource(
    this.key, {
    required this.energyGain,
    required this.bondGain,
    this.dailyCap,
  });

  final String key;
  final int energyGain;
  final int bondGain;
  final int? dailyCap;

  static BuddyCareSource? fromKey(String key) => BuddyCareSource.values
      .where((source) => source.key == key.toUpperCase())
      .firstOrNull;
}

enum BuddyVitality { lively, steady, sleepy, napping }

/// Care points are separate from XP. Timestamps and daily counts follow the
/// server's Asia/Phnom_Penh care day so guest progress can be merged safely.
class BuddyCare {
  const BuddyCare({
    required this.energy,
    required this.bond,
    required this.updatedAt,
    this.careDay = '',
    this.dailyCounts = const {},
    this.lessonBondAwardsToday = 0,
    this.appliedSourceIds = const {},
  });

  factory BuddyCare.initial(DateTime now) => BuddyCare(
    energy: 60,
    bond: 0,
    updatedAt: now,
    careDay: phnomPenhCareDay(now),
  );

  final int energy;
  final int bond;
  final DateTime updatedAt;
  final String careDay;
  final Map<BuddyCareSource, int> dailyCounts;
  final int lessonBondAwardsToday;

  /// IDs prevent duplicate local reactions while the server request is in
  /// flight. The server remains the durable idempotency authority.
  final Set<String> appliedSourceIds;

  int get bondLevel => 1 + math.sqrt(bond / 15).floor();

  BuddyVitality get vitality => switch (energy) {
    >= 70 => BuddyVitality.lively,
    >= 35 => BuddyVitality.steady,
    >= 1 => BuddyVitality.sleepy,
    _ => BuddyVitality.napping,
  };

  BuddyCare settle(DateTime now) {
    final elapsedMinutes = math
        .max(0, now.difference(updatedAt).inMinutes)
        .toInt();
    final decay = elapsedMinutes ~/ 72;
    return copyWith(
      energy: (energy - decay).clamp(0, 100).toInt(),
      updatedAt: now,
      careDay: phnomPenhCareDay(now),
      dailyCounts: _countsForDay(now),
      lessonBondAwardsToday: _isSameCareDay(now) ? lessonBondAwardsToday : 0,
      appliedSourceIds: _isSameCareDay(now) ? appliedSourceIds : const {},
    );
  }

  BuddyCare gain(BuddyCareSource source, DateTime now, {String? sourceId}) {
    final current = settle(now);
    if (sourceId != null &&
        current.appliedSourceIds.contains('${source.key}:$sourceId')) {
      return current;
    }
    final count = current.dailyCounts[source] ?? 0;
    if (source.dailyCap case final cap? when count >= cap) return current;

    final awardsLessonBond =
        source == BuddyCareSource.lesson &&
        current.lessonBondAwardsToday < maxDailyLessonBondAwards;
    final counts = Map<BuddyCareSource, int>.of(current.dailyCounts)
      ..[source] = count + 1;
    return current.copyWith(
      energy: (current.energy + source.energyGain).clamp(0, 100).toInt(),
      bond:
          current.bond +
          (source != BuddyCareSource.lesson || awardsLessonBond
              ? source.bondGain
              : 0),
      dailyCounts: counts,
      lessonBondAwardsToday: awardsLessonBond
          ? current.lessonBondAwardsToday + 1
          : current.lessonBondAwardsToday,
      appliedSourceIds: sourceId == null
          ? current.appliedSourceIds
          : {...current.appliedSourceIds, '${source.key}:$sourceId'},
    );
  }

  static const maxDailyLessonBondAwards = 5;

  int countFor(BuddyCareSource source, DateTime now) =>
      _isSameCareDay(now) ? dailyCounts[source] ?? 0 : 0;

  Map<BuddyCareSource, int> _countsForDay(DateTime now) =>
      _isSameCareDay(now) ? dailyCounts : const {};

  bool _isSameCareDay(DateTime now) =>
      careDay.isNotEmpty && careDay == phnomPenhCareDay(now);

  BuddyCare copyWith({
    int? energy,
    int? bond,
    DateTime? updatedAt,
    String? careDay,
    Map<BuddyCareSource, int>? dailyCounts,
    int? lessonBondAwardsToday,
    Set<String>? appliedSourceIds,
  }) => BuddyCare(
    energy: energy ?? this.energy,
    bond: bond ?? this.bond,
    updatedAt: updatedAt ?? this.updatedAt,
    careDay: careDay ?? this.careDay,
    dailyCounts: dailyCounts ?? this.dailyCounts,
    lessonBondAwardsToday: lessonBondAwardsToday ?? this.lessonBondAwardsToday,
    appliedSourceIds: appliedSourceIds ?? this.appliedSourceIds,
  );

  Map<String, Object?> toJson() => {
    'energy': energy,
    'bond': bond,
    'updatedAt': updatedAt.toIso8601String(),
    'careDay': careDay,
    'dailyCounts': {
      for (final entry in dailyCounts.entries) entry.key.key: entry.value,
    },
    'lessonBondAwardsToday': lessonBondAwardsToday,
    'appliedSourceIds': appliedSourceIds.toList(),
  };

  factory BuddyCare.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final rawCounts = json['dailyCounts'];
    final counts = <BuddyCareSource, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final source = BuddyCareSource.fromKey(entry.key.toString());
        final count = entry.value;
        if (source != null && count is num) counts[source] = count.toInt();
      }
    }
    return BuddyCare(
      energy: (json['energy'] as num?)?.toInt().clamp(0, 100).toInt() ?? 60,
      bond: (json['bond'] as num?)?.toInt().clamp(0, 0x7fffffff).toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
      careDay: json['careDay']?.toString() ?? '',
      dailyCounts: counts,
      lessonBondAwardsToday:
          (json['lessonBondAwardsToday'] as num?)
              ?.toInt()
              .clamp(0, 5)
              .toInt() ??
          (counts[BuddyCareSource.lesson] ?? 0).clamp(0, 5).toInt(),
      appliedSourceIds: (json['appliedSourceIds'] as List? ?? const [])
          .map((id) => id.toString())
          .toSet(),
    ).settle(now);
  }
}

/// Fixed UTC+7 day boundary used by the backend and by guest care records.
String phnomPenhCareDay(DateTime dateTime) {
  final local = dateTime.toUtc().add(const Duration(hours: 7));
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

MascotMood moodFor(BuddyVitality vitality) => switch (vitality) {
  BuddyVitality.lively => MascotMood.happy,
  BuddyVitality.steady || BuddyVitality.sleepy => MascotMood.idle,
  BuddyVitality.napping => MascotMood.sleep,
};

MascotFace faceFor(BuddyVitality vitality) => switch (vitality) {
  BuddyVitality.lively => MascotFace.happy,
  BuddyVitality.steady => MascotFace.neutral,
  BuddyVitality.sleepy || BuddyVitality.napping => MascotFace.sleepy,
};
