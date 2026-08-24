import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../social/data/social_api.dart';
import '../data/profile_models.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_ui.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rank = ref.watch(profileRankProvider);
    return Scaffold(
      backgroundColor: ProfilePalette.canvas(context),
      body: RefreshIndicator(
        color: ProfilePalette.green(context),
        onRefresh: () => ref.refresh(profileRankProvider.future),
        child: CustomScrollView(
          key: const PageStorageKey('leaderboard-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RiksaPageHeader(
                title: l10n.leaderboard,
                subtitle: l10n.learningHeaderSubtitle,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                RiksaSpacing.md,
                RiksaSpacing.sm,
                RiksaSpacing.md,
                RiksaSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: rank.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _LeaderboardError(
                    message: _rankErrorMessage(error, l10n),
                    onRetry: () => ref.invalidate(profileRankProvider),
                  ),
                  data: (data) => _RankOverview(data: data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankOverview extends StatelessWidget {
  const _RankOverview({required this.data});

  final LeaderboardRank data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('leaderboard-rank-overview'),
      children: [
        _RankCard(
          icon: Icons.public_rounded,
          label: l10n.countryRank,
          rank: data.countryRank,
          score: data.countryScore,
          tier: data.countryTier,
        ),
        const SizedBox(height: 12),
        _RankCard(
          icon: Icons.location_on_outlined,
          label: l10n.provinceRank,
          rank: data.provinceRank ?? 0,
          score: data.provinceScore ?? 0,
          tier: data.provinceTier,
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.icon,
    required this.label,
    required this.rank,
    required this.score,
    this.tier,
  });

  final IconData icon;
  final String label;
  final int rank;
  final int score;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfilePanel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ProfilePalette.greenSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ProfilePalette.green(context)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ProfilePalette.muted(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rank > 0 ? '#$rank' : l10n.unranked,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score XP',
                style: TextStyle(
                  color: ProfilePalette.xp(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (tier != null)
                Text(
                  readableProfileName(tier!),
                  style: TextStyle(
                    color: ProfilePalette.green(context),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  const _LeaderboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfilePanel(
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: Text(l10n.tryAgain)),
        ],
      ),
    );
  }
}

String _rankErrorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) return dioErrorMessage(error);
  if (error is SocialApiException) return error.message;
  return l10n.profileLoadFailed;
}
