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
        icon: Icons.chat_bubble_outline_rounded,
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
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: SizedBox(
        height: 66,
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.bottomLeft,
            child: AnimatedContainer(
              key: const ValueKey('bottom-nav-morph'),
              width: collapsed ? 58 : constraints.maxWidth,
              height: 66,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF161716) : const Color(0xFF20211F);
    const barForeground = Color(0xFFF3F3EF);
    final effectiveIndex = collapsed ? 0 : currentIndex;
    const activeSize = 44.0;
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
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: AppRadii.extraLargeBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .24 : .16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        AnimatedPositioned(
          key: const ValueKey('bottom-nav-active-circle'),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          top: 18,
          left: activeLeft,
          width: activeSize,
          height: activeSize,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: effectiveIndex == 2
                    ? const Color(0xFFE9E4FA)
                    : const Color(0xFFFAFAF7),
                shape: BoxShape.circle,
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
                  color: const Color(0xFF20211F),
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
            height: 52,
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
                          color: barForeground.withValues(alpha: .58),
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
