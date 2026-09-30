import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

/// Floating navigation: a white pill holding the four places a learner goes,
/// and a round AI Tutor button beside it for the one thing we most want them
/// to do. The selected tab sits in its own soft pill so where you are never
/// depends on colour alone. Pushed screens hide the bar (see the app shell).
///
/// Branch indices: 0 Home, 1 Learn, 2 AI Tutor, 3 Ranks, 4 Profile,
/// 5 Notifications. Index 2 is the round button rather than a pill item, and
/// Profile has no tab: it opens from the drawer, so no pill is lit there.
class RiksaBottomNavigationBar extends StatelessWidget {
  const RiksaBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    this.isExpanded = true,
    this.onExpand,
    this.notificationCount = 0,
  }) : assert(currentIndex >= 0 && currentIndex < 6),
       assert(isExpanded || onExpand != null);

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool isExpanded;
  final VoidCallback? onExpand;

  /// Unread notifications, shown as a badge on the bell. Zero hides it.
  final int notificationCount;

  static const int aiTutorIndex = 2;
  static const int profileIndex = 4;
  static const double _height = 60;

  /// How long the bar takes to collapse or open again. Buttons that make room
  /// for it (see [AboveBottomNavigation]) move in step.
  static const Duration switchDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final tabs = <(int, _RiksaNavigationItem)>[
      (
        0,
        _RiksaNavigationItem(
          label: l10n.home,
          icon: Icons.space_dashboard_outlined,
          activeIcon: Icons.space_dashboard_rounded,
        ),
      ),
      (
        1,
        _RiksaNavigationItem(
          label: l10n.learn,
          icon: Icons.auto_stories_outlined,
          activeIcon: Icons.auto_stories_rounded,
        ),
      ),
      (
        3,
        _RiksaNavigationItem(
          label: l10n.leaderboard,
          icon: Icons.leaderboard_outlined,
          activeIcon: Icons.leaderboard_rounded,
        ),
      ),
      (
        5,
        _RiksaNavigationItem(
          label: l10n.notificationsTitle,
          icon: Icons.notifications_none_rounded,
          activeIcon: Icons.notifications_rounded,
          badgeCount: notificationCount,
          badgeLabel: notificationCount > 0
              ? l10n.notificationsUnreadBadge(notificationCount)
              : null,
        ),
      ),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill = isDark
        ? palette.surface.withValues(alpha: 0.46)
        : Colors.white.withValues(alpha: 0.58);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);
    final shadow = BoxShadow(
      color: palette.ink.withValues(alpha: isDark ? .18 : .08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    );

    final activeTabIcon = switch (currentIndex) {
      aiTutorIndex => Icons.auto_awesome_rounded,
      profileIndex => Icons.account_circle_rounded,
      _ => tabs.firstWhere((t) => t.$1 == currentIndex).$2.activeIcon,
    };

    final fullBar = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SafeArea(
        key: const ValueKey('full-bottom-nav-bar'),
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadii.fullBorder,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    key: const ValueKey('bottom-nav-surface'),
                    decoration: ShapeDecoration(
                      color: glassFill,
                      shape: StadiumBorder(
                        side: BorderSide(color: glassBorder),
                      ),
                      shadows: [shadow],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _PillTabTrack(
                        tabs: tabs,
                        currentIndex: currentIndex,
                        onSelected: onSelected,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _AiTutorButton(
              label: l10n.aiTutor,
              selected: currentIndex == aiTutorIndex,
              shadow: shadow,
              glassBorder: glassBorder,
              glassFill: glassFill,
              onTap: () => onSelected(aiTutorIndex),
            ),
          ],
        ),
      ),
    );

    final collapsedFab = SafeArea(
      key: const ValueKey('collapsed-bottom-nav-fab'),
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Semantics(
        label: MaterialLocalizations.of(context).showMenuTooltip,
        button: true,
        onTap: onExpand,
        excludeSemantics: true,
        child: Container(
          width: RiksaBottomNavigationBar._height,
          height: RiksaBottomNavigationBar._height,
          decoration: ShapeDecoration(
            shape: CircleBorder(side: BorderSide(color: glassBorder)),
            shadows: [shadow],
            color: glassFill,
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.54),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.36),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onExpand,
                      child: Center(
                        child: Icon(
                          activeTabIcon,
                          color: palette.brand,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: RiksaMotion.resolve(context, switchDuration),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.bottomLeft,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: isExpanded ? fullBar : collapsedFab,
    );
  }
}

/// Lifts a tab screen's floating action button above the floating tab bar.
///
/// The shell's Scaffold extends its body under the bar and reports the bar as
/// bottom padding, but a tab's own Scaffold places its button from the device
/// inset alone, which leaves it under the AI Tutor button. Where the bar is
/// hidden the padding is only the device inset, and this adds nothing.
///
/// [context] must sit above the tab's Scaffold: the Scaffold strips all
/// padding from its button slot, so reading it inside the button sees none.
class AboveBottomNavigation extends StatelessWidget {
  AboveBottomNavigation({
    super.key,
    required BuildContext context,
    required this.child,
  }) : lift = math.max(
         0,
         MediaQuery.paddingOf(context).bottom -
             MediaQuery.viewPaddingOf(context).bottom,
       );

  final double lift;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // While the bar is collapsed to its small button on the start side, the
    // AI Tutor button is gone, so the action button drops into its place.
    final expanded = BottomNavigationExpansion.maybeOf(context) ?? true;
    return AnimatedPadding(
      duration: RiksaMotion.resolve(
        context,
        RiksaBottomNavigationBar.switchDuration,
      ),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: expanded ? lift : 0),
      child: child,
    );
  }
}

