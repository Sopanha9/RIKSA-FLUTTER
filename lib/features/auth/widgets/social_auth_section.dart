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
    required this.isRegistration,
    this.showDivider = true,
  });

  final bool isRegistration;
  final bool showDivider;

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
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_googleReady)
          buildGoogleProviderButton(
            label: strings.signInWithGoogle,
            locale: locale,
            loading: loading,
            onPressed: _authenticateWithGoogle,
          )
        else
          OutlinedButton.icon(
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
            label: Text(strings.signInWithGoogle),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('telegram_auth_button'),
          onPressed: loading
              ? null
              : () => context.push(
                  '/auth/telegram?register=${widget.isRegistration}',
                ),
          icon: const TelegramLogo(),
          label: Text(strings.signInWithTelegram),
        ),
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
