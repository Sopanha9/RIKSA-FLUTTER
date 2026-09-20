import '../../../core/sound/learning_sound.dart';
import '../../../core/sound/sound_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notifications/streak_reminder_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_cover_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_ui.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final themeMode = ref.watch(themeModeProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final locale = ref.watch(localeProvider).locale;
    final localAvatar = ref.watch(profileAvatarProvider);
    final frameTier = ref
        .watch(profileDashboardProvider)
        .value
        ?.gamification
        .currentTier;
    final streakReminderAsync = ref.watch(streakReminderStateProvider);
    final streakReminderEnabled = streakReminderAsync.value ?? true;

    return Scaffold(
      backgroundColor: ProfilePalette.canvas(context),
      appBar: AppBar(
        backgroundColor: ProfilePalette.canvas(context),
        centerTitle: false,
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                if (user != null)
                  ProfilePanel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      key: const ValueKey('settings-edit-profile'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      leading: RiksaProfileAvatar(
                        user: user,
                        radius: 25,
                        avatarPath: localAvatar,
                        frameTier: frameTier,
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '@${user.username}',
                        style: TextStyle(color: ProfilePalette.muted(context)),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/profile/edit'),
                    ),
                  ),
                const SizedBox(height: 18),
                ProfilePanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsSwitchRow(
                        key: const ValueKey('settings-streak-reminders'),
                        icon: Icons.notifications_none_rounded,
                        title: l10n.notificationPreferences,
                        subtitle: l10n.notificationPreferencesHint,
                        value: streakReminderEnabled,
                        onChanged: (value) {
                          final isKm =
                              Localizations.localeOf(context).languageCode ==
                              'km';
                          ref
                              .read(streakReminderStateProvider.notifier)
                              .toggle(
                                enabled: value,
                                title: isKm
                                    ? '🔥 រក្សាខ្សែពិន្ទុបន្ត (Streak) របស់អ្នក!'
                                    : '🔥 Keep your learning streak alive!',
                                body: isKm
                                    ? 'ចំណាយពេល ៥ នាទីយប់នេះដើម្បីរៀន និងការពារ Streak របស់អ្នក។'
                                    : 'Take 5 minutes tonight to practice and protect your streak.',
                              );
                        },
                      ),
                      const _SettingsDivider(),
                      _SettingsSwitchRow(
                        key: const ValueKey('settings-learning-sounds'),
                        icon: Icons.volume_up_outlined,
                        title: l10n.learningSounds,
                        subtitle: l10n.learningSoundsHint,
                        value: soundEnabled,
                        onChanged: (value) {
                          ref
                              .read(soundEnabledProvider.notifier)
                              .set(enabled: value);
                          // Turning it on plays the cue it turns on, so the
                          // switch demonstrates itself.
                          if (value) ref.playSound(LearningSound.correct);
                        },
                      ),
                      const _SettingsDivider(),
                      _SettingsSwitchRow(
                        key: const ValueKey('settings-dark-mode'),
                        icon: Icons.dark_mode_outlined,
                        title: l10n.darkMode,
                        subtitle: l10n.darkModeHint,
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) => ref
                            .read(themeModeProvider.notifier)
                            .setDarkMode(value),
                      ),
                      const _SettingsDivider(),
                      ListTile(
                        leading: Icon(
                          Icons.translate_rounded,
                          color: ProfilePalette.muted(context),
                        ),
                        title: Text(l10n.language),
                        subtitle: Text(
                          locale.languageCode == 'km'
                              ? l10n.languageKm
                              : l10n.languageEn,
                          style: TextStyle(
                            color: ProfilePalette.muted(context),
                          ),
                        ),
                        trailing: Switch.adaptive(
                          value: locale.languageCode == 'km',
                          activeTrackColor: ProfilePalette.green(context),
                          onChanged: (_) =>
                              ref.read(localeProvider.notifier).toggle(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.helpAndLegal,
                  style: TextStyle(
                    color: ProfilePalette.muted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                ProfilePanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _DocumentRow(
                        icon: Icons.help_outline_rounded,
                        label: l10n.faq,
                        url: _supportDocuments.faq,
                      ),
                      const _SettingsDivider(),
                      _DocumentRow(
                        icon: Icons.description_outlined,
                        label: l10n.termsOfService,
                        url: _supportDocuments.terms,
                      ),
                      const _SettingsDivider(),
                      _DocumentRow(
                        icon: Icons.privacy_tip_outlined,
                        label: l10n.privacyPolicy,
                        url: _supportDocuments.privacy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                OutlinedButton.icon(
                  key: const ValueKey('settings-logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    backgroundColor: ProfilePalette.panel(context),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/auth/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l10n.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the published documents live. A row without an address here is shown
/// as not yet available instead of pretending to be a link: tapping one only
/// to be told the document does not exist is worse than seeing that up front.
/// Fill these in and the rows become ordinary links.
const _supportDocuments = (faq: null, terms: null, privacy: null);

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: ProfilePalette.muted(context)),
    title: Text(title),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: ProfilePalette.muted(context), fontSize: 12),
    ),
    trailing: Switch.adaptive(
      value: value,
      activeTrackColor: ProfilePalette.green(context),
      onChanged: onChanged,
    ),
  );
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;

  /// Null while the document has no published address.
  final String? url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final address = url;
    final muted = ProfilePalette.muted(context);
    if (address == null) {
      return ListTile(
        enabled: false,
        leading: Icon(icon, color: muted),
        title: Text(label),
        trailing: Text(
          l10n.supportDocumentComingSoon,
          style: TextStyle(color: muted, fontWeight: FontWeight.w600),
        ),
      );
    }
    return ListTile(
      leading: Icon(icon, color: muted),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final opened = await launchUrl(
          Uri.parse(address),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.supportDocumentUnavailable)),
          );
        }
      },
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 56, color: ProfilePalette.border(context));
}
