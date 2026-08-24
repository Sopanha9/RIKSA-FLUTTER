import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/social_models.dart';

Future<void> showStreakDetailsSheet(
  BuildContext context,
  CommunityStreak streak,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) => StreakDetailsSheet(streak: streak),
);

class StreakDetailsSheet extends StatelessWidget {
  const StreakDetailsSheet({super.key, required this.streak});

  final CommunityStreak streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final today = _day(DateTime.now());
    final activityDates = _activityDates(streak);
    final calendarMonth = _day(streak.lastTrackedDate ?? today);

    return ConstrainedBox(
      key: const ValueKey('streak-details-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.streakTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.streakSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            _RecentWeek(today: today, activeDates: activityDates),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StreakMetric(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.gamificationOrange,
                    background: AppColors.gamificationOrangeSoft,
                    value: streak.current,
                    label: l10n.currentStreak,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StreakMetric(
                    icon: Icons.star_rounded,
                    iconColor: AppColors.gamificationGold,
                    background: AppColors.gamificationGoldSoft,
                    value: streak.highest,
                    label: l10n.bestStreak,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LastTrackedCard(lastTrackedDate: streak.lastTrackedDate),
            if (streak.nextMilestoneName != null) ...[
              const SizedBox(height: 12),
              _MilestoneCard(streak: streak),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.activityCalendar,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _ActivityCalendar(
              month: calendarMonth,
              today: today,
              activeDates: activityDates,
              lastTrackedDate: streak.lastTrackedDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentWeek extends StatelessWidget {
  const _RecentWeek({required this.today, required this.activeDates});

  final DateTime today;
  final Set<DateTime> activeDates;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final weekdays = [
      ...material.narrowWeekdays.skip(1),
      material.narrowWeekdays.first,
    ];
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Row(
      children: [
        for (var index = 0; index < 7; index++)
          Expanded(
            child: _DayStatus(
              label: weekdays[index],
              date: monday.add(Duration(days: index)),
              today: today,
              active: activeDates.contains(monday.add(Duration(days: index))),
            ),
          ),
      ],
    );
  }
}

class _DayStatus extends StatelessWidget {
  const _DayStatus({
    required this.label,
    required this.date,
    required this.today,
    required this.active,
  });

  final String label;
  final DateTime date;
  final DateTime today;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final future = date.isAfter(today);
    final missedToday = date == today && !active;
    final colors = Theme.of(context).colorScheme;
    final background = active
        ? AppColors.success
        : missedToday
        ? AppColors.gamificationOrange
        : future
        ? Colors.transparent
        : colors.surfaceContainerHighest;
    final foreground = active || missedToday
        ? Colors.white
        : colors.onSurfaceVariant;

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: future ? Border.all(color: colors.outlineVariant) : null,
          ),
          alignment: Alignment.center,
          child: active
              ? Icon(Icons.check_rounded, size: 21, color: foreground)
              : missedToday
              ? Icon(Icons.priority_high_rounded, size: 20, color: foreground)
              : Text(
                  '${date.day}',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppRadii.mediumBorder,
    ),
    child: Column(
      children: [
        Icon(icon, size: 40, color: iconColor),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.neutralInk,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.neutralInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _LastTrackedCard extends StatelessWidget {
  const _LastTrackedCard({required this.lastTrackedDate});

  final DateTime? lastTrackedDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('streak-last-tracked'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.gamificationOrangeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.gamificationOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lastTracked,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastTrackedDate == null
                      ? l10n.noTrackedDate
                      : MaterialLocalizations.of(
                          context,
                        ).formatShortDate(lastTrackedDate!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.streak});

  final CommunityStreak streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.gamificationOrangeSoft,
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.gamificationOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${streak.daysToNext} • ${streak.nextMilestoneName}',
              style: const TextStyle(
                color: AppColors.neutralInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCalendar extends StatelessWidget {
  const _ActivityCalendar({
    required this.month,
    required this.today,
    required this.activeDates,
    required this.lastTrackedDate,
  });

  final DateTime month;
  final DateTime today;
  final Set<DateTime> activeDates;
  final DateTime? lastTrackedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final material = MaterialLocalizations.of(context);
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final weekdays = [
      ...material.narrowWeekdays.skip(1),
      material.narrowWeekdays.first,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Text(
            material.formatMonthYear(month),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final weekday in weekdays)
                Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 44,
            ),
            itemCount: cells,
            itemBuilder: (context, index) {
              final dayNumber = index - offset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(month.year, month.month, dayNumber);
              return _CalendarDay(
                date: date,
                isToday: date == today,
                isActive: activeDates.contains(date),
                isLastTracked:
                    lastTrackedDate != null && date == _day(lastTrackedDate!),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.isToday,
    required this.isActive,
    required this.isLastTracked,
  });

  final DateTime date;
  final bool isToday;
  final bool isActive;
  final bool isLastTracked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: isToday ? AppColors.neutralInk : Colors.transparent,
        borderRadius: AppRadii.smallBorder,
        border: isLastTracked && !isToday
            ? Border.all(color: AppColors.gamificationOrange, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              color: isToday ? Colors.white : colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.success
                  : isToday
                  ? Colors.white24
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

Set<DateTime> _activityDates(CommunityStreak streak) {
  final result = (streak.activityDates ?? const <DateTime>[]).map(_day).toSet();
  final lastTrackedDate = streak.lastTrackedDate;
  if (result.isEmpty && lastTrackedDate != null && streak.current > 0) {
    final end = _day(lastTrackedDate);
    for (var offset = 0; offset < streak.current; offset++) {
      result.add(end.subtract(Duration(days: offset)));
    }
  }
  return result;
}

DateTime _day(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}
