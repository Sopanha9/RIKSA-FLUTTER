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
import 'buddy_panel/buddy_head_art.dart';
import 'buddy_panel/buddy_panel_content.dart';
import 'buddy_panel/buddy_panel_route.dart';

const _headHitWidth = 72.0;
const _headHitHeight = 64.0;
const _positionKey = 'riksa_floating_buddy_position';
const _hiddenDateKey = 'riksa_floating_buddy_hidden_date';

class FloatingBuddy extends ConsumerStatefulWidget {
  const FloatingBuddy({super.key});

  @override
  ConsumerState<FloatingBuddy> createState() => _FloatingBuddyState();
}

class _FloatingBuddyState extends ConsumerState<FloatingBuddy> {
  final GlobalKey _headKey = GlobalKey();
  double _left = 12;
  double _top = 190;
  double _canvasWidth = 0;
  bool _hiddenToday = false;
  bool _panelOpen = false;
  bool _pressed = false;

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
    final quests =
        data ??
        TodayQuests.guestPreview(
          titles: [
            l10n.questPreviewLesson,
            l10n.questPreviewAnswers,
            l10n.questPreviewSocial,
          ],
          showLockedActions: userId == null,
        );
    final face = _panelOpen ? MascotFace.happy : _faceFor(quests, streak);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasWidth = constraints.maxWidth;
        final insets = MediaQuery.viewPaddingOf(context);
        final minTop = insets.top + 12;
        final bottomClearance = math.max(112.0, insets.bottom + 92).toDouble();
        final maxTop = math
            .max(
              minTop,
              constraints.maxHeight - bottomClearance - _headHitHeight,
            )
            .toDouble();
        final left = _left
            .clamp(8.0, math.max(8.0, constraints.maxWidth - _headHitWidth - 8))
            .toDouble();
        final top = _top.clamp(minTop, maxTop).toDouble();
        if (left != _left || top != _top) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _left = left;
              _top = top;
            });
          });
        }
        final snappedLeft = left < constraints.maxWidth / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: top,
              child: KeyedSubtree(
                key: const ValueKey('floating-buddy-head'),
                child: Semantics(
                  button: true,
                  label: l10n.buddyHeadOpenSemantics,
                  child: GestureDetector(
                    key: _headKey,
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: _panelOpen
                        ? null
                        : (details) {
                            setState(() {
                              _left = (_left + details.delta.dx)
                                  .clamp(
                                    8.0,
                                    math.max(
                                      8.0,
                                      _canvasWidth - _headHitWidth - 8,
                                    ),
                                  )
                                  .toDouble();
                              _top = (_top + details.delta.dy)
                                  .clamp(minTop, maxTop)
                                  .toDouble();
                            });
                          },
                    onPanEnd: _panelOpen
                        ? null
                        : (_) {
                            setState(() {
                              _left =
                                  _left + _headHitWidth / 2 < _canvasWidth / 2
                                  ? 8.0
                                  : math
                                        .max(
                                          8.0,
                                          _canvasWidth - _headHitWidth - 8,
                                        )
                                        .toDouble();
                            });
                            _savePosition();
                          },
                    onLongPress: _panelOpen ? null : _hideForToday,
                    onTapDown: _panelOpen || reducedMotion
                        ? null
                        : (_) => setState(() => _pressed = true),
                    onTapCancel: _panelOpen || reducedMotion
                        ? null
                        : () => setState(() => _pressed = false),
                    onTapUp: _panelOpen || reducedMotion
                        ? null
                        : (_) => setState(() => _pressed = false),
                    onTap: _panelOpen
                        ? _closePanel
                        : () => _openPanel(
                            isGuest: userId == null,
                            streak: streak,
                            quests: quests,
                          ),
                    child: AnimatedScale(
                      scale: _pressed && !reducedMotion ? .88 : 1,
                      duration: RiksaMotion.resolve(context, RiksaMotion.fast),
                      curve: Curves.easeOutBack,
                      child: SizedBox(
                        width: _headHitWidth,
                        height: _headHitHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            BuddyHeadArt(
                              face: face,
                              size: 76,
                              semanticLabel: l10n.buddyHeadOpenSemantics,
                            ),
                            if (quests.claimableCount > 0)
                              Positioned(
                                top: -1,
                                right: snappedLeft ? -1 : null,
                                left: snappedLeft ? null : -1,
                                child: _ClaimBadge(
                                  count: quests.claimableCount,
                                  dark: isDark,
                                ),
                              ),
                          ],
                        ),
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

  Future<void> _openPanel({
    required bool isGuest,
    required int streak,
    required TodayQuests quests,
  }) async {
    final headContext = _headKey.currentContext;
    final renderObject = headContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final origin = renderObject.localToGlobal(Offset.zero);
    final rect = origin & renderObject.size;
    setState(() {
      _panelOpen = true;
      _pressed = false;
    });
    final l10n = AppLocalizations.of(context)!;
    final weekPreview = WeeklyQuests.guestPreview(
      titles: [
        l10n.weeklyPreviewLessons,
        l10n.weeklyPreviewAnswers,
        l10n.weeklyPreviewActiveDays,
        l10n.weeklyPreviewSocial,
      ],
      showLockedActions: isGuest,
    );
    final router = GoRouter.of(context);
    try {
      await openBuddyPanel(
        context: context,
        headRect: rect,
        openSemantics: l10n.buddyHeadOpenSemantics,
        closeSemantics: l10n.buddyPanelClose,
        onHeadTap: _closePanel,
        contentBuilder: (height) => BuddyPanelContent(
          isGuest: isGuest,
          todayPreview: quests,
          weekPreview: weekPreview,
          initialStreak: streak,
          maxHeight: height,
          requireAccountAction: (reason) {
            if (ref.read(authProvider) is Authenticated) return true;
            // Close the panel first: the sign-in screen would otherwise be
            // pushed underneath the open modal and the tap would look dead.
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            if (mounted) setState(() => _panelOpen = false);
            // Push after the pop has been applied; a push issued in the same
            // frame as removing the modal is dropped by the router.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) requireAccount(context, ref, reason: reason);
            });
            return false;
          },
          onNavigate: (path) {
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            if (mounted) setState(() => _panelOpen = false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) router.push(path);
            });
          },
          onClose: _closePanel,
        ),
      );
    } finally {
      if (mounted && _panelOpen) setState(() => _panelOpen = false);
    }
  }

  void _closePanel() {
    if (!_panelOpen) return;
    setState(() => _panelOpen = false);
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();
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
}

String _localDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _ClaimBadge extends StatelessWidget {
  const _ClaimBadge({required this.count, required this.dark});
  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 22),
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      color: context.riksa.semantic.error,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: dark
            ? Colors.white.withValues(alpha: .82)
            : context.riksa.surface,
        width: 1.5,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      '$count',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
