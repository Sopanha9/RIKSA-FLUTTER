import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/mascot_face.dart';
import '../../mascot/presentation/widgets/mascot_scene.dart';
import '../../mascot/presentation/widgets/mascot_view.dart';

/// One intro page: whose home it is set in, how the two buddies behave, and
/// what floats above them.
class _IntroPage {
  const _IntroPage({
    required this.home,
    required this.crocRest,
    required this.capyRest,
    required this.crocCue,
    required this.capyCue,
    required this.floaters,
  });

  /// Which buddy's scene fills the background.
  final MascotSpecies home;
  final MascotMood crocRest;
  final MascotMood capyRest;

  /// Played once as the page comes into view.
  final MascotMood crocCue;
  final MascotMood capyCue;
  final List<_Floater> floaters;
}

/// A bubble drifting above the buddies: a face (someone in the community) or
/// an icon (something to do).
class _Floater {
  const _Floater.face(this.species, this.face, this.alignment, this.tint)
    : icon = null;
  const _Floater.icon(this.icon, this.alignment, this.tint)
    : species = null,
      face = null;

  final MascotSpecies? species;
  final MascotFace? face;
  final IconData? icon;
  final Alignment alignment;
  final Color tint;
}

/// The three-page introduction, shown straight after the splash.
///
/// RIKSA is a place to learn with other people, so the story leads with the
/// community, then learning together, then growing with a buddy, which sets
/// up picking one next. Both buddies act each page out in their scenes, and
/// the words sit on the same bottom sheet as the buddy and language pages.
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
  static const _pages = [
    _IntroPage(
      home: MascotSpecies.capybara,
      crocRest: MascotMood.idle,
      capyRest: MascotMood.idle,
      crocCue: MascotMood.greeting,
      capyCue: MascotMood.greeting,
      floaters: [
        _Floater.face(
          MascotSpecies.crocodile,
          MascotFace.laughing,
          Alignment(-.74, .15),
          AppColors.tileGreen,
        ),
        _Floater.icon(
          Icons.forum_rounded,
          Alignment(0, -.45),
          AppColors.tileBlue,
        ),
        _Floater.face(
          MascotSpecies.capybara,
          MascotFace.love,
          Alignment(.74, .2),
          AppColors.tilePink,
        ),
      ],
    ),
    _IntroPage(
      home: MascotSpecies.crocodile,
      crocRest: MascotMood.thinking,
      capyRest: MascotMood.idle,
      crocCue: MascotMood.thinking,
      capyCue: MascotMood.happy,
      floaters: [
        _Floater.icon(
          Icons.menu_book_rounded,
          Alignment(-.74, .15),
          AppColors.tileLavender,
        ),
        _Floater.icon(
          Icons.auto_awesome_rounded,
          Alignment(0, -.45),
          AppColors.tileYellow,
        ),
        _Floater.face(
          MascotSpecies.capybara,
          MascotFace.proud,
          Alignment(.74, .2),
          AppColors.tilePeach,
        ),
      ],
    ),
    _IntroPage(
      home: MascotSpecies.capybara,
      crocRest: MascotMood.happy,
      capyRest: MascotMood.love,
      crocCue: MascotMood.celebrate,
      capyCue: MascotMood.celebrate,
      floaters: [
        _Floater.icon(
          Icons.local_fire_department_rounded,
          Alignment(-.74, .15),
          AppColors.tilePeach,
        ),
        _Floater.icon(
          Icons.emoji_events_rounded,
          Alignment(0, -.45),
          AppColors.tileYellow,
        ),
        _Floater.icon(
          Icons.favorite_rounded,
          Alignment(.74, .2),
          AppColors.tilePink,
        ),
      ],
    ),
  ];

  late final PageController _pageController;
  late final AnimationController _float;
  late final List<(MascotController, MascotController)> _buddies = [
    for (final page in _pages)
      (MascotController(page.crocRest), MascotController(page.capyRest)),
  ];
  Timer? _cueTimer;
  int _currentPage = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MascotScenes.precacheAll(context);
      _cue(0);
    });
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
    _cueTimer?.cancel();
    _pageController.dispose();
    _float.dispose();
    for (final (croc, capy) in _buddies) {
      croc.dispose();
      capy.dispose();
    }
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  /// The buddies act the page out: the crocodile first, the capybara a beat
  /// later so they never move in lockstep.
  void _cue(int index) {
    final page = _pages[index];
    final (croc, capy) = _buddies[index];
    _cueTimer?.cancel();
    croc.react(page.crocCue);
    _cueTimer = Timer(
      const Duration(milliseconds: 350),
      () => capy.react(page.capyCue),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _cue(index);
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _pages.length) return;
    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(index);
    } else {
      await _pageController.animateToPage(
        index,
        duration: RiksaMotion.emphasis,
        curve: RiksaMotion.standardCurve,
      );
    }
  }

  Future<void> _continue() async {
    if (_finishing) return;
    if (!_isLastPage) return _goTo(_currentPage + 1);
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
    context.go('/mascot-select');
  }

  /// Returning learners skip the rest of first-run setup entirely, keeping
  /// whichever language they read the intro in.
  Future<void> _logIn() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final notifier = ref.read(localeProvider.notifier);
    await notifier.setLocale(ref.read(localeProvider).locale);
    await notifier.completeIntro();
    await notifier.completeOnboarding();
    if (mounted) context.go('/auth/login');
  }

  /// Swipes on the sheet turn pages too, so the whole screen feels like one
  /// surface.
  void _onSheetDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    final forward = Directionality.of(context) == TextDirection.ltr
        ? velocity < 0
        : velocity > 0;
    _goTo(_currentPage + (forward ? 1 : -1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final isDark = theme.brightness == Brightness.dark;
    final titles = [
      l10n.onboardingCommunityTitle,
      l10n.onboardingLearningTitle,
      l10n.onboardingAchievementTitle,
    ];
    final bodies = [
      l10n.onboardingCommunityBody,
      l10n.onboardingLearningBody,
      l10n.onboardingAchievementBody,
    ];
    final actionLabel = _isLastPage
        ? l10n.onboardingGetStarted
        : l10n.nextLabel;
    final fade = RiksaMotion.resolve(context, RiksaMotion.standard);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: MascotSceneBackdrop(species: _pages[_currentPage].home),
          ),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PageView.builder(
                          key: const Key('onboarding_pages'),
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) => _IntroStage(
                            key: Key('intro_page_$index'),
                            page: _pages[index],
                            buddies: _buddies[index],
                            float: _float,
                            semanticLabel: titles[index],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            const LanguageToggle(),
                            const Spacer(),
                            AnimatedOpacity(
                              opacity: _isLastPage ? 0 : 1,
                              duration: fade,
                              child: TextButton(
                                key: const Key('onboarding_skip'),
                                onPressed: _isLastPage || _finishing
                                    ? null
                                    : _finish,
                                style: TextButton.styleFrom(
                                  backgroundColor: palette.surface.withValues(
                                    alpha: .85,
                                  ),
                                  foregroundColor: palette.ink,
                                  shape: const StadiumBorder(),
                                  minimumSize: const Size(64, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                ),
                                child: Text(
                                  l10n.skipLabel,
                                  style: RiksaTypography.bodyStyleFor(
                                    l10n.skipLabel,
                                    const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
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
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: _onSheetDrag,
                child: MascotSceneSheet(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PageIndicator(
                        count: _pages.length,
                        currentPage: _currentPage,
                        onTap: _goTo,
                      ),
                      const SizedBox(height: 16),
                      // Every page's words are laid out at once so the sheet
                      // keeps the height of the longest and never jumps.
                      Stack(
                        children: [
                          for (var i = 0; i < _pages.length; i++)
                            ExcludeSemantics(
                              excluding: i != _currentPage,
                              child: IgnorePointer(
                                ignoring: i != _currentPage,
                                child: AnimatedOpacity(
                                  opacity: i == _currentPage ? 1 : 0,
                                  duration: fade,
                                  child: _IntroCopy(
                                    key: Key('intro_copy_$i'),
                                    title: titles[i],
                                    body: bodies[i],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('onboarding_continue'),
                        onPressed: _finishing ? null : _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? palette.brand
                              : palette.brandStrong,
                          foregroundColor: palette.onBrand,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: _finishing
                            ? SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.onBrand,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    actionLabel,
                                    style: RiksaTypography.bodyStyleFor(
                                      actionLabel,
                                      const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                      if (widget.onComplete == null) ...[
                        const SizedBox(height: 4),
                        TextButton(
                          key: const Key('onboarding_login'),
                          onPressed: _finishing ? null : _logIn,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            foregroundColor: palette.inkMuted,
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: '${l10n.haveAccount} ',
                              children: [
                                TextSpan(
                                  text: l10n.login,
                                  style: TextStyle(
                                    color: palette.brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            style: RiksaTypography.bodyStyleFor(
                              l10n.haveAccount,
                              const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroCopy extends StatelessWidget {
  const _IntroCopy({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: RiksaTypography.titleStyleFor(
            title,
            theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            khmerHeight: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: RiksaTypography.bodyStyleFor(
            body,
            theme.textTheme.bodyMedium?.copyWith(
              color: palette.inkMuted,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

/// Both buddies standing together on the grass, with the page's bubbles
/// drifting above them.
class _IntroStage extends StatelessWidget {
  const _IntroStage({
    super.key,
    required this.page,
    required this.buddies,
    required this.float,
    required this.semanticLabel,
  });

  final _IntroPage page;
  final (MascotController, MascotController) buddies;
  final Animation<double> float;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final (croc, capy) = buddies;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            // Leave room at the top for the language and skip controls.
            final buddy = math
                .min(
                  box.maxWidth * .44,
                  (box.maxHeight - 140) / MascotView.heightFactor,
                )
                .clamp(0.0, 196.0);
            final floaterArea = math.max(0.0, box.maxHeight - buddy * 1.25);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 56,
                  height: math.max(0.0, floaterArea - 56),
                  child: Stack(
                    children: [
                      for (final (index, floater) in page.floaters.indexed)
                        Align(
                          alignment: floater.alignment,
                          child: AnimatedBuilder(
                            animation: float,
                            builder: (context, bubble) => Transform.translate(
                              offset: Offset(
                                0,
                                math.sin(
                                      (float.value + index / 3) * 2 * math.pi,
                                    ) *
                                    5,
                              ),
                              child: bubble,
                            ),
                            child: _Bubble(floater: floater),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MascotView(
                        species: MascotSpecies.crocodile,
                        size: buddy,
                        controller: croc,
                      ),
                      SizedBox(width: buddy * .02),
                      // The capybara stands a touch smaller and further back.
                      MascotView(
                        species: MascotSpecies.capybara,
                        size: buddy * .92,
                        controller: capy,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.floater});

  final _Floater floater;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final species = floater.species;
    final face = floater.face;
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: palette.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: floater.tint, shape: BoxShape.circle),
        child: species != null && face != null
            ? Padding(
                padding: const EdgeInsets.all(3),
                child: MascotFaceView(species: species, face: face, size: 42),
              )
            : Icon(floater.icon, color: palette.brand, size: 24),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.currentPage,
    required this.onTap,
  });

  final int count;
  final int currentPage;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Semantics(
      label: 'Page ${currentPage + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: AnimatedContainer(
                duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                curve: RiksaMotion.standardCurve,
                width: index == currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == currentPage ? palette.brand : palette.outline,
                  borderRadius: AppRadii.fullBorder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
