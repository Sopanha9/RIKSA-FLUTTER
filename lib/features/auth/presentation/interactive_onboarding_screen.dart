import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/sound/learning_sound.dart';
import '../../../core/sound/sound_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/mascot_face.dart';
import '../../mascot/presentation/widgets/mascot_scene.dart';
import '../../mascot/presentation/widgets/mascot_speech.dart';
import '../../mascot/presentation/widgets/mascot_view.dart';
import '../../mascot/providers/mascot_provider.dart';
import '../data/auth_models.dart';
import '../data/onboarding_models.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

/// Picks the English or Khmer copy, the way the onboarding models do.
String _t(String lang, String en, String km) => lang == 'km' ? km : en;

/// [AnimatedSize] cannot take a zero duration, which reduced motion gives.
Duration _sizeDuration(BuildContext context) {
  final duration = RiksaMotion.resolve(context, RiksaMotion.standard);
  return duration == Duration.zero ? const Duration(milliseconds: 1) : duration;
}

/// First-run setup, done together with the learner's buddy.
///
/// The buddy stands in its home scene at the top, talks the learner through
/// each step and reacts to every choice; the step itself sits on a sheet
/// below. The steps are a starting subject, one question from it (so the
/// learner is doing the subject within seconds of picking it), a home
/// province (the learner's leaderboard squad) and a roadmap confirmation.
class InteractiveOnboardingScreen extends ConsumerStatefulWidget {
  const InteractiveOnboardingScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  ConsumerState<InteractiveOnboardingScreen> createState() =>
      _InteractiveOnboardingScreenState();
}

