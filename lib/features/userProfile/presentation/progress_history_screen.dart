import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_glass.dart';
import '../../../core/widgets/riksa_rank_badge.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../data/profile_models.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_ui.dart';

/// Names an XP source in the learner's language.
///
/// The backend sends screaming snake case (`LESSON`, `STREAK_BONUS`). Showing
/// that raw, even tidied up, leaves English inside a Khmer screen, so known
/// values are mapped and anything new falls back to a readable form of the
/// code rather than an empty row.
String xpSourceLabel(
  AppLocalizations l10n,
  String sourceType,
) => switch (sourceType.toUpperCase()) {
  'LESSON' || 'LESSON_COMPLETE' || 'LESSON_COMPLETION' => l10n.xpSourceLesson,
  'EXERCISE' || 'EXERCISE_CORRECT' => l10n.xpSourceExercise,
  'ACHIEVEMENT' || 'ACHIEVEMENT_UNLOCK' => l10n.xpSourceAchievement,
  'STREAK' || 'STREAK_BONUS' => l10n.xpSourceStreak,
  'XP_REWARD' || 'REWARD' => l10n.xpSourceReward,
  'QUEST' => l10n.xpSourceDailyQuest,
  'QUEST_BONUS' => l10n.xpSourceQuestBonus,
  'WEEKLY_QUEST' => l10n.xpSourceWeeklyQuest,
  'QUEST_CHEST' => l10n.xpSourceChest,
  'SETUP_TASK' => l10n.xpSourceSetup,
  'RESOURCE_SAVED' => l10n.xpSourceResourceSaved,
  'ADMIN_ADJUST' => l10n.xpSourceAdmin,
  _ =>
    sourceType
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' '),
};

/// An icon and colour per XP source, so a glance tells lessons from quests.
(IconData, Color) xpSourceStyle(String sourceType) =>
    switch (sourceType.toUpperCase()) {
      'LESSON' ||
      'LESSON_COMPLETE' ||
      'LESSON_COMPLETION' => (Icons.menu_book_rounded, const Color(0xFF3B82F6)),
      'EXERCISE' || 'EXERCISE_CORRECT' => (
        Icons.check_circle_rounded,
        const Color(0xFF22C55E),
      ),
      'ACHIEVEMENT' || 'ACHIEVEMENT_UNLOCK' => (
        Icons.emoji_events_rounded,
        const Color(0xFFF59E0B),
      ),
      'STREAK' || 'STREAK_BONUS' => (
        Icons.local_fire_department_rounded,
        const Color(0xFFF97316),
      ),
      'QUEST' ||
      'WEEKLY_QUEST' ||
      'QUEST_BONUS' => (Icons.flag_rounded, const Color(0xFF8B5CF6)),
      'QUEST_CHEST' => (Icons.inventory_2_rounded, const Color(0xFFD97706)),
      'SETUP_TASK' => (Icons.rocket_launch_rounded, const Color(0xFF14B8A6)),
      'RESOURCE_SAVED' => (Icons.bookmark_rounded, const Color(0xFFEC4899)),
      _ => (Icons.bolt_rounded, const Color(0xFFEAB308)),
    };

/// Names a leaderboard scope in the learner's language.
String rankScopeLabel(AppLocalizations l10n, String scope) =>
    switch (scope.toUpperCase()) {
      'PROVINCE' => l10n.leaderboardProvince,
      'COUNTRY' || 'GLOBAL' || 'NATIONAL' => l10n.leaderboardNational,
      _ => scope.replaceAll('_', ' '),
    };

class ProgressHistoryScreen extends ConsumerWidget {
  const ProgressHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.riksa.rewardSoft,
          leading: const Center(
            child: RiksaBackButton(fallbackLocation: '/profile'),
          ),
          title: Text(l10n.progressHistoryTitle),
          // His glass tab strip, driven by the same DefaultTabController.
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: _ProgressSectionTabs(),
          ),
        ),
        backgroundColor: context.riksa.canvas,
        body: TabBarView(
          children: [
            _XpHistory(ref: ref),
            _RankHistory(ref: ref),
          ],
        ),
      ),
    );
  }
}

/// A failure the learner can act on, rather than a sentence they can only read.
class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IllustratedEmptyState(
      key: const ValueKey('progress-history-error'),
      title: message,
      body: l10n.loadFailedCheckConnection,
      actionLabel: l10n.tryAgain,
      onAction: onRetry,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context)!.loading,
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _XpHistory extends StatelessWidget {
  const _XpHistory({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(xpHistoryProvider)
        .when(
          loading: () => const _Loading(),
          error: (_, _) => _HistoryError(
            message: l10n.progressHistoryXpFailed,
            onRetry: () => ref.invalidate(xpHistoryProvider),
          ),
          data: (items) => items.isEmpty
              ? IllustratedEmptyState(
                  title: l10n.progressHistoryXpEmptyTitle,
                  body: l10n.progressHistoryXpEmptyBody,
                )
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(xpHistoryProvider.future),
                  child: _XpList(items: items),
                ),
        );
  }
}

class _XpList extends StatelessWidget {
  const _XpList({required this.items});

  final List<XpActivity> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String dayLabel(DateTime day) {
      final difference = today.difference(day).inDays;
      if (difference == 0) return l10n.progressHistoryToday;
      if (difference == 1) return l10n.progressHistoryYesterday;
      return DateFormat.MMMEd(locale).format(day);
    }

