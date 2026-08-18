import 'dart:ui';

import 'package:flutter/material.dart';

const _defaultAccentColor = Color(0xFF7C5CFF);

/// A floating, glass-style bottom navigation bar used across the app.
///
/// The parent controls its placement and supplies [compact] to preserve the
/// scroll-driven single-item animation used on the Home screen.
class AdaptiveNavbar extends StatelessWidget {
  const AdaptiveNavbar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.dark,
    required this.compact,
    this.items = appNavigationItems,
    this.accentColor = _defaultAccentColor,
    super.key,
  }) : assert(selectedIndex >= 0 && selectedIndex < items.length);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool dark;
  final bool compact;
  final List<AppNavigationItem> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.bottomLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: compact ? 80 : constraints.maxWidth,
            height: 80,
            decoration: BoxDecoration(
              color: (dark ? const Color(0xFF151821) : Colors.white).withValues(alpha: .82),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: dark ? const Color(0xFF303645) : Colors.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: compact
                    ? _NavigationItem(
                        item: items[selectedIndex],
                        active: true,
                        dark: dark,
                        accentColor: accentColor,
                        onTap: () => onDestinationSelected(selectedIndex),
                      )
                    : Row(
                        children: List.generate(
                          items.length,
                          (index) => Expanded(
                            child: _NavigationItem(
                              item: items[index],
                              active: index == selectedIndex,
                              dark: dark,
                              accentColor: accentColor,
                              onTap: () => onDestinationSelected(index),
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

class AppNavigationItem {
  const AppNavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const appNavigationItems = [
  AppNavigationItem(icon: Icons.home_rounded, label: 'Home'),
  AppNavigationItem(icon: Icons.article_outlined, label: 'Blog'),
  AppNavigationItem(icon: Icons.menu_book_rounded, label: 'Lessons'),
  AppNavigationItem(icon: Icons.sports_esports_rounded, label: 'Game'),
  AppNavigationItem(icon: Icons.settings_outlined, label: 'Settings'),
];

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.active,
    required this.dark,
    required this.accentColor,
    required this.onTap,
  });

  final AppNavigationItem item;
  final bool active;
  final bool dark;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = dark ? const Color(0xFF9499A6) : const Color(0xFF92959D);

    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 35,
              height: 29,
              decoration: BoxDecoration(
                color: active ? accentColor.withValues(alpha: .15) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: active ? accentColor : inactiveColor, size: 20),
            ),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? accentColor : inactiveColor,
                fontSize: 9,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (active)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
              ),
          ],
        ),
      ),
    );
  }
}
