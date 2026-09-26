import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_brand.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Launch screen and deterministic app bootstrap gate.
///
/// A returning learner sees the wordmark while the session restores and is
/// sent on automatically. On first run the screen becomes the welcome, and
/// Get Started leads to the buddy picker, then language selection, then setup.
class SplashAnimationScreen extends ConsumerStatefulWidget {
  const SplashAnimationScreen({super.key});

  @override
  ConsumerState<SplashAnimationScreen> createState() =>
      _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends ConsumerState<SplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _minimumTimeElapsed = false;
  bool _navigationScheduled = false;

  /// Set once bootstrap finds no saved language: the learner is new, and the
  /// screen waits for Get Started instead of moving on by itself.
  bool _welcoming = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _minimumTimeElapsed = true);
      _scheduleDestination();
    });
  }

  void _scheduleDestination() {
    if (!_minimumTimeElapsed || _navigationScheduled || _welcoming) return;
    if (!mounted) return;
    final locale = ref.read(localeProvider);
    final auth = ref.read(authProvider);
    if (!locale.isReady || auth is AuthInitial || auth is AuthUnavailable) {
      return;
    }
    if (!locale.hasSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _welcoming = true);
      });
      return;
    }

    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!locale.hasViewedOnboarding) {
        context.go('/onboarding');
      } else {
        context.go(kLandingLocation);
      }
    });
  }

  /// The buddy comes first, so the language page is already the learner's
  /// own buddy asking which language to speak, never a placeholder one.
  void _getStarted() => context.go('/mascot-select');

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
    final theme = Theme.of(context);
    final palette = context.riksa;
    _scheduleDestination();
    final unavailable = auth is AuthUnavailable ? auth : null;

    final entrance = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .6, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: fade,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: .86,
                            end: 1,
                          ).animate(entrance),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const RiksaWordmark(fontSize: 76),
                              const SizedBox(height: 22),
                              Text(
                                strings.splashTagline,
                                key: const Key('splash_tagline'),
                                textAlign: TextAlign.center,
                                style: RiksaTypography.titleStyleFor(
                                  strings.splashTagline,
                                  theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 260,
                                ),
                                child: Text(
                                  strings.splashDescription,
                                  textAlign: TextAlign.center,
                                  style: RiksaTypography.bodyStyleFor(
                                    strings.splashDescription,
                                    theme.textTheme.bodySmall?.copyWith(
                                      color: palette.inkMuted,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: RiksaMotion.resolve(
                      context,
                      RiksaMotion.standard,
                    ),
                    child: switch ((unavailable, _welcoming)) {
                      (final AuthUnavailable offline, _) => _OfflineActions(
                        key: const ValueKey('offline'),
                        message: offline.message,
                        onRetry: () => ref
                            .read(authProvider.notifier)
                            .bootstrap(force: true),
                        onUseAnotherAccount: () =>
                            ref.read(authProvider.notifier).logout(),
                        retryLabel: strings.tryAgain,
                        anotherAccountLabel: strings.useAnotherAccount,
                      ),
                      (_, true) => _WelcomeActions(
                        key: const ValueKey('welcome'),
                        label: strings.onboardingGetStarted,
                        onStart: _getStarted,
                      ),
                      _ => _BootstrapIndicator(
                        key: const ValueKey('loading'),
                        ready: locale.isReady && auth is! AuthInitial,
                        readyLabel: strings.readyToLearn,
                        loadingLabel: strings.preparingYourSpace,
                      ),
                    },
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

/// Hand-drawn marks scattered around the wordmark, as on the welcome board.
class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.surface, palette.canvas, palette.brandSoft],
                  stops: const [0, .55, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 26,
            child: Transform.rotate(
              angle: 2.4,
              child: RiksaDoodle(
                RiksaDoodleKind.arrow,
                size: 46,
                color: palette.ink,
              ),
            ),
          ),
          Positioned(
            top: 76,
            right: 30,
            child: RiksaDoodle(
              RiksaDoodleKind.star,
              size: 40,
              color: palette.ink,
            ),
          ),
          Positioned(
            left: -26,
            bottom: 250,
            child: RiksaDoodle(
              RiksaDoodleKind.globe,
              size: 96,
              color: palette.brand.withValues(alpha: .35),
            ),
          ),
          Positioned(
            right: 38,
            bottom: 290,
            child: RiksaDoodle(
              RiksaDoodleKind.sparkle,
              size: 30,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    super.key,
    required this.label,
    required this.onStart,
  });

  final String label;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A solid Material 3 filled pill rather than the theme's glass
          // one: the deep violet is the primary tone the reference uses for
          // its main call to action.
          FilledButton(
            key: const Key('splash_get_started'),
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? palette.brand : palette.brandStrong,
              foregroundColor: palette.onBrand,
              shadowColor: Colors.transparent,
              elevation: 0,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.bodyStyleFor(
                      label,
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
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
    final palette = context.riksa;
    final label = ready ? readyLabel : loadingLabel;
    return SizedBox(
      height: 64,
      child: Column(
        children: [
          SizedBox(
            width: 96,
            child: LinearProgressIndicator(
              minHeight: 4,
              borderRadius: AppRadii.fullBorder,
              backgroundColor: palette.outline,
              color: palette.jade,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: RiksaTypography.bodyStyleFor(
              label,
              Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: palette.inkMuted),
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
    final palette = context.riksa;
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.largeBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
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
