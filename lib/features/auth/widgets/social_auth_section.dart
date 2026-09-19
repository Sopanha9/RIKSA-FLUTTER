import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/telegram_logo.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/google_auth_client.dart';
import '../providers/auth_provider.dart';
import 'google_provider_button.dart';

class SocialAuthSection extends ConsumerStatefulWidget {
  const SocialAuthSection({
    super.key,
    this.showDivider = true,
    this.compact = false,
  });

  final bool showDivider;

  /// Puts Telegram and Google side by side with just the provider names, as
  /// under the login form. The full-width buttons read better on sign-up.
  final bool compact;

  @override
  ConsumerState<SocialAuthSection> createState() => _SocialAuthSectionState();
}

class _SocialAuthSectionState extends ConsumerState<SocialAuthSection> {
  StreamSubscription<GoogleAuthEvent>? _googleEvents;
  bool _googleReady = false;
  bool _preparingGoogle = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final client = ref.read(googleAuthClientProvider);
    _googleEvents = client.events.listen((event) {
      if (!mounted || event is! GoogleAuthProblem) return;
      setState(() => _localError = _googleMessage(event.kind));
    });
    unawaited(_prepareGoogle());
  }

  @override
  void dispose() {
    _googleEvents?.cancel();
    super.dispose();
  }

  Future<void> _prepareGoogle() async {
    try {
      await ref.read(googleAuthClientProvider).prepare();
      if (mounted) setState(() => _googleReady = true);
    } on GoogleAuthClientException {
      // Keep a normal tappable button so the missing setup is explained only
      // when a developer or tester tries to use it.
    } finally {
      if (mounted) setState(() => _preparingGoogle = false);
    }
  }

  Future<void> _authenticateWithGoogle() async {
    setState(() => _localError = null);
    ref.read(authProvider.notifier).clearError();
    try {
      await ref.read(googleAuthClientProvider).authenticate();
    } on GoogleAuthClientException catch (error) {
      if (mounted) setState(() => _localError = _googleMessage(error.kind));
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError = AppLocalizations.of(context)!.googleFailed,
        );
      }
    }
  }

  String _googleMessage(GoogleAuthProblemKind kind) {
    final strings = AppLocalizations.of(context)!;
    return switch (kind) {
      GoogleAuthProblemKind.notConfigured => strings.googleNotConfigured,
      GoogleAuthProblemKind.unsupported => strings.googleUnsupported,
      GoogleAuthProblemKind.failed => strings.googleFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final loading = ref.watch(authProvider) is AuthLoading;
    final locale = Localizations.localeOf(context).languageCode;

    // One flow for sign-in and sign-up: the server signs existing Telegram
    // accounts in and asks new ones for a username afterwards.
    Widget telegram(String label) => OutlinedButton.icon(
      key: const Key('telegram_auth_button'),
      onPressed: loading ? null : () => context.push('/auth/telegram'),
      icon: const TelegramLogo(),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    Widget google(String label) => _googleReady
        ? buildGoogleProviderButton(
            label: label,
            locale: locale,
            loading: loading,
            onPressed: _authenticateWithGoogle,
          )
        : OutlinedButton.icon(
            key: const Key('google_auth_button'),
            onPressed: loading || _preparingGoogle
                ? null
                : _authenticateWithGoogle,
            icon: _preparingGoogle
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const GoogleLogo(),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDivider) ...[
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  strings.orContinueWith,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.riksa.inkMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (widget.compact)
          Row(
            children: [
              Expanded(child: telegram('Telegram')),
              const SizedBox(width: 12),
              Expanded(child: google('Google')),
            ],
          )
        else ...[
          telegram(strings.signInWithTelegram),
          const SizedBox(height: 12),
          google(strings.signInWithGoogle),
        ],
        if (_localError != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              _localError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
