import '../../../core/sound/learning_sound.dart';
import '../../../core/sound/sound_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_cover_provider.dart';
import 'widgets/profile_ui.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final themeMode = ref.watch(themeModeProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final locale = ref.watch(localeProvider).locale;
    final localAvatar = ref.watch(profileAvatarProvider);

    return Scaffold(
      backgroundColor: ProfilePalette.canvas(context),
      appBar: AppBar(
        backgroundColor: ProfilePalette.canvas(context),
        centerTitle: true,
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.w900),
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
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
                        icon: Icons.notifications_none_rounded,
                        title: l10n.notificationPreferences,
                        subtitle: l10n.notificationPreferencesHint,
                        value: _notificationsEnabled,
                        onChanged: (value) =>
                            setState(() => _notificationsEnabled = value),
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
                        onTap: () => _showDocument(context, l10n.faq),
                      ),
                      const _SettingsDivider(),
                      _DocumentRow(
                        icon: Icons.description_outlined,
                        label: l10n.termsOfService,
                        onTap: () =>
                            _showDocument(context, l10n.termsOfService),
                      ),
                      const _SettingsDivider(),
                      _DocumentRow(
                        icon: Icons.privacy_tip_outlined,
                        label: l10n.privacyPolicy,
                        onTap: () => _showDocument(context, l10n.privacyPolicy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                OutlinedButton.icon(
                  key: const ValueKey('settings-logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7B8B),
                    backgroundColor: ProfilePalette.panel(context),
                    side: const BorderSide(color: Color(0xFF593139)),
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

  Future<void> _showDocument(BuildContext context, String title) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(l10n.supportDocumentUnavailable),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: ProfilePalette.muted(context)),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 56, color: ProfilePalette.border(context));
}
