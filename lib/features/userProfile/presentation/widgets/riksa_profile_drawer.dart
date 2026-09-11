import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/language_toggle.dart';

import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers/profile_cover_provider.dart';
import '../../providers/profile_provider.dart';
import 'profile_ui.dart';

/// The account menu, on the X drawer layout.
///
/// Identity at the top, destinations as a plain list, account actions below a
/// rule, and one low bar for the two things that are not navigation: theme and
/// sign out. There are no counts of other people here, because Riksa has no
/// follow graph. The slot X gives Following/Followers carries what the learner
/// actually accumulated: XP, streak and achievements.
class RiksaProfileDrawer extends ConsumerWidget {
  const RiksaProfileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.riksa;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;

    return Drawer(
      key: const ValueKey('profile-drawer'),
      backgroundColor: palette.canvas,
      // Square on the leading edge, rounded on the trailing one: the panel
      // reads as pulled out from the edge of the screen rather than floating.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(AppRadii.feature),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                RiksaSpacing.md,
                20,
                RiksaSpacing.md,
              ),
              child: _DrawerIdentity(user: user),
            ),
            Expanded(
              // A filled sliver rather than a plain list: the account actions
              // sit against the footer while there is room, and the whole lot
              // scrolls once there is not, which is what happens on a short
              // screen at a large text scale.
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-profile'),
                          icon: Icons.person_outline_rounded,
                          label: AppLocalizations.of(context)!.profile,
                          onTap: () => _go(context, '/profile'),
                        ),
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-leaderboard'),
                          icon: Icons.emoji_events_outlined,
                          label: AppLocalizations.of(context)!.leaderboard,
                          onTap: () => _go(context, '/leaderboard'),
                        ),
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-progress'),
                          icon: Icons.timeline_rounded,
                          label: AppLocalizations.of(context)!.progressHistory,
                          onTap: () => _go(context, '/progress'),
                        ),
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-communities'),
                          icon: Icons.groups_outlined,
                          label: AppLocalizations.of(context)!.communitiesMenu,
                          onTap: () => _go(context, '/communities'),
                        ),
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-my-posts'),
                          icon: Icons.article_outlined,
                          label: AppLocalizations.of(context)!.myPosts,
                          onTap: () => _go(context, '/blog/my-posts'),
                        ),
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-saved-lessons'),
                          icon: Icons.bookmark_border_rounded,
                          label: Localizations.localeOf(context).languageCode == 'km'
                              ? 'មេរៀនបានរក្សាទុក'
                              : 'Saved Lessons',
                          onTap: () => _go(context, '/learn/saved'),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: RiksaSpacing.sm,
                          ),
                          child: Divider(height: 1, color: palette.outline),
                        ),
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-edit-profile'),
                          icon: Icons.edit_outlined,
                          label: AppLocalizations.of(context)!.editProfile,
                          onTap: () => _go(context, '/profile/edit'),
                        ),
                        _DrawerItem(
                          itemKey: const ValueKey('drawer-settings'),
                          icon: Icons.settings_outlined,
                          label: AppLocalizations.of(context)!.settings,
                          onTap: () => _go(context, '/profile/settings'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.outline),
            const _DrawerFooter(),
          ],
        ),
      ),
    );
  }

  /// Closes the drawer before navigating, so returning to home does not land
  /// the learner back on an open menu.
  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.push(path);
  }
}

class _DrawerIdentity extends ConsumerWidget {
  const _DrawerIdentity({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final theme = Theme.of(context);
    final dashboard = ref.watch(profileDashboardProvider);
    final decimal = NumberFormat.decimalPattern();

    if (user case final AuthUser signedIn) {
      final name = signedIn.displayName.trim().isEmpty
          ? signedIn.username
          : signedIn.displayName.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RiksaProfileAvatar(
            user: signedIn,
            radius: 27,
            avatarPath: ref.watch(profileAvatarProvider),
            frameTier: dashboard.value?.gamification.currentTier,
          ),
          const SizedBox(height: RiksaSpacing.sm),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RiksaTypography.titleStyleFor(
              name,
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '@${signedIn.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.gradeStemLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: RiksaSpacing.sm),
          // Where X counts other people, Riksa counts the learner's own work.
          Wrap(
            key: const ValueKey('drawer-counts'),
            spacing: 14,
            runSpacing: 6,
            children: [
              _Count(
                value: decimal.format(
                  dashboard.value?.gamification.totalXp ?? 0,
                ),
                label: l10n.totalXp,
              ),
              _Count(
                value: decimal.format(
                  dashboard.value?.gamification.currentStreak ?? 0,
                ),
                label: l10n.currentStreak,
              ),
              _Count(
                value: decimal.format(
                  dashboard.value?.earnedAchievementCount ?? 0,
                ),
                label: l10n.achievements,
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.profile,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: RiksaSpacing.xxs),
        Text(
          l10n.loginSubtitle,
          style: TextStyle(color: palette.inkMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: TextStyle(
          color: context.riksa.ink,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(color: context.riksa.inkMuted, fontSize: 13),
      ),
    ],
  );
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.itemKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Key itemKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: itemKey,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 24, color: context.riksa.ink),
          const SizedBox(width: RiksaSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RiksaTypography.bodyStyleFor(
                label,
                TextStyle(
                  color: context.riksa.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The quick controls bar: appearance and language switching on the left and
/// right, with sign out below.
class _DrawerFooter extends ConsumerWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                label: l10n.darkMode,
                child: Tooltip(
                  message: l10n.darkMode,
                  child: InkWell(
                    key: const ValueKey('drawer-theme-toggle'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(themeModeProvider.notifier).setDarkMode(!isDark);
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              RotationTransition(turns: animation, child: child),
                          child: Icon(
                            isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            key: ValueKey(isDark),
                            size: 20,
                            color: isDark
                                ? const Color(0xFFFFD54F)
                                : palette.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const LanguageToggle(),
            ],
          ),
          if (ref.watch(authProvider) is Authenticated) ...[
            const SizedBox(height: RiksaSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('drawer-logout'),
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n.logout),
                style: TextButton.styleFrom(
                  foregroundColor: palette.inkMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
