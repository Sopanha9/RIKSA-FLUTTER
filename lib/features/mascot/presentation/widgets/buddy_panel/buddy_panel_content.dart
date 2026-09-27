import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/quests/data/quest_models.dart';
import '../../../../../features/quests/providers/today_quests_provider.dart';
import '../../../../../features/userProfile/providers/profile_provider.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/mascot.dart';
import '../../../providers/mascot_provider.dart';
import 'buddy_head_art.dart';

enum _PanelTab { today, week }

class BuddyPanelContent extends ConsumerStatefulWidget {
  const BuddyPanelContent({
    super.key,
    required this.isGuest,
    required this.todayPreview,
    required this.weekPreview,
    required this.initialStreak,
    required this.maxHeight,
    required this.requireAccountAction,
    required this.onNavigate,
    required this.onClose,
  });

  final bool isGuest;
  final TodayQuests todayPreview;
  final WeeklyQuests weekPreview;
  final int initialStreak;
  final double maxHeight;
  final bool Function(String reason) requireAccountAction;
  final void Function(String path) onNavigate;
  final VoidCallback onClose;

  @override
  ConsumerState<BuddyPanelContent> createState() => _BuddyPanelContentState();
}

class _BuddyPanelContentState extends ConsumerState<BuddyPanelContent> {
  _PanelTab _tab = _PanelTab.today;
  String? _claimingId;
  String? _justClaimedId;
  int _flightXp = 0;
  int _flightKey = 0;
  Timer? _flightTimer;

