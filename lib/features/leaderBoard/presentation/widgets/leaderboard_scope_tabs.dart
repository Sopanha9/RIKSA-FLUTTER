import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../userProfile/data/profile_models.dart';
import '../../../userProfile/presentation/widgets/profile_ui.dart';

class LeaderboardScopeTabs extends StatelessWidget {
  const LeaderboardScopeTabs({
    super.key,
    required this.selected,
    required this.provinceLabel,
    required this.onChanged,
  });

  final LeaderboardScope selected;
  final String? provinceLabel;
  final ValueChanged<LeaderboardScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = (provinceLabel != null && provinceLabel!.trim().isNotEmpty)
        ? readableProfileName(provinceLabel!)
        : 'Province';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          LeaderboardPillTab(
            label: 'National',
            selected: selected == LeaderboardScope.country,
            onTap: () => onChanged(LeaderboardScope.country),
          ),
          const SizedBox(width: RiksaSpacing.xs),
          LeaderboardPillTab(
            label: label,
            selected: selected == LeaderboardScope.province,
            onTap: () => onChanged(LeaderboardScope.province),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? palette.jade : AppColors.ink)
                : palette.surface,
            borderRadius: AppRadii.fullBorder,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : palette.outline.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? (isDark ? AppColors.darkCanvas : Colors.white)
                  : palette.inkMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
