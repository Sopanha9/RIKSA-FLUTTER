import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/telegram_logo.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/data/auth_api.dart';
import '../../../auth/data/external_link_opener.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../mascot/domain/mascot.dart';
import '../../../mascot/presentation/widgets/mascot_speech.dart';
import '../../../mascot/presentation/widgets/mascot_view.dart';
import '../../../mascot/providers/mascot_provider.dart';

/// Opens the phone verification sheet. Resolves true once the number is verified.
Future<bool> showPhoneVerifySheet(BuildContext context) async {
  final verified = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const PhoneVerifySheet(),
  );
  return verified ?? false;
}

/// Verifies the phone number through the Telegram bot: the learner opens the
/// bot, taps "Share my phone number", and this sheet notices by checking the
/// profile until the number shows up.
class PhoneVerifySheet extends ConsumerStatefulWidget {
  const PhoneVerifySheet({super.key});

  @override
  ConsumerState<PhoneVerifySheet> createState() => _PhoneVerifySheetState();
}

enum _Stage { ready, opening, waiting, done }

class _PhoneVerifySheetState extends ConsumerState<PhoneVerifySheet>
    with WidgetsBindingObserver {
  static const _pollEvery = Duration(seconds: 3);
  static const _giveUpAfter = Duration(minutes: 15);

  final _mascot = MascotController(MascotMood.idle);
  _Stage _stage = _Stage.ready;
  String? _error;
  Timer? _poll;
  DateTime? _startedAt;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mascot.react(MascotMood.greeting);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _mascot.dispose();
    super.dispose();
  }

  /// Coming back from Telegram is the likeliest moment it just finished.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _stage == _Stage.waiting) {
      _check();
    }
  }

  Future<void> _open() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _stage = _Stage.opening;
      _error = null;
    });
    try {
      final links = await ref.read(authApiProvider).startPhoneVerification();
      final open = ref.read(externalLinkOpenerProvider);
      final appUrl = links.botAppUrl;
      final opened =
          (appUrl != null && !kIsWeb && await open(appUrl)) ||
          await open(links.botUrl);
      if (!mounted) return;
      if (!opened) {
        setState(() {
          _stage = _Stage.ready;
          _error = l10n.telegramOpenFailed;
        });
        return;
      }
      _startedAt = DateTime.now();
      _poll?.cancel();
      _poll = Timer.periodic(_pollEvery, (_) => _check());
      _mascot.mood = MascotMood.thinking;
      setState(() => _stage = _Stage.waiting);
    } catch (error) {
      if (!mounted) return;
      _mascot.mood = MascotMood.sad;
      setState(() {
        _stage = _Stage.ready;
        _error = error is AuthFailure ? error.message : l10n.actionFailed;
      });
    }
  }

  Future<void> _check() async {
    if (_checking || _stage != _Stage.waiting) return;
    if (DateTime.now().difference(_startedAt!) > _giveUpAfter) {
      _poll?.cancel();
      _mascot.mood = MascotMood.idle;
      setState(() => _stage = _Stage.ready);
      return;
    }
    _checking = true;
    final user = await ref.read(authProvider.notifier).refreshProfile();
    _checking = false;
    if (!mounted || user == null || !user.hasVerifiedPhone) return;
    _poll?.cancel();
    _mascot.react(MascotMood.celebrate);
    setState(() => _stage = _Stage.done);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final profile = ref.watch(mascotProvider).profile;
    final species = profile?.species ?? MascotSpecies.crocodile;
    final line = switch (_stage) {
      _Stage.done => l10n.phoneVerifyBuddyDone,
      _Stage.waiting => l10n.phoneVerifyBuddyWaiting,
      _ => _error == null ? l10n.phoneVerifyBuddyStart : l10n.codeBuddyWrong,
    };

    Widget step(int number, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: palette.brand.withValues(alpha: .14),
            foregroundColor: palette.brand,
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: RiksaTypography.bodyStyleFor(
                text,
                theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MascotView(
                  species: species,
                  size: 88,
                  controller: _mascot,
                  interactive: true,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: MascotSpeechBubble(
                    key: const ValueKey('phone-verify-line'),
                    line: line,
                    tail: SpeechTail.left,
                    maxWidth: 240,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.phoneVerifyTitle,
              style: RiksaTypography.titleStyleFor(
                l10n.phoneVerifyTitle,
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.phoneVerifyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            step(1, l10n.phoneVerifyStepOpen),
            step(2, l10n.phoneVerifyStepShare),
            step(3, l10n.phoneVerifyStepBack),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                key: const ValueKey('phone-verify-error'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_stage == _Stage.done)
              FilledButton.icon(
                onPressed: null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.verified_rounded),
                label: Text(l10n.phoneVerifiedTitle),
              )
            else
              FilledButton.icon(
                key: const ValueKey('phone-verify-open'),
                onPressed: _stage == _Stage.opening ? null : _open,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF229ED9),
                  foregroundColor: Colors.white,
                ),
                icon: _stage == _Stage.opening
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const TelegramLogo(size: 20),
                label: Text(
                  _stage == _Stage.waiting
                      ? l10n.phoneVerifyOpenAgain
                      : l10n.phoneVerifyOpen,
                ),
              ),
            if (_stage == _Stage.waiting) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.phoneVerifyWaiting,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
