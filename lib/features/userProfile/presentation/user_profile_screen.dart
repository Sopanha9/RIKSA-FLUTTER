import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_bottom_navigation_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/profile_models.dart';
import '../providers/profile_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late final ScrollController _scrollController;
  bool _navigationCollapsed = false;
  double _directionTravel = 0;
  double? _lastOffset;
  ScrollDirection? _trackedDirection;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final current = position.pixels;
    final previous = _lastOffset ?? current;
    _lastOffset = current;
    final delta = current - previous;
    final direction = position.userScrollDirection;
    final down = direction == ScrollDirection.reverse && delta > 0;
    final up = direction == ScrollDirection.forward && delta < 0;
    if ((!down && !up) || delta.abs() < .1) return;

    if (_trackedDirection != direction) {
      _trackedDirection = direction;
      _directionTravel = 0;
    }
    _directionTravel += delta.abs();
    if (_directionTravel < 18) return;
    _directionTravel = 0;
    if (_navigationCollapsed != down) {
      setState(() => _navigationCollapsed = down);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final dashboard = ref.watch(profileDashboardProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: RiksaBottomNavigationBar(
        currentIndex: 4,
        collapsed: _navigationCollapsed,
        onSelected: (index) {
          if (index == 1) context.go('/learn');
          if (index == 2) context.go('/home');
        },
        onCollapsedTap: () {
          setState(() => _navigationCollapsed = false);
        },
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimaryHover,
        onRefresh: () async {
          ref.invalidate(profileDashboardProvider);
          await ref.read(profileDashboardProvider.future);
        },
        child: CustomScrollView(
          key: const PageStorageKey('user-profile-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                l10n.profile,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton.filledTonal(
                  key: const ValueKey('profile-account-menu'),
                  tooltip: l10n.accountSettings,
                  onPressed: user == null
                      ? null
                      : () => _showAccountSheet(user),
                  icon: const Icon(Icons.more_vert_rounded),
                ),
                const SizedBox(width: 12),
              ],
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: Column(
                      children: [
                        _ProfileHero(user: user),
                        const SizedBox(height: 18),
                        dashboard.when(
                          loading: () => const _ProfileLoading(),
                          error: (error, _) => _ProfileError(
                            message: _errorMessage(error, l10n),
                            onRetry: () =>
                                ref.invalidate(profileDashboardProvider),
                          ),
                          data: (data) => _DashboardContent(data: data),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 118)),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object error, AppLocalizations l10n) {
    if (error is DioException) return dioErrorMessage(error);
    return l10n.profileLoadFailed;
  }

  Future<void> _showAccountSheet(AuthUser user) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.accountSettings,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              _AccountRow(
                icon: Icons.alternate_email_rounded,
                label: user.email ?? '@${user.username}',
                value: user.emailVerified ? l10n.verified : l10n.notVerified,
              ),
              const SizedBox(height: 12),
              _AccountRow(
                icon: Icons.shield_outlined,
                label: l10n.accountRole,
                value: _readableName(user.role),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const ValueKey('profile-logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(sheetContext).colorScheme.error,
                ),
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) context.go('/auth/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : user?.username ?? l10n.riksaLearner;
    final bio = user?.bio?.trim();
    final memberSince = user?.createdAt == null
        ? null
        : DateFormat.yMMM(
            Localizations.localeOf(context).languageCode,
          ).format(user!.createdAt!.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F6EB), Color(0xFFCDEFD8)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFB7E1C3)),
      ),
      child: Column(
        children: [
          _ProfileAvatar(user: user, displayName: displayName),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF143C20),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '@${user?.username ?? 'riksa'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF496551),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF294A32),
                height: 1.45,
              ),
            ),
          ],
          if (memberSince != null) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .68),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.memberSince(memberSince),
                style: const TextStyle(
                  color: Color(0xFF36583E),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.displayName});

  final AuthUser? user;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final url = _assetUrl(user?.avatarUrl);
    final initial = displayName.isEmpty ? 'R' : displayName[0].toUpperCase();
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimaryPressed.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFDEF3E5),
        foregroundImage: url == null ? null : NetworkImage(url),
        onForegroundImageError: url == null ? null : (_, _) {},
        child: Text(
          initial,
          style: const TextStyle(
            color: Color(0xFF173F25),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final ProfileDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gamification = data.gamification;
    final achievements = [...data.achievements]
      ..sort((a, b) {
        if (a.earned != b.earned) return a.earned ? -1 : 1;
        return b.progressPercent.compareTo(a.progressPercent);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                key: const ValueKey('profile-total-xp'),
                icon: Icons.bolt_rounded,
                value: NumberFormat.compact().format(gamification.totalXp),
                label: l10n.totalXp,
                background: const Color(0xFFE4F3E8),
                foreground: const Color(0xFF1D5A2E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                key: const ValueKey('profile-streak'),
                icon: Icons.local_fire_department_rounded,
                value: '${gamification.currentStreak}',
                label: l10n.currentStreak,
                background: const Color(0xFFFFEFE4),
                foreground: const Color(0xFFAD4E19),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                key: const ValueKey('profile-achievements'),
                icon: Icons.workspace_premium_rounded,
                value: '${data.earnedAchievementCount}',
                label: l10n.achievements,
                background: const Color(0xFFF1EFE3),
                foreground: const Color(0xFF625A22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _TierProgressCard(gamification: gamification),
        const SizedBox(height: 26),
        _SectionTitle(title: l10n.achievements),
        const SizedBox(height: 12),
        if (achievements.isEmpty)
          _EmptyCard(
            icon: Icons.workspace_premium_outlined,
            message: l10n.noAchievements,
          )
        else
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _AchievementCard(achievement: achievements[index]),
            ),
          ),
        const SizedBox(height: 26),
        _SectionTitle(title: l10n.recentActivity),
        const SizedBox(height: 12),
        if (data.activities.isEmpty)
          _EmptyCard(
            icon: Icons.history_rounded,
            message: l10n.noRecentActivity,
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < data.activities.length;
                  index++
                ) ...[
                  _ActivityRow(activity: data.activities[index]),
                  if (index < data.activities.length - 1)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    height: 116,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: foreground, size: 22),
        const Spacer(),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: foreground,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground.withValues(alpha: .72),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    ),
  );
}

class _TierProgressCard extends StatelessWidget {
  const _TierProgressCard({required this.gamification});

  final GamificationProfile gamification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentTier = _readableName(
      gamification.currentTier ?? l10n.startingTier,
    );
    final nextTier = gamification.nextTier == null
        ? null
        : _readableName(gamification.nextTier!);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18201C),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B3830),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF73D68E),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentRank,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .62),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currentTier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${gamification.totalXp} XP',
                style: const TextStyle(
                  color: Color(0xFF8BE2A2),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: gamification.nextTierProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: .13),
              color: const Color(0xFF56C975),
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              nextTier == null
                  ? l10n.highestRankReached
                  : l10n.xpUntilNextRank(gamification.xpToNext, nextTier),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final ProfileAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _achievementColors(achievement.rarity);
    return Container(
      width: 158,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.$2.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AchievementIcon(achievement: achievement, color: colors.$2),
              const Spacer(),
              Icon(
                achievement.earned
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                color: colors.$2,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            achievement.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.$2,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: achievement.progressPercent,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .68),
              color: colors.$2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.earned
                ? l10n.earned
                : '${achievement.progress}/${achievement.progressMax}',
            style: TextStyle(
              color: colors.$2.withValues(alpha: .78),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  const _AchievementIcon({required this.achievement, required this.color});

  final ProfileAchievement achievement;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = _assetUrl(achievement.iconUrl);
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        shape: BoxShape.circle,
      ),
      child: url == null
          ? Icon(Icons.workspace_premium_rounded, color: color, size: 23)
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.workspace_premium_rounded, color: color, size: 23),
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final XpActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = activity.createdAt == null
        ? ''
        : DateFormat.MMMd(
            Localizations.localeOf(context).languageCode,
          ).add_jm().format(activity.createdAt!.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F5EB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _activityIcon(activity.sourceType),
              color: AppColors.brandPrimaryPressed,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activityLabel(l10n, activity.sourceType),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '+${activity.amount} XP',
            style: const TextStyle(
              color: AppColors.brandPrimaryHover,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.brandPrimaryHover, size: 30),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      SizedBox(height: 116, child: LinearProgressIndicator()),
      SizedBox(height: 18),
      SizedBox(height: 150, child: LinearProgressIndicator()),
    ],
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _EmptyCardWithAction(
      message: message,
      actionLabel: l10n.tryAgain,
      onAction: onRetry,
    );
  }
}

