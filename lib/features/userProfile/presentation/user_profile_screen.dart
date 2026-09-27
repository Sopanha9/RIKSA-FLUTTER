import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_rank_badge.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blog/data/blog_models.dart';
import '../../blog/providers/blog_provider.dart';
import '../../social/data/social_api.dart';
import '../../social/data/social_models.dart';
import '../../social/presentation/widgets/social_create_menu.dart';
import '../../social/presentation/widgets/social_owner_menu.dart';
import '../../social/presentation/widgets/social_post_card.dart';
import '../../social/providers/social_feed_provider.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_companion.dart';
import '../../mascot/providers/mascot_provider.dart';
import '../data/profile_models.dart';
import '../providers/profile_cover_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_cover.dart';
import 'widgets/profile_post_actions.dart';
import 'widgets/profile_ui.dart';
import 'public_profile_navigation.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _scrollController = ScrollController();
  ProfileTab _tab = ProfileTab.posts;
  bool _showSavedShortcut = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final dashboard = ref.watch(profileDashboardProvider);
    final l10n = AppLocalizations.of(context)!;

    return ProfilePaletteScope.editorial(
      context: context,
      child: Builder(
        builder: (context) => Scaffold(
          key: const ValueKey('personal-profile-scaffold'),
          backgroundColor: context.riksa.canvas,
          floatingActionButton: AnimatedSlide(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            curve: RiksaMotion.standardCurve,
            offset: _showSavedShortcut ? Offset.zero : const Offset(1.2, 0),
            child: AnimatedOpacity(
              duration: RiksaMotion.resolve(context, RiksaMotion.standard),
              opacity: _showSavedShortcut ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_showSavedShortcut,
                child: _SavedLessonsSideShortcut(
                  label: l10n.menuSavedLessons,
                  onTap: () => context.push('/learn/saved'),
                ),
              ),
            ),
          ),
          body: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (!_showSavedShortcut) {
                  setState(() => _showSavedShortcut = true);
                }
              } else if (notification.direction == ScrollDirection.forward) {
                if (_showSavedShortcut) {
                  setState(() => _showSavedShortcut = false);
                }
              }
              return false;
            },
            child: RefreshIndicator(
              color: ProfilePalette.green(context),
              onRefresh: () async {
                ref
                  ..invalidate(profileDashboardProvider)
                  ..invalidate(profileRankProvider);
                if (user != null) ref.invalidate(userPostsProvider(user.id));
                await ref.read(profileDashboardProvider.future);
              },
              child: CustomScrollView(
                key: const PageStorageKey('user-profile-scroll'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverSafeArea(
                    bottom: false,
                    sliver: SliverToBoxAdapter(
                      child: centeredProfileColumn(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                          child: _ProfileTopBar(
                            shareLabel: l10n.shareProfile,
                            settingsLabel: l10n.settings,
                            editLabel: l10n.editProfile,
                            onShare: user == null ? null : () => _share(user),
                            onSettings: () => context.push('/profile/settings'),
                            onEdit: () => context.push('/profile/edit'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: centeredProfileColumn(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: user == null
                            ? const _ProfileLoading()
                            : _ProfileHeader(user: user, dashboard: dashboard),
                      ),
                    ),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: ProfileTabsHeaderDelegate(
                      extent: ProfileTabs.heightFor(context),
                      color: context.riksa.canvas,
                      tabs: ProfileTabs(
                        selected: _tab,
                        postsLabel: l10n.posts,
                        articlesLabel: l10n.profileArticlesTab,
                        achievementsLabel: l10n.profileBadgesTab,
                        rankLabel: l10n.profileRankTab,
                        onSelected: (tab) => setState(() => _tab = tab),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: centeredProfileColumn(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                        child: AnimatedSwitcher(
                          duration: RiksaMotion.resolve(
                            context,
                            RiksaMotion.standard,
                          ),
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  ...previousChildren,
                                  ?currentChild,
                                ],
                              ),
                          child: user == null
                              ? const _ProfileLoading()
                              : switch (_tab) {
                                  ProfileTab.posts => _PostsTab(user: user),
                                  ProfileTab.articles => _ArticlesTab(
                                    user: user,
                                  ),
                                  ProfileTab.achievements => _AchievementsTab(
                                    dashboard: dashboard,
                                  ),
                                  ProfileTab.rank => const _RankTab(),
                                },
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _bottomInteractiveClearance(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share(AuthUser user) async {
    await Clipboard.setData(ClipboardData(text: '/profile/${user.id}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileLinkCopied),
        ),
      );
  }

  double _bottomInteractiveClearance(BuildContext context) {
    if (_tab == ProfileTab.posts) {
      final auth = ref.watch(authProvider);
      final user = auth is Authenticated ? auth.user : null;
      if (user != null) {
        final posts = ref.watch(userPostsProvider(user.id));
        if (posts.asData?.value.posts.isEmpty == true) {
          return MediaQuery.paddingOf(context).bottom + 24;
        }
      }
    }
    return MediaQuery.paddingOf(context).bottom + 112;
  }
}

class _SavedLessonsSideShortcut extends StatelessWidget {
  const _SavedLessonsSideShortcut({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? palette.surface.withValues(alpha: .46)
        : Colors.white.withValues(alpha: .58);
    final border = isDark
        ? Colors.white.withValues(alpha: .12)
        : Colors.white.withValues(alpha: .72);

    return Tooltip(
      message: label,
      child: Container(
        width: 60,
        height: 60,
        decoration: ShapeDecoration(
          shape: CircleBorder(side: BorderSide(color: border)),
          shadows: [
            BoxShadow(
              color: palette.ink.withValues(alpha: isDark ? .18 : .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          color: fill,
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.54),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.36),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey('profile-saved-lessons-side-shortcut'),
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: Center(
                      child: Icon(
                        Icons.bookmark_border_rounded,
                        color: palette.brand,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen's action row.
///
/// It carries no "Profile" title: the bottom navigation already labels this
/// tab, and repeating it here spent a full row on a word the user can see.
/// Utilities sit leading, the one primary action trailing.
class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.shareLabel,
    required this.settingsLabel,
    required this.editLabel,
    required this.onShare,
    required this.onSettings,
    required this.onEdit,
  });

  final String shareLabel;
  final String settingsLabel;
  final String editLabel;
  final VoidCallback? onShare;
  final VoidCallback onSettings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        ProfileIconAction(
          key: const ValueKey('profile-share'),
          tooltip: shareLabel,
          icon: Icons.ios_share_rounded,
          onPressed: onShare ?? () {},
        ),
        const SizedBox(width: 8),
        ProfileIconAction(
          key: const ValueKey('profile-settings'),
          tooltip: settingsLabel,
          icon: Icons.settings_outlined,
          onPressed: onSettings,
        ),
        // Expanded, not Spacer plus Flexible: those two compete for the free
        // space and truncate a long Khmer label while room is still going
        // spare. Here the button takes all of it and aligns itself trailing.
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _ProfileEditButton(
              key: const ValueKey('profile-edit'),
              label: editLabel,
              onPressed: onEdit,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The primary action on the signed-in user's own profile, matching the
/// position X gives its edit control.
class _ProfileEditButton extends StatelessWidget {
  const _ProfileEditButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
    ),
    // Styled on the child so the label keeps the theme's font family.
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
    ),
  );
}

/// Identity card from the reference profile: a slim cover strip, the avatar
/// hanging off its leading edge, name and tier, then XP progress through the
/// current tier. The learning numbers follow in their own row.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user, required this.dashboard});

  final AuthUser user;
  final AsyncValue<ProfileDashboardData> dashboard;

  static const double _coverHeight = 84;
  static const double _avatarRadius = 42;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final game = dashboard.asData?.value.gamification;
    final achievements = dashboard.asData?.value.achievements ?? const [];
    final earnedAchievements = achievements.where((item) => item.earned).length;
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName.trim();
    final handle = user.username.trim();
    final coverId = ref.watch(profileCoverProvider);
    final localAvatar = ref.watch(profileAvatarProvider);
    final decimal = NumberFormat.decimalPattern(locale);
    final meta = [
      ?_provinceLabel(ref, locale),
      if (user.createdAt != null)
        '${l10n.joined} ${DateFormat.yMMMM(locale).format(user.createdAt!.toLocal())}',
    ].join(' • ');
    final buddy = ref.watch(mascotProvider).profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadii.largeBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              key: const ValueKey('profile-learning-card'),
              decoration: BoxDecoration(
                color: context.riksa.surface.withValues(alpha: 0.6),
                borderRadius: AppRadii.largeBorder,
                border: Border.all(
                  color: context.riksa.outline.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileCover(
                        key: const ValueKey('profile-cover'),
                        coverId: coverId,
                        height: _coverHeight,
                        borderRadius: BorderRadius.zero,
                      ),
                      PositionedDirectional(
                        start: 14,
                        top: _coverHeight - _avatarRadius,
                        child: ProfileHeroAvatar(
                          key: const ValueKey('profile-hero-avatar'),
                          user: user,
                          radius: _avatarRadius,
                          avatarPath: localAvatar,
                          frameTier: game?.currentTier,
                          editLabel: l10n.changePhoto,
                          onEdit: () => context.push('/profile/edit'),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    // Clears the half of the avatar that hangs below the cover.
                    padding: EdgeInsetsDirectional.fromSTEB(
                      14 + _avatarRadius * 2 + 12,
                      8,
                      14,
                      0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: _avatarRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: RiksaTypography.titleStyleFor(
                                    name,
                                    theme.textTheme.titleMedium?.copyWith(
                                      color: context.riksa.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (user.emailVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified_rounded,
                                  key: const ValueKey(
                                    'profile-verification-badge',
                                  ),
                                  size: 17,
                                  color: ProfilePalette.green(context),
                                ),
                              ],
                            ],
                          ),
                          if (handle.isNotEmpty)
                            Text(
                              '@$handle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.riksa.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: _ProfileTierProgress(gamification: game),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (user.bio?.trim().isNotEmpty == true || meta.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.bio?.trim().isNotEmpty == true)
                  Text(
                    user.bio!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.bodyStyleFor(
                      user.bio!.trim(),
                      theme.textTheme.bodyMedium?.copyWith(
                        color: context.riksa.ink,
                      ),
                    ),
                  ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: RiksaTypography.bodyStyleFor(
                      meta,
                      theme.textTheme.bodySmall?.copyWith(
                        color: context.riksa.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (buddy != null) ...[
          const SizedBox(height: RiksaSpacing.sm),
          Row(
            key: const ValueKey('profile-buddy-identity'),
            children: [
              const BuddyFaceReaction(
                face: MascotFace.proud,
                size: 44,
                loops: 1,
              ),
              const SizedBox(width: RiksaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileStudyBuddy,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.riksa.inkMuted,
                      ),
                    ),
                    Text(
                      buddy.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _ProfileStats(
          items: [
            (
              key: null,
              value: decimal.format(game?.totalXp ?? 0),
              label: l10n.totalXp,
            ),
            (
              key: const ValueKey('profile-streak'),
              value: decimal.format(game?.currentStreak ?? 0),
              label: l10n.currentStreak,
            ),
            (
              key: null,
              value: decimal.format(earnedAchievements),
              label: l10n.achievements,
            ),
          ],
        ),
      ],
    );
  }

  /// The user's province, once the options list has resolved. Absent while it
  /// loads rather than showing a raw province id.
  String? _provinceLabel(WidgetRef ref, String locale) {
    final provinceId = user.provinceId;
    if (provinceId == null || provinceId.isEmpty) return null;
    final options = ref.watch(provinceOptionsProvider).asData?.value;
    if (options == null) return null;
    for (final option in options) {
      if (option.id != provinceId) continue;
      final label = locale == 'km' ? option.nameKhmer : option.nameLatin;
      return label.trim().isEmpty ? null : label.trim();
    }
    return null;
  }
}

/// Tier pill, then how far through the current tier the learner is.
class _ProfileTierProgress extends StatelessWidget {
  const _ProfileTierProgress({required this.gamification});

  final GamificationProfile? gamification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final decimal = NumberFormat.decimalPattern(locale);
    final palette = context.riksa;
    final game = gamification;
    final tier = readableProfileName(game?.currentTier ?? l10n.startingTier);
    final ladderIndex = game?.currentTier == null
        ? -1
        : profileTierLadder.indexOf(game!.currentTier!.toUpperCase());
    final nextTier = game?.nextTier;
    final isFinalStep =
        nextTier != null &&
        profileTierLadder.indexOf(nextTier.toUpperCase()) ==
            profileTierLadder.length - 1;
    final progressLabel = nextTier == null
        ? l10n.highestRankReached
        : isFinalStep
        ? l10n.xpUntilFinalRank(
            game?.xpToNext ?? 0,
            readableProfileName(nextTier),
          )
        : l10n.xpUntilNextRank(
            game?.xpToNext ?? 0,
            readableProfileName(nextTier),
          );
    final band = game != null && game.tierBandXp > 0
        ? l10n.tierBandProgress(
            decimal.format(game.xpIntoTier),
            decimal.format(game.tierBandXp),
          )
        : null;
    final small = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: context.riksa.inkMuted,
      fontWeight: FontWeight.w500,
    );

    return Semantics(
      label: ladderIndex < 0
          ? tier
          : '$tier, ${l10n.tierPosition(ladderIndex + 1, profileTierLadder.length)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                flex: 2,
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 10, 3),
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: AppRadii.fullBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RiksaRankBadge(tier: game?.currentTier, size: 20),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tier,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: palette.brand,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (band != null)
                Expanded(
                  flex: 1,
                  child: Text(
                    band,
                    key: const ValueKey('profile-tier-band'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: small,
                  ),
                ),
            ],
          ),
          // At the top of the ladder there is nothing left to fill, and a
          // permanently full bar is decoration.
          if (nextTier != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: AppRadii.fullBorder,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: (game?.nextTierProgress ?? 0).clamp(0, 1).toDouble(),
                ),
                duration: RiksaMotion.resolve(
                  context,
                  RiksaMotion.emphasisLong,
                ),
                curve: RiksaMotion.standardCurve,
                builder: (context, animated, _) => LinearProgressIndicator(
                  key: const ValueKey('profile-level-progress'),
                  value: animated,
                  minHeight: 6,
                  backgroundColor: palette.brandSoft,
                  valueColor: AlwaysStoppedAnimation(palette.brand),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(progressLabel, style: small),
        ],
      ),
    );
  }
}

/// Three learning numbers side by side, as in the reference stats row.
class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.items});

  final List<({Key? key, String value, String label})> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: AppRadii.largeBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          key: const ValueKey('profile-stats'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: context.riksa.surface.withValues(alpha: 0.6),
            borderRadius: AppRadii.largeBorder,
            border: Border.all(
              color: context.riksa.outline.withValues(alpha: 0.5),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (final (index, item) in items.indexed) ...[
                  if (index > 0)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: context.riksa.outline,
                    ),
                  Expanded(
                    child: Column(
                      key: item.key,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.value,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: context.riksa.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: RiksaTypography.bodyStyleFor(
                              item.label,
                              theme.textTheme.labelSmall?.copyWith(
                                color: context.riksa.inkMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Owner-only article preview. The public feed hides pending and rejected
/// articles, so the profile must show their status instead of losing them.
class _ArticlesTab extends ConsumerWidget {
  const _ArticlesTab({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preview = myArticlesPreviewProvider(user.id);
    final articles = ref.watch(preview);
    Future<void> openAll() async {
      await context.push('/blog/my-posts');
      ref.invalidate(preview);
    }

    return Column(
      key: const ValueKey('profile-articles-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.blogYourPosts, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        articles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Column(
            children: [
              Text(l10n.blogMyPostsFailed),
              TextButton(
                onPressed: () => ref.invalidate(preview),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
          data: (page) => page.content.isEmpty
              ? Column(
                  children: [
                    Text(l10n.blogMyPostsEmptyBody),
                    TextButton.icon(
                      onPressed: () async {
                        final created = await context.push<bool>(
                          '/blog/create',
                        );
                        if (created == true) {
                          ref.invalidate(preview);
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.writeArticle),
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (final article in page.content)
                      _ArticlePreviewRow(article: article, onTap: openAll),
                    TextButton.icon(
                      onPressed: openAll,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.viewAll),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ArticlePreviewRow extends StatelessWidget {
  const _ArticlePreviewRow({required this.article, required this.onTap});

  final BlogPost article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = switch (article.status) {
      BlogStatus.pending => l10n.blogStatusPending,
      BlogStatus.approved => l10n.blogStatusApproved,
      BlogStatus.rejected => l10n.blogStatusRejected,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.riksa.surface,
        borderRadius: AppRadii.mediumBorder,
        child: InkWell(
          key: ValueKey('profile-article-${article.id}'),
          borderRadius: AppRadii.mediumBorder,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.riksa.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The author's own posts, with the whole lifecycle in one place: the
/// composer at the top, then each post carrying its own edit and delete.
class _PostsTab extends ConsumerStatefulWidget {
  const _PostsTab({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends ConsumerState<_PostsTab> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(userPostsProvider(widget.user.id));
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('profile-posts-tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileComposerPrompt(
          user: widget.user,
          avatarPath: ref.watch(profileAvatarProvider),
          frameTier: ref
              .watch(profileDashboardProvider)
              .value
              ?.gamification
              .currentTier,
          onTap: _create,
        ),
        const SizedBox(height: 14),
        posts.when(
          loading: () => const _ProfileLoading(key: ValueKey('posts-loading')),
          error: (error, _) => _ErrorPanel(
            message: _errorMessage(error, l10n),
            onRetry: () => ref.invalidate(userPostsProvider(widget.user.id)),
          ),
          data: (page) => page.posts.isEmpty
              ? ProfilePostsEmpty(onCreate: _create)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfilePostsSummary(count: page.posts.length),
                    const SizedBox(height: 10),
                    Column(
                      key: const ValueKey('profile-posts'),
                      children: [
                        for (final post in page.posts)
                          GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onLongPress: () => _manage(post),
                            child: SocialPostCard(
                              post: post,
                              onTap: () =>
                                  context.push('/community/posts/${post.id}'),
                              onAuthorTap:
                                  publicProfilePath(post.author.id) == null
                                  ? null
                                  : () => openUserProfile(
                                      context,
                                      post.author.id,
                                    ),
                              onReact: () async {
                                await ref
                                    .read(socialApiProvider)
                                    .react(
                                      postId: post.id,
                                      reaction: SocialReaction.upvote,
                                    );
                                _refresh();
                              },
                              onShare: () async {
                                await ref
                                    .read(socialApiProvider)
                                    .share(post.id);
                                _refresh();
                              },
                              // This tab only ever lists the signed-in user's
                              // own posts, so every card is editable.
                              onEdit: () => _edit(post),
                              onDelete: () => _delete(post),
                              // The author already owns this screen, so an
                              // official tint here would only make their own
                              // posts look unlike the ones readers see.
                              highlightOfficial: false,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _refresh() => ref.invalidate(userPostsProvider(widget.user.id));

  /// Writes a new post, question or article. An article never lands in this
  /// tab — it waits for moderation — so the author is taken to the one list
  /// that shows it.
  Future<void> _create() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final action = await showSocialCreateMenu(context);
      if (!mounted || action == null) return;
      final created = await context.push<bool>(socialCreateRoute(action));
      if (created != true || !mounted) return;
      if (action == SocialCreateAction.article) {
        await context.push<void>('/blog/my-posts');
        return;
      }
      _refresh();
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _manage(SocialPost post) async {
    final action = await showProfilePostActions(context, title: post.title);
    if (!mounted || action == null) return;
    switch (action) {
      case ProfilePostAction.edit:
        await _edit(post);
      case ProfilePostAction.delete:
        await _delete(post);
    }
  }

  Future<void> _edit(SocialPost post) async {
    final saved = await context.push<bool>(
      '/community/posts/${post.id}/edit',
      extra: post,
    );
    if (saved != true || !mounted) return;
    _refresh();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.postUpdated)));
  }

  Future<void> _delete(SocialPost post) async {
    if (!await confirmSocialPostDeletion(context)) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(socialFeedProvider.notifier)
        .deletePost(post.id);
    _refresh();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure ?? l10n.postDeleted)));
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.dashboard});

  final AsyncValue<ProfileDashboardData> dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return dashboard.when(
      loading: () =>
          const _ProfileLoading(key: ValueKey('achievements-loading')),
      error: (error, _) => _EmptyPanel(
        icon: Icons.cloud_off_rounded,
        message: _errorMessage(error, l10n),
      ),
      data: (data) {
        final earned = data.achievements.where((item) => item.earned).toList();
        if (earned.isEmpty) {
          return _EmptyPanel(
            icon: Icons.workspace_premium_outlined,
            message: l10n.noAchievements,
          );
        }
        return ProfileAchievementGrid(
          key: const ValueKey('profile-achievements-grid'),
          itemCount: earned.length,
          itemBuilder: (context, index) =>
              _AchievementTile(achievement: earned[index]),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final ProfileAchievement achievement;

  @override
  Widget build(BuildContext context) => ProfileAchievementTile(
    name: achievement.name,
    description: achievement.description,
    iconUrl: achievement.iconUrl,
    trailingLabel: '+${achievement.xpReward} XP',
  );
}

class _RankTab extends ConsumerWidget {
  const _RankTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = ref.watch(profileRankProvider);
    final l10n = AppLocalizations.of(context)!;
    return rank.when(
      loading: () => const _ProfileLoading(key: ValueKey('rank-loading')),
      error: (error, _) => _ErrorPanel(
        message: _errorMessage(error, l10n),
        onRetry: () => ref.invalidate(profileRankProvider),
      ),
      data: (data) => Column(
        key: const ValueKey('profile-rank'),
        children: [
          _RankCard(
            icon: const ProfileRankPixelIcon(kind: ProfileRankIconKind.country),
            label: l10n.countryRank,
            rank: data.countryRank,
            score: data.countryScore,
            tier: data.countryTier,
          ),
          const SizedBox(height: 12),
          _RankCard(
            icon: const ProfileRankPixelIcon(
              kind: ProfileRankIconKind.province,
            ),
            label: l10n.provinceRank,
            rank: data.provinceRank ?? 0,
            score: data.provinceScore ?? 0,
            tier: data.provinceTier,
          ),
        ],
      ),
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

  final Widget icon;
  final String label;
  final int rank;
  final int score;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileRankCard(
      iconWidget: icon,
      label: label,
      rank: rank,
      unrankedLabel: l10n.unranked,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$score XP',
            style: TextStyle(
              color: ProfilePalette.xp(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (tier != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RiksaRankBadge(tier: tier, size: 28),
                const SizedBox(width: 4),
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

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) => ProfileLoadingState(key: key);
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) =>
      ProfileEmptyPanel(icon: icon, message: message);
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ProfileErrorPanel(
    message: message,
    retryLabel: AppLocalizations.of(context)!.tryAgain,
    onRetry: onRetry,
  );
}

String _errorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) return dioErrorMessage(error);
  if (error is SocialApiException) return error.message;
  return l10n.profileLoadFailed;
}
