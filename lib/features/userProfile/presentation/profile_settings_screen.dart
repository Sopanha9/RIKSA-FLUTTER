import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notifications/streak_reminder_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/sound/learning_sound.dart';
import '../../../core/sound/sound_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/buddy_look.dart';
import '../../mascot/providers/buddy_care_provider.dart';
import '../../mascot/presentation/widgets/mascot_scene.dart';
import '../../mascot/presentation/widgets/mascot_speech.dart';
import '../../mascot/presentation/widgets/mascot_view.dart';
import '../../mascot/providers/buddy_preferences_provider.dart';
import '../providers/profile_cover_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_ui.dart';
import '../../../core/network/support_documents.dart';

String _t(String lang, String en, String km) => lang == 'km' ? km : en;

/// Settings, told by the learner's buddy: it stands on its scene at the top
/// and answers each change, so the page is part of the app rather than a
/// system form bolted onto it.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _buddy = MascotController();

  /// The buddy's current line, as an English/Khmer pair so a language switch
  /// re-renders it in the new language. Null means the greeting.
  (String, String)? _line;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reactionsOn) _buddy.react(MascotMood.greeting);
    });
  }

  @override
  void dispose() {
    _buddy.dispose();
    super.dispose();
  }

  bool get _reactionsOn => ref.read(buddyReactionsEnabledProvider);

  /// Plays [mood] and says [line] — unless the learner switched reactions
  /// off, in which case the buddy keeps still and quiet.
  void _say(MascotMood mood, String en, String km) {
    if (!_reactionsOn) return;
    setState(() => _line = (en, km));
    _buddy.react(mood);
  }

  Future<void> _confirmLogout(String lang, String name) async {
    final palette = context.riksa;
    final buddyLook = ref.read(buddyLookProvider);
    final leave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: palette.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final title = _t(lang, 'Leaving already?', 'ចាកចេញហើយឬ?');
        final body = _t(
          lang,
          '$name will keep your streak warm until you’re back.',
          '$name នឹងរក្សាស្ទ្រីករបស់អ្នក រហូតដល់អ្នកត្រឡប់មកវិញ។',
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BuddyLook(
                  species: buddyLook.species,
                  face: MascotFace.sad,
                  equipped: buddyLook.equipped,
                  size: 88,
                  semanticLabel: name,
                ),
                const SizedBox(height: RiksaSpacing.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: RiksaTypography.titleStyleFor(
                    title,
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: RiksaSpacing.xs),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: RiksaTypography.bodyStyleFor(
                    body,
                    theme.textTheme.bodyMedium?.copyWith(
                      color: palette.inkMuted,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: RiksaSpacing.lg),
                _PillButton(
                  key: const ValueKey('settings-logout-stay'),
                  label: _t(lang, 'Stay', 'នៅបន្ត'),
                  filled: true,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
                const SizedBox(height: RiksaSpacing.xs),
                _PillButton(
                  key: const ValueKey('settings-logout-confirm'),
                  label: AppLocalizations.of(sheetContext)!.logout,
                  color: theme.colorScheme.error,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (leave != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final themeMode = ref.watch(themeModeProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final reactionsEnabled = ref.watch(buddyReactionsEnabledProvider);
    final locale = ref.watch(localeProvider).locale;
    final lang = locale.languageCode;
    final localAvatar = ref.watch(profileAvatarProvider);
    final frameTier = ref
        .watch(profileDashboardProvider)
        .value
        ?.gamification
        .currentTier;
    final streakReminderEnabled =
        ref.watch(streakReminderStateProvider).value ?? true;
    final shareMilestones = user?.shareMilestones ?? true;
    final buddyLook = ref.watch(buddyLookProvider);
    final species = buddyLook.species;
    final buddyName = buddyLook.name;

    final firstName = user?.displayName.trim().split(' ').first ?? '';
    final greeting = firstName.isEmpty
        ? ('Make RIKSA feel like yours.', 'ធ្វើឲ្យ RIKSA ក្លាយជារបស់អ្នក។')
        : (
            'Hi $firstName! Make RIKSA feel like yours.',
            'សួស្តី $firstName! ធ្វើឲ្យ RIKSA ក្លាយជារបស់អ្នក។',
          );
    final line = _line ?? greeting;
    final lineText = _t(lang, line.$1, line.$2);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SettingsHero(
              species: species,
              controller: _buddy,
              line: lineText,
              title: l10n.settings,
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                RiksaSpacing.md,
                0,
                RiksaSpacing.md,
                RiksaSpacing.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (user != null) ...[
                          _Group(
                            children: [
                              _Row(
                                key: const ValueKey('settings-edit-profile'),
                                leading: RiksaProfileAvatar(
                                  user: user,
                                  radius: 24,
                                  avatarPath: localAvatar,
                                  frameTier: frameTier,
                                ),
                                title: user.displayName,
                                titleWeight: FontWeight.w800,
                                subtitle: '@${user.username}',
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: palette.inkFaint,
                                ),
                                onTap: () => context.push('/profile/edit'),
                              ),
                            ],
                          ),
                          const SizedBox(height: RiksaSpacing.lg),
                        ],
                        _SectionLabel(
                          _t(lang, 'Your buddy', 'មិត្តរៀនរបស់អ្នក'),
                        ),
                        _Group(
                          children: [
                            _Row(
                              leading: GestureDetector(
                                onTap: () => _say(
                                  MascotMood.love,
                                  'Hehe, that tickles!',
                                  'ហិហិ រមាស់ណាស់!',
                                ),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: palette.brandSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: BuddyLook(
                                    species: species,
                                    face: reactionsEnabled
                                        ? MascotFace.happy
                                        : MascotFace.neutral,
                                    equipped: buddyLook.equipped,
                                    size: 40,
                                    semanticLabel: buddyName,
                                  ),
                                ),
                              ),
                              title: buddyName,
                              titleWeight: FontWeight.w800,
                              subtitle: _t(
                                lang,
                                'Your study buddy · Tap to change',
                                'មិត្តរៀនរបស់អ្នក · ចុចដើម្បីប្ដូរ',
                              ),
                              // First run no longer passes the picker, so
                              // this is where a buddy is chosen or changed.
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: palette.inkMuted,
                              ),
                              onTap: () => context.push('/mascot-select'),
                            ),
                            const _Divider(),
                            _SwitchRow(
                              key: const ValueKey('settings-buddy-reactions'),
                              icon: Icons.emoji_emotions_outlined,
                              title: l10n.buddyReactions,
                              subtitle: l10n.buddyReactionsHint,
                              value: reactionsEnabled,
                              onChanged: (value) async {
                                final saved = await ref
                                    .read(
                                      buddyReactionsEnabledProvider.notifier,
                                    )
                                    .setEnabled(value);
                                if (!mounted || !context.mounted) return;
                                if (!saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.saveFailed)),
                                  );
                                  return;
                                }
                                if (value) {
                                  // Read the new value directly: the
                                  // provider rebuilds after this frame.
                                  setState(
                                    () => _line = (
                                      'Yay, I can talk again!',
                                      'យ៉េ! ខ្ញុំអាចនិយាយបានវិញហើយ!',
                                    ),
                                  );
                                  _buddy.react(MascotMood.celebrate);
                                } else {
                                  setState(
                                    () => _line = (
                                      'Okay — I’ll keep quiet and let you focus.',
                                      'បាទ ខ្ញុំនឹងស្ងាត់ ឲ្យអ្នកផ្ដោតលើការរៀន។',
                                    ),
                                  );
                                  _buddy.mood = MascotMood.idle;
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: RiksaSpacing.lg),
                        _SectionLabel(_t(lang, 'Preferences', 'ចំណូលចិត្ត')),
                        _Group(
                          children: [
                            _SwitchRow(
                              key: const ValueKey('settings-streak-reminders'),
                              icon: Icons.notifications_none_rounded,
                              title: l10n.notificationPreferences,
                              subtitle: l10n.notificationPreferencesHint,
                              value: streakReminderEnabled,
                              onChanged: (value) {
                                final streak =
                                    ref
                                        .read(profileDashboardProvider)
                                        .value
                                        ?.gamification
                                        .currentStreak ??
                                    0;
                                final reminderTitle = streak > 0
                                    ? l10n.reminderNotificationTitle(
                                        buddyName,
                                        streak,
                                      )
                                    : l10n.reminderNotificationTitleNoStreak(
                                        buddyName,
                                      );
                                ref
                                    .read(streakReminderStateProvider.notifier)
                                    .toggle(
                                      enabled: value,
                                      title: reminderTitle,
                                      body: l10n.reminderNotificationBody,
                                    );
                                value
                                    ? _say(
                                        MascotMood.happy,
                                        'I’ll nudge you before your streak slips.',
                                        'ខ្ញុំនឹងរំលឹកអ្នក មុនស្ទ្រីកដាច់។',
                                      )
                                    : _say(
                                        MascotMood.sad,
                                        'No reminders? Don’t forget about me!',
                                        'គ្មានការរំលឹក? កុំភ្លេចខ្ញុំណា!',
                                      );
                              },
                            ),
                            const _Divider(),
                            if (user != null) ...[
                              _SwitchRow(
                                key: const ValueKey(
                                  'settings-share-milestones',
                                ),
                                icon: Icons.celebration_outlined,
                                title: l10n.milestoneShareTitle,
                                subtitle: l10n.milestoneShareHint,
                                value: shareMilestones,
                                onChanged: (value) async {
                                  final saved = await ref
                                      .read(authProvider.notifier)
                                      .updateProfile(
                                        UpdateProfileRequest(
                                          shareMilestones: value,
                                        ),
                                      );
                                  if (!mounted || !context.mounted) return;
                                  if (!saved) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.saveFailed)),
                                    );
                                  }
                                },
                              ),
                              const _Divider(),
                            ],
                            _SwitchRow(
                              key: const ValueKey('settings-learning-sounds'),
                              icon: Icons.volume_up_outlined,
                              title: l10n.learningSounds,
                              subtitle: l10n.learningSoundsHint,
                              value: soundEnabled,
                              onChanged: (value) {
                                ref
                                    .read(soundEnabledProvider.notifier)
                                    .set(enabled: value);
                                // Turning it on plays the cue it turns on, so
                                // the switch demonstrates itself.
                                if (value) ref.playSound(LearningSound.correct);
                                value
                                    ? _say(
                                        MascotMood.happy,
                                        'Ding! Sounds are on.',
                                        'ទីង! សំឡេងបើកហើយ។',
                                      )
                                    : _say(
                                        MascotMood.thinking,
                                        'Shh… silent study mode.',
                                        'ស៊ូ… របៀបរៀនស្ងាត់។',
                                      );
                              },
                            ),
                            const _Divider(),
                            _SwitchRow(
                              key: const ValueKey('settings-dark-mode'),
                              icon: Icons.dark_mode_outlined,
                              title: l10n.darkMode,
                              subtitle: l10n.darkModeHint,
                              value: themeMode == ThemeMode.dark,
                              onChanged: (value) {
                                ref
                                    .read(themeModeProvider.notifier)
                                    .setDarkMode(value);
                                value
                                    ? _say(
                                        MascotMood.sleep,
                                        'Cozy. Easier on the eyes at night.',
                                        'ស្រួលភ្នែក សម្រាប់រៀនពេលយប់។',
                                      )
                                    : _say(
                                        MascotMood.happy,
                                        'Rise and shine!',
                                        'ភ្ញាក់ឡើង ភ្លឺស្វាងហើយ!',
                                      );
                              },
                            ),
                            const _Divider(),
                            _Row(
                              leading: const _IconTile(Icons.translate_rounded),
                              title: l10n.language,
                              trailing: _LanguageSwitch(
                                isKhmer: lang == 'km',
                                onChanged: (km) {
                                  if ((lang == 'km') == km) return;
                                  ref.read(localeProvider.notifier).toggle();
                                  _say(
                                    MascotMood.greeting,
                                    'Hello! Let’s study in English.',
                                    'សួស្តី! តោះរៀនជាភាសាខ្មែរ។',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RiksaSpacing.lg),
                        _SectionLabel(l10n.helpAndLegal),
                        _Group(
                          children: [
                            _DocumentRow(
                              icon: Icons.help_outline_rounded,
                              label: l10n.faq,
                              url: _supportDocuments.faq,
                            ),
                            const _Divider(),
                            _DocumentRow(
                              icon: Icons.description_outlined,
                              label: l10n.termsOfService,
                              url: _supportDocuments.terms,
                            ),
                            const _Divider(),
                            _DocumentRow(
                              icon: Icons.privacy_tip_outlined,
                              label: l10n.privacyPolicy,
                              url: _supportDocuments.privacy,
                            ),
                          ],
                        ),
                        const SizedBox(height: RiksaSpacing.xl),
                        _PillButton(
                          key: const ValueKey('settings-logout'),
                          label: l10n.logout,
                          icon: Icons.logout_rounded,
                          color: theme.colorScheme.error,
                          onPressed: () => _confirmLogout(lang, buddyName),
                        ),
                        const SizedBox(height: RiksaSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the published documents live. A row without an address here is shown
/// as not yet available instead of pretending to be a link: tapping one only
/// to be told the document does not exist is worse than seeing that up front.
/// Fill these in and the rows become ordinary links.
final _supportDocuments = (
  faq: SupportDocuments.faq,
  terms: SupportDocuments.termsOfService,
  privacy: SupportDocuments.privacyPolicy,
);

/// The scene with the buddy and its speech bubble, a back button and the
/// title. Its bottom edge is the top of the rounded content sheet.
class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.species,
    required this.controller,
    required this.line,
    required this.title,
  });

  final MascotSpecies species;
  final MascotController controller;
  final String line;
  final String title;

  static const _sheetRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final palette = context.riksa;
    final theme = Theme.of(context);
    final top = media.padding.top;
    final baseHeight = (media.size.height * .22).clamp(150.0, 200.0);
    final buddySize = (baseHeight - 36) / MascotView.heightFactor;
    // The buddy keeps its size; the scene grows so a long line at a large
    // text size (Khmer at 2x is the worst case) still fits in its bubble.
    final textScale = media.textScaler.scale(1);
    final khmer = RiksaTypography.containsKhmer(line);
    final sceneHeight =
        baseHeight +
        (textScale - 1).clamp(0.0, 1.5) * (khmer ? 110 : 70) +
        (khmer ? 12 : 0);
    final bubbleStyle = RiksaTypography.bodyStyleFor(
      line,
      theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
    return SizedBox(
      height: top + 56 + sceneHeight + _sheetRadius,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: _sheetRadius,
            child: MascotSceneBackdrop(species: species),
          ),
          // Keeps the title and back button readable over bright sky.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + 72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .28),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 16,
            top: top + 4,
            height: 48,
            child: Row(
              children: [
                RiksaBackButton(
                  key: const ValueKey('profile-settings-back'),
                  fallbackLocation: '/profile',
                  style: IconButton.styleFrom(
                    backgroundColor: palette.surface.withValues(alpha: .9),
                    foregroundColor: palette.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.titleStyleFor(
                      title,
                      theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 16,
            bottom: _sheetRadius - 4,
            height: sceneHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MascotView(
                  species: species,
                  size: buddySize,
                  controller: controller,
                  interactive: true,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: buddySize * .5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: MascotSpeechBubble(
                        key: ValueKey(line),
                        line: line,
                        tail: SpeechTail.left,
                        maxWidth: 360,
                        textAlign: TextAlign.start,
                        style: bubbleStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _sheetRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.canvas,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_sheetRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: context.riksa.inkMuted,
      fontWeight: FontWeight.w800,
      letterSpacing: .2,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, RiksaSpacing.xs),
      child: Text(text, style: RiksaTypography.titleStyleFor(text, style)),
    );
  }
}

/// A white card holding a run of rows, separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 68, color: context.riksa.outline);
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: context.riksa.brandSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: 21, color: context.riksa.brandStrong),
  );
}

/// One settings row. Text wraps instead of truncating, so Khmer at large text
/// sizes grows the row rather than clipping it.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.leading,
    required this.title,
    this.titleWeight = FontWeight.w700,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final Widget leading;
  final String title;
  final FontWeight titleWeight;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final text = Theme.of(context).textTheme;
    final titleStyle = text.bodyLarge?.copyWith(
      fontWeight: titleWeight,
      color: enabled ? palette.ink : palette.inkFaint,
    );
    final subtitleStyle = text.bodySmall?.copyWith(
      color: palette.inkMuted,
      height: 1.35,
    );
    return InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: RiksaTypography.titleStyleFor(title, titleStyle),
                    ),
                    if (subtitle case final subtitle?) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: RiksaTypography.bodyStyleFor(
                          subtitle,
                          subtitleStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing case final trailing?) ...[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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
  Widget build(BuildContext context) => MergeSemantics(
    child: _Row(
      leading: _IconTile(icon),
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: context.riksa.brand,
        onChanged: onChanged,
      ),
    ),
  );
}

/// EN / ខ្មែរ as two segments: a language is a choice between two named
/// options, which a bare on/off switch did not say.
class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.isKhmer, required this.onChanged});

  final bool isKhmer;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    Widget segment(String label, bool khmer) {
      final selected = isKhmer == khmer;
      final style = Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: selected ? palette.onBrand : palette.inkMuted,
      );
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () => onChanged(khmer),
          child: AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            curve: RiksaMotion.standardCurve,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? palette.brandStrong : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: RiksaTypography.titleStyleFor(label, style),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [segment('EN', false), segment('ខ្មែរ', true)],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = color ?? (isDark ? palette.brand : palette.brandStrong);
    final style = filled
        ? FilledButton.styleFrom(
            backgroundColor: tone,
            foregroundColor: palette.onBrand,
            shadowColor: Colors.transparent,
            elevation: 0,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(52),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: tone,
            backgroundColor: palette.surface,
            shadowColor: Colors.transparent,
            elevation: 0,
            side: BorderSide(color: tone.withValues(alpha: .6)),
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(52),
          );
    final text = Text(
      label,
      style: RiksaTypography.titleStyleFor(
        label,
        const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
    if (filled) {
      return FilledButton(style: style, onPressed: onPressed, child: text);
    }
    return icon == null
        ? OutlinedButton(style: style, onPressed: onPressed, child: text)
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon),
            label: text,
          );
  }
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
    final palette = context.riksa;
    final address = url;
    if (address == null) {
      return _Row(
        enabled: false,
        leading: _IconTile(icon),
        title: label,
        trailing: Text(
          l10n.supportDocumentComingSoon,
          style: TextStyle(
            color: palette.inkFaint,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return _Row(
      leading: _IconTile(icon),
      title: label,
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 18,
        color: palette.inkFaint,
      ),
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
