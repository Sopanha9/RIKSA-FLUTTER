import 'package:flutter/material.dart';

import '../../../../core/widgets/riksa_segmented_tabs.dart';
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
    return RiksaSegmentedTabs<LeaderboardScope>(
      controlKey: const ValueKey('leaderboard-scope-control'),
      segments: [
        (
          value: LeaderboardScope.country,
          label: l10n.leaderboardNational,
          semanticKey: 'leaderboard-national-tab',
        ),
        (
          value: LeaderboardScope.province,
          label: l10n.leaderboardProvince,
          semanticKey: 'leaderboard-province-tab',
        ),
      ],
      selected: selected,
      onChanged: onChanged,
    );
  }
}