/// Tells tab screens whether the floating bar is open or collapsed.
///
/// The shell provides it; [AboveBottomNavigation] reads it so a tab's action
/// button sits above the open bar and takes the AI Tutor button's place when
/// the bar collapses on scroll.
class BottomNavigationExpansion
    extends InheritedNotifier<ValueListenable<bool>> {
  const BottomNavigationExpansion({
    super.key,
    required ValueListenable<bool> expanded,
    required super.child,
  }) : super(notifier: expanded);

  /// Whether the bar is open, or null outside a shell.
  static bool? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BottomNavigationExpansion>()
      ?.notifier
      ?.value;
}

class _PillTabTrack extends StatelessWidget {
  const _PillTabTrack({
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<(int, _RiksaNavigationItem)> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final selectedSlot = tabs.indexWhere((tab) => tab.$1 == currentIndex);
    final duration = RiksaMotion.resolve(
      context,
      const Duration(milliseconds: 320),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / tabs.length;
        final indicatorLeft = selectedSlot < 0 ? 0.0 : selectedSlot * tabWidth;
        return SizedBox(
          height: RiksaBottomNavigationBar._height - 8,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeOutCubic,
                left: indicatorLeft,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: AnimatedOpacity(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  opacity: selectedSlot < 0 ? 0 : 1,
                  child: DecoratedBox(
                    key: const ValueKey('bottom-nav-selection-pill'),
                    decoration: ShapeDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.54),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.36),
                        ),
                      ),
                      shadows: [
                        BoxShadow(
                          color: palette.ink.withValues(alpha: .06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (index, item) in tabs)
                    Expanded(
                      child: _PillTab(
                        index: index,
                        item: item,
                        selected: index == currentIndex,
                        onTap: () => onSelected(index),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.index,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final _RiksaNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final color = selected
        ? palette.brand
        : palette.inkMuted.withValues(alpha: 0.82);
    final badgeLabel = item.badgeLabel;
    return Semantics(
      key: ValueKey('bottom-nav-destination-$index'),
      label: badgeLabel == null ? item.label : '${item.label}, $badgeLabel',
      selected: selected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: InkWell(
          key: ValueKey('bottom-nav-item-$index'),
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: RiksaBottomNavigationBar._height - 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: selected ? 1.08 : 1),
                    duration: RiksaMotion.resolve(
                      context,
                      const Duration(milliseconds: 220),
                    ),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: AnimatedSwitcher(
                      duration: RiksaMotion.resolve(
                        context,
                        const Duration(milliseconds: 180),
                      ),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: Badge(
                        key: ValueKey('bottom-nav-icon-$index-$selected'),
                        isLabelVisible: item.badgeCount > 0,
                        label: Text(
                          item.badgeCount > 99 ? '99+' : '${item.badgeCount}',
                          key: ValueKey('bottom-nav-badge-$index'),
                        ),
                        backgroundColor: palette.saffron,
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          color: color,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // The bar has a fixed height, so a long or enlarged label
                  // shrinks to fit rather than wrapping; the icon keeps its size.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: RiksaMotion.resolve(
                        context,
                        const Duration(milliseconds: 180),
                      ),
                      curve: Curves.easeOutCubic,
                      style: RiksaTypography.bodyStyleFor(
                        item.label,
                        TextStyle(
                          fontFamily: RiksaTypography.latinFamily,
                          fontSize: selected ? 11.2 : 10.8,
                          height: 1.18,
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      )!,
                      child: Text(
                        item.label,
                        key: ValueKey('bottom-nav-label-$index'),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round purple action beside the pill. When the tutor is the open tab it
/// picks up a lime ring, matching the lime used for "you" elsewhere.
class _AiTutorButton extends StatelessWidget {
  const _AiTutorButton({
    required this.label,
    required this.selected,
    required this.shadow,
    required this.glassBorder,
    required this.glassFill,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final BoxShadow shadow;
  final Color glassBorder;
  final Color glassFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    const size = RiksaBottomNavigationBar._height;
    return Semantics(
      key: const ValueKey(
        'bottom-nav-destination-${RiksaBottomNavigationBar.aiTutorIndex}',
      ),
      label: label,
      selected: selected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          key: const ValueKey(
            'bottom-nav-item-${RiksaBottomNavigationBar.aiTutorIndex}',
          ),
          duration: RiksaMotion.resolve(context, RiksaMotion.standard),
          curve: RiksaMotion.standardCurve,
          width: size,
          height: size,
          decoration: ShapeDecoration(
            shape: CircleBorder(side: BorderSide(color: glassBorder)),
            shadows: [shadow],
            color: glassFill,
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                  curve: RiksaMotion.standardCurve,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.54),
                    border: Border.all(
                      color: selected
                          ? AppColors.lime
                          : Colors.white.withValues(alpha: 0.36),
                      width: 3,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTap,
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: palette.brand,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiksaNavigationItem {
  const _RiksaNavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount = 0,
    this.badgeLabel,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badgeCount;

  /// Read out by screen readers after the label, e.g. "3 unread".
  final String? badgeLabel;
}
