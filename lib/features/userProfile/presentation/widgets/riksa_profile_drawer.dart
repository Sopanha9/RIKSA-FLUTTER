import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/language_toggle.dart';
import '../../../../core/widgets/riksa_logo.dart';
import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../mascot/domain/mascot.dart';
import '../../../mascot/presentation/widgets/buddy_companion.dart';
import '../../../mascot/providers/mascot_provider.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../providers/profile_cover_provider.dart';
import '../../providers/profile_provider.dart';
import 'profile_ui.dart';

/// The account menu, on the X drawer layout.
///
/// Identity at the top with the learner's buddy in the corner X gives other
/// accounts, the main destinations as a list of large rows, then a rule and
/// the quieter settings, help and about rows, and one low bar for theme,
/// language and sign out. The counts are the learner's own work (XP, streak,
/// achievements) in the slot X gives Following/Followers.
class RiksaProfileDrawer extends ConsumerWidget {
  const RiksaProfileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.riksa;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      key: const ValueKey('profile-drawer'),
      backgroundColor: palette.canvas,
      width: 304,
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: RiksaSpacing.md),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: _DrawerIdentity(user: user),
                  ),
                  if (user != null)
                    _DrawerItem(
                      itemKey: const ValueKey('drawer-profile'),
                      icon: Icons.person_outline_rounded,
                      label: l10n.profile,
                      onTap: () => _go(context, '/profile'),
                    ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-progress'),
                    icon: Icons.insights_rounded,
                    label: l10n.progressHistory,
                    onTap: () => _go(context, '/progress'),
                  ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-my-posts'),
                    icon: Icons.chat_bubble_outline_rounded,
                    label: l10n.myPosts,
                    onTap: () => _go(context, '/profile'),
                  ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-my-articles'),
                    icon: Icons.article_outlined,
                    label: l10n.blogYourPosts,
                    onTap: () => _go(context, '/blog/my-posts'),
                  ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-saved-lessons'),
                    icon: Icons.bookmark_border_rounded,
                    label: l10n.menuSavedLessons,
                    onTap: () => _go(context, '/learn/saved'),
                  ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-communities'),
                    icon: Icons.groups_2_outlined,
                    label: l10n.communitiesMenu,
                    onTap: () => _go(context, '/communities'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: RiksaSpacing.xs,
                    ),
                    child: Divider(height: 1, color: palette.outline),
                  ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-settings'),
                    icon: Icons.settings_outlined,
                    label: l10n.settings,
                    small: true,
                    onTap: () => _go(context, '/profile/settings'),
                  ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-faq'),
                    icon: Icons.help_outline_rounded,
                    label: l10n.helpAndLegal,
                    small: true,
                    onTap: () => _showHelp(context),
                  ),
                  _DrawerItem(
                    itemKey: const ValueKey('drawer-about-riksa'),
                    icon: Icons.info_outline_rounded,
                    label: l10n.drawerAbout,
                    small: true,
                    onTap: () => _showAbout(context),
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

  /// FAQ and the legal documents in one sheet. None is published yet, so each
  /// says so up front instead of pretending to be a link.
  Future<void> _showHelp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.helpAndLegal,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final (icon, label) in [
              (Icons.help_outline_rounded, l10n.faq),
              (Icons.description_outlined, l10n.termsOfService),
              (Icons.privacy_tip_outlined, l10n.privacyPolicy),
              (Icons.check_circle_outline_rounded, l10n.drawerUserAgreement),
            ])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                enabled: false,
                leading: Icon(icon),
                title: Text(label),
                trailing: Text(
                  l10n.supportDocumentComingSoon,
                  style: TextStyle(
                    color: palette.inkFaint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: RiksaSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final palette = context.riksa;
    final theme = Theme.of(context);
    final km = Localizations.localeOf(context).languageCode == 'km';
    final body = km
        ? 'RIKSA ជាកន្លែងដែលសិស្សកម្ពុជារៀនជាមួយគ្នា៖ មេរៀន មិត្តរៀនរបស់អ្នក និងសហគមន៍ដែលជួយឲ្យអ្នកបន្តទៅមុខ។'
        : 'RIKSA is where Cambodian students learn together: lessons, a study '
              'buddy of your own, and a community that keeps you going.';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BuddyFaceReaction(face: MascotFace.happy, size: 72),
              const SizedBox(height: RiksaSpacing.sm),
              const RiksaLogo(fontSize: 30),
              const SizedBox(height: RiksaSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: RiksaTypography.bodyStyleFor(
                  body,
                  theme.textTheme.bodyMedium?.copyWith(
                    color: palette.inkMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final buddy = ref.watch(mascotProvider).profile;
    final decimal = NumberFormat.decimalPattern();

    if (user case final AuthUser signedIn) {
      final name = signedIn.displayName.trim().isEmpty
          ? signedIn.username
          : signedIn.displayName.trim();
      void openProfile() {
        Navigator.of(context).pop();
        context.push('/profile');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: openProfile,
                customBorder: const CircleBorder(),
                child: RiksaProfileAvatar(
                  user: signedIn,
                  radius: 26,
                  avatarPath: ref.watch(profileAvatarProvider),
                  frameTier: dashboard.value?.gamification.currentTier,
                ),
              ),
              const Spacer(),
              // Where X shows your other accounts, RIKSA shows your buddy.
              if (buddy != null)
                Tooltip(
                  message: l10n.profileBuddyNamed(buddy.name),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.brandSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.outline),
                    ),
                    alignment: Alignment.center,
                    child: const BuddyFaceReaction(
                      face: MascotFace.happy,
                      size: 34,
                      loops: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: RiksaSpacing.sm),
          InkWell(
            onTap: openProfile,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiksaTypography.titleStyleFor(
                    name,
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '@${signedIn.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RiksaSpacing.sm),
          Wrap(
            key: const ValueKey('drawer-counts'),
            spacing: 16,
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
        const BuddyFaceReaction(face: MascotFace.happy, size: 52),
        const SizedBox(height: RiksaSpacing.sm),
        Text(
          l10n.profile,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: RiksaSpacing.xxs),
        Text(
          l10n.loginSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
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
          fontWeight: FontWeight.w600,
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

/// One destination. Main destinations are large and bold, as on X; [small]
/// rows (settings, help, about) sit quieter below the rule.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.itemKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.small = false,
  });

  final Key itemKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final text = Theme.of(context).textTheme;
    final style = small
        ? text.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: palette.ink,
          )
        : text.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: palette.ink,
            letterSpacing: -.2,
          );
    return InkWell(
      key: itemKey,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: small ? 10 : 11,
        ),
        child: Row(
          children: [
            Icon(icon, size: small ? 22 : 26, color: palette.ink),
            SizedBox(width: small ? 16 : 20),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.titleStyleFor(label, style),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                              RotationTransition(
                                turns: animation,
                                child: child,
                              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
