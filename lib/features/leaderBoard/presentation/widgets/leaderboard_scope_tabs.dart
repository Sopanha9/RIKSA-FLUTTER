import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../userProfile/data/profile_models.dart';
import '../../../../l10n/gen/app_localizations.dart';

class LeaderboardScopeTabs extends StatelessWidget {
  const LeaderboardScopeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final LeaderboardScope selected;
  final ValueChanged<LeaderboardScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassFill = isDark
        ? palette.surface.withValues(alpha: 0.46)
        : Colors.white.withValues(alpha: 0.58);
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);
    final selectedFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.54);
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    Widget tab(
      String label,
      bool isSelected,
      VoidCallback onTap,
      String key,
    ) => Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          key: ValueKey(key),
          onTap: onTap,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.fullBorder,
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.fullBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            key: const ValueKey('leaderboard-scope-control'),
            // 40px pill inside a 48px target: the visual stays, the thumb wins.
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: AppRadii.fullBorder,
              border: Border.all(color: glassBorder),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 2;
                final showingProvince = selected == LeaderboardScope.province;
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      start: showingProvince ? tabWidth : 0,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selectedFill,
                          borderRadius: AppRadii.fullBorder,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.36),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.ink.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        tab(
                          l10n.leaderboardNational,
                          selected == LeaderboardScope.country,
                          () => onChanged(LeaderboardScope.country),
                          'leaderboard-national-tab',
                        ),
                        tab(
                          l10n.leaderboardProvince,
                          selected == LeaderboardScope.province,
                          () => onChanged(LeaderboardScope.province),
                          'leaderboard-province-tab',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
