import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'widgets/onboarding_art.dart';

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

  static const _scenes = [
    OnboardingScene.learning,
    OnboardingScene.achievement,
    OnboardingScene.community,
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
    if (_currentPage < _scenes.length - 1) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        await _pageController.nextPage(
          duration: RiksaMotion.emphasis,
          curve: RiksaMotion.standardCurve,
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
      backgroundColor: context.riksa.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PageView.builder(
                      key: const Key('onboarding_pages'),
                      controller: _pageController,
                      itemCount: _scenes.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: RiksaSpacing.md),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          padding: const EdgeInsets.all(RiksaSpacing.xs),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? context.riksa.surface
                                : _sceneColor(_scenes[index]),
                            borderRadius: AppRadii.extraLargeBorder,
                          ),
                          child: Transform.scale(
                            scale: 1.1,
                            child: OnboardingArt(
                              scene: _scenes[index],
                              active: index == _currentPage,
                              semanticLabel: l10n.onboardingTitle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _PageIndicator(
                    count: _scenes.length,
                    currentPage: _currentPage,
                  ),
                  const SizedBox(height: RiksaSpacing.lg),
                  Text(
                    l10n.onboardingTitle,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.55,
                      height: 1.17,
                    ),
                  ),
                  const SizedBox(height: RiksaSpacing.xs),
                  AnimatedSwitcher(
                    duration: RiksaMotion.resolve(
                      context,
                      RiksaMotion.standard,
                    ),
                    child: Text(
                      bodies[_currentPage],
                      key: ValueKey(_currentPage),
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: RiksaSpacing.lg),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      key: const Key('onboarding_continue'),
                      onPressed: _finishing ? null : _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.dark
                            ? AppColors.editorialPink
                            : AppColors.editorialBlack,
                        foregroundColor: theme.brightness == Brightness.dark
                            ? AppColors.editorialAubergine
                            : Colors.white,
                      ),
                      child: _finishing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.continueLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _sceneColor(OnboardingScene scene) => switch (scene) {
    OnboardingScene.learning => AppColors.editorialPinkSoft,
    OnboardingScene.achievement => AppColors.editorialCreamSoft,
    OnboardingScene.community => AppColors.editorialMint,
  };
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentPage});

  final int count;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Page ${currentPage + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            width: index == currentPage ? 7 : 5,
            height: index == currentPage ? 7 : 5,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == currentPage
                  ? AppColors.editorialPink
                  : theme.brightness == Brightness.dark
                  ? context.riksa.outline
                  : AppColors.editorialOutline,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