    // Newest first, with a header whenever the day changes.
    final children = <Widget>[_XpSummary(items: items, today: today)];
    DateTime? currentDay;
    for (final item in items) {
      final at = item.createdAt?.toLocal();
      final day = at == null ? null : DateTime(at.year, at.month, at.day);
      if (day != null && day != currentDay) {
        currentDay = day;
        final total = items
            .where((other) {
              final t = other.createdAt?.toLocal();
              return t != null &&
                  t.year == day.year &&
                  t.month == day.month &&
                  t.day == day.day;
            })
            .fold<int>(0, (sum, other) => sum + other.amount);
        children.add(
          _DayHeader(label: dayLabel(day), total: l10n.xpAmount(total)),
        );
      }
      children.add(_XpRow(item: item));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: children,
    );
  }
}

/// This week's and today's totals, so the list starts with the big picture.
class _XpSummary extends StatelessWidget {
  const _XpSummary({required this.items, required this.today});

  final List<XpActivity> items;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final weekStart = today.subtract(const Duration(days: 6));
    var week = 0;
    var todayTotal = 0;
    final perDay = List<int>.filled(7, 0);
    for (final item in items) {
      final at = item.createdAt?.toLocal();
      if (at == null) continue;
      final day = DateTime(at.year, at.month, at.day);
      if (day.isBefore(weekStart)) continue;
      week += item.amount;
      perDay[day.difference(weekStart).inDays.clamp(0, 6)] += item.amount;
      if (day == today) todayTotal += item.amount;
    }
    final peak = perDay.fold<int>(1, (a, b) => b > a ? b : a);

    return Container(
      key: const ValueKey('xp-summary'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: AppRadii.mediumBorder,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.rewardSoft, palette.brand.withValues(alpha: .12)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.progressHistoryThisWeek,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.xpAmount(week),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.progressHistoryTodayTotal(todayTotal),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          // One bar per day, oldest on the left.
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Container(
                    width: 10,
                    height: 6 + 50 * perDay[i] / peak,
                    decoration: BoxDecoration(
                      color: i == 6
                          ? palette.brand
                          : palette.brand.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.total});

  final String label;
  final String total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            total,
            style: theme.textTheme.labelLarge?.copyWith(
              color: palette.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  const _XpRow({required this.item});

  final XpActivity item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final language = Localizations.localeOf(context).languageCode;
    final (icon, color) = xpSourceStyle(item.sourceType);
    final detail = item.detailFor(language)?.trim() ?? '';
    final time = item.createdAt == null
        ? ''
        : DateFormat.jm(
            Localizations.localeOf(context).toString(),
          ).format(item.createdAt!.toLocal());
    final title = xpSourceLabel(l10n, item.sourceType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiksaTypography.bodyStyleFor(
                    title,
                    theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.bodyStyleFor(
                      detail,
                      theme.textTheme.bodySmall,
                    ),
                  ),
                Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: palette.rewardSoft,
              borderRadius: AppRadii.fullBorder,
            ),
            child: Text(
              l10n.xpAmount(item.amount),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankHistory extends StatelessWidget {
  const _RankHistory({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(rankHistoryProvider)
        .when(
          loading: () => const _Loading(),
          error: (_, _) => _HistoryError(
            message: l10n.progressHistoryRankFailed,
            onRetry: () => ref.invalidate(rankHistoryProvider),
          ),
          data: (items) => items.isEmpty
              ? IllustratedEmptyState(
                  title: l10n.progressHistoryRankEmptyTitle,
                  body: l10n.progressHistoryRankEmptyBody,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _RankRow(item: items[i], latest: i == 0),
                ),
        );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.item, required this.latest});

  final RankHistoryEntry item;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final up = item.isPromotion;
    final newName = readableProfileName(item.newRank);
    final title = up
        ? l10n.progressHistoryRankedUp(newName)
        : l10n.progressHistoryRankedDown(newName);
    final date = item.changedAt == null
        ? ''
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).format(item.changedAt!.toLocal());

    return Container(
      key: ValueKey('rank-change-${item.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(
          color: latest && up
              ? palette.reward.withValues(alpha: .6)
              : palette.outline,
        ),
      ),
      child: Row(
        children: [
          RiksaRankBadge(
            tier: item.oldRank,
            size: 40,
            semanticLabel: readableProfileName(item.oldRank),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: up ? const Color(0xFF22C55E) : palette.inkMuted,
            ),
          ),
          RiksaRankBadge(tier: item.newRank, size: 52, semanticLabel: newName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: RiksaTypography.bodyStyleFor(
                    title,
                    theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${rankScopeLabel(l10n, item.scope)} · $date',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (latest && up)
            const BuddyFaceReaction(face: MascotFace.proud, size: 40, loops: 1),
        ],
      ),
    );
  }
}

class _ProgressSectionTabs extends StatefulWidget {
  const _ProgressSectionTabs();

  @override
  State<_ProgressSectionTabs> createState() => _ProgressSectionTabsState();
}

class _ProgressSectionTabsState extends State<_ProgressSectionTabs> {
  late TabController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = DefaultTabController.of(context);
    _controller.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    Widget tab(String label, int index) {
      final isSelected = _controller.index == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _controller.animateTo(index);
            },
            borderRadius: AppRadii.fullBorder,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  label,
                  Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? palette.brand : palette.inkMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        height: 46,
        child: RiksaGlassSurface(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 2;
              final showingRank = _controller.index == 1;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    start: showingRank ? tabWidth : 0,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: const RiksaGlassSelection(),
                  ),
                  Row(
                    children: [tab('XP activity', 0), tab('Rank changes', 1)],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
