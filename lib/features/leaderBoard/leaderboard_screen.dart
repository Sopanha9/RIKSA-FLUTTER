import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/riksa_avatar_image.dart';
import '../../core/widgets/riksa_components.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/data/auth_api.dart';
import '../auth/providers/auth_provider.dart';
import '../social/data/social_api.dart';
import '../userProfile/data/profile_models.dart';
import '../userProfile/presentation/public_profile_navigation.dart';
import '../userProfile/presentation/widgets/profile_ui.dart';
import '../userProfile/providers/profile_provider.dart';

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
            ref.refresh(profileRankProvider.future).catchError((_) => const LeaderboardRank(countryRank: 0, countryScore: 0)),
            ref.refresh(leaderboardProvider(_scope).future).catchError((_) => const <LeaderboardRow>[]),
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
                      _TopHeader(title: '${l10n.leaderboard} 🏆'),

                      // Fix 1: Standardized 24px vertical rhythm
                      const SizedBox(height: RiksaSpacing.lg),

                      // Search Box
                      RiksaSearchField(
                        controller: _searchController,
                        hintText: 'Search learners...',
                      ),

                      // Fix 1: Standardized 24px vertical rhythm
                      const SizedBox(height: RiksaSpacing.lg),

                      // Scope Filter Tabs
                      _ScopeFilterTabs(
                        selected: _scope,
                        provinceLabel: currentUser?.provinceId,
                        onChanged: (scope) => setState(() => _scope = scope),
                      ),

                      // Fix 1: Standardized 24px vertical rhythm
                      const SizedBox(height: RiksaSpacing.lg),

                      // Podium Section (Handles loading, error, and live server data)
                      boardAsync.when(
                        loading: () => const _PodiumLoadingShimmer(),
                        error: (error, _) => _LeaderboardError(
                          message: _rankErrorMessage(error, l10n),
                          onRetry: () {
                            ref.invalidate(leaderboardProvider(_scope));
                            ref.invalidate(profileRankProvider);
                          },
                        ),
                        data: (rows) {
                          if (rows.isEmpty && _scope == LeaderboardScope.province && (currentUser?.provinceId == null || currentUser!.provinceId!.isEmpty)) {
                            return _ProvincePrompt(
                              onSelectProvince: () => context.push('/auth/province'),
                            );
                          }
                          final filtered = _filterRows(rows, _searchQuery);
                          final podium = filtered.take(3).toList();
                          return _LeaderboardPodium(
                            podium: podium,
                            currentUserId: currentUser?.id,
                          );
                        },
                      ),

                      // Fix 1: Standardized 24px vertical rhythm before sheet
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
                  final listRows = filtered.length > 3 ? filtered.skip(3).toList() : const <LeaderboardRow>[];
                  return _RankingsSheet(
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

// ─────────────────────────────────────────────────────────────────────────────
// 1. TOP HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? context.riksa.surfaceRaised : AppColors.ink,
            shape: BoxShape.circle,
            boxShadow: RiksaElevation.low(Theme.of(context).brightness),
          ),
          child: IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? context.riksa.ink : Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SCOPE FILTER TABS
// ─────────────────────────────────────────────────────────────────────────────

