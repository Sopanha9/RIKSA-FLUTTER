import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';

class OnboardingSplashScreen extends ConsumerStatefulWidget {
  const OnboardingSplashScreen({super.key, this.onComplete});

  /// Optional test/embedding hook. The app normally navigates through GoRouter.
  final VoidCallback? onComplete;

  @override
  ConsumerState<OnboardingSplashScreen> createState() =>
      _OnboardingSplashScreenState();
}

class _OnboardingSplashScreenState
    extends ConsumerState<OnboardingSplashScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _finishing = false;

  static const _assets = [
    'assets/images/splashScreen/image.png',
    'assets/images/splashScreen/image copy.png',
    'assets/images/splashScreen/image copy 2.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_finishing) return;
    if (_currentPage < _assets.length - 1) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    setState(() => _finishing = true);
    await ref.read(localeProvider.notifier).completeIntro();
    if (!mounted) return;
    if (widget.onComplete case final callback?) {
      setState(() => _finishing = false);
      callback();
      return;
    }
    context.go('/province-select');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bodies = [
      l10n.onboardingLearningBody,
      l10n.onboardingAchievementBody,
      l10n.onboardingCommunityBody,
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PageView.builder(
                  key: const Key('onboarding_pages'),
                  controller: _pageController,
                  itemCount: _assets.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                    child: Image.asset(
                      _assets[index],
                      key: ValueKey(_assets[index]),
                      fit: BoxFit.contain,
                      semanticLabel: l10n.onboardingTitle,
                    ),
                  ),
                ),
              ),
              _PageIndicator(count: _assets.length, currentPage: _currentPage),
              const SizedBox(height: 22),
              Text(
                l10n.onboardingTitle,
                textAlign: TextAlign.start,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.35,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  bodies[_currentPage],
                  key: ValueKey(_currentPage),
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Poppins',
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('onboarding_continue'),
                  onPressed: _finishing ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lightTextPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.lightTextPrimary,
                    disabledForegroundColor: Colors.white70,
                    shape: const StadiumBorder(),
                  ),
                  child: _finishing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.continueLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentPage});

  final int count;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Page ${currentPage + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == currentPage ? 7 : 5,
            height: index == currentPage ? 7 : 5,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == currentPage
                  ? colors.onSurface
                  : colors.outlineVariant,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
