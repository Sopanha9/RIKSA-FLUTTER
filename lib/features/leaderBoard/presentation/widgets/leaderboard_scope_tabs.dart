import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../userProfile/data/profile_models.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const ValueKey('leaderboard-scope-control'),
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? context.riksa.surfaceRaised : AppColors.editorialField,
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: LeaderboardPillTab(
              label: 'National',
              selected: selected == LeaderboardScope.country,
              onTap: () => onChanged(LeaderboardScope.country),
            ),
          ),
          Expanded(
            child: LeaderboardPillTab(
              label: 'Province',
              selected: selected == LeaderboardScope.province,
              onTap: () => onChanged(LeaderboardScope.province),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardPillTab extends StatelessWidget {
  const LeaderboardPillTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.fullBorder,
        child: AnimatedContainer(
          duration: RiksaMotion.standard,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.editorialPink : AppColors.editorialBlack)
                : Colors.transparent,
            borderRadius: AppRadii.fullBorder,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? (isDark ? AppColors.editorialAubergine : Colors.white)
                  : palette.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
