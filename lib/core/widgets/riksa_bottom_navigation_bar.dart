import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

class RiksaBottomNavigationBar extends StatelessWidget {
  const RiksaBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.collapsed,
    required this.onSelected,
    required this.onCollapsedTap,
  }) : assert(currentIndex >= 0 && currentIndex < 5);

  final int currentIndex;
  final bool collapsed;
  final ValueChanged<int> onSelected;
  final VoidCallback onCollapsedTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <_RiksaNavigationItem>[
      _RiksaNavigationItem(label: l10n.home, icon: Icons.home_outlined),
      _RiksaNavigationItem(label: l10n.learn, icon: Icons.school_outlined),
      _RiksaNavigationItem(
        label: l10n.aiTutor,
        icon: Icons.auto_awesome_outlined,
      ),
      _RiksaNavigationItem(
        label: l10n.leaderboard,
        icon: Icons.emoji_events_outlined,
      ),
      _RiksaNavigationItem(
        label: l10n.profile,
        icon: Icons.account_circle_outlined,
      ),
    ];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: SizedBox(
        height: 74,
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.bottomLeft,
            child: AnimatedContainer(
              key: const ValueKey('bottom-nav-morph'),
              width: collapsed ? 58 : constraints.maxWidth,
              height: 74,
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeInOutCubic,
              child: _NavigationSurface(
                expandedWidth: constraints.maxWidth,
                items: items,
                currentIndex: currentIndex,
                collapsed: collapsed,
                onSelected: onSelected,
                onCollapsedTap: onCollapsedTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationSurface extends StatelessWidget {
  const _NavigationSurface({
    required this.expandedWidth,
    required this.items,
    required this.currentIndex,
    required this.collapsed,
    required this.onSelected,
    required this.onCollapsedTap,
  });
  final double expandedWidth;
  final List<_RiksaNavigationItem> items;
  final int currentIndex;
  final bool collapsed;
  final ValueChanged<int> onSelected;
  final VoidCallback onCollapsedTap;

  double _itemCenter(int index) {
    const edgeCenter = 29.0;
    final spacing = (expandedWidth - (edgeCenter * 2)) / (items.length - 1);
    return edgeCenter + (spacing * index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? palette.surfaceRaised : palette.ink;
    final barForeground = isDark ? palette.ink : palette.canvas;
    final effectiveIndex = collapsed ? 0 : currentIndex;
    const activeSize = 48.0;
    final activeLeft = collapsed
        ? 5.0
        : _itemCenter(effectiveIndex) - (activeSize / 2);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: AppRadii.extraLargeBorder,
              border: Border.all(color: palette.outline.withValues(alpha: .4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .2 : .12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          key: const ValueKey('bottom-nav-active-circle'),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          top: 21,
          left: activeLeft,
          width: activeSize,
          height: activeSize,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.jade,
                shape: BoxShape.circle,
                border: Border.all(
                  color: barForeground.withValues(alpha: .28),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.jade.withValues(alpha: .24),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .78, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  items[effectiveIndex].icon,
                  key: ValueKey(effectiveIndex),
                  size: collapsed ? 24 : 27,
                  color: isDark ? AppColors.darkCanvas : Colors.white,
                ),
              ),
            ),
          ),
        ),
        for (var index = 0; index < items.length; index++)
          Positioned(
            left: _itemCenter(index) - 26,
            bottom: 0,
            width: 52,
            height: 58,
            child: IgnorePointer(
              ignoring: collapsed && index != 0,
              child: Semantics(
                button: true,
                selected: effectiveIndex == index,
                label: items[index].label,
                child: Tooltip(
                  message: items[index].label,
                  child: InkResponse(
                    key: ValueKey('bottom-nav-item-$index'),
                    onTap: collapsed
                        ? (index == 0 ? onCollapsedTap : null)
                        : () => onSelected(index),
                    radius: 27,
                    containedInkWell: true,
                    highlightShape: BoxShape.circle,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 130),
                        curve: collapsed
                            ? Curves.easeOutCubic
                            : Curves.easeInCubic,
                        opacity: collapsed || currentIndex == index ? 0 : 1,
                        child: Icon(
                          items[index].icon,
                          size: 24,
                          color: barForeground.withValues(alpha: .64),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RiksaNavigationItem {
  const _RiksaNavigationItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