  @override
  void dispose() {
    _flightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final todayAsync = widget.isGuest ? null : ref.watch(todayQuestsProvider);
    final weekAsync = widget.isGuest ? null : ref.watch(weeklyQuestsProvider);
    final today = todayAsync?.value ?? widget.todayPreview;
    final week = weekAsync?.value ?? widget.weekPreview;
    final gamification = widget.isGuest
        ? null
        : ref.watch(profileDashboardProvider).value?.gamification;
    final streak = widget.isGuest
        ? 0
        : (gamification?.currentStreak ?? widget.initialStreak);
    final buddyName =
        ref.watch(mascotProvider).profile?.name ??
        MascotProfile.defaultName(MascotSpecies.crocodile);
    final activeAsync = _tab == _PanelTab.today ? todayAsync : weekAsync;
    final isLoading = !widget.isGuest && activeAsync?.isLoading == true;
    final hasError = !widget.isGuest && activeAsync?.hasError == true;
    final isReducedMotion = MediaQuery.disableAnimationsOf(context);
    final rows = _tab == _PanelTab.today
        ? today.quests.map(_fromDaily).toList(growable: false)
        : week.quests.map(_fromWeekly).toList(growable: false);
    final claimableToday = today.claimableCount;
    final claimableWeek = week.claimableCount;
    final moodLine = _buddyLine(l10n, buddyName, today, streak);
    final line = _justClaimedId == null
        ? moodLine
        : _BuddyLine(moodLine.text, MascotFace.happy);
    final countdownAt = _tab == _PanelTab.today
        ? today.resetsAt
        : week.resetsAt;

    return SizedBox(
      height: widget.maxHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BuddyHeadArt(face: line.face, size: 62),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 58),
                        margin: const EdgeInsets.only(top: 7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: context.riksa.brandSoft,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                        child: Text(
                          line.text,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.buddyPanelClose,
                      onPressed: widget.onClose,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StreakTile(streak: streak)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _WeeklyChestTile(
                        chest: week.chest,
                        isGuest: widget.isGuest,
                        locale: locale,
                        onOpen: _openChest,
                        onRequireAccount: widget.requireAccountAction,
                        onNavigate: widget.onNavigate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Tabs(
                  selected: _tab,
                  todayCount: claimableToday,
                  weekCount: claimableWeek,
                  onSelected: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (hasError)
                  _LoadError(
                    message: _tab == _PanelTab.today
                        ? l10n.questLoadFailed
                        : l10n.weeklyLoadFailed,
                    onRetry: () {
                      if (_tab == _PanelTab.today) {
                        unawaited(
                          ref.read(todayQuestsProvider.notifier).refresh(),
                        );
                      } else {
                        unawaited(
                          ref.read(weeklyQuestsProvider.notifier).refresh(),
                        );
                      }
                    },
                  )
                else if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Text(
                      _tab == _PanelTab.today
                          ? l10n.questPreviewStreak
                          : l10n.weeklyPreviewLessons,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...rows.map(
                    (row) => _QuestRow(
                      // Guest previews have no server id; their titles are
                      // distinct, so they keep the keys unique.
                      key: ValueKey(
                        'buddy-quest-${row.id.isEmpty ? 'preview-${row.title}' : row.id}',
                      ),
                      quest: row,
                      isGuest: widget.isGuest,
                      isClaiming: _claimingId == row.id,
                      animateXp: _justClaimedId == row.id,
                      onClaim: () => _claim(row),
                      onGo: () => widget.onNavigate(row.destination),
                      onRequireAccount: widget.requireAccountAction,
                    ),
                  ),
                if (_tab == _PanelTab.today && today.allClaimed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.buddyPanelDailyBonus(today.allClaimedBonusXp),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.riksa.brandStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                _ResetsCountdown(resetsAt: countdownAt ?? _guestReset(_tab)),
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const ValueKey('buddy-market-entry'),
                  onPressed: () => widget.onNavigate('/market'),
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: Text(
                    widget.isGuest
                        ? l10n.marketBrowse
                        : l10n.marketSpendXp(
                            NumberFormat.decimalPattern(
                              locale,
                            ).format(gamification?.xpBalance ?? 0),
                          ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.isGuest) ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.buddyPanelGuestPrompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => widget.requireAccountAction('save_streak'),
                    child: Text(l10n.buddyPanelSignIn),
                  ),
                ],
              ],
            ),
          ),
          if (_flightXp > 0)
            Positioned(
              left: 58,
              top: widget.maxHeight * .53,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_flightKey),
                  tween: Tween(begin: 0, end: 1),
                  duration: isReducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 760),
                  curve: Curves.easeOutCubic,
                  onEnd: isReducedMotion
                      ? null
                      : () {
                          if (mounted) {
                            setState(() {
                              _flightXp = 0;
                              _justClaimedId = null;
                            });
                          }
                        },
                  builder: (context, value, _) => Opacity(
                    opacity: isReducedMotion
                        ? 1
                        : (1 - value).clamp(0.0, 1.0).toDouble(),
                    child: Transform.translate(
                      offset: isReducedMotion
                          ? Offset.zero
                          : Offset(80 * value, -140 * value),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.riksa.brand,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Text(
                            isReducedMotion
                                ? '+$_flightXp XP'
                                : '+${(_flightXp * value).round()} XP',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: context.riksa.onBrand,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _BuddyLine _buddyLine(
    AppLocalizations l10n,
    String name,
    TodayQuests today,
    int streak,
  ) {
    if (today.claimableCount > 0) {
      return _BuddyLine(l10n.buddyPanelClaimable(name), MascotFace.happy);
    }
    final lesson = today.quests.where(
      (quest) => quest.type == DailyQuestType.completeLesson,
    );
    final lessonLeft = lesson.any(
      (quest) => quest.target - quest.progress == 1 && !quest.completed,
    );
    if (streak > 0 && DateTime.now().hour >= 18 && lessonLeft) {
      return _BuddyLine(l10n.buddyPanelStreakAtRisk(name), MascotFace.nervous);
    }
    if (today.allClaimed) {
      return _BuddyLine(l10n.buddyPanelAllDone(name), MascotFace.cool);
    }
    return _BuddyLine(l10n.buddyPanelGreeting(name), MascotFace.happy);
  }

  _QuestRowData _fromDaily(DailyQuest quest) {
    final l10n = AppLocalizations.of(context)!;
    final title =
        quest.titleKm.isNotEmpty &&
            Localizations.localeOf(context).languageCode == 'km'
        ? quest.titleKm
        : quest.title.isNotEmpty
        ? quest.title
        : switch (quest.type) {
            DailyQuestType.completeLesson => l10n.questPreviewLesson,
            DailyQuestType.correctAnswers => l10n.questPreviewAnswers,
            DailyQuestType.socialAction => l10n.questPreviewSocial,
          };
    return _QuestRowData(
      id: quest.id,
      title: title,
      progress: quest.progress,
      target: quest.target,
      xp: quest.xpReward,
      claimed: quest.claimed,
      claimable: quest.claimable,
      icon: switch (quest.type) {
        DailyQuestType.completeLesson => Icons.menu_book_rounded,
        DailyQuestType.correctAnswers => Icons.check_circle_outline_rounded,
        DailyQuestType.socialAction => Icons.favorite_border_rounded,
      },
      destination: quest.type == DailyQuestType.socialAction
          ? '/social'
          : '/learn',
      weekly: false,
    );
  }

  _QuestRowData _fromWeekly(WeeklyQuest quest) {
    final l10n = AppLocalizations.of(context)!;
    final title =
        quest.titleKm.isNotEmpty &&
            Localizations.localeOf(context).languageCode == 'km'
        ? quest.titleKm
        : quest.title.isNotEmpty
        ? quest.title
        : switch (quest.type) {
            WeeklyQuestType.lessons => l10n.weeklyPreviewLessons,
            WeeklyQuestType.correctAnswers => l10n.weeklyPreviewAnswers,
            WeeklyQuestType.activeDays => l10n.weeklyPreviewActiveDays,
            WeeklyQuestType.social => l10n.weeklyPreviewSocial,
          };
    return _QuestRowData(
      id: quest.id,
      title: title,
      progress: quest.progress,
      target: quest.target,
      xp: quest.xpReward,
      claimed: quest.claimed,
      claimable: quest.claimable,
      icon: switch (quest.type) {
        WeeklyQuestType.lessons => Icons.menu_book_rounded,
        WeeklyQuestType.correctAnswers => Icons.check_circle_outline_rounded,
        WeeklyQuestType.activeDays => Icons.calendar_month_rounded,
        WeeklyQuestType.social => Icons.people_alt_outlined,
      },
      destination: quest.type == WeeklyQuestType.social ? '/social' : '/learn',
      weekly: true,
    );
  }

  Future<void> _claim(_QuestRowData row) async {
    if (widget.isGuest) {
      widget.requireAccountAction('claim_quest');
      return;
    }
    if (row.id.isEmpty || _claimingId != null) return;
    setState(() => _claimingId = row.id);
    try {
      if (row.weekly) {
        await ref.read(weeklyQuestsProvider.notifier).claim(row.id);
      } else {
        await ref.read(todayQuestsProvider.notifier).claim(row.id);
      }
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact().catchError((_) {}));
      setState(() {
        _claimingId = null;
        _justClaimedId = row.id;
        _flightXp = row.xp;
        _flightKey++;
      });
      _flightTimer?.cancel();
      if (MediaQuery.disableAnimationsOf(context)) {
        _flightTimer = Timer(const Duration(milliseconds: 1600), () {
          if (mounted) {
            setState(() {
              _flightXp = 0;
              _justClaimedId = null;
            });
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _claimingId = null);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.questClaimFailed),
          ),
        );
      }
    }
  }

  Future<void> _openChest() async {
    if (widget.isGuest) {
      widget.requireAccountAction('open_weekly_chest');
      return;
    }
    try {
      await ref.read(weeklyQuestsProvider.notifier).openChest();
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact().catchError((_) {}));
      final xp = ref.read(weeklyQuestsProvider).value?.chest.xpReward ?? 0;
      setState(() {
        _flightXp = xp;
        _flightKey++;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chestOpenFailed),
          ),
        );
      }
    }
  }