class _EmptyCardWithAction extends StatelessWidget {
  const _EmptyCardWithAction({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: AppColors.brandPrimaryHover,
          size: 34,
        ),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.brandPrimaryPressed),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

String? _assetUrl(String? value) {
  final path = value?.trim();
  if (path == null || path.isEmpty) return null;
  final uri = Uri.tryParse(path);
  if (uri?.hasScheme == true) return path;
  return '${ApiConfig.baseUrl}${path.startsWith('/') ? path : '/$path'}';
}

String _readableName(String value) => value
    .toLowerCase()
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

(Color, Color) _achievementColors(String rarity) => switch (rarity) {
  'LEGENDARY' => (const Color(0xFFFFE9D9), const Color(0xFF9A4A13)),
  'EPIC' => (const Color(0xFFEDE8F5), const Color(0xFF60458A)),
  'RARE' => (const Color(0xFFE5F0ED), const Color(0xFF286353)),
  _ => (const Color(0xFFF1EFE3), const Color(0xFF655D28)),
};

IconData _activityIcon(String sourceType) => switch (sourceType) {
  'LESSON_COMPLETION' => Icons.menu_book_rounded,
  'ACHIEVEMENT_REWARD' => Icons.workspace_premium_rounded,
  'MAINTAIN_STREAK' => Icons.local_fire_department_rounded,
  'REACH_RANK' => Icons.emoji_events_rounded,
  'WELCOME_BONUS' => Icons.celebration_rounded,
  _ => Icons.bolt_rounded,
};

String _activityLabel(AppLocalizations l10n, String sourceType) =>
    switch (sourceType) {
      'LESSON_COMPLETION' => l10n.lessonCompletionReward,
      'ACHIEVEMENT_REWARD' => l10n.achievementReward,
      'MAINTAIN_STREAK' => l10n.streakReward,
      'REACH_RANK' => l10n.rankReward,
      'WELCOME_BONUS' => l10n.welcomeBonus,
      _ => l10n.xpReward,
    };