class _ScopeFilterTabs extends StatelessWidget {
  const _ScopeFilterTabs({
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
          _PillTab(
            label: 'National',
            selected: selected == LeaderboardScope.country,
            onTap: () => onChanged(LeaderboardScope.country),
          ),
          const SizedBox(width: RiksaSpacing.xs),
          _PillTab(
            label: label,
            selected: selected == LeaderboardScope.province,
            onTap: () => onChanged(LeaderboardScope.province),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
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

// ─────────────────────────────────────────────────────────────────────────────
// 3. TOP 1-3 PODIUM SHOWCASE (Live Server Data)
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardPodium extends StatelessWidget {
  const _LeaderboardPodium({
    required this.podium,
    required this.currentUserId,
  });

  final List<LeaderboardRow> podium;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    if (podium.isEmpty) {
      return ProfilePanel(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 36, color: context.riksa.inkMuted),
            const SizedBox(height: 8),
            Text(
              'No ranked scholars in this scope yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.riksa.inkMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final rank1 = podium.isNotEmpty ? podium.firstWhere((r) => r.rank == 1, orElse: () => podium[0]) : null;
    final rank2 = podium.length > 1 ? podium.firstWhere((r) => r.rank == 2, orElse: () => podium[1]) : null;
    final rank3 = podium.length > 2 ? podium.firstWhere((r) => r.rank == 3, orElse: () => podium[2]) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank #2 (Left)
        Expanded(
          child: rank2 != null
              ? _PodiumCard(
                  row: rank2,
                  ringColor: const Color(0xFFA39A8C),
                  isCurrentUser: currentUserId != null && rank2.userId == currentUserId,
                  onTap: () => _openProfile(context, rank2.userId),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        // Rank #1 (Center, elevated as a whole block)
        Expanded(
          child: rank1 != null
              ? _PodiumCard(
                  row: rank1,
                  ringColor: const Color(0xFFE69A18),
                  isElevated: true,
                  hasCrown: true,
                  isCurrentUser: currentUserId != null && rank1.userId == currentUserId,
                  onTap: () => _openProfile(context, rank1.userId),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        // Rank #3 (Right)
        Expanded(
          child: rank3 != null
              ? _PodiumCard(
                  row: rank3,
                  ringColor: const Color(0xFFB87824),
                  isCurrentUser: currentUserId != null && rank3.userId == currentUserId,
                  onTap: () => _openProfile(context, rank3.userId),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _openProfile(BuildContext context, String userId) {
    final path = publicProfilePath(userId);
    if (path != null) context.push(path);
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.row,
    required this.ringColor,
    required this.onTap,
    this.isElevated = false,
    this.hasCrown = false,
    this.isCurrentUser = false,
  });

  final LeaderboardRow row;
  final Color ringColor;
  final VoidCallback onTap;
  final bool isElevated;
  final bool hasCrown;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = row.fallbackName;
    final tierLabel = row.rankingTier != null ? readableProfileName(row.rankingTier!) : 'Scholar';

    final cardContent = Material(
      color: palette.surface,
      borderRadius: AppRadii.largeBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.largeBorder,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.largeBorder,
            border: Border.all(
              color: isCurrentUser
                  ? AppColors.editorialPink
                  : (isElevated
                      ? AppColors.editorialPink.withValues(alpha: 0.8)
                      : palette.outline.withValues(alpha: 0.5)),
              width: (isElevated || isCurrentUser) ? 1.5 : 1.0,
            ),
            boxShadow: isElevated
                ? [
                    BoxShadow(
                      color: AppColors.editorialPink.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : RiksaElevation.low(Theme.of(context).brightness),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crown on top of #1
              if (hasCrown) ...[
                const Text('👑', style: TextStyle(fontSize: 18, height: 1)),
                const SizedBox(height: 2),
              ] else ...[
                const SizedBox(height: 20),
              ],

              // Avatar with rank badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 2.5),
                    ),
                    child: RiksaAvatarImage(
                      value: row.avatarUrl,
                      label: displayName,
                      size: 47,
                      backgroundColor: palette.surfaceRaised,
                      foregroundColor: palette.ink,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: row.rank == 1 ? AppColors.achievementSaffron : AppColors.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.surface, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${row.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Name
              SizedBox(
                height: 18,
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              // Subtitle / Tier
              SizedBox(
                height: 16,
                child: Text(
                  tierLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isElevated ? AppColors.editorialPink : palette.inkMuted,
                    fontSize: 10.5,
                    fontWeight: isElevated ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // XP pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.editorialPink
                      : (isDark ? palette.surfaceRaised : AppColors.ink),
                  borderRadius: AppRadii.fullBorder,
                ),
                child: Text(
                  '${row.score} XP',
                  style: TextStyle(
                    color: isCurrentUser
                        ? AppColors.ink
                        : (isDark ? palette.ink : Colors.white),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isElevated) {
      return Transform.translate(
        offset: const Offset(0, -14),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. RANKINGS SLIDING SHEET (Live Server Data)
// ─────────────────────────────────────────────────────────────────────────────

class _RankingsSheet extends StatelessWidget {
  const _RankingsSheet({
    required this.listRows,
    required this.currentUser,
    required this.userRankData,
    required this.scope,
    required this.hasTotalRows,
  });

  final List<LeaderboardRow> listRows;
  final dynamic currentUser;
  final LeaderboardRank? userRankData;
  final LeaderboardScope scope;
  final bool hasTotalRows;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark
        ? AppColors.editorialAubergineRaised
        : AppColors.editorialAubergine;

    // Resolve current user rank info from /leaderboard/me
    final userRankNumber = scope == LeaderboardScope.province
        ? (userRankData?.provinceRank ?? 0)
        : (userRankData?.countryRank ?? 0);
    final userScore = scope == LeaderboardScope.province
        ? (userRankData?.provinceScore ?? 0)
        : (userRankData?.countryScore ?? 0);
    final userTierName = scope == LeaderboardScope.province
        ? (userRankData?.provinceTier ?? 'Scholar')
        : (userRankData?.countryTier ?? 'Scholar');

    final userName = currentUser != null
        ? (currentUser.displayName.trim().isNotEmpty
            ? '${currentUser.displayName.trim()} (You)'
            : '${currentUser.username} (You)')
        : 'You';

    // Check if the current user is already shown in the displayed rows
    final userInList = currentUser != null && listRows.any((r) => r.userId == currentUser.id);

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        RiksaSpacing.md,
        RiksaSpacing.md,
        RiksaSpacing.md,
        RiksaSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Grab Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF48464C),
                borderRadius: AppRadii.fullBorder,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sheet Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rankings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (listRows.isNotEmpty)
                Text(
                  'Top ${listRows.length + 3}',
                  style: const TextStyle(
                    color: Color(0xFFCAC4D0),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Render live list rows (#4+)
          for (final row in listRows) ...[
            _RankingListRow(
              rank: row.rank,
              name: row.fallbackName,
              subtitle: row.rankingTier != null ? readableProfileName(row.rankingTier!) : 'Scholar',
              xp: row.score,
              avatarUrl: row.avatarUrl,
              avatarLabel: row.fallbackName,
              isCurrentUser: currentUser != null && row.userId == currentUser.id,
              onTap: () {
                final path = publicProfilePath(row.userId);
                if (path != null) context.push(path);
              },
            ),
            const SizedBox(height: 10),
          ],

          // If current user is not in the list and has a rank, show gap indicator + user rank row
          if (!userInList && currentUser != null && userRankNumber > 0) ...[
            const _RankGapIndicator(),
            const SizedBox(height: 8),
            _RankingListRow(
              rank: userRankNumber,
              name: userName,
              subtitle: '${readableProfileName(userTierName)} • ${scope == LeaderboardScope.province ? "Province" : "National"}',
              xp: userScore,
              avatarUrl: currentUser.avatarUrl,
              avatarLabel: userName,
              isCurrentUser: true,
              onTap: () => context.push('/profile'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. CONSOLIDATED LIST ROW
// ─────────────────────────────────────────────────────────────────────────────

class _RankingListRow extends StatelessWidget {
  const _RankingListRow({
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.xp,
    required this.avatarLabel,
    this.avatarUrl,
    this.isCurrentUser = false,
    this.onTap,
  });

  final int rank;
  final String name;
  final String subtitle;
  final int xp;
  final String avatarLabel;
  final String? avatarUrl;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrentUser ? const Color(0xFFFFF9FC) : Colors.white,
      borderRadius: AppRadii.largeBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.largeBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.largeBorder,
            border: Border.all(
              color: isCurrentUser ? AppColors.editorialPink : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Left-aligned fixed width rank column
              SizedBox(
                width: 34,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isCurrentUser
                        ? AppColors.editorialPink
                        : const Color(0xFF70695E),
                  ),
                ),
              ),

              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser
                        ? AppColors.editorialPink
                        : AppColors.brandJade,
                    width: 2,
                  ),
                ),
                child: RiksaAvatarImage(
                  value: avatarUrl,
                  label: avatarLabel,
                  size: 34,
                  backgroundColor: const Color(0xFFF2EFE9),
                  foregroundColor: const Color(0xFF121212),
                ),
              ),

              const SizedBox(width: 10),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF121212),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: AppRadii.smallBorder,
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF70695E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // XP pill: pink for current user, black for default
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentUser ? AppColors.editorialPink : AppColors.ink,
                  borderRadius: AppRadii.fullBorder,
                ),
                child: Text(
                  '$xp XP',
                  style: TextStyle(
                    color: isCurrentUser ? AppColors.ink : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Action arrow button
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.ink
                      : AppColors.editorialPinkSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isCurrentUser ? Colors.white : AppColors.ink,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. LOADING SHIMMER & HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _PodiumLoadingShimmer extends StatelessWidget {
  const _PodiumLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ProvincePrompt extends StatelessWidget {
  const _ProvincePrompt({required this.onSelectProvince});

  final VoidCallback onSelectProvince;

  @override
  Widget build(BuildContext context) {
    return ProfilePanel(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.location_on_outlined, size: 36, color: context.riksa.jade),
          const SizedBox(height: 8),
          const Text(
            'Select your province to see your local community leaderboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onSelectProvince,
            child: const Text('Set Province'),
          ),
        ],
      ),
    );
  }
}

class _RankGapIndicator extends StatelessWidget {
  const _RankGapIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '• • •',
          style: TextStyle(
            color: Color(0xFF70695E),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────

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
