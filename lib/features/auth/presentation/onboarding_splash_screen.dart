import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.riksa.surface,
                        borderRadius: AppRadii.fullBorder,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RiksaSpacing.sm,
                          vertical: RiksaSpacing.xs,
                        ),
                        child: Text(
                          'RIKSA',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.riksa.jadeStrong,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: RiksaSpacing.sm),
                  Expanded(
                    child: PageView.builder(
                      key: const Key('onboarding_pages'),
                      controller: _pageController,
                      itemCount: _assets.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: RiksaSpacing.md),
                        child: RiksaPastelCard(
                          tone: switch (index) {
                            0 => RiksaPastelTone.jade,
                            1 => RiksaPastelTone.cream,
                            _ => RiksaPastelTone.blush,
                          },
                          padding: const EdgeInsets.all(RiksaSpacing.md),
                          child: Image.asset(
                            _assets[index],
                            key: ValueKey(_assets[index]),
                            fit: BoxFit.contain,
                            semanticLabel: l10n.onboardingTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _PageIndicator(
                    count: _assets.length,
                    currentPage: _currentPage,
                  ),
                  const SizedBox(height: RiksaSpacing.lg),
                  Text(
                    l10n.onboardingTitle,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.headlineLarge,
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
                    height: 54,
                    child: FilledButton(
                      key: const Key('onboarding_continue'),
                      onPressed: _finishing ? null : _continue,
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
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
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
