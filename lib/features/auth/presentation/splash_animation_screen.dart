import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
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
      backgroundColor: const Color(0xFFFCFCFE),
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
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
    return const IgnorePointer(
      child: RepaintBoundary(
        child: ClipRect(child: CustomPaint(painter: _SplashSmokePainter())),
      ),
    );
  }
}

class _SplashSmokePainter extends CustomPainter {
  const _SplashSmokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width * .62).clamp(200.0, 440.0);
    final haze = Paint()
      ..color = const Color(0x99FFDA9C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, 18),
        width: radius * 2,
        height: 230,
      ),
      haze,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 - radius * .35, 62),
        width: radius,
        height: 160,
      ),
      Paint()
        ..color = const Color(0x33FFE8BD)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );
  }

  @override
  bool shouldRepaint(_SplashSmokePainter oldDelegate) => false;
}

class _EditionBadge extends StatelessWidget {
  const _EditionBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: const Text(
            'MADE FOR CAMBODIA  •  2026',
            style: TextStyle(
              color: Color(0xFF242433),
              fontFamily: 'Poppins',
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
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF4548FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            'R',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 48,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Riksa',
          style: TextStyle(
            color: Color(0xFF242433),
            fontSize: 28,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'រៀន. គិត. អភិវឌ្ឍន៍.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF858591),
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
    const accent = Color(0xFF4548FF);
    return SizedBox(
      height: 54,
      child: Column(
        children: [
          SizedBox(
            width: 92,
            child: LinearProgressIndicator(
              minHeight: 3,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: accent.withValues(alpha: .08),
              color: ready ? const Color(0xFF4CAF50) : accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            (ready ? readyLabel : loadingLabel).toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF858591),
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
    const accent = Color(0xFF4548FF);
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E9F0)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF242433)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onUseAnotherAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                  ),
                  child: Text(anotherAccountLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                  ),
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
