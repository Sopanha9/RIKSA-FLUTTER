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
              duration: const Duration(milliseconds: 380),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final isDark = theme.brightness == Brightness.dark;
    final barColor = isDark
        ? AppColors.editorialAubergineRaised
        : AppColors.editorialNeutralSurface;
    final barForeground = isDark
        ? AppColors.editorialPinkSoft
        : AppColors.editorialMuted;
    final activeBackground = isDark
        ? AppColors.editorialPink
        : AppColors.editorialBlack;
    final activeForeground = isDark
        ? AppColors.editorialAubergine
        : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 58,
          child: IgnorePointer(
            ignoring: collapsed,
            child: _ExpandedNavigationBar(
              expandedWidth: expandedWidth,
              items: items,
              currentIndex: currentIndex,
              collapsed: collapsed,
              barColor: barColor,
              barForeground: barForeground,
              activeBackground: activeBackground,
              activeForeground: activeForeground,
              isDark: isDark,
              onSelected: onSelected,
            ),
          ),
        ),
        Positioned(
          key: const ValueKey('bottom-nav-active-circle'),
          left: 3,
          bottom: 0,
          width: 52,
          height: 52,
          child: IgnorePointer(
            ignoring: !collapsed,
            child: AnimatedScale(
              scale: collapsed ? 1 : .78,
              duration: const Duration(milliseconds: 380),
              curve: collapsed
                  ? const Interval(.45, 1, curve: Curves.easeOutBack)
                  : const Interval(0, .45, curve: Curves.easeInCubic),
              child: AnimatedOpacity(
                key: const ValueKey('bottom-nav-collapsed-content'),
                opacity: collapsed ? 1 : 0,
                duration: const Duration(milliseconds: 380),
                curve: collapsed
                    ? const Interval(.45, 1, curve: Curves.easeOutCubic)
                    : const Interval(0, .45, curve: Curves.easeInCubic),
                child: _CollapsedNavigationButton(
                  item: items.first,
                  backgroundColor: activeBackground,
                  foregroundColor: activeForeground,
                  borderColor: isDark
                      ? palette.canvas.withValues(alpha: .18)
                      : Colors.transparent,
                  isDark: isDark,
                  onTap: onCollapsedTap,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandedNavigationBar extends StatelessWidget {
  const _ExpandedNavigationBar({
    required this.expandedWidth,
    required this.items,
    required this.currentIndex,
    required this.collapsed,
    required this.barColor,
    required this.barForeground,
    required this.activeBackground,
    required this.activeForeground,
    required this.isDark,
    required this.onSelected,
  });

  final double expandedWidth;
  final List<_RiksaNavigationItem> items;
  final int currentIndex;
  final bool collapsed;
  final Color barColor;
  final Color barForeground;
  final Color activeBackground;
  final Color activeForeground;
  final bool isDark;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('bottom-nav-surface'),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: collapsed ? barColor.withValues(alpha: 0) : barColor,
        borderRadius: AppRadii.extraLargeBorder,
        boxShadow: collapsed
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .24 : .1),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: OverflowBox(
        alignment: AlignmentDirectional.centerStart,
        minWidth: expandedWidth,
        maxWidth: expandedWidth,
        child: SizedBox(
          width: expandedWidth,
          height: 58,
          child: AnimatedOpacity(
            key: const ValueKey('bottom-nav-expanded-content'),
            opacity: collapsed ? 0 : 1,
            duration: const Duration(milliseconds: 380),
            curve: collapsed
                ? const Interval(0, .65, curve: Curves.easeOutCubic)
                : const Interval(.35, 1, curve: Curves.easeInCubic),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final labelStyle =
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: activeForeground,
                        fontWeight: FontWeight.w700,
                      ) ??
                      TextStyle(
                        color: activeForeground,
                        fontWeight: FontWeight.w700,
                      );
                  final labelPainter = TextPainter(
                    text: TextSpan(
                      text: items[currentIndex].label,
                      style: labelStyle,
                    ),
                    maxLines: 1,
                    textDirection: Directionality.of(context),
                  )..layout();
                  final calculatedMaximum =
                      constraints.maxWidth - ((items.length - 1) * 44);
                  final maximumActiveWidth = calculatedMaximum < 88
                      ? 88.0
                      : calculatedMaximum;
                  final minimumActiveWidth = maximumActiveWidth < 112
                      ? maximumActiveWidth
                      : 112.0;
                  final activeWidth = (labelPainter.width + 59).clamp(
                    minimumActiveWidth,
                    maximumActiveWidth,
                  );
                  final inactiveWidth =
                      (constraints.maxWidth - activeWidth) / (items.length - 1);

                  return Row(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        _ExpandedNavigationDestination(
                          index: index,
                          item: items[index],
                          selected: index == currentIndex,
                          width: index == currentIndex
                              ? activeWidth
                              : inactiveWidth,
                          activeBackground: activeBackground,
                          activeForeground: activeForeground,
                          inactiveForeground: barForeground,
                          labelStyle: labelStyle,
                          onTap: () => onSelected(index),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedNavigationDestination extends StatelessWidget {
  const _ExpandedNavigationDestination({
    required this.index,
    required this.item,
    required this.selected,
    required this.width,
    required this.activeBackground,
    required this.activeForeground,
    required this.inactiveForeground,
    required this.labelStyle,
    required this.onTap,
  });

  final int index;
  final _RiksaNavigationItem item;
  final bool selected;
  final double width;
  final Color activeBackground;
  final Color activeForeground;
  final Color inactiveForeground;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: ValueKey('bottom-nav-destination-$index'),
      width: width,
      height: 48,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected ? activeBackground : Colors.transparent,
        borderRadius: AppRadii.fullBorder,
      ),
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Tooltip(
          message: item.label,
          child: InkWell(
            key: ValueKey('bottom-nav-item-$index'),
            onTap: onTap,
            borderRadius: AppRadii.fullBorder,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: selected ? 13 : 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: selected ? 25 : 24,
                    color: selected ? activeForeground : inactiveForeground,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          item.label,
                          key: ValueKey('bottom-nav-label-$index'),
                          maxLines: 1,
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsedNavigationButton extends StatelessWidget {
  const _CollapsedNavigationButton({
    required this.item,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.isDark,
    required this.onTap,
  });

  final _RiksaNavigationItem item;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('bottom-nav-active-indicator'),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.editorialAubergine.withValues(
              alpha: isDark ? .3 : .2,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        selected: true,
        label: item.label,
        child: Tooltip(
          message: item.label,
          child: InkWell(
            key: const ValueKey('bottom-nav-collapsed-item'),
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Icon(item.icon, size: 27, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

class _RiksaNavigationItem {
  const _RiksaNavigationItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