class _InteractiveOnboardingScreenState
    extends ConsumerState<InteractiveOnboardingScreen> {
  final MascotController _buddy = MascotController();

  int _currentPage = 0;
  bool _forward = true;
  static const int _totalPages = 4;
  static const int _questionPage = 1;
  static const int _provincePage = 2;
  static const int _payoffPage = 3;
  bool _submitting = false;
  final TextEditingController _provinceSearchController =
      TextEditingController();
  String _provinceQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MascotScenes.precacheAll(context);
      _buddy.react(MascotMood.greeting);
    });
  }

  @override
  void dispose() {
    _buddy.dispose();
    _provinceSearchController.dispose();
    super.dispose();
  }

  bool _isStepComplete(OnboardingSetupData data) {
    return switch (_currentPage) {
      0 => data.subject != null,
      _questionPage => data.quizAnswer1Index != null,
      _provincePage => data.provinceId != null,
      _ => true,
    };
  }

  void _goTo(int page) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = page > _currentPage;
      _currentPage = page;
    });
    // The buddy settles into the mood of the new step.
    _buddy.mood = page == _payoffPage ? MascotMood.happy : MascotMood.idle;
  }

  Future<void> _next(
    OnboardingSetupData data, {
    required bool hasSavedProvince,
  }) async {
    if (_submitting) return;
    if (_currentPage < _totalPages - 1) {
      _goTo(
        hasSavedProvince && _currentPage == _questionPage
            ? _payoffPage
            : _currentPage + 1,
      );
      return;
    }
    await _saveAndNavigate(_startLocation(data));
  }

  Future<void> _back({required bool hasSavedProvince}) async {
    if (_submitting) return;
    if (_currentPage > 0) {
      _goTo(
        hasSavedProvince && _currentPage == _payoffPage
            ? _questionPage
            : _currentPage - 1,
      );
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) router.pop();
  }

  /// Setup ends on the chosen subject's path, so the learner is not asked to
  /// pick a subject again on the learning home.
  String _startLocation(OnboardingSetupData data) => switch (data.subject) {
    final subject? => '/learn/subject/${subject.id}',
    null => kLandingLocation,
  };

  Future<void> _saveAndNavigate(String route) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ref.read(onboardingProvider.notifier).commitSetup();
    final provinceId = ref.read(onboardingProvider).provinceId;
    final auth = ref.read(authProvider);
    final hasSavedProvince =
        auth is Authenticated && (auth.user.provinceId?.isNotEmpty ?? false);
    if (provinceId == null || hasSavedProvince) {
      await ref.read(localeProvider.notifier).completeOnboarding();
    } else {
      // Completing onboarding clears the pending squad, so a guest's province
      // stays pending until sign-in sends it; a signed-in learner's goes now.
      await ref.read(authProvider.notifier).saveProvinceSelection(provinceId);
    }

    if (!mounted) return;
    if (widget.onComplete case final callback?) {
      setState(() => _submitting = false);
      callback();
      return;
    }

    context.go(route);
  }

  /// What the buddy says: it opens each step, then answers the choice made.
  String _buddyLine(OnboardingSetupData setup, String lang, String name) {
    if (_currentPage == 0) {
      final subject = setup.subject;
      return subject == null
          ? _t(
              lang,
              'Hi, I\'m $name! Which subject should we start with?',
              'សួស្តី ខ្ញុំឈ្មោះ $name! តើយើងគួរចាប់ផ្តើមពីមុខវិជ្ជាណា?',
            )
          : _t(
              lang,
              '${subject.title(lang)} is a great place to start.',
              'ចាប់ផ្តើមពី${subject.title(lang)}គឺល្អណាស់។',
            );
    }
    if (_currentPage == _questionPage) {
      final answer = setup.quizAnswer1Index;
      final subject = setup.subject;
      if (answer == null || subject == null) {
        return _t(
          lang,
          'Quick one to warm up. You\'ve got this!',
          'សំណួរខ្លីមួយដើម្បីកម្តៅខ្លួន។ អ្នកធ្វើបាន!',
        );
      }
      final question = OnboardingCuratedQuestions.forSubject(subject).first;
      return answer == question.correctIndex
          ? _t(
              lang,
              'Yes! That\'s your first win.',
              'ត្រូវហើយ! នេះជាជ័យជម្នះដំបូងរបស់អ្នក។',
            )
          : _t(
              lang,
              'Close! Now you know it for the exam.',
              'ជិតហើយ! ឥឡូវអ្នកដឹងសម្រាប់ការប្រឡងហើយ។',
            );
    }
    if (_currentPage == _provincePage) {
      return setup.provinceId == null
          ? _t(
              lang,
              'Where are you from? Your province is your squad.',
              'តើអ្នកមកពីខេត្តណា? ខេត្តរបស់អ្នកគឺជាក្រុមរបស់អ្នក។',
            )
          : _t(
              lang,
              'Welcome to the ${setup.provinceNameLatin} squad!',
              'សូមស្វាគមន៍មកកាន់ក្រុម${setup.provinceNameKhmer}!',
            );
    }
    return _t(
      lang,
      'Your ${setup.subject?.title(lang) ?? 'study'} roadmap is ready.',
      'ផ្លូវរៀន${setup.subject?.title(lang) ?? 'របស់អ្នក'}រួចរាល់ហើយ។',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      final hasSavedProvince =
          next is Authenticated && (next.user.provinceId?.isNotEmpty ?? false);
      if (hasSavedProvince && _currentPage == _provincePage) {
        _goTo(_payoffPage);
      }
    });
    final palette = context.riksa;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale =
        Localizations.maybeLocaleOf(context) ??
        ref.watch(localeProvider).locale;
    final lang = locale.languageCode;
    final setup = ref.watch(onboardingProvider);
    final auth = ref.watch(authProvider);
    final hasSavedProvince =
        auth is Authenticated && (auth.user.provinceId?.isNotEmpty ?? false);
    final profile = ref.watch(mascotProvider).profile;
    final species = profile?.species ?? MascotSpecies.crocodile;
    final name = profile?.name ?? MascotProfile.defaultName(species);
    final canContinue = _isStepComplete(setup);
    final notifier = ref.read(onboardingProvider.notifier);

    final isPayoffScreen = _currentPage == _payoffPage;
    final progressPage = hasSavedProvince && _currentPage > _questionPage
        ? _currentPage - 1
        : _currentPage;
    final pageCount = hasSavedProvince ? _totalPages - 1 : _totalPages;
    final l10n = AppLocalizations.of(context)!;

    final step = switch (_currentPage) {
      0 => _SubjectStep(
        selectedSubject: setup.subject,
        lang: lang,
        onSelect: (subject) {
          // A double tap must not advance twice and skip the first question.
          if (_currentPage != 0) return;
          notifier.setSubject(subject);
          _buddy.react(MascotMood.happy);
          unawaited(_next(setup, hasSavedProvince: hasSavedProvince));
        },
      ),
      _questionPage => _QuizStep(
        key: const ValueKey('first_question_step'),
        question: OnboardingCuratedQuestions.forSubject(
          setup.subject ?? OnboardingSubject.math,
        ).first,
        selectedAnswerIndex: setup.quizAnswer1Index,
        lang: lang,
        species: species,
        buddyName: name,
        onSelectAnswer: (index, isCorrect) {
          notifier.answerFirstQuestion(index);
          ref.playSound(
            isCorrect ? LearningSound.correct : LearningSound.wrong,
          );
          _buddy.react(isCorrect ? MascotMood.celebrate : MascotMood.sad);
        },
      ),
      _provincePage => _ProvinceStep(
        selectedProvinceId: setup.provinceId,
        selectedProvinceName: lang == 'km'
            ? setup.provinceNameKhmer
            : setup.provinceNameLatin,
        lang: lang,
        searchController: _provinceSearchController,
        query: _provinceQuery,
        onQueryChanged: (q) => setState(() => _provinceQuery = q.trim()),
        onSelect: (province) {
          notifier.setProvince(
            id: province.id,
            nameLatin: province.nameLatin,
            nameKhmer: province.nameKhmer,
          );
          _buddy.react(MascotMood.greeting);
        },
      ),
      _ => _PayoffStep(
        key: const ValueKey('payoff_step'),
        setup: setup,
        lang: lang,
        submitting: _submitting,
        onStart: () => _saveAndNavigate(_startLocation(setup)),
      ),
    };

    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: palette.canvas,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: MascotSceneBackdrop(
                species: species,
                party: isPayoffScreen,
              ),
            ),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                    child: _OnboardingHeader(
                      currentPage: progressPage,
                      totalPages: pageCount,
                      onBack: () => _back(hasSavedProvince: hasSavedProvince),
                    ),
                  ),
                ),
                _BuddyStrip(
                  species: species,
                  controller: _buddy,
                  line: _buddyLine(setup, lang, name),
                  hero: isPayoffScreen,
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: palette.canvas,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .12),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: duration,
                                    switchInCurve: RiksaMotion.standardCurve,
                                    switchOutCurve: Curves.easeIn,
                                    layoutBuilder: (current, previous) => Stack(
                                      alignment: Alignment.topCenter,
                                      // The step on its way out must not
                                      // take a second tap meant for the next.
                                      children: [
                                        for (final child in previous)
                                          IgnorePointer(child: child),
                                        ?current,
                                      ],
                                    ),
                                    transitionBuilder: (child, animation) {
                                      final incoming =
                                          child.key == ValueKey(_currentPage);
                                      final from = (incoming == _forward)
                                          ? .12
                                          : -.12;
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween(
                                            begin: Offset(from, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey(_currentPage),
                                      child: step,
                                    ),
                                  ),
                                ),
                                if (!isPayoffScreen) ...[
                                  const SizedBox(height: 14),
                                  FilledButton(
                                    key: const Key('onboarding_continue_btn'),
                                    onPressed: canContinue && !_submitting
                                        ? () => _next(
                                            setup,
                                            hasSavedProvince: hasSavedProvince,
                                          )
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isDark
                                          ? palette.brand
                                          : palette.brandStrong,
                                      foregroundColor: palette.onBrand,
                                      disabledBackgroundColor: palette.outline,
                                      disabledForegroundColor: palette.inkFaint,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      side: BorderSide.none,
                                      shape: const StadiumBorder(),
                                      minimumSize: const Size.fromHeight(52),
                                    ),
                                    child: _submitting
                                        ? SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              color: palette.onBrand,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _t(lang, 'Continue', 'បន្ត'),
                                                style:
                                                    RiksaTypography.bodyStyleFor(
                                                      _t(
                                                        lang,
                                                        'Continue',
                                                        'បន្ត',
                                                      ),
                                                      const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                ],
                                if (_currentPage == 0) ...[
                                  const SizedBox(height: 4),
                                  TextButton(
                                    key: const ValueKey(
                                      'onboarding_returning_account',
                                    ),
                                    onPressed: _submitting
                                        ? null
                                        : () => context.go(
                                            '/auth/login?onboardingReturning=true',
                                          ),
                                    child: Text(
                                      l10n.onboardingReturningAccount,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Back, a segmented progress track and the step count, on a frosted pill
/// so they read over the scene.
class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          style: IconButton.styleFrom(
            backgroundColor: palette.surface.withValues(alpha: .92),
            foregroundColor: palette.ink,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: .92),
              borderRadius: AppRadii.fullBorder,
            ),
            child: Row(
              children: [
                for (var i = 0; i < totalPages; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedContainer(
                      duration: duration,
                      curve: RiksaMotion.standardCurve,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i < currentPage
                            ? palette.brand
                            : i == currentPage
                            ? palette.jade
                            : palette.outline,
                        borderRadius: AppRadii.fullBorder,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Text(
                  '${currentPage + 1}/$totalPages',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The buddy on the grass, talking from a bubble beside it.
///
/// On the reward step it becomes a stage: the buddy grows, stands in the
/// middle and celebrates with the bubble over its head.
class _BuddyStrip extends StatelessWidget {
  const _BuddyStrip({
    required this.species,
    required this.controller,
    required this.line,
    this.hero = false,
  });

  final MascotSpecies species;
  final MascotController controller;
  final String line;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Shorter phones and an open keyboard squeeze the buddy, not the step.
    final keyboard = media.viewInsets.bottom > 0;
    final height = keyboard
        ? 0.0
        : hero
        ? (media.size.height * .26).clamp(168.0, 224.0)
        : (media.size.height * .2).clamp(118.0, 176.0);
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
    final Widget content;
    if (hero) {
      final buddy = ((height - 64) / MascotView.heightFactor).clamp(0.0, 170.0);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The buddy's box keeps headroom for hops; tuck the bubble into it.
          Transform.translate(
            offset: Offset(0, buddy * .2),
            child: MascotSpeechBubble(line: line, maxWidth: 320, style: style),
          ),
          MascotView(
            species: species,
            size: buddy,
            controller: controller,
            interactive: true,
          ),
        ],
      );
    } else {
      final buddy = height / MascotView.heightFactor;
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MascotView(
            species: species,
            size: buddy,
            controller: controller,
            interactive: true,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: buddy * .45),
              child: Align(
                alignment: Alignment.centerLeft,
                child: MascotSpeechBubble(
                  line: line,
                  tail: SpeechTail.left,
                  maxWidth: 400,
                  textAlign: TextAlign.start,
                  style: style,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return AnimatedContainer(
      duration: RiksaMotion.resolve(context, RiksaMotion.emphasis),
      curve: RiksaMotion.standardCurve,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: RiksaTypography.titleStyleFor(
            title,
            theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
            khmerHeight: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: RiksaTypography.bodyStyleFor(
            subtitle,
            theme.textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// A check that pops in when its card is chosen.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);
    return AnimatedContainer(
      duration: duration,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : Colors.transparent,
        border: Border.all(
          color: selected ? color : palette.inkFaint,
          width: selected ? 0 : 1.6,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

/// A tappable card that lifts and takes an accent border when chosen.
class _ChoiceSurface extends StatelessWidget {
  const _ChoiceSurface({
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(14),
    this.enabled = true,
  });

  final bool selected;
  final Color accent;
  final Color? tint;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);
    return Semantics(
      button: true,
      selected: selected,
      child: RiksaTapFeedback(
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.largeBorder,
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: AnimatedContainer(
              duration: duration,
              curve: RiksaMotion.standardCurve,
              padding: padding,
              decoration: BoxDecoration(
                color: selected && tint != null ? tint : palette.surface,
                borderRadius: AppRadii.largeBorder,
                border: Border.all(
                  color: selected ? accent : palette.outline,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: .14),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selectedGoal,
    required this.lang,
    required this.onSelect,
  });

  final OnboardingGoal? selectedGoal;
  final String lang;
  final ValueChanged<OnboardingGoal> onSelect;

  static (Color, Color) _colors(OnboardingGoal goal, RiksaPalette palette) =>
      switch (goal) {
        OnboardingGoal.bacII => (
          AppColors.tileYellow,
          AppColors.achievementSaffron,
        ),
        OnboardingGoal.stemClass => (AppColors.tileLavender, palette.brand),
        OnboardingGoal.curiosity => (AppColors.tileMint, AppColors.brandJade),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    return ListView(
      children: [
        _StepTitle(
          title: _t(
            lang,
            'What is your learning goal?',
            'តើអ្នកចង់សម្រេចគោលដៅអ្វី?',
          ),
          subtitle: _t(
            lang,
            'We will personalize your daily study path to match your target.',
            'យើងនឹងរៀបចំដំណើរការសិក្សាឱ្យស័ក្តិសមបំផុតសម្រាប់អ្នក',
          ),
        ),
        for (final goal in OnboardingGoal.values) ...[
          Builder(
            builder: (context) {
              final selected = selectedGoal == goal;
              final (soft, accent) = _colors(goal, palette);
              return _ChoiceSurface(
                selected: selected,
                accent: accent,
                onTap: () => onSelect(goal),
                child: Row(
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.08 : 1,
                      duration: duration,
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: AppRadii.mediumBorder,
                        ),
                        child: Icon(goal.icon, color: accent, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title(lang),
                            style: RiksaTypography.titleStyleFor(
                              goal.title(lang),
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            goal.subtitle(lang),
                            style: RiksaTypography.bodyStyleFor(
                              goal.subtitle(lang),
                              theme.textTheme.bodySmall?.copyWith(
                                color: palette.inkMuted,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CheckBadge(selected: selected, color: accent),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SubjectStep extends StatelessWidget {
  const _SubjectStep({
    required this.selectedSubject,
    required this.lang,
    required this.onSelect,
  });

  final OnboardingSubject? selectedSubject;
  final String lang;
  final ValueChanged<OnboardingSubject> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    return ListView(
      children: [
        _StepTitle(
          title: _t(
            lang,
            'Pick your starting subject',
            'ជ្រើសរើសមុខវិជ្ជាចាប់ផ្តើម',
          ),
          subtitle: _t(
            lang,
            'You can switch or explore other subjects at any time.',
            'អ្នកអាចរៀន ឬផ្លាស់ប្តូរមុខវិជ្ជាផ្សេងទៀតបានគ្រប់ពេល',
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .92,
          children: [
            for (final subject in OnboardingSubject.values)
              Builder(
                builder: (context) {
                  final selected = selectedSubject == subject;
                  final accent = subject.accentColor(context);
                  final soft = subject.softColor(context);
                  return _ChoiceSurface(
                    selected: selected,
                    accent: accent,
                    tint: Color.alphaBlend(
                      soft.withValues(alpha: .45),
                      palette.surface,
                    ),
                    onTap: () => onSelect(subject),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedRotation(
                              turns: selected ? -.03 : 0,
                              duration: duration,
                              child: AnimatedScale(
                                scale: selected ? 1.1 : 1,
                                duration: duration,
                                curve: Curves.easeOutBack,
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: soft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    subject.icon,
                                    color: accent,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            _CheckBadge(selected: selected, color: accent),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          subject.title(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RiksaTypography.titleStyleFor(
                            subject.title(lang),
                            theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subject.subtitle(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RiksaTypography.bodyStyleFor(
                            subject.subtitle(lang),
                            theme.textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// The province step, framed as joining a squad: learners from the same
/// province earn points together on the national leaderboard.
// ignore: unused_element
class _ProvinceStep extends StatelessWidget {
  const _ProvinceStep({
    required this.selectedProvinceId,
    required this.selectedProvinceName,
    required this.lang,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onSelect,
  });

  final String? selectedProvinceId;
  final String? selectedProvinceName;
  final String lang;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ProvinceOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;

    return Consumer(
      builder: (context, ref, child) {
        final provincesAsync = ref.watch(provinceOptionsProvider);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _StepTitle(
                title: _t(
                  lang,
                  'Which province are you representing?',
                  'តើអ្នករស់នៅខេត្ត-រាជធានីណា?',
                ),
                subtitle: _t(
                  lang,
                  'Join your province squad. Every lesson you finish helps it climb the national leaderboard.',
                  'ចូលរួមក្រុមខេត្តរបស់អ្នក។ មេរៀននីមួយៗដែលអ្នករៀនចប់ជួយខេត្តរបស់អ្នកឡើងលើតារាងចំណាត់ថ្នាក់ជាតិ។',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: _sizeDuration(context),
                curve: RiksaMotion.standardCurve,
                alignment: Alignment.topCenter,
                child: selectedProvinceName == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _SquadCard(
                          name: selectedProvinceName!,
                          lang: lang,
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: RiksaSearchField(
                key: const Key('onboarding_province_search'),
                controller: searchController,
                hintText: _t(
                  lang,
                  'Search province...',
                  'ស្វែងរកខេត្ត-រាជធានី...',
                ),
                onChanged: onQueryChanged,
                trailing: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            provincesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _t(
                      lang,
                      'Failed to load provinces',
                      'មិនអាចទាញយកទិន្នន័យខេត្តបានទេ',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.inkMuted),
                  ),
                ),
              ),
              data: (provinces) {
                final q = query.toLowerCase();
                final filtered = provinces
                    .where(
                      (p) =>
                          q.isEmpty ||
                          p.nameLatin.toLowerCase().contains(q) ||
                          p.nameKhmer.contains(q),
                    )
                    .toList();
                return SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final province in filtered)
                        _ProvinceChip(
                          label: lang == 'km'
                              ? province.nameKhmer
                              : province.nameLatin,
                          selected: selectedProvinceId == province.id,
                          onTap: () => onSelect(province),
                        ),
                    ],
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: theme.textTheme.bodySmall?.fontSize),
            ),
          ],
        );
      },
    );
  }
}

class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.name, required this.lang});

  final String name;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final title = _t(lang, 'Representing $name!', 'អ្នកតំណាងខេត្ត $name!');
    final body = _t(
      lang,
      'Your XP now counts for your whole squad.',
      'XP របស់អ្នកនឹងរាប់បញ្ចូលសម្រាប់ក្រុមទាំងមូល។',
    );
    return TweenAnimationBuilder<double>(
      key: ValueKey(name),
      tween: Tween(
        begin: MediaQuery.disableAnimationsOf(context) ? 1 : .9,
        end: 1,
      ),
      duration: RiksaMotion.resolve(context, RiksaMotion.standard),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.brandStrong, palette.brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadii.largeBorder,
          boxShadow: [
            BoxShadow(
              color: palette.brand.withValues(alpha: .25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: RiksaTypography.titleStyleFor(
                      title,
                      theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: RiksaTypography.bodyStyleFor(
                      body,
                      theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: .85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.emoji_events_rounded, color: palette.reward, size: 26),
          ],
        ),
      ),
    );
  }
}

class _ProvinceChip extends StatelessWidget {
  const _ProvinceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.fullBorder,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: duration,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? palette.brand : palette.surface,
              borderRadius: AppRadii.fullBorder,
              border: Border.all(
                color: selected ? palette.brand : palette.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: _sizeDuration(context),
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: palette.onBrand,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Text(
                  label,
                  style: RiksaTypography.bodyStyleFor(
                    label,
                    TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? palette.onBrand : palette.ink,
                    ),
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

// ignore: unused_element
class _PaceStep extends StatelessWidget {
  const _PaceStep({
    required this.selectedPace,
    required this.lang,
    required this.onSelect,
  });

  final OnboardingPace? selectedPace;
  final String lang;
  final ValueChanged<OnboardingPace> onSelect;

  static IconData _icon(OnboardingPace pace) => switch (pace) {
    OnboardingPace.casual => Icons.local_cafe_rounded,
    OnboardingPace.regular => Icons.bolt_rounded,
    OnboardingPace.serious => Icons.rocket_launch_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);

    return ListView(
      children: [
        _StepTitle(
          title: _t(
            lang,
            'Set your daily study pace',
            'កំណត់គោលដៅសិក្សាប្រចាំថ្ងៃ',
          ),
          subtitle: _t(
            lang,
            'Consistent daily practice creates long-term mastery.',
            'ការអនុវត្តជារៀងរាល់ថ្ងៃជួយឱ្យអ្នកចងចាំ និងយល់កាន់តែច្បាស់',
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final pace in OnboardingPace.values) ...[
                if (pace != OnboardingPace.values.first)
                  const SizedBox(width: 10),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final selected = selectedPace == pace;
                      final ink = selected ? palette.brand : palette.ink;
                      return _ChoiceSurface(
                        selected: selected,
                        accent: palette.brand,
                        tint: palette.brandSoft,
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                        onTap: () => onSelect(pace),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 22,
                              child: pace.isRecommended
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.reward,
                                        borderRadius: AppRadii.fullBorder,
                                      ),
                                      child: Text(
                                        _t(lang, 'Popular', 'ណែនាំ'),
                                        style: RiksaTypography.bodyStyleFor(
                                          _t(lang, 'Popular', 'ណែនាំ'),
                                          TextStyle(
                                            color: palette.onAccent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            AnimatedScale(
                              scale: selected ? 1.15 : 1,
                              duration: duration,
                              curve: Curves.easeOutBack,
                              child: Icon(_icon(pace), color: ink, size: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${pace.minutes}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: ink,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              _t(lang, 'min / day', 'នាទី / ថ្ងៃ'),
                              style: RiksaTypography.bodyStyleFor(
                                _t(lang, 'min / day', 'នាទី / ថ្ងៃ'),
                                theme.textTheme.labelSmall?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pace.title(lang),
                              textAlign: TextAlign.center,
                              style: RiksaTypography.titleStyleFor(
                                pace.title(lang),
                                theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: duration,
          child: selectedPace == null
              ? const SizedBox(key: ValueKey('no_pace'), width: double.infinity)
              : _WeekPreview(
                  key: ValueKey(selectedPace),
                  pace: selectedPace!,
                  lang: lang,
                ),
        ),
      ],
    );
  }
}

/// What the chosen pace adds up to: a week of lit streak flames, the minutes
/// it totals and the XP each day earns.
class _WeekPreview extends StatelessWidget {
  const _WeekPreview({super.key, required this.pace, required this.lang});

  final OnboardingPace pace;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final days = MaterialLocalizations.of(context).narrowWeekdays;
    final weekly = pace.minutes * 7;
    final summary = _t(
      lang,
      '$weekly min a week · +${pace.xpReward} XP a day',
      '$weekly នាទី ក្នុងមួយសប្តាហ៍ · +${pace.xpReward} XP ក្នុងមួយថ្ងៃ',
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.largeBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pace.subtitle(lang),
            style: RiksaTypography.bodyStyleFor(
              pace.subtitle(lang),
              theme.textTheme.bodySmall?.copyWith(color: palette.inkMuted),
            ),
          ),
          const SizedBox(height: 12),
          // The flames light up one after another across the week.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduce ? 7 : 0, end: 7),
            duration: const Duration(milliseconds: 900),
            builder: (context, lit, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < lit
                              ? AppColors.tilePeach
                              : palette.outline.withValues(alpha: .5),
                        ),
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 20,
                          color: i < lit
                              ? const Color(0xFFFF6B2C)
                              : palette.inkFaint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days[(i + 1) % 7],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: RiksaTypography.bodyStyleFor(
              summary,
              theme.textTheme.labelLarge?.copyWith(
                color: palette.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A warm-up question. The buddy cheers or consoles from the top; the
/// explanation lands here, from the buddy's face, under the answers.
// ignore: unused_element
class _QuizStep extends StatelessWidget {
  const _QuizStep({
    super.key,
    required this.question,
    required this.selectedAnswerIndex,
    required this.lang,
    required this.species,
    required this.buddyName,
    required this.onSelectAnswer,
  });

  final OnboardingQuizQuestion question;
  final int? selectedAnswerIndex;
  final String lang;
  final MascotSpecies species;
  final String buddyName;
  final void Function(int index, bool isCorrect) onSelectAnswer;

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final options = question.options(lang);
    final answered = selectedAnswerIndex != null;
    final isCorrect = selectedAnswerIndex == question.correctIndex;
    final subject = question.subject;
    final challenge =
        '${subject.title(lang)} · ${_t(lang, 'Your first question', 'សំណួរដំបូងរបស់អ្នក')}';

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _Pill(
                  icon: subject.icon,
                  label: challenge,
                  background: subject.softColor(context),
                  foreground: subject.accentColor(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _XpBadge(earned: answered && isCorrect),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.brandSoft,
            borderRadius: AppRadii.largeBorder,
          ),
          child: Text(
            question.question(lang),
            style: RiksaTypography.titleStyleFor(
              question.question(lang),
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.ink,
                height: 1.35,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < options.length; i++) ...[
          _buildOptionCard(
            context: context,
            index: i,
            optionText: options[i],
            isSelected: selectedAnswerIndex == i,
            isTargetCorrect: i == question.correctIndex,
            answered: answered,
          ),
          const SizedBox(height: 10),
        ],
        AnimatedSwitcher(
          duration: RiksaMotion.resolve(context, RiksaMotion.standard),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          ),
          child: answered
              ? Padding(
                  key: const ValueKey('feedback'),
                  padding: const EdgeInsets.only(top: 4),
                  child: _RevealOnAppear(
                    child: _BuddyFeedback(
                      species: species,
                      buddyName: buddyName,
                      isCorrect: isCorrect,
                      message: isCorrect
                          ? question.kruAiSuccess(lang)
                          : question.kruAiHint(lang),
                      lang: lang,
                    ),
                  ),
                )
              : const SizedBox(
                  key: ValueKey('waiting'),
                  width: double.infinity,
                ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required int index,
    required String optionText,
    required bool isSelected,
    required bool isTargetCorrect,
    required bool answered,
  }) {
    final palette = context.riksa;
    final theme = Theme.of(context);

    Color accent = palette.brand;
    Color? tint;
    Color letterBg = palette.outline.withValues(alpha: .5);
    Color letterColor = palette.ink;
    Widget? trailingIcon;

    if (answered) {
      if (isSelected && isTargetCorrect) {
        accent = palette.semantic.success;
        tint = palette.semantic.successContainer;
        letterBg = palette.semantic.success;
        letterColor = palette.semantic.onSuccess;
        trailingIcon = Icon(
          Icons.check_circle_rounded,
          color: palette.semantic.success,
          size: 24,
        );
      } else if (isSelected && !isTargetCorrect) {
        accent = palette.semantic.error;
        tint = palette.semantic.errorContainer;
        letterBg = palette.semantic.error;
        letterColor = palette.semantic.onError;
        trailingIcon = Icon(
          Icons.cancel_rounded,
          color: palette.semantic.error,
          size: 24,
        );
      } else if (isTargetCorrect) {
        trailingIcon = Icon(
          Icons.check_circle_outline_rounded,
          color: palette.semantic.success,
          size: 22,
        );
      }
    }

    // A wrong pick gives a short shake.
    final shake = answered && isSelected && !isTargetCorrect;
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0,
        end: shake && !MediaQuery.disableAnimationsOf(context) ? 1 : 0,
      ),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(8 * (1 - t) * math.sin(t * math.pi * 6), 0),
        child: child,
      ),
      child: _ChoiceSurface(
        selected: isSelected,
        accent: accent,
        tint: tint,
        enabled: !answered,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: answered
            ? null
            : () => onSelectAnswer(index, index == question.correctIndex),
        child: Row(
          children: [
            AnimatedContainer(
              duration: RiksaMotion.resolve(context, RiksaMotion.standard),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: AppRadii.mediumBorder,
              ),
              child: Center(
                child: Text(
                  _letters[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: letterColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                optionText,
                style: RiksaTypography.bodyStyleFor(
                  optionText,
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: palette.ink,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            ?trailingIcon,
          ],
        ),
      ),
    );
  }
}

/// Scrolls its child into view once it has grown in, so the buddy's
/// explanation is not left below the fold on a phone.
class _RevealOnAppear extends StatefulWidget {
  const _RevealOnAppear({required this.child});

  final Widget child;

  @override
  State<_RevealOnAppear> createState() => _RevealOnAppearState();
}

class _RevealOnAppearState extends State<_RevealOnAppear> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  Future<void> _reveal() async {
    // The card grows in, so wait for the list's extent to settle; revealing it
    // any earlier would scroll to a card that is still too short.
    var extent = -1.0;
    for (var frame = 0; frame < 60; frame++) {
      if (!mounted) return;
      final position = Scrollable.maybeOf(context)?.position;
      if (position == null || !position.hasContentDimensions) return;
      if (position.maxScrollExtent == extent && extent >= 0) break;
      extent = position.maxScrollExtent;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 1,
      duration: RiksaMotion.resolve(context, RiksaMotion.standard),
      curve: RiksaMotion.standardCurve,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RiksaTypography.bodyStyleFor(
                label,
                TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The question's reward. Once it is won, a copy floats up off the badge.
class _XpBadge extends StatelessWidget {
  const _XpBadge({required this.earned});

  final bool earned;

  @override
  Widget build(BuildContext context) {
    const label = '+10 XP';
    final foreground = earned ? context.riksa.onAccent : context.riksa.reward;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: earned ? context.riksa.reward : context.riksa.rewardSoft,
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
    if (!earned || MediaQuery.disableAnimationsOf(context)) return badge;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        badge,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOut,
                builder: (context, t, child) => Opacity(
                  opacity: (1 - t).clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, -36 * t),
                    child: Transform.scale(scale: 1 + .2 * t, child: child),
                  ),
                ),
                child: badge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The buddy's explanation after an answer, from its matching face.
class _BuddyFeedback extends StatelessWidget {
  const _BuddyFeedback({
    required this.species,
    required this.buddyName,
    required this.isCorrect,
    required this.message,
    required this.lang,
  });

  final MascotSpecies species;
  final String buddyName;
  final bool isCorrect;
  final String message;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final theme = Theme.of(context);
    final tag = isCorrect
        ? _t(lang, 'Brilliant!', 'ពូកែណាស់!')
        : _t(lang, 'Hint', 'ការណែនាំ');
    final accent = isCorrect ? AppColors.brandJadeStrong : palette.brand;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.tileMint : palette.surfaceRaised,
        borderRadius: AppRadii.extraLargeBorder,
        border: Border.all(
          color: isCorrect
              ? AppColors.brandJade.withValues(alpha: .35)
              : palette.outline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(3),
            child: MascotFaceView(
              species: species,
              face: isCorrect ? MascotFace.proud : MascotFace.oops,
              size: 42,
              loops: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      buddyName,
                      style: RiksaTypography.titleStyleFor(
                        buddyName,
                        theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .12),
                        borderRadius: AppRadii.fullBorder,
                      ),
                      child: Text(
                        tag,
                        style: RiksaTypography.bodyStyleFor(
                          tag,
                          TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: RiksaTypography.bodyStyleFor(
                    message,
                    theme.textTheme.bodyMedium?.copyWith(
                      color: isCorrect
                          ? AppColors.brandJadeStrong
                          : palette.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirms the selected learning path before opening the curriculum.
class _PayoffStep extends StatelessWidget {
  const _PayoffStep({
    super.key,
    required this.setup,
    required this.lang,
    required this.submitting,
    required this.onStart,
  });

  final OnboardingSetupData setup;
  final String lang;
  final bool submitting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final subject =
        setup.subject?.title(lang) ??
        _t(lang, 'your subject', 'មុខវិជ្ជារបស់អ្នក');
    final title = _t(
      lang,
      'Your $subject roadmap is ready',
      'ផ្លូវរៀន$subject របស់អ្នករួចរាល់ហើយ',
    );
    final body = _t(
      lang,
      'Choose a lesson and start learning at your own pace.',
      'ជ្រើសរើសមេរៀនមួយ ហើយចាប់ផ្តើមរៀនតាមល្បឿនរបស់អ្នក។',
    );
    final startLabel = _t(lang, 'Start learning', 'ចាប់ផ្តើមរៀន');

    return ListView(
      key: const ValueKey('onboarding-roadmap-ready'),
      children: [
        const SizedBox(height: 16),
        Icon(Icons.route_rounded, size: 56, color: palette.brand),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: RiksaTypography.titleStyleFor(
            title,
            theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.ink,
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
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('onboarding_start_learning'),
          onPressed: submitting ? null : onStart,
          style: FilledButton.styleFrom(
            backgroundColor: palette.brandStrong,
            foregroundColor: palette.onBrand,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          child: submitting
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    color: palette.onBrand,
                    strokeWidth: 2,
                  ),
                )
              : Text(startLabel),
        ),
      ],
    );
  }
}
