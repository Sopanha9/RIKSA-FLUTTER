import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_logo.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Animated launch screen and deterministic app bootstrap gate.
class SplashAnimationScreen extends ConsumerStatefulWidget {
  const SplashAnimationScreen({super.key});

  @override
  ConsumerState<SplashAnimationScreen> createState() =>
      _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends ConsumerState<SplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _minimumTimeElapsed = false;
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1050),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(
      begin: .82,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _minimumTimeElapsed = true);
      _scheduleDestination();
    });
  }

  void _scheduleDestination() {
    if (!_minimumTimeElapsed || _navigationScheduled || !mounted) return;
    final locale = ref.read(localeProvider);
    final auth = ref.read(authProvider);
    if (!locale.isReady || auth is AuthInitial || auth is AuthUnavailable) {
      return;
    }

    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!locale.hasSelection) {
        context.go('/language-select');
      } else if (!locale.hasViewedOnboarding) {
        context.go('/onboarding');
      } else if (!locale.hasCompletedOnboarding &&
          locale.pendingProvinceId == null) {
        context.go('/province-select');
      } else if (auth is Authenticated) {
        context.go('/home');
      } else {
        context.go('/auth/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final auth = ref.watch(authProvider);
    final strings = AppLocalizations.of(context)!;
    _scheduleDestination();
    final unavailable = auth is AuthUnavailable ? auth : null;

    return Scaffold(
      backgroundColor: AppColors.lightCanvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashAtmosphere(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: _EditionBadge(),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: child,
                          ),
                        ),
                        child: const _SplashMark(),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: unavailable == null
                        ? _BootstrapIndicator(
                            key: const ValueKey('loading'),
                            ready: locale.isReady && auth is! AuthInitial,
                            readyLabel: strings.readyToLearn,
                            loadingLabel: strings.preparingYourSpace,
                          )
                        : _OfflineActions(
                            key: const ValueKey('offline'),
                            message: unavailable.message,
                            onRetry: () => ref
                                .read(authProvider.notifier)
                                .bootstrap(force: true),
                            onUseAnotherAccount: () =>
                                ref.read(authProvider.notifier).logout(),
                            retryLabel: strings.tryAgain,
                            anotherAccountLabel: strings.useAnotherAccount,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashAtmosphere extends StatelessWidget {
  const _SplashAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -90,
          child: _BlurOrb(color: AppTheme.secondary.withValues(alpha: .2)),
        ),
        Positioned(
          bottom: -150,
          left: -110,
          child: _BlurOrb(
            color: AppTheme.primary.withValues(alpha: .13),
            size: 330,
          ),
        ),
      ],
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, this.size = 280});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _EditionBadge extends StatelessWidget {
  const _EditionBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.fullBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: AppRadii.fullBorder,
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: const Text(
            'MADE FOR CAMBODIA  •  2026',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 104,
          height: 104,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: .12),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppTheme.primary,
            size: 42,
          ),
        ),
        const SizedBox(height: 28),
        const RiksaLogo(fontSize: 64),
        const SizedBox(height: 12),
        const Text(
          'រៀន. គិត. អភិវឌ្ឍន៍.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.muted,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _BootstrapIndicator extends StatelessWidget {
  const _BootstrapIndicator({
    super.key,
    required this.ready,
    required this.readyLabel,
    required this.loadingLabel,
  });

  final bool ready;
  final String readyLabel;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Column(
        children: [
          SizedBox(
            width: 92,
            child: LinearProgressIndicator(
              minHeight: 3,
              borderRadius: AppRadii.fullBorder,
              backgroundColor: AppTheme.primary.withValues(alpha: .08),
              color: ready ? AppTheme.secondary : AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            (ready ? readyLabel : loadingLabel).toUpperCase(),
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineActions extends StatelessWidget {
  const _OfflineActions({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onUseAnotherAccount,
    required this.retryLabel,
    required this.anotherAccountLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onUseAnotherAccount;
  final String retryLabel;
  final String anotherAccountLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onUseAnotherAccount,
                  child: Text(anotherAccountLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
