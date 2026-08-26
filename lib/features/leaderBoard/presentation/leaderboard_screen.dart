import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:riksa_app/core/theme/app_theme.dart';
import 'package:riksa_app/core/widgets/riksa_components.dart';
import 'package:riksa_app/l10n/gen/app_localizations.dart';
import 'package:riksa_app/features/auth/providers/auth_provider.dart';
import 'package:riksa_app/features/userProfile/data/profile_models.dart';
import 'package:riksa_app/features/userProfile/presentation/widgets/profile_ui.dart';
import 'package:riksa_app/features/userProfile/providers/profile_provider.dart';
import 'widgets/leaderboard_header.dart';
import 'widgets/leaderboard_podium.dart';
import 'widgets/leaderboard_scope_tabs.dart';
import 'widgets/leaderboard_states.dart';
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

    return Scaffold(
      backgroundColor: ProfilePalette.canvas(context),
      body: RefreshIndicator(
        color: ProfilePalette.green(context),
        onRefresh: () async {
          ref.invalidate(profileRankProvider);
          ref.invalidate(leaderboardProvider(_scope));
          await Future.wait([
            ref
                .refresh(profileRankProvider.future)
                .catchError((_) => const LeaderboardRank(countryRank: 0, countryScore: 0)),
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
                      // Top Header Bar
                      LeaderboardHeader(title: '${l10n.leaderboard} 🏆'),

                      const SizedBox(height: RiksaSpacing.lg),

                      // Search Box
                      RiksaSearchField(
                        controller: _searchController,
                        hintText: 'Search learners...',
                      ),

                      const SizedBox(height: RiksaSpacing.lg),

                      // Scope Filter Tabs
                      LeaderboardScopeTabs(
                        selected: _scope,
                        provinceLabel: currentUser?.provinceId,
                        onChanged: (scope) => setState(() => _scope = scope),
                      ),

                      const SizedBox(height: RiksaSpacing.lg),

                      // Podium Section (Handles loading, error, and live server data)
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
                          return LeaderboardPodium(
                            podium: podium,
                            currentUserId: currentUser?.id,
                          );
                        },
                      ),

                      const SizedBox(height: RiksaSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),

            // Sliding Dark Sheet with Rankings List
            SliverToBoxAdapter(
              child: boardAsync.maybeWhen(
                data: (rows) {
                  final filtered = _filterRows(rows, _searchQuery);
                  final listRows = filtered.length > 3
                      ? filtered.skip(3).toList()
                      : const <LeaderboardRow>[];
                  return RankingsSheet(
                    listRows: listRows,
                    currentUser: currentUser,
                    userRankData: userRankData,
                    scope: _scope,
                    hasTotalRows: filtered.isNotEmpty,
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            // Clearance for bottom navigation
            const SliverToBoxAdapter(
              child: SizedBox(height: RiksaSpacing.xxl),
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
