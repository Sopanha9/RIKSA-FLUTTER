import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/riksa_logo.dart';
import '../providers/auth_provider.dart';

/// Splash screen: Riksa logo fades in + scales up, then auto-navigates
/// to onboarding after 2 seconds.
class SplashAnimationScreen extends ConsumerStatefulWidget {
  const SplashAnimationScreen({super.key});

  @override
  ConsumerState<SplashAnimationScreen> createState() => _SplashAnimationScreenState();
}

class _SplashAnimationScreenState extends ConsumerState<SplashAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fade: 0.0 → 1.0 over the full duration
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Scale: 0.6 → 1.0 with a slight overshoot bounce
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // After fade-in (1.2s) + hold (0.8s) = 2.0s total, navigate
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        final auth = ref.read(authProvider);
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        String destination;
        if (auth is Authenticated) {
          destination = '/home';
        } else if (prefs.getBool('riksa_intro_seen') ?? false) {
          destination = '/auth/login';
        } else {
          destination = '/onboarding';
        }
        context.go(destination);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            );
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RiksaLogo(fontSize: 64),
              SizedBox(height: 16),
              Text(
                'Learn. Reflect. Grow.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF536471),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
