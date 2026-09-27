import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pixel_fire_icon.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/social_models.dart';

Future<void> showStreakDetailsSheet(
  BuildContext context,
  CommunityStreak streak,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: false,
  showDragHandle: true,
  backgroundColor: Colors.transparent,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) => SizedBox(
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.riksa.surface.withValues(alpha: .94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: .42)),
      ),
      child: StreakDetailsSheet(streak: streak),
    ),
  ),
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
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.streakTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
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
                    kind: _StreakMetricKind.current,
                    value: streak.current,
                    label: l10n.currentStreak,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StreakMetric(
                    kind: _StreakMetricKind.best,
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
                fontWeight: FontWeight.w700,
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
    final palette = context.riksa;
    final background = active
        ? palette.brand
        : missedToday
        ? AppColors.gamificationOrange
        : future
        ? Colors.white.withValues(alpha: .42)
        : palette.surfaceRaised;
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
            border: Border.all(
              color: active || missedToday
                  ? Colors.white.withValues(alpha: .36)
                  : colors.outlineVariant,
            ),
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

enum _StreakMetricKind { current, best }

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({
    required this.kind,
    required this.value,
    required this.label,
  });

  final _StreakMetricKind kind;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => _GlassStreakCard(
    padding: const EdgeInsets.all(15),
    child: Column(
      children: [
        kind == _StreakMetricKind.current
            ? const PixelFireIcon(size: 34)
            : const Icon(
                Icons.star_rounded,
                size: 35,
                color: AppColors.gamificationGold,
              ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: context.riksa.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.riksa.inkMuted,
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
    return _GlassStreakCard(
      key: const ValueKey('streak-last-tracked'),
      padding: const EdgeInsets.all(16),
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
                    fontWeight: FontWeight.w600,
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
    return _GlassStreakCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.gamificationOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${streak.daysToNext} • ${streak.nextMilestoneName}',
              style: TextStyle(
                color: context.riksa.ink,
                fontWeight: FontWeight.w600,
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
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final gridEnd = lastDayOfMonth.add(
      Duration(days: DateTime.daysPerWeek - lastDayOfMonth.weekday),
    );
    final gridStart = gridEnd.subtract(
      const Duration(days: DateTime.daysPerWeek * 11 + 6),
    );
    final weekCount = gridEnd.difference(gridStart).inDays ~/ 7 + 1;
    final weekdays = [
      ...material.narrowWeekdays.skip(1),
      material.narrowWeekdays.first,
    ];
    final firstVisibleMonth = DateTime(gridStart.year, gridStart.month);
    final visibleMonths = [
      for (var index = 0; index < 4; index++)
        DateTime(firstVisibleMonth.year, firstVisibleMonth.month + index),
    ].where((date) => !date.isAfter(gridEnd)).toList();
    final activeInRange = activeDates
        .where((date) => !date.isBefore(gridStart) && !date.isAfter(gridEnd))
        .length;

    return _GlassStreakCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Activity history',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$activeInRange active',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.riksa.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 26),
            child: Row(
              children: [
                for (final visibleMonth in visibleMonths)
                  Expanded(
                    child: Text(
                      material.formatMonthYear(visibleMonth).split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.riksa.inkMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) {
              const labelWidth = 18.0;
              const labelGap = 8.0;
              final gridWidth = constraints.maxWidth - labelWidth - labelGap;
              final gap = weekCount > 10 ? 3.0 : 5.0;
              final cellSize = ((gridWidth - (weekCount - 1) * gap) / weekCount)
                  .clamp(10.0, 16.0);
              const bottomGap = 3.0;
              final rowHeight = cellSize + bottomGap;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Column(
                      children: [
                        for (var row = 0; row < DateTime.daysPerWeek; row++)
                          SizedBox(
                            height: rowHeight,
                            child: row.isEven
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      weekdays[row],
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: labelGap),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var week = 0; week < weekCount; week++)
                          Column(
                            children: [
                              for (
                                var day = 0;
                                day < DateTime.daysPerWeek;
                                day++
                              )
                                Builder(
                                  builder: (context) {
                                    final date = gridStart.add(
                                      Duration(days: week * 7 + day),
                                    );
                                    return _ContributionCell(
                                      date: date,
                                      size: cellSize,
                                      bottomGap: bottomGap,
                                      isToday: date == today,
                                      isActive: activeDates.contains(date),
                                      isLastTracked:
                                          lastTrackedDate != null &&
                                          date == _day(lastTrackedDate!),
                                    );
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _ContributionLegend(
            activeColor: AppColors.success,
            quietColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

class _ContributionCell extends StatelessWidget {
  const _ContributionCell({
    required this.date,
    required this.size,
    required this.bottomGap,
    required this.isToday,
    required this.isActive,
    required this.isLastTracked,
  });

  final DateTime date;
  final double size;
  final double bottomGap;
  final bool isToday;
  final bool isActive;
  final bool isLastTracked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.riksa;
    final color = isActive
        ? AppColors.success
        : isToday
        ? palette.brand.withValues(alpha: .55)
        : colors.surfaceContainerHighest.withValues(alpha: .72);

    return Tooltip(
      message:
          '${MaterialLocalizations.of(context).formatShortDate(date)}'
          '${isActive ? ' • active' : ''}',
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.only(bottom: bottomGap),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isLastTracked
                ? AppColors.gamificationOrange
                : isToday
                ? palette.brand
                : Colors.white.withValues(alpha: .42),
            width: isLastTracked || isToday ? 1.4 : .7,
          ),
        ),
      ),
    );
  }
}

class _ContributionLegend extends StatelessWidget {
  const _ContributionLegend({
    required this.activeColor,
    required this.quietColor,
  });

  final Color activeColor;
  final Color quietColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: context.riksa.inkMuted,
      fontWeight: FontWeight.w700,
    );
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(l10n.heatmapLess, style: style),
        const SizedBox(width: 6),
        for (final color in [
          quietColor.withValues(alpha: .72),
          Color.lerp(quietColor, activeColor, .32)!,
          Color.lerp(quietColor, activeColor, .62)!,
          activeColor,
        ])
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsetsDirectional.only(end: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white.withValues(alpha: .38)),
            ),
          ),
        const SizedBox(width: 2),
        Text(l10n.heatmapMore, style: style),
      ],
    );
  }
}

class _GlassStreakCard extends StatelessWidget {
  const _GlassStreakCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? palette.surface.withValues(alpha: .46)
        : Colors.white.withValues(alpha: .58);
    final border = isDark
        ? Colors.white.withValues(alpha: .12)
        : Colors.white.withValues(alpha: .72);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.mediumBorder,
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: isDark ? .16 : .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppRadii.mediumBorder,
          border: Border.all(color: border),
        ),
        child: child,
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