  DateTime _guestReset(_PanelTab tab) => DateTime.now().add(
    tab == _PanelTab.today ? const Duration(hours: 7) : const Duration(days: 4),
  );
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.riksa.brandSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: context.riksa.brand,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  l10n.buddyPanelStreak,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.buddyPanelDays(streak),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: l10n.buddyPanelDays(streak),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var day = 0; day < 7; day++)
                  Container(
                    key: ValueKey('buddy-streak-day-$day'),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: day >= 7 - math.min(streak, 7)
                          ? context.riksa.brand
                          : context.riksa.surface,
                      border: Border.all(color: context.riksa.brand, width: 1),
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

class _WeeklyChestTile extends StatelessWidget {
  const _WeeklyChestTile({
    required this.chest,
    required this.isGuest,
    required this.locale,
    required this.onOpen,
    required this.onRequireAccount,
    required this.onNavigate,
  });

  final WeeklyChest chest;
  final bool isGuest;
  final String locale;
  final VoidCallback onOpen;
  final bool Function(String reason) onRequireAccount;
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = chest.target <= 0
        ? 0.0
        : (chest.points / chest.target).clamp(0.0, 1.0).toDouble();
    final itemName = chest.rewardItem == null
        ? null
        : locale == 'km' && chest.rewardItem!.nameKm.isNotEmpty
        ? chest.rewardItem!.nameKm
        : chest.rewardItem!.name;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.riksa.saffronSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: context.riksa.saffron),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  l10n.buddyPanelWeeklyChest,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (chest.opened) ...[
            Text(
              l10n.chestOpenedXp(chest.xpReward),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (itemName != null)
              TextButton.icon(
                onPressed: () => onNavigate('/market/wardrobe'),
                icon: const Icon(Icons.checkroom_rounded, size: 16),
                label: Text(
                  l10n.wardrobeChestWear(itemName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  alignment: AlignmentDirectional.centerStart,
                ),
              ),
          ] else ...[
            Text(
              l10n.chestProgress(chest.points, chest.target),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: context.riksa.surface,
                color: context.riksa.saffron,
              ),
            ),
            if (chest.openable) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 34),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: isGuest
                        ? () => onRequireAccount('open_weekly_chest')
                        : onOpen,
                    icon: isGuest
                        ? const Icon(Icons.lock_rounded, size: 16)
                        : const SizedBox.shrink(),
                    label: Text(l10n.chestOpen, maxLines: 1),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.todayCount,
    required this.weekCount,
    required this.onSelected,
  });

  final _PanelTab selected;
  final int todayCount;
  final int weekCount;
  final ValueChanged<_PanelTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.riksa.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabChoice(
              key: const ValueKey('buddy-tab-today'),
              label: l10n.buddyPanelToday,
              count: todayCount,
              selected: selected == _PanelTab.today,
              onTap: () => onSelected(_PanelTab.today),
            ),
          ),
          Expanded(
            child: _TabChoice(
              key: const ValueKey('buddy-tab-week'),
              label: l10n.buddyPanelThisWeek,
              count: weekCount,
              selected: selected == _PanelTab.week,
              onTap: () => onSelected(_PanelTab.week),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChoice extends StatelessWidget {
  const _TabChoice({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: RiksaMotion.resolve(context, RiksaMotion.fast),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.riksa.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: context.riksa.semantic.error,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    super.key,
    required this.quest,
    required this.isGuest,
    required this.isClaiming,
    required this.animateXp,
    required this.onClaim,
    required this.onGo,
    required this.onRequireAccount,
  });

  final _QuestRowData quest;
  final bool isGuest;
  final bool isClaiming;
  final bool animateXp;
  final VoidCallback onClaim;
  final VoidCallback onGo;
  final bool Function(String reason) onRequireAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = quest.target <= 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0).toDouble();
    final faded = quest.claimed;
    final action = quest.claimed
        ? Text(
            l10n.questClaimed,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall,
          )
        : quest.claimable
        ? FilledButton(
            onPressed: isClaiming
                ? null
                : isGuest
                ? () => onRequireAccount('claim_quest')
                : onClaim,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 9),
            ),
            child: isClaiming
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : isGuest
                ? const Icon(Icons.lock_rounded, size: 17)
                : Text(l10n.questClaim),
          )
        : TextButton(
            onPressed: onGo,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(l10n.buddyPanelGo, maxLines: 1),
          );

    return Semantics(
      label: isGuest && quest.claimable
          ? l10n.questSignInToClaim
          : quest.claimed
          ? l10n.questClaimed
          : quest.claimable
          ? l10n.questClaim
          : l10n.buddyPanelGo,
      child: Opacity(
        opacity: faded ? .56 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: context.riksa.surfaceRaised.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _ProgressRing(progress: ratio, icon: quest.icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: faded ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (animateXp && !MediaQuery.disableAnimationsOf(context))
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: quest.xp.toDouble()),
                        duration: const Duration(milliseconds: 650),
                        builder: (context, value, _) => Text(
                          '+${value.round()} XP',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: context.riksa.brandStrong,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      )
                    else
                      Text(
                        l10n.buddyPanelProgress(
                          quest.progress,
                          quest.target,
                          quest.xp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          decoration: faded ? TextDecoration.lineThrough : null,
                          color: context.riksa.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 86),
                child: action,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.icon});
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 38,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: progress,
          strokeWidth: 3,
          backgroundColor: context.riksa.outline,
          color: context.riksa.brand,
        ),
        Icon(icon, size: 18, color: context.riksa.brandStrong),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message, textAlign: TextAlign.center),
      TextButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context)!.questRetry),
      ),
    ],
  );
}

class _ResetsCountdown extends StatefulWidget {
  const _ResetsCountdown({required this.resetsAt});
  final DateTime resetsAt;

  @override
  State<_ResetsCountdown> createState() => _ResetsCountdownState();
}

class _ResetsCountdownState extends State<_ResetsCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final difference = widget.resetsAt.difference(DateTime.now());
    final remaining = difference.isNegative ? Duration.zero : difference;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return Text(
      l10n.buddyPanelResetsIn(hours, minutes),
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: context.riksa.inkMuted),
    );
  }
}

class _BuddyLine {
  const _BuddyLine(this.text, this.face);
  final String text;
  final MascotFace face;
}

class _QuestRowData {
  const _QuestRowData({
    required this.id,
    required this.title,
    required this.progress,
    required this.target,
    required this.xp,
    required this.claimed,
    required this.claimable,
    required this.icon,
    required this.destination,
    required this.weekly,
  });

  final String id;
  final String title;
  final int progress;
  final int target;
  final int xp;
  final bool claimed;
  final bool claimable;
  final IconData icon;
  final String destination;
  final bool weekly;
}
