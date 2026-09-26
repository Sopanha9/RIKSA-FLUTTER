import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/profile_ui.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'widgets/leaderboard_header.dart';
import 'widgets/leaderboard_podium.dart';
import 'widgets/leaderboard_scope_tabs.dart';
import 'widgets/leaderboard_states.dart';
import 'widgets/current_user_rank_card.dart';
import 'widgets/rankings_sheet.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late LeaderboardScope _scope;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    _scope = user?.provinceId?.isNotEmpty == true
        ? LeaderboardScope.province
        : LeaderboardScope.country;
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() => _searchQuery = query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final rankAsync = ref.watch(profileRankProvider);
    final boardAsync = ref.watch(leaderboardProvider(_scope));

    final currentUser = auth is Authenticated ? auth.user : null;
    final userRankData = rankAsync.asData?.value;

    final userRankNumber = _scope == LeaderboardScope.province
        ? (userRankData?.provinceRank ?? 0)
        : (userRankData?.countryRank ?? 0);
    final userScore = _scope == LeaderboardScope.province
        ? (userRankData?.provinceScore ?? 0)
        : (userRankData?.countryScore ?? 0);
    final userTierName = _scope == LeaderboardScope.province
        ? (userRankData?.provinceTier ?? l10n.startingTier)
        : (userRankData?.countryTier ?? l10n.startingTier);
    final showCurrentUserRank = currentUser != null && userRankNumber > 0;
    return Scaffold(
      backgroundColor: context.riksa.canvas,
      body: RefreshIndicator(
        color: context.riksa.brand,
        onRefresh: () async {
          ref.invalidate(profileRankProvider);
          ref.invalidate(leaderboardProvider(_scope));
          await Future.wait([
            ref
                .refresh(profileRankProvider.future)
                .catchError(
                  (_) => const LeaderboardRank(countryRank: 0, countryScore: 0),
                ),
            ref
                .refresh(leaderboardProvider(_scope).future)
                .catchError((_) => const <LeaderboardRow>[]),
          ]);
        },
        child: CustomScrollView(
          key: const PageStorageKey('leaderboard-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  RiksaSpacing.md,
                  RiksaSpacing.sm,
                  RiksaSpacing.md,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LeaderboardHeader(title: l10n.leaderboard),
                      const SizedBox(height: RiksaSpacing.sm),
                      LeaderboardScopeTabs(
                        selected: _scope,
                        onChanged: (scope) => setState(() => _scope = scope),
                      ),
                      const SizedBox(height: RiksaSpacing.md),
                      boardAsync.when(
                        loading: () => const PodiumLoadingShimmer(),
                        error: (error, _) => LeaderboardError(
                          message: leaderboardErrorMessage(error, l10n),
                          onRetry: () {
                            ref.invalidate(leaderboardProvider(_scope));
                            ref.invalidate(profileRankProvider);
                          },
                        ),
                        data: (rows) {
                          if (rows.isEmpty &&
                              _scope == LeaderboardScope.province &&
                              (currentUser?.provinceId == null ||
                                  currentUser!.provinceId!.isEmpty)) {
                            return ProvincePrompt(
                              onSelectProvince: () =>
                                  context.push('/province-select'),
                            );
                          }

                          final filtered = _filterRows(rows, _searchQuery);
                          // The top three stand on the podium; the list picks
                          // up at fourth. A search shows every match as rows,
                          // since a filtered podium would crown the wrong
                          // people.
                          final showPodium =
                              _searchQuery.isEmpty && filtered.isNotEmpty;
                          final podium = showPodium
                              ? filtered.where((row) => row.rank <= 3).toList()
                              : const <LeaderboardRow>[];
                          final listRows = showPodium
                              ? filtered.where((row) => row.rank > 3).toList()
                              : filtered;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showPodium) ...[
                                LeaderboardPodium(
                                  podium: podium,
                                  currentUserId: currentUser?.id,
                                ),
                                const SizedBox(height: RiksaSpacing.md),
                              ],
                              if (showCurrentUserRank)
                                CurrentUserRankCard(
                                  rank: userRankNumber,
                                  name:
                                      currentUser.displayName.trim().isNotEmpty
                                      ? currentUser.displayName.trim()
                                      : currentUser.username,
                                  tier: readableProfileName(userTierName),
                                  scopeLabel:
                                      _scope == LeaderboardScope.province
                                      ? l10n.leaderboardProvince
                                      : l10n.leaderboardNational,
                                  xp: userScore,
                                  avatarUrl: currentUser.avatarUrl,
                                  avatarLabel:
                                      currentUser.displayName.trim().isNotEmpty
                                      ? currentUser.displayName.trim()
                                      : currentUser.username,
                                  onTap: () => context.push('/profile'),
                                ),
                              if (showCurrentUserRank &&
                                  _searchQuery.isEmpty) ...[
                                const SizedBox(height: RiksaSpacing.md),
                                Text(
                                  l10n.leaderboardNearbyLearners,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: RiksaSpacing.xs),
                                for (final row in _nearbyRows(
                                  rows,
                                  userRankNumber,
                                ))
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Text('#${row.rank}'),
                                    title: Text(
                                      row.userId == currentUser.id
                                          ? l10n.homeYou
                                          : row.fallbackName,
                                    ),
                                    trailing: Text(l10n.xpAmount(row.score)),
                                  ),
                              ],
                              const SizedBox(height: RiksaSpacing.md),
                              _LeaderboardSearchField(
                                controller: _searchController,
                              ),
                              const SizedBox(height: RiksaSpacing.md),
                              RankingsSheet(
                                listRows: listRows,
                                totalCount: filtered.length,
                                currentUser: currentUser,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + RiksaSpacing.lg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LeaderboardRow> _filterRows(List<LeaderboardRow> rows, String query) {
    if (query.isEmpty) return rows;
    return rows.where((row) {
      final name = row.displayName?.toLowerCase() ?? '';
      final tier = row.rankingTier?.toLowerCase() ?? '';
      return name.contains(query) || tier.contains(query);
    }).toList();
  }

  List<LeaderboardRow> _nearbyRows(List<LeaderboardRow> rows, int rank) {
    final sorted = [...rows]
      ..sort((a, b) =>
          (a.rank - rank).abs().compareTo((b.rank - rank).abs()));
    return sorted.take(3).toList(growable: false)
      ..sort((a, b) => a.rank.compareTo(b.rank));
  }
}

class _LeaderboardSearchField extends StatelessWidget {
  const _LeaderboardSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.leaderboardSearchLearners,
        hintStyle: TextStyle(color: context.riksa.inkMuted),
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: context.riksa.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RiksaSpacing.md,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.fullBorder,
          borderSide: BorderSide(color: context.riksa.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.fullBorder,
          borderSide: BorderSide(color: context.riksa.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.fullBorder,
          borderSide: BorderSide(color: context.riksa.brand, width: 1.5),
        ),
      ),
    );
  }
}
