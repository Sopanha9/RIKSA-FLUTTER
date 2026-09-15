import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_brand.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'widgets/onboarding_art.dart';

/// The three-page introduction to the app.
///
/// Each page stages its illustration on a soft lavender disc with floating
/// subject bubbles, then the headline and promise. Skip and Next sit together
/// at the bottom so the learner can always leave or move on with one thumb.
class OnboardingSplashScreen extends ConsumerStatefulWidget {
  const OnboardingSplashScreen({super.key, this.onComplete});

  /// Optional test/embedding hook. The app normally navigates through GoRouter.
  final VoidCallback? onComplete;

  @override
  ConsumerState<OnboardingSplashScreen> createState() =>
      _OnboardingSplashScreenState();
}

class _OnboardingSplashScreenState extends ConsumerState<OnboardingSplashScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _float;
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
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _float.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _scenes.length - 1;

  Future<void> _continue() async {
    if (_finishing) return;
    if (!_isLastPage) {
      if (MediaQuery.of(context).disableAnimations) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        await _pageController.nextPage(
          duration: RiksaMotion.emphasis,
          curve: RiksaMotion.standardCurve,
        );
      }
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
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
    final actionLabel = _isLastPage
        ? l10n.onboardingGetStarted
        : l10n.nextLabel;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: _OnboardingStage(
                                scene: _scenes[index],
                                float: _float,
                                child: OnboardingArt(
                                  scene: _scenes[index],
                                  active: index == _currentPage,
                                  semanticLabel: titles[index],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            titles[index],
                            textAlign: TextAlign.center,
                            style: RiksaTypography.titleStyleFor(
                              titles[index],
                              theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.4,
                              ),
                              khmerHeight: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bodies[index],
                            textAlign: TextAlign.center,
                            style: RiksaTypography.bodyStyleFor(
                              bodies[index],
                              theme.textTheme.bodyMedium?.copyWith(
                                color: palette.inkMuted,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _PageIndicator(
                  count: _scenes.length,
                  currentPage: _currentPage,
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 24, 16),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        opacity: _isLastPage ? 0 : 1,
                        duration: RiksaMotion.resolve(
                          context,
                          RiksaMotion.standard,
                        ),
                        child: TextButton(
                          key: const Key('onboarding_skip'),
                          onPressed: _isLastPage || _finishing ? null : _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: palette.inkMuted,
                          ),
                          child: Text(l10n.skipLabel),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('onboarding_continue'),
                        onPressed: _finishing ? null : _continue,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(128, 54),
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                        ),
                        child: _finishing
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The illustration on a lavender disc, ringed by floating subject bubbles.
class _OnboardingStage extends StatelessWidget {
  const _OnboardingStage({
    required this.scene,
    required this.float,
    required this.child,
  });

  final OnboardingScene scene;
  final Animation<double> float;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final bubbles = switch (scene) {
      OnboardingScene.learning => const [
        (
          Icons.menu_book_outlined,
          Alignment(-.62, -.72),
          AppColors.tileLavender,
        ),
        (Icons.science_outlined, Alignment(.66, -.62), AppColors.tileLavender),
        (Icons.eco_outlined, Alignment(-.8, .5), AppColors.tileGreen),
      ],
      OnboardingScene.achievement => const [
        (
          Icons.emoji_events_outlined,
          Alignment(-.66, -.7),
          AppColors.tileYellow,
        ),
        (
          Icons.local_fire_department_outlined,
          Alignment(.7, -.6),
          AppColors.tilePeach,
        ),
        (
          Icons.star_outline_rounded,
          Alignment(.82, .48),
          AppColors.tileLavender,
        ),
      ],
      OnboardingScene.community => const [
        (Icons.forum_outlined, Alignment(-.66, -.7), AppColors.tileBlue),
        (
          Icons.favorite_border_rounded,
          Alignment(.7, -.62),
          AppColors.tilePink,
        ),
        (Icons.groups_outlined, Alignment(-.82, .5), AppColors.tileLavender),
      ],
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final disc =
            math.min(constraints.maxWidth, constraints.maxHeight) * .92;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: disc,
              height: disc,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [palette.brandSoft, palette.canvas],
                  stops: const [.62, 1],
                ),
              ),
            ),
            Positioned(
              right: constraints.maxWidth * .12,
              bottom: constraints.maxHeight * .1,
              child: RiksaDoodle(
                RiksaDoodleKind.sparkle,
                size: 22,
                color: palette.brand.withValues(alpha: .6),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * .1,
              top: constraints.maxHeight * .42,
              child: RiksaDoodle(
                RiksaDoodleKind.squiggle,
                size: 26,
                color: AppColors.lime,
              ),
            ),
            SizedBox(width: disc, height: disc, child: child),
            for (final (index, (icon, alignment, tint)) in bubbles.indexed)
              Align(
                alignment: alignment,
                child: AnimatedBuilder(
                  animation: float,
                  builder: (context, bubble) => Transform.translate(
                    offset: Offset(
                      0,
                      math.sin((float.value + index / 3) * 2 * math.pi) * 5,
                    ),
                    child: bubble,
                  ),
                  child: _Bubble(icon: icon, tint: tint),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rowBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: RiksaIconTile(
        icon: icon,
        background: tint,
        foreground: palette.brand,
        size: 40,
        iconSize: 22,
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
    final palette = context.riksa;
    return Semantics(
      label: 'Page ${currentPage + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            curve: RiksaMotion.standardCurve,
            width: index == currentPage ? 22 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index == currentPage ? palette.brand : palette.outline,
              borderRadius: AppRadii.fullBorder,
            ),
          ),
        ),
      ),
    );
  }
}
