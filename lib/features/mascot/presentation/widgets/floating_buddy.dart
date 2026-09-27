import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/require_account.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/quests/data/quest_models.dart';
import '../../../../features/quests/providers/today_quests_provider.dart';
import '../../../../features/userProfile/providers/profile_provider.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/mascot.dart';
import '../../providers/mascot_provider.dart';
import 'mascot_face.dart';

const _headSize = 56.0;
const _positionKey = 'riksa_floating_buddy_position';
const _hiddenDateKey = 'riksa_floating_buddy_hidden_date';

class FloatingBuddy extends ConsumerStatefulWidget {
  const FloatingBuddy({super.key});

  @override
  ConsumerState<FloatingBuddy> createState() => _FloatingBuddyState();
}

class _FloatingBuddyState extends ConsumerState<FloatingBuddy> {
  double _left = 12;
  double _top = 190;
  double _canvasWidth = 0;
  bool _hiddenToday = false;

  @override
  void initState() {
    super.initState();
    _restorePosition();
    _restoreHiddenState();
  }

  Future<void> _restorePosition() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final values = preferences.getStringList(_positionKey);
      if (!mounted || values == null || values.length != 2) return;
      setState(() {
        _left = double.tryParse(values[0]) ?? _left;
        _top = double.tryParse(values[1]) ?? _top;
      });
    } catch (_) {
      // Keeping the default position is enough if local storage is unavailable.
    }
  }

  Future<void> _restoreHiddenState() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final today = _localDate(DateTime.now());
      final hidden = preferences.getString(_hiddenDateKey) == today;
      if (mounted && hidden != _hiddenToday) {
        setState(() => _hiddenToday = hidden);
      }
    } catch (_) {
      // The buddy remains visible if local storage is unavailable.
    }
  }

  Future<void> _savePosition() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_positionKey, [
        _left.toStringAsFixed(1),
        _top.toStringAsFixed(1),
      ]);
    } catch (_) {
      // Dragging should not depend on preferences being writable.
    }
  }

  Future<void> _hideForToday() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldHide = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.buddyHeadHideTitle),
        content: Text(l10n.buddyHeadHideBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.buddyHeadHideAction),
          ),
        ],
      ),
    );
    if (shouldHide != true || !mounted) return;
    setState(() => _hiddenToday = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_hiddenDateKey, _localDate(DateTime.now()));
    } catch (_) {
      // The current view is still hidden for this app session.
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) => Consumer(
        builder: (context, ref, _) => _buildForCurrentRoute(context, ref),
      ),
    );
  }

  Widget _buildForCurrentRoute(BuildContext context, WidgetRef watchRef) {
    final router = GoRouter.of(context);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (_hiddenToday || keyboardOpen || _isHiddenRoute(path)) {
      return const SizedBox.shrink();
    }

    final userId = watchRef.watch(currentUserIdProvider);
    final data = userId == null
        ? null
        : watchRef.watch(todayQuestsProvider).value;
    final streak = userId == null
        ? 0
        : (watchRef
                  .watch(profileDashboardProvider)
                  .value
                  ?.gamification
                  .currentStreak ??
              0);
    final l10n = AppLocalizations.of(context)!;
    final localQuests =
        data ??
        TodayQuests.guestPreview(
          titles: [
            l10n.questPreviewLesson,
            l10n.questPreviewAnswers,
            l10n.questPreviewSocial,
          ],
        );
    final face = _faceFor(localQuests, streak);
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasWidth = constraints.maxWidth;
        final insets = MediaQuery.viewPaddingOf(context);
        final minTop = insets.top + 12;
        final bottomClearance = math.max(112.0, insets.bottom + 92).toDouble();
        final maxTop = math
            .max(minTop, constraints.maxHeight - bottomClearance - _headSize)
            .toDouble();
        final left = _left
            .clamp(8.0, math.max(8.0, constraints.maxWidth - _headSize - 8))
            .toDouble();
        if (left != _left || _top < minTop || _top > maxTop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _left = left;
              _top = _top.clamp(minTop, maxTop).toDouble();
            });
          });
        }
        return Stack(
          children: [
            Positioned(
              left: left,
              top: _top.clamp(minTop, maxTop).toDouble(),
              child: GestureDetector(
                key: const ValueKey('floating-buddy-head'),
                onPanUpdate: (details) {
                  setState(() {
                    _left = (_left + details.delta.dx)
                        .clamp(8.0, math.max(8.0, _canvasWidth - _headSize - 8))
                        .toDouble();
                    _top = (_top + details.delta.dy)
                        .clamp(minTop, maxTop)
                        .toDouble();
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _left = _left + _headSize / 2 < _canvasWidth / 2
                        ? 8
                        : math.max(8, _canvasWidth - _headSize - 8);
                  });
                  _savePosition();
                },
                onLongPress: _hideForToday,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showTodaySheet(
                      context,
                      isGuest: userId == null,
                      streak: streak,
                      quests: localQuests,
                    ),
                    child: SizedBox.square(
                      dimension: _headSize + 8,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: _headSize,
                            height: _headSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.riksa.surface,
                              border: Border.all(
                                color: context.riksa.brand,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: MascotFaceAvatar(
                              face: face,
                              size: _headSize,
                              loops: 1,
                              semanticLabel: l10n.buddyHeadOpenSemantics,
                            ),
                          ),
                          if (localQuests.claimableCount > 0)
                            Positioned(
                              right: -1,
                              top: -2,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 20),
                                height: 20,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: context.riksa.semantic.error,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.riksa.surface,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${localQuests.claimableCount}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  MascotFace _faceFor(TodayQuests quests, int streak) {
    if (quests.claimableCount > 0) return MascotFace.happy;
    if (quests.allClaimed) return MascotFace.cool;
    final completedLesson = quests.quests.any(
      (quest) =>
          quest.type == DailyQuestType.completeLesson && quest.progress > 0,
    );
    final hour = DateTime.now().hour;
    if (streak > 0 && hour >= 18 && !completedLesson) return MascotFace.crying;
    final hasProgress = quests.quests.any((quest) => quest.progress > 0);
    if (!hasProgress && hour < 12) return MascotFace.happy;
    return MascotFace.neutral;
  }

  bool _isLessonRoute(String path) {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.length < 2 || parts.first != 'learn') return false;
    return !const {
      'saved',
      'roadmap',
      'completion',
      'resume',
    }.contains(parts[1]);
  }

  /// A subject's roadmap has its own buddy standing on the map, so a second
  /// one floating over it would only crowd the screen.
  bool _isSubjectRoute(String path) =>
      path.startsWith('/learn/roadmap/') || path.startsWith('/learn/subject/');

  bool _isHiddenRoute(String path) =>
      _isLessonRoute(path) ||
      _isSubjectRoute(path) ||
      path.startsWith('/auth') ||
      path.startsWith('/onboarding');

  Future<void> _showTodaySheet(
    BuildContext context, {
    required bool isGuest,
    required int streak,
    required TodayQuests quests,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _TodayQuestsSheet(
        isGuest: isGuest,
        streak: streak,
        preview: quests,
        requireAccountAction: (reason) =>
            requireAccount(context, ref, reason: reason),
      ),
    );
  }
}

String _localDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _TodayQuestsSheet extends ConsumerWidget {
  const _TodayQuestsSheet({
    required this.isGuest,
    required this.streak,
    required this.preview,
    required this.requireAccountAction,
  });

  final bool isGuest;
  final int streak;
  final TodayQuests preview;
  final bool Function(String reason) requireAccountAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final buddyName =
        ref.watch(mascotProvider).profile?.name ??
        MascotProfile.defaultName(MascotSpecies.crocodile);
    final asyncQuests = isGuest ? null : ref.watch(todayQuestsProvider);
    final content = isGuest ? preview : asyncQuests?.value ?? preview;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = screenHeight * .9;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.buddyHeadTodayTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const MascotFaceAvatar(face: MascotFace.happy, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.buddyHeadGreeting(buddyName),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StreakPill(streak: streak),
              const SizedBox(height: 16),
              if (!isGuest && asyncQuests?.isLoading == true)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!isGuest && asyncQuests?.hasError == true)
                _SheetError(
                  onRetry: () =>
                      ref.read(todayQuestsProvider.notifier).refresh(),
                )
              else
                ...content.quests.map(
                  (quest) => _QuestRow(
                    quest: quest,
                    isGuest: isGuest,
                    locale: locale,
                    onClaim: () async {
                      if (!requireAccountAction('claim_quest')) {
                        return;
                      }
                      try {
                        await ref
                            .read(todayQuestsProvider.notifier)
                            .claim(quest.id);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.questClaimFailed)),
                          );
                        }
                      }
                    },
                  ),
                ),
              if (isGuest) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.buddyHeadGuestPrompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => requireAccountAction('save_streak'),
                  child: Text(l10n.buddyHeadSignIn),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/learn'),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.buddyHeadStartLesson),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends ConsumerWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.riksa.brandSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🔥'),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.buddyHeadCurrentStreak)),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              l10n.buddyHeadStreakDays(streak),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.quest,
    required this.isGuest,
    required this.locale,
    required this.onClaim,
  });

  final DailyQuest quest;
  final bool isGuest;
  final String locale;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = locale == 'km' && quest.titleKm.isNotEmpty
        ? quest.titleKm
        : quest.title.isNotEmpty
        ? quest.title
        : switch (quest.type) {
            DailyQuestType.completeLesson => l10n.questPreviewLesson,
            DailyQuestType.correctAnswers => l10n.questPreviewAnswers,
            DailyQuestType.socialAction => l10n.questPreviewSocial,
          };
    final ratio = quest.target <= 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(quest.type), color: context.riksa.brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text('+${quest.xpReward} XP'),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 5),
            Text(l10n.buddyHeadProgress(quest.progress, quest.target)),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: quest.claimed
                  ? Text(l10n.questClaimed)
                  : quest.claimable && !isGuest
                  ? TextButton(onPressed: onClaim, child: Text(l10n.questClaim))
                  : isGuest
                  ? Text(l10n.questSignInToClaim)
                  : Text(
                      l10n.buddyHeadProgressShort(quest.progress, quest.target),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(DailyQuestType type) => switch (type) {
    DailyQuestType.completeLesson => Icons.menu_book_outlined,
    DailyQuestType.correctAnswers => Icons.check_circle_outline,
    DailyQuestType.socialAction => Icons.favorite_border,
  };
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(l10n.questLoadFailed),
        TextButton(onPressed: onRetry, child: Text(l10n.questRetry)),
      ],
    );
  }
}
