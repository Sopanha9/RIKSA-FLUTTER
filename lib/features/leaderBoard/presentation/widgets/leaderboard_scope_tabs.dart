import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_interactions.dart';
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
    return Container(
      key: const ValueKey('leaderboard-scope-control'),
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.riksa.surface,
        borderRadius: AppRadii.fullBorder,
        border: Border.all(color: context.riksa.outline),
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

    return Material(
      color: Colors.transparent,
      child: RiksaTapFeedback(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.fullBorder,
          child: AnimatedContainer(
            duration: RiksaMotion.standard,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? palette.brand : Colors.transparent,
              borderRadius: AppRadii.fullBorder,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? palette.onBrand : palette.inkMuted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
