import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/telegram_logo.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/auth_api.dart';
import '../data/auth_models.dart';
import '../data/auth_validators.dart';
import '../data/external_link_opener.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

/// Passwordless Telegram sign-in and sign-up with two options:
///
/// * **Open Telegram**: opens `t.me/<bot>?start=login_<nonce>`. The user taps
///   Confirm in the bot while this screen polls, and re-checks immediately when
///   the app returns to the foreground.
/// * **Log in with code**: the bot answers /start or /code with a short code
///   that the user pastes here.
///
/// Either way, existing accounts are signed in and new Telegram users choose a
/// username and display name (prefilled from Telegram) on the profile step.
class TelegramAuthScreen extends ConsumerStatefulWidget {
  const TelegramAuthScreen({super.key});

  @override
  ConsumerState<TelegramAuthScreen> createState() => _TelegramAuthScreenState();
}

enum _Phase { intro, starting, waiting, code, profile }

/// Characters the server uses for codes (no 0/O or 1/I).
final _codeInText = RegExp(r'(?<![A-Z0-9])[A-HJ-NP-Z2-9]{8}(?![A-Z0-9])');

class _TelegramAuthScreenState extends ConsumerState<TelegramAuthScreen>
    with WidgetsBindingObserver {
  static const _maxBackoff = Duration(seconds: 15);
  static const _codeLength = 8;

  final _profileFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _codeController = TextEditingController();

  _Phase _phase = _Phase.intro;
  TelegramAuthChallenge? _challenge;
  DateTime? _expiresAt;
  Duration _pollInterval = const Duration(seconds: 3);
  Timer? _pollTimer;
  Timer? _countdownTimer;
  bool _polling = false;

  /// Bumped whenever a request is abandoned so late responses are ignored.
  int _generation = 0;

  TelegramBotInfo? _botInfo;
  bool _redeemingCode = false;
  String? _codeError;

  String? _signupToken;
  TelegramProfile? _profile;
  String? _error;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    _usernameController.dispose();
    _displayNameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_phase == _Phase.waiting) {
      // Users usually confirm in Telegram and switch straight back, so check
      // immediately instead of waiting for the next scheduled poll.
      _pollTimer?.cancel();
      unawaited(_poll());
    } else if (_phase == _Phase.code && _codeController.text.isEmpty) {
      unawaited(_pasteCode(silent: true));
    }
  }

  AppLocalizations get _strings => AppLocalizations.of(context)!;

  void _stopTimers() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pollTimer = null;
    _countdownTimer = null;
  }

  /// Abandons any request and shows [phase] (the two options by default).
  void _reset({String? error, _Phase phase = _Phase.intro}) {
    _generation++;
    _stopTimers();
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _phase = phase;
      _challenge = null;
      _expiresAt = null;
      _polling = false;
      _redeemingCode = false;
      _signupToken = null;
      _profile = null;
      _usernameError = null;
      _codeError = null;
      _error = error;
    });
  }

  // ------------------------------------------------------------ Open Telegram

  Future<void> _authorize() async {
    if (_phase == _Phase.starting) return;
    final generation = ++_generation;
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _phase = _Phase.starting;
      _error = null;
    });
    final TelegramAuthChallenge challenge;
    try {
      challenge = await ref.read(authApiProvider).startTelegramAuth();
    } on AuthFailure catch (failure) {
      if (mounted && generation == _generation) {
        setState(() {
          _phase = _Phase.intro;
          _error = failure.message;
        });
      }
      return;
    }
    if (!mounted || generation != _generation) return;

    setState(() {
      _challenge = challenge;
      _expiresAt = clock.now().add(challenge.expiresIn);
      _pollInterval = challenge.pollInterval;
      _phase = _Phase.waiting;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining == Duration.zero) {
        _reset(error: _strings.telegramExpired);
      } else {
        setState(() {});
      }
    });
    _schedulePoll();
    await _openChallengeLink();
  }

  Future<void> _openChallengeLink() async {
    final challenge = _challenge;
    if (challenge == null) return;
    final opened = await _launch(challenge.botAppUrl, challenge.botUrl);
    if (!mounted || challenge != _challenge) return;
    setState(() => _error = opened ? null : _strings.telegramOpenFailed);
  }

  /// Prefers the Telegram app link, then the https link (Telegram Web or the
  /// app via OS link handling). Browsers can't open `tg://`, so web skips it.
  Future<bool> _launch(Uri? appUrl, Uri? webUrl) async {
    final open = ref.read(externalLinkOpenerProvider);
    if (appUrl != null && !kIsWeb && await open(appUrl)) return true;
    return webUrl != null && await open(webUrl);
  }

  Future<void> _copyLink() async {
    final challenge = _challenge;
    if (challenge == null) return;
    await Clipboard.setData(ClipboardData(text: challenge.botUrl.toString()));
    if (!mounted) return;
    _showSnack(_strings.telegramLinkCopied);
  }

  Duration get _remaining {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return Duration.zero;
    final left = expiresAt.difference(clock.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, _poll);
  }

  Future<void> _poll() async {
    final challenge = _challenge;
    if (challenge == null || _polling || _phase != _Phase.waiting) return;
    final generation = _generation;
    _polling = true;
    try {
      final result = await ref
          .read(authApiProvider)
          .pollTelegramAuth(challenge);
      if (!mounted || generation != _generation) return;
      switch (result.status) {
        case TelegramAuthStatus.pending:
          _pollInterval = challenge.pollInterval;
          _schedulePoll();
        case TelegramAuthStatus.authenticated ||
            TelegramAuthStatus.profileRequired:
          await _handleResult(result);
        case TelegramAuthStatus.expired:
          _reset(error: _strings.telegramExpired);
        case TelegramAuthStatus.denied:
          _reset(error: _strings.telegramDenied);
      }
    } on AuthFailure catch (failure) {
      if (!mounted || generation != _generation) return;
      switch (failure.kind) {
        case AuthFailureKind.network || AuthFailureKind.server:
          // Keep waiting; the confirmation is stored server-side.
          _schedulePoll();
        case AuthFailureKind.rateLimited:
          final doubled = _pollInterval * 2;
          _pollInterval = doubled > _maxBackoff ? _maxBackoff : doubled;
          _schedulePoll();
        case _:
          _reset(error: _strings.telegramExpired);
      }
    } finally {
      if (generation == _generation) _polling = false;
    }
  }

  // ------------------------------------------------------------ Log in with code

  void _showCodeStep() {
    _reset(phase: _Phase.code);
    _codeController.clear();
    if (_botInfo == null) unawaited(_loadBotInfo());
  }

  Future<void> _loadBotInfo() async {
    try {
      final info = await ref.read(authApiProvider).telegramBotInfo();
      if (mounted) setState(() => _botInfo = info);
    } on AuthFailure {
      // The screen still works without the handle; only "Open bot" is hidden.
    }
  }

  Future<void> _openBotForCode() async {
    final info = _botInfo;
    final opened = await _launch(info?.botAppUrl, info?.botUrl);
    if (!mounted || opened) return;
    setState(() => _error = _strings.telegramOpenFailed);
  }

  static String _normalizeCode(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Future<void> _pasteCode({bool silent = false}) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || _phase != _Phase.code) return;
    final text = (data?.text ?? '').toUpperCase().replaceAll('-', '');
    final match = _codeInText.firstMatch(text);
    if (match == null) {
      if (!silent) _showSnack(_strings.telegramNoCodeInClipboard);
      return;
    }
    _codeController.text = match.group(0)!;
    await _redeemCode();
  }

  Future<void> _redeemCode() async {
    if (_redeemingCode || ref.read(authProvider) is AuthLoading) return;
    final code = _normalizeCode(_codeController.text);
    if (code.length != _codeLength) {
      setState(() => _codeError = _strings.telegramCodeInvalidFormat);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final generation = _generation;
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _redeemingCode = true;
      _codeError = null;
      _error = null;
    });
    try {
      final result = await ref.read(authApiProvider).redeemTelegramCode(code);
      if (!mounted || generation != _generation) return;
      setState(() => _redeemingCode = false);
      if (result.status == TelegramAuthStatus.authenticated ||
          result.status == TelegramAuthStatus.profileRequired) {
        await _handleResult(result);
      } else {
        setState(() => _codeError = _strings.telegramCodeRejected);
      }
    } on AuthFailure catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _redeemingCode = false;
        if (failure.kind == AuthFailureKind.validation) {
          _codeError = _strings.telegramCodeRejected;
        } else {
          _error = failure.message;
        }
      });
    }
  }

  // ------------------------------------------------------------ shared result

  Future<void> _handleResult(TelegramAuthPoll result) async {
    _stopTimers();
    if (result.status == TelegramAuthStatus.profileRequired) {
      _showProfileStep(result);
      return;
    }
    final returnTo = _phase == _Phase.code ? _Phase.code : _Phase.intro;
    await ref.read(authProvider.notifier).acceptTelegramSession(result.auth!);
    if (mounted && ref.read(authProvider) is AuthError) {
      _generation++;
      setState(() => _phase = returnTo);
    }
  }

  void _showProfileStep(TelegramAuthPoll result) {
    final profile = result.profile;
    final suggestedUsername = profile?.username?.trim() ?? '';
    final suggestedName = profile?.displayName ?? '';
    _usernameController.text =
        AuthValidators.isRegistrationUsername(suggestedUsername)
        ? suggestedUsername
        : '';
    _displayNameController.text = suggestedName.length > 100
        ? suggestedName.substring(0, 100)
        : suggestedName;
    setState(() {
      _signupToken = result.signupToken;
      _profile = profile;
      _challenge = null;
      _error = null;
      _usernameError = null;
      _phase = _Phase.profile;
    });
  }

  Future<void> _createAccount() async {
    final signupToken = _signupToken;
    if (signupToken == null || ref.read(authProvider) is AuthLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _usernameError = null;
      _error = null;
    });
    if (!_profileFormKey.currentState!.validate()) return;
    final failure = await ref
        .read(authProvider.notifier)
        .completeTelegramSignup(
          TelegramCompleteRequest(
            signupToken: signupToken,
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
          ),
        );
    if (!mounted || failure == null) return;
    if (failure.kind == AuthFailureKind.unauthorized ||
        failure.statusCode == 410) {
      _reset(error: _strings.telegramSignupExpired);
    } else if (failure.statusCode == 409) {
      setState(() => _usernameError = failure.message);
    } else {
      setState(() => _error = failure.message);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _back() {
    if (_phase != _Phase.intro) {
      _reset();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final loading = auth is AuthLoading;
    final error = _error ?? (auth is AuthError ? auth.message : null);
    final bot = _botInfo?.handle ?? strings.telegramTheBot;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Authenticated) {
        context.go(authenticatedLandingFor(GoRouter.of(context).state.uri));
      }
    });

    final (eyebrow, title, subtitle) = switch (_phase) {
      _Phase.intro || _Phase.starting => (
        strings.telegramEyebrow,
        strings.telegramAuthTitle,
        strings.telegramAuthSubtitle,
      ),
      _Phase.waiting => (
        strings.telegramEyebrow,
        strings.telegramWaitingTitle,
        strings.telegramWaitingSubtitle,
      ),
      _Phase.code => (
        strings.telegramEyebrow,
        strings.telegramCodeTitle,
        strings.telegramCodeSubtitle(bot),
      ),
      _Phase.profile => (
        strings.telegramProfileEyebrow,
        strings.telegramProfileTitle,
        strings.telegramProfileSubtitle,
      ),
    };

    return PopScope<Object?>(
      canPop: _phase == _Phase.intro || loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !loading) _back();
      },
      child: AuthScaffold(
        onBack: loading ? null : _back,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: TelegramLogo(size: 58)),
            const SizedBox(height: 18),
            AuthHeader(eyebrow: eyebrow, title: title, subtitle: subtitle),
            const SizedBox(height: 24),
            AuthPanel(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: Column(
                  key: ValueKey(
                    _phase == _Phase.starting ? _Phase.intro : _phase,
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      AuthErrorBanner(message: error),
                      const SizedBox(height: 16),
                    ],
                    ...switch (_phase) {
                      _Phase.intro || _Phase.starting => _buildIntro(strings),
                      _Phase.waiting => _buildWaiting(strings, loading),
                      _Phase.code => _buildCode(strings, bot, loading),
                      _Phase.profile => _buildProfile(strings, loading),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIntro(AppLocalizations strings) {
    final starting = _phase == _Phase.starting;
    return [
      FilledButton.icon(
        key: const Key('telegram_authorize'),
        onPressed: starting ? null : _authorize,
        icon: starting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(strings.telegramAuthorize),
      ),
      const SizedBox(height: 8),
      _Caption(strings.telegramAuthorizeHint),
      const SizedBox(height: 18),
      AuthDivider(label: strings.orLabel),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        key: const Key('telegram_use_code'),
        onPressed: starting ? null : _showCodeStep,
        icon: const Icon(Icons.pin_outlined),
        label: Text(strings.telegramUseCode),
      ),
      const SizedBox(height: 8),
      _Caption(strings.telegramUseCodeHint),
      const SizedBox(height: 20),
      _Note(
        icon: Icons.lock_outline_rounded,
        text: strings.telegramPrivacyNote,
      ),
    ];
  }

  List<Widget> _buildWaiting(AppLocalizations strings, bool loading) {
    final theme = Theme.of(context);
    final remaining = _remaining;
    final minutes = remaining.inMinutes;
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return [
      const SizedBox(height: 4),
      const Center(
        child: SizedBox.square(
          dimension: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.editorialPink,
                ),
              ),
              TelegramLogo(size: 40),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        loading
            ? strings.preparingYourSpace
            : strings.telegramExpiresIn('$minutes:$seconds'),
        key: const Key('telegram_waiting_status'),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        key: const Key('telegram_open_again'),
        onPressed: loading ? null : _openChallengeLink,
        icon: const Icon(Icons.open_in_new_rounded),
        label: Text(strings.telegramOpenAgain),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        key: const Key('telegram_copy_link'),
        onPressed: loading ? null : _copyLink,
        icon: const Icon(Icons.link_rounded),
        label: Text(strings.telegramCopyLink),
      ),
      const SizedBox(height: 4),
      TextButton(
        key: const Key('telegram_switch_to_code'),
        onPressed: loading ? null : _showCodeStep,
        child: Text(strings.telegramSwitchToCode),
      ),
      TextButton(
        key: const Key('telegram_cancel'),
        onPressed: loading ? null : _reset,
        child: Text(strings.cancel),
      ),
    ];
  }

  List<Widget> _buildCode(AppLocalizations strings, String bot, bool loading) {
    final theme = Theme.of(context);
    final busy = loading || _redeemingCode;
    final canOpenBot = _botInfo?.botUrl != null;
    return [
      _Step(number: 1, label: strings.telegramCodeStepOpen(bot)),
      _Step(number: 2, label: strings.telegramCodeStepCopy),
      _Step(number: 3, label: strings.telegramCodeStepPaste),
      if (canOpenBot) ...[
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const Key('telegram_open_bot'),
          onPressed: busy ? null : _openBotForCode,
          icon: const TelegramLogo(size: 20),
          label: Text(strings.telegramOpenBot(bot)),
        ),
      ],
      const SizedBox(height: 18),
      TextField(
        key: const Key('telegram_code_input'),
        controller: _codeController,
        enabled: !busy,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        style: theme.textTheme.headlineSmall?.copyWith(
          letterSpacing: 6,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          const _UpperCaseFormatter(),
          LengthLimitingTextInputFormatter(_codeLength),
        ],
        onChanged: (value) {
          if (_codeError != null) setState(() => _codeError = null);
        },
        onSubmitted: (_) => _redeemCode(),
        decoration: InputDecoration(
          labelText: strings.telegramCodeLabel,
          hintText: strings.telegramCodeHint,
          errorText: _codeError,
          errorMaxLines: 3,
          suffixIcon: IconButton(
            key: const Key('telegram_paste_code'),
            tooltip: strings.telegramPasteCode,
            onPressed: busy ? null : _pasteCode,
            icon: const Icon(Icons.content_paste_rounded),
          ),
        ),
      ),
      const SizedBox(height: 18),
      FilledButton(
        key: const Key('telegram_code_submit'),
        onPressed: busy ? null : _redeemCode,
        child: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(strings.telegramSignIn),
      ),
      const SizedBox(height: 4),
      TextButton(
        key: const Key('telegram_use_open_instead'),
        onPressed: busy ? null : _reset,
        child: Text(strings.telegramUseOpenInstead),
      ),
    ];
  }

  List<Widget> _buildProfile(AppLocalizations strings, bool loading) {
    final displayName = _profile?.displayName;
    final connectedName = displayName != null && displayName.isNotEmpty
        ? displayName
        : _profile?.username;
    return [
      if (connectedName != null && connectedName.isNotEmpty) ...[
        _Note(
          key: const Key('telegram_connected_as'),
          icon: Icons.verified_rounded,
          text: strings.telegramConnectedAs(connectedName),
        ),
        const SizedBox(height: 18),
      ],
      Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('telegram_profile_username'),
              controller: _usernameController,
              enabled: !loading,
              maxLength: 50,
              autofocus: _usernameController.text.isEmpty,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newUsername],
              textInputAction: TextInputAction.next,
              forceErrorText: _usernameError,
              onChanged: (_) {
                if (_usernameError != null) {
                  setState(() => _usernameError = null);
                }
              },
              decoration: InputDecoration(
                labelText: strings.username,
                hintText: strings.usernameHint,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.requiredField;
                }
                if (!AuthValidators.isRegistrationUsername(value)) {
                  return strings.usernameTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('telegram_profile_display_name'),
              controller: _displayNameController,
              enabled: !loading,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createAccount(),
              decoration: InputDecoration(
                labelText: strings.displayName,
                hintText: strings.displayNameHint,
                prefixIcon: const Icon(Icons.badge_outlined),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.requiredField;
                }
                if (!AuthValidators.isDisplayName(value)) {
                  return strings.displayNameTooLong;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        key: const Key('telegram_create_account'),
        onPressed: loading ? null : _createAccount,
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(strings.telegramCreateAccount),
      ),
      const SizedBox(height: 4),
      TextButton(
        key: const Key('telegram_use_another_account'),
        onPressed: loading ? null : _reset,
        child: Text(strings.telegramUseAnotherAccount),
      ),
    ];
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.riksa.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: context.riksa.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
