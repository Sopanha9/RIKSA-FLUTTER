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
  LeaderboardScope _scope = LeaderboardScope.country;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
        ? (userRankData?.provinceTier ?? 'Scholar')
        : (userRankData?.countryTier ?? 'Scholar');
    final showCurrentUserRank = currentUser != null && userRankNumber > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? context.riksa.canvas
          : AppColors.editorialNeutralCanvas,
      body: RefreshIndicator(
        color: AppColors.editorialPink,
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
                      const SizedBox(height: RiksaSpacing.lg),
                      _LeaderboardSearchField(controller: _searchController),
                      const SizedBox(height: RiksaSpacing.md),
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
                                  context.push('/auth/province'),
                            );
                          }

                          final filtered = _filterRows(rows, _searchQuery);
                          final podium = filtered.take(3).toList();
                          final listRows = filtered.length > 3
                              ? filtered.skip(3).toList()
                              : const <LeaderboardRow>[];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LeaderboardPodium(
                                podium: podium,
                                currentUserId: currentUser?.id,
                              ),
                              if (showCurrentUserRank) ...[
                                const SizedBox(height: RiksaSpacing.sm),
                                CurrentUserRankCard(
                                  rank: userRankNumber,
                                  name:
                                      currentUser.displayName.trim().isNotEmpty
                                      ? currentUser.displayName.trim()
                                      : currentUser.username,
                                  tier: readableProfileName(userTierName),
                                  scopeLabel:
                                      _scope == LeaderboardScope.province
                                      ? 'Province'
                                      : 'National',
                                  xp: userScore,
                                  avatarUrl: currentUser.avatarUrl,
                                  avatarLabel:
                                      currentUser.displayName.trim().isNotEmpty
                                      ? currentUser.displayName.trim()
                                      : currentUser.username,
                                  onTap: () => context.push('/profile'),
                                ),
                              ],
                              const SizedBox(height: RiksaSpacing.md),
                              RankingsSheet(
                                listRows: listRows,
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
}

class _LeaderboardSearchField extends StatelessWidget {
  const _LeaderboardSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search learners',
        hintStyle: TextStyle(
          color: isDark ? context.riksa.inkMuted : AppColors.editorialMuted,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: isDark
            ? context.riksa.surfaceRaised
            : AppColors.editorialField,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RiksaSpacing.md,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.fullBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.fullBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.fullBorder,
          borderSide: BorderSide(color: AppColors.editorialPink, width: 1.5),
        ),
      ),
    );
  }
}
