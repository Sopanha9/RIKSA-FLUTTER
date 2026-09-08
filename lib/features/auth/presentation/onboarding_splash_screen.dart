import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'widgets/onboarding_art.dart';

/// The three-card introduction to the app.
///
/// Each card is a full-bleed pastel stage with its own illustration, headline
/// and promise, under a sheet that holds the copy and the single way forward.
/// The illustration is edge to edge rather than framed in a card: a boxed
/// picture reads as content inside the app, and this screen is not the app yet.
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

  /// How far the sheet rides up over the stage.
  ///
  /// The Scaffold is painted in the sheet's own colour, so the strip the sheet
  /// vacates at the bottom is invisible and no measurement is needed to make
  /// the rounded corners sit on the artwork.
  static const _sheetOverlap = 28.0;

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

  bool get _isLastPage => _currentPage == _scenes.length - 1;

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
    final palette = context.riksa;
    final titles = [
      l10n.onboardingLearningTitle,
      l10n.onboardingAchievementTitle,
      l10n.onboardingCommunityTitle,
    ];
    final bodies = [
      l10n.onboardingLearningBody,
      l10n.onboardingAchievementBody,
      l10n.onboardingCommunityBody,
    ];

    return Scaffold(
      backgroundColor: palette.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: RiksaMotion.resolve(context, RiksaMotion.emphasis),
              curve: RiksaMotion.standardCurve,
              color: theme.brightness == Brightness.dark
                  ? palette.canvas
                  : _sceneColor(_scenes[_currentPage]),
              child: SafeArea(
                bottom: false,
                child: PageView.builder(
                  key: const Key('onboarding_pages'),
                  controller: _pageController,
                  itemCount: _scenes.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => Padding(
                    // Only the bottom inset matters: the sheet covers the last
                    // stretch of the stage, and art tucked under it is lost.
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      RiksaSpacing.md,
                      24,
                      RiksaSpacing.lg + _sheetOverlap,
                    ),
                    child: OnboardingArt(
                      scene: _scenes[index],
                      active: index == _currentPage,
                      semanticLabel: titles[index],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -_sheetOverlap),
            child: _OnboardingSheet(
              title: titles[_currentPage],
              body: bodies[_currentPage],
              page: _currentPage,
              pageCount: _scenes.length,
              actionLabel: _isLastPage
                  ? l10n.onboardingGetStarted
                  : l10n.continueLabel,
              busy: _finishing,
              onAction: _finishing ? null : _continue,
            ),
          ),
        ],
      ),
    );
  }

  Color _sceneColor(OnboardingScene scene) => switch (scene) {
    OnboardingScene.learning => AppColors.editorialPinkSoft,
    OnboardingScene.achievement => AppColors.editorialCreamSoft,
    OnboardingScene.community => AppColors.editorialMint,
  };
}

/// The white panel that carries the words and the one way forward.
class _OnboardingSheet extends StatelessWidget {
  const _OnboardingSheet({
    required this.title,
    required this.body,
    required this.page,
    required this.pageCount,
    required this.actionLabel,
    required this.busy,
    required this.onAction,
  });

  final String title;
  final String body;
  final int page;
  final int pageCount;
  final String actionLabel;
  final bool busy;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.feature + 4),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                RiksaSpacing.lg,
                24,
                RiksaSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageIndicator(count: pageCount, currentPage: page),
                  const SizedBox(height: RiksaSpacing.lg),
                  // Both strings cross-fade together: the headline and its
                  // promise are one thought, and swapping them apart would read
                  // as two unrelated changes.
                  AnimatedSwitcher(
                    duration: RiksaMotion.resolve(
                      context,
                      RiksaMotion.standard,
                    ),
                    child: Column(
                      key: ValueKey(page),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: RiksaTypography.titleStyleFor(
                            title,
                            theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.6,
                              height: 1.15,
                            ),
                            khmerHeight: 1.3,
                          ),
                        ),
                        const SizedBox(height: RiksaSpacing.sm),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: RiksaTypography.bodyStyleFor(
                            body,
                            theme.textTheme.bodyMedium?.copyWith(
                              color: palette.inkMuted,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RiksaSpacing.lg),
                  FilledButton(
                    key: const Key('onboarding_continue'),
                    onPressed: busy ? null : onAction,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      backgroundColor: theme.brightness == Brightness.dark
                          ? AppColors.editorialPink
                          : AppColors.editorialAubergine,
                      foregroundColor: theme.brightness == Brightness.dark
                          ? AppColors.editorialAubergine
                          : const Color(0xFFFFF7FB),
                    ),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            actionLabel,
                            style: RiksaTypography.bodyStyleFor(
                              actionLabel,
                              const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
    );
  }
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
          // The current page reads as a bar rather than a bigger dot, so the
          // position is legible without comparing three similar circles.
          (index) => AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            curve: RiksaMotion.standardCurve,
            width: index == currentPage ? 22 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index == currentPage
                  ? AppColors.editorialPink
                  : theme.brightness == Brightness.dark
                  ? context.riksa.outline
                  : AppColors.editorialOutline,
              borderRadius: AppRadii.fullBorder,
            ),
          ),
        ),
      ),
    );
  }
}
