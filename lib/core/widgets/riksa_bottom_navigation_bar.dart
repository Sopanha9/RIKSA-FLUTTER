import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

/// Floating navigation: a white pill holding the four places a learner goes,
/// and a round AI Tutor button beside it for the one thing we most want them
/// to do. The selected tab sits in its own soft pill so where you are never
/// depends on colour alone. Pushed screens hide the bar (see the app shell).
///
/// Branch indices are unchanged: 0 Home, 1 Learn, 2 AI Tutor, 3 Ranks,
/// 4 Profile. Index 2 is the round button rather than a pill item.
class RiksaBottomNavigationBar extends StatelessWidget {
  const RiksaBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  }) : assert(currentIndex >= 0 && currentIndex < 5);

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const int aiTutorIndex = 2;
  static const double _height = 60;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final tabs = <(int, _RiksaNavigationItem)>[
      (
        0,
        _RiksaNavigationItem(
          label: l10n.home,
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
      ),
      (
        1,
        _RiksaNavigationItem(
          label: l10n.learn,
          icon: Icons.menu_book_outlined,
          activeIcon: Icons.menu_book_rounded,
        ),
      ),
      (
        3,
        _RiksaNavigationItem(
          label: l10n.ranksTab,
          icon: Icons.emoji_events_outlined,
          activeIcon: Icons.emoji_events_rounded,
        ),
      ),
      (
        4,
        _RiksaNavigationItem(
          label: l10n.profile,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? .35 : .08),
      blurRadius: 20,
      offset: const Offset(0, 6),
    );

    // Labels grow with the learner's text size, but only so far: past that
    // the fixed-height pill would have to shrink them again anyway.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.fullBorder,
                  boxShadow: [shadow],
                ),
                child: Material(
                  key: const ValueKey('bottom-nav-surface'),
                  color: palette.surface,
                  shape: StadiumBorder(
                    side: BorderSide(color: palette.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
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
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _AiTutorButton(
              label: l10n.aiTutor,
              selected: currentIndex == aiTutorIndex,
              shadow: shadow,
              onTap: () => onSelected(aiTutorIndex),
            ),
          ],
        ),
      ),
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
    final color = selected ? palette.brand : palette.inkMuted;
    return Semantics(
      key: ValueKey('bottom-nav-destination-$index'),
      label: item.label,
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
          child: AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            curve: RiksaMotion.standardCurve,
            height: RiksaBottomNavigationBar._height - 8,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: ShapeDecoration(
              color: selected ? palette.brandSoft : Colors.transparent,
              shape: const StadiumBorder(),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: 2),
                // The bar has a fixed height, so a long or enlarged label
                // shrinks to fit rather than wrapping; the icon keeps its size.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    key: ValueKey('bottom-nav-label-$index'),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: RiksaTypography.bodyStyleFor(
                      item.label,
                      TextStyle(
                        fontFamily: RiksaTypography.latinFamily,
                        fontSize: 11,
                        height: 1.25,
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
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
    required this.onTap,
  });

  final String label;
  final bool selected;
  final BoxShadow shadow;
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
          duration: RiksaMotion.resolve(context, RiksaMotion.standard),
          curve: RiksaMotion.standardCurve,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [shadow],
            border: Border.all(
              color: selected ? AppColors.lime : palette.surface,
              width: 3,
            ),
          ),
          child: Material(
            color: palette.brand,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey(
                'bottom-nav-item-${RiksaBottomNavigationBar.aiTutorIndex}',
              ),
              onTap: onTap,
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
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
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
