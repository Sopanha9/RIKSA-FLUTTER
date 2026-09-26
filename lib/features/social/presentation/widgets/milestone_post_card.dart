import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/social_models.dart';

/// Celebration content inside the shared social row. Reactions, comments and
/// navigation stay owned by SocialPostCard so milestones behave like posts.
class MilestonePostCard extends StatelessWidget {
  const MilestonePostCard({super.key, required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final milestone = post.milestone;
    if (milestone == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final author = post.author.displayName.trim().isEmpty
        ? post.author.username
        : post.author.displayName;
    final detail = milestone.getTitle(language);
    final (emoji, headline) = switch (milestone.type) {
      SocialMilestoneType.streak => (
        '🔥',
        l10n.milestoneStreakMessage(author, milestone.value ?? 0),
      ),
      SocialMilestoneType.rankUp => (
        '🏅',
        l10n.milestoneRankMessage(author, detail),
      ),
      SocialMilestoneType.unitComplete => (
        '🎓',
        l10n.milestoneUnitMessage(author, detail),
      ),
    };
    final palette = context.riksa;
    return Container(
      key: ValueKey('milestone-${milestone.type.name}-${post.id}'),
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34, height: 1.15)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.milestoneCelebrationLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
