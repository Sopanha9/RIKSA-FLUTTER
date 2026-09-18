import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/telegram_logo.dart';
import '../data/auth_models.dart';
import '../data/onboarding_models.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

/// Phase 1, 2 & 3 of RIKSA's interactive progressive onboarding.
///
/// Features a multi-step setup & challenge flow:
/// 1. Academic Target Goal
/// 2. Starting Subject
/// 3. Province Selection & Leaderboard Pride
/// 4. Daily Study Pace Commitment
/// 5. Challenge Question 1 + Kru AI Cameo
/// 6. Challenge Question 2 + Kru AI Cameo
/// 7. Streak & XP Payoff Screen + Frictionless 1-Tap Conversion
class InteractiveOnboardingScreen extends ConsumerStatefulWidget {
  const InteractiveOnboardingScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  ConsumerState<InteractiveOnboardingScreen> createState() =>
      _InteractiveOnboardingScreenState();
}

class _InteractiveOnboardingScreenState
    extends ConsumerState<InteractiveOnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _provinceSearchController =
      TextEditingController();

  int _currentPage = 0;
  static const int _totalPages = 7;
  String _provinceQuery = '';
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _provinceSearchController.dispose();
    super.dispose();
  }

  bool _isStepComplete(OnboardingSetupData data) {
    return switch (_currentPage) {
      0 => data.goal != null,
      1 => data.subject != null,
      2 => data.provinceId != null,
      3 => data.pace != null,
      4 => data.quizAnswer1Index != null,
      5 => data.quizAnswer2Index != null,
      6 => true,
      _ => false,
    };
  }

  Future<void> _next(OnboardingSetupData data) async {
    if (_submitting) return;

    if (_currentPage < _totalPages - 1) {
      if (MediaQuery.of(context).disableAnimations) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        await _pageController.nextPage(
          duration: RiksaMotion.standard,
          curve: RiksaMotion.standardCurve,
        );
      }
      setState(() => _currentPage++);
      return;
    }

    // Step 7 (Payoff): proceed with primary save
    await _saveAndNavigate('/auth/telegram');
  }

  Future<void> _back() async {
    if (_submitting) return;
    if (_currentPage > 0) {
      if (MediaQuery.of(context).disableAnimations) {
        _pageController.jumpToPage(_currentPage - 1);
      } else {
        await _pageController.previousPage(
          duration: RiksaMotion.standard,
          curve: RiksaMotion.standardCurve,
        );
      }
      setState(() => _currentPage--);
    } else {
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) {
        router.pop();
      }
    }
  }

  Future<void> _saveAndNavigate(String route) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ref.read(onboardingProvider.notifier).commitSetup();
    await ref.read(localeProvider.notifier).completeIntro();

    if (!mounted) return;
    if (widget.onComplete case final callback?) {
      setState(() => _submitting = false);
      callback();
      return;
    }

    context.go(route);
  }

  Future<void> _handleGoogleAuth() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ref.read(onboardingProvider.notifier).commitSetup();
    await ref.read(localeProvider.notifier).completeIntro();

    try {
      await ref.read(googleAuthClientProvider).authenticate();
    } catch (_) {
      if (mounted) {
        context.go('/auth/login');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _buttonLabel(String lang) {
    return switch (_currentPage) {
      3 => lang == 'km' ? 'ចាប់ផ្តើមការសាកល្បង' : 'Start Challenge',
      4 => lang == 'km' ? 'សំណួរបន្ទាប់' : 'Next Challenge',
      5 => lang == 'km' ? 'ទទួលយករង្វាន់' : 'Claim Reward',
      _ => lang == 'km' ? 'បន្ត' : 'Continue',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final locale = Localizations.maybeLocaleOf(context) ??
        ref.watch(localeProvider).locale;
    final lang = locale.languageCode;
    final setup = ref.watch(onboardingProvider);
    final canContinue = _isStepComplete(setup);

    final subject = setup.subject ?? OnboardingSubject.math;
    final questions = OnboardingCuratedQuestions.forSubject(subject);
    final isPayoffScreen = _currentPage == 6;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OnboardingHeader(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    onBack: _back,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _GoalStep(
                          selectedGoal: setup.goal,
                          lang: lang,
                          onSelect: (goal) {
                            ref
                                .read(onboardingProvider.notifier)
                                .setGoal(goal);
                          },
                        ),
                        _SubjectStep(
                          selectedSubject: setup.subject,
                          lang: lang,
                          onSelect: (subject) {
                            ref
                                .read(onboardingProvider.notifier)
                                .setSubject(subject);
                          },
                        ),
                        _ProvinceStep(
                          selectedProvinceId: setup.provinceId,
                          selectedProvinceName:
                              lang == 'km'
                                  ? setup.provinceNameKhmer
                                  : setup.provinceNameLatin,
                          lang: lang,
                          searchController: _provinceSearchController,
                          query: _provinceQuery,
                          onQueryChanged:
                              (q) => setState(() => _provinceQuery = q.trim()),
                          onSelect: (province) {
                            ref
                                .read(onboardingProvider.notifier)
                                .setProvince(
                                  id: province.id,
                                  nameLatin: province.nameLatin,
                                  nameKhmer: province.nameKhmer,
                                );
                          },
                        ),
                        _PaceStep(
                          selectedPace: setup.pace,
                          lang: lang,
                          onSelect: (pace) {
                            ref
                                .read(onboardingProvider.notifier)
                                .setPace(pace);
                          },
                        ),
                        _QuizStep(
                          key: const ValueKey('quiz_step_1'),
                          questionNumber: 1,
                          totalQuestions: 2,
                          question: questions[0],
                          selectedAnswerIndex: setup.quizAnswer1Index,
                          lang: lang,
                          onSelectAnswer: (idx, isCorrect) {
                            ref
                                .read(onboardingProvider.notifier)
                                .setQuizAnswer1(idx, isCorrect);
                          },
                        ),
                        _QuizStep(
                          key: const ValueKey('quiz_step_2'),
                          questionNumber: 2,
                          totalQuestions: 2,
                          question: questions[1],
                          selectedAnswerIndex: setup.quizAnswer2Index,
                          lang: lang,
                          onSelectAnswer: (idx, isCorrect) {
                            ref
                                .read(onboardingProvider.notifier)
                                .setQuizAnswer2(idx, isCorrect);
                          },
                        ),
                        _PayoffStep(
                          key: const ValueKey('payoff_step'),
                          setup: setup,
                          lang: lang,
                          submitting: _submitting,
                          onSaveTelegram: () => _saveAndNavigate('/auth/telegram'),
                          onSaveGoogle: _handleGoogleAuth,
                          onSaveEmail: () => _saveAndNavigate('/auth/login'),
                          onLogin: () => _saveAndNavigate('/auth/login'),
                        ),
                      ],
                    ),
                  ),
                  if (!isPayoffScreen) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('onboarding_continue_btn'),
                      onPressed: canContinue && !_submitting
                          ? () => _next(setup)
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.largeBorder,
                        ),
                      ),
                      child: _submitting
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                color: palette.canvas,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _buttonLabel(lang),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final progress = (currentPage + 1) / totalPages;

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: palette.ink,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadii.fullBorder,
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: palette.outline),
                  AnimatedFractionallySizedBox(
                    duration: RiksaMotion.standard,
                    curve: RiksaMotion.standardCurve,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.brand,
                        borderRadius: AppRadii.fullBorder,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '${currentPage + 1}/$totalPages',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: palette.inkMuted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selectedGoal,
    required this.lang,
    required this.onSelect,
  });

  final OnboardingGoal? selectedGoal;
  final String lang;
  final ValueChanged<OnboardingGoal> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lang == 'km'
              ? 'តើអ្នកចង់សម្រេចគោលដៅអ្វី?'
              : 'What is your learning goal?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lang == 'km'
              ? 'យើងនឹងរៀបចំដំណើរការសិក្សាឱ្យស័ក្តិសមបំផុតសម្រាប់អ្នក'
              : 'We will personalize your daily study path to match your target.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.inkMuted,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: OnboardingGoal.values.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final goal = OnboardingGoal.values[index];
              final isSelected = selectedGoal == goal;

              return RiksaTapFeedback(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadii.largeBorder,
                    onTap: () => onSelect(goal),
                    child: AnimatedContainer(
                      duration: RiksaMotion.standard,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: AppRadii.largeBorder,
                        border: Border.all(
                          color: isSelected ? palette.brand : palette.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: palette.brand.withValues(alpha: .14),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.brand.withValues(alpha: .12)
                                  : palette.outline.withValues(alpha: .5),
                              borderRadius: AppRadii.mediumBorder,
                            ),
                            child: Icon(
                              goal.icon,
                              color: isSelected ? palette.brand : palette.ink,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title(lang),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.subtitle(lang),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.inkMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? palette.brand : palette.inkFaint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lang == 'km'
              ? 'ជ្រើសរើសមុខវិជ្ជាចាប់ផ្តើម'
              : 'Pick your starting subject',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lang == 'km'
              ? 'អ្នកអាចរៀន ឬផ្លាស់ប្តូរមុខវិជ្ជាផ្សេងទៀតបានគ្រប់ពេល'
              : 'You can switch or explore other subjects at any time.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.inkMuted,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: OnboardingSubject.values.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = OnboardingSubject.values[index];
              final isSelected = selectedSubject == subject;
              final accent = subject.accentColor(context);

              return RiksaTapFeedback(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadii.largeBorder,
                    onTap: () => onSelect(subject),
                    child: AnimatedContainer(
                      duration: RiksaMotion.standard,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: AppRadii.largeBorder,
                        border: Border.all(
                          color: isSelected ? accent : palette.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: .15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: subject.softColor(context),
                              borderRadius: AppRadii.mediumBorder,
                            ),
                            child: Icon(subject.icon, color: accent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject.title(lang),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subject.subtitle(lang),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.inkMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: isSelected ? accent : palette.inkFaint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lang == 'km'
                  ? 'តើអ្នករស់នៅខេត្ត-រាជធានីណា?'
                  : 'Which province are you representing?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lang == 'km'
                  ? 'ពិន្ទុសិក្សារបស់អ្នកនឹងជួយខេត្តរបស់អ្នកនៅលើតារាងពិន្ទុជាតិ!'
                  : 'Your learning XP will help your home province climb the national leaderboard!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.inkMuted,
              ),
            ),
            if (selectedProvinceName != null) ...[
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: RiksaMotion.standard,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.brand.withValues(alpha: .08),
                  borderRadius: AppRadii.largeBorder,
                  border: Border.all(
                    color: palette.brand.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🇰🇭', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'km'
                                ? 'អ្នកតំណាងខេត្ត $selectedProvinceName!'
                                : 'Representing $selectedProvinceName!',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.brand,
                            ),
                          ),
                          Text(
                            lang == 'km'
                                ? 'ត្រៀមខ្លួនរួមចំណែកពិន្ទុលើតារាងជាតិ'
                                : 'Ready to contribute XP to the national leaderboard',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.achievementSaffron,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            RiksaSearchField(
              key: const Key('onboarding_province_search'),
              controller: searchController,
              hintText:
                  lang == 'km'
                      ? 'ស្វែងរកខេត្ត-រាជធានី...'
                      : 'Search province...',
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
            const SizedBox(height: 12),
            Expanded(
              child: provincesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Center(
                  child: Text(
                    lang == 'km'
                        ? 'មិនអាចទាញយកទិន្នន័យខេត្តបានទេ'
                        : 'Failed to load provinces',
                    style: TextStyle(color: palette.inkMuted),
                  ),
                ),
                data: (provinces) {
                  final filtered = provinces.where((p) {
                    final q = query.toLowerCase();
                    return q.isEmpty ||
                        p.nameLatin.toLowerCase().contains(q) ||
                        p.nameKhmer.contains(q);
                  }).toList();

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final province = filtered[index];
                      final isSelected = selectedProvinceId == province.id;

                      return RiksaTapFeedback(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppRadii.largeBorder,
                            onTap: () => onSelect(province),
                            child: AnimatedContainer(
                              duration: RiksaMotion.standard,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surface,
                                borderRadius: AppRadii.largeBorder,
                                border: Border.all(
                                  color: isSelected
                                      ? palette.brand
                                      : palette.outline,
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lang == 'km'
                                          ? province.nameKhmer
                                          : province.nameLatin,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? palette.brand
                                                : palette.ink,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    lang == 'km'
                                        ? province.nameLatin
                                        : province.nameKhmer,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: palette.inkFaint,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? palette.brand
                                        : palette.inkFaint,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaceStep extends StatelessWidget {
  const _PaceStep({
    required this.selectedPace,
    required this.lang,
    required this.onSelect,
  });

  final OnboardingPace? selectedPace;
  final String lang;
  final ValueChanged<OnboardingPace> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lang == 'km'
              ? 'កំណត់គោលដៅសិក្សាប្រចាំថ្ងៃ'
              : 'Set your daily study pace',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lang == 'km'
              ? 'ការអនុវត្តជារៀងរាល់ថ្ងៃជួយឱ្យអ្នកចងចាំ និងយល់កាន់តែច្បាស់'
              : 'Consistent daily practice creates long-term mastery.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.inkMuted,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: OnboardingPace.values.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final pace = OnboardingPace.values[index];
              final isSelected = selectedPace == pace;

              return RiksaTapFeedback(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadii.largeBorder,
                    onTap: () => onSelect(pace),
                    child: AnimatedContainer(
                      duration: RiksaMotion.standard,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: AppRadii.largeBorder,
                        border: Border.all(
                          color: isSelected ? palette.brand : palette.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: palette.brand.withValues(alpha: .14),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.brand.withValues(alpha: .12)
                                  : palette.outline.withValues(alpha: .4),
                              borderRadius: AppRadii.mediumBorder,
                            ),
                            child: Center(
                              child: Text(
                                '${pace.minutes}m',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isSelected
                                      ? palette.brand
                                      : palette.ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      pace.title(lang),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: palette.ink,
                                      ),
                                    ),
                                    if (pace.isRecommended)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.lime,
                                          borderRadius: AppRadii.fullBorder,
                                        ),
                                        child: Text(
                                          lang == 'km' ? 'ណែនាំ' : 'Popular',
                                          style: const TextStyle(
                                            color: AppColors.limeInk,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pace.subtitle(lang),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.inkMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.brand.withValues(alpha: .12)
                                  : palette.outline.withValues(alpha: .4),
                              borderRadius: AppRadii.fullBorder,
                            ),
                            child: Text(
                              '+${pace.xpReward} XP',
                              style: TextStyle(
                                color: isSelected
                                    ? palette.brand
                                    : palette.inkMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The interactive challenge screen with instant Kru AI feedback cameo.
class _QuizStep extends StatelessWidget {
  const _QuizStep({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    required this.selectedAnswerIndex,
    required this.lang,
    required this.onSelectAnswer,
  });

  final int questionNumber;
  final int totalQuestions;
  final OnboardingQuizQuestion question;
  final int? selectedAnswerIndex;
  final String lang;
  final void Function(int index, bool isCorrect) onSelectAnswer;

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final options = question.options(lang);
    final answered = selectedAnswerIndex != null;
    final isCorrect = selectedAnswerIndex == question.correctIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: palette.brand.withValues(alpha: .1),
                borderRadius: AppRadii.fullBorder,
              ),
              child: Text(
                lang == 'km'
                    ? 'ការសាកល្បង $questionNumber នៃ $totalQuestions'
                    : 'Challenge $questionNumber of $totalQuestions',
                style: TextStyle(
                  color: palette.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.limeSoft,
                borderRadius: AppRadii.fullBorder,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.limeInk,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '+10 XP',
                    style: TextStyle(
                      color: AppColors.limeInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question.question(lang),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.ink,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
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
              if (answered) ...[
                const SizedBox(height: 8),
                _KruAiReactionCameo(
                  isCorrect: isCorrect,
                  message: isCorrect
                      ? question.kruAiSuccess(lang)
                      : question.kruAiHint(lang),
                  lang: lang,
                ),
              ],
            ],
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

    Color backgroundColor = palette.surface;
    Color borderColor = palette.outline;
    Color letterBg = palette.outline.withValues(alpha: .5);
    Color letterColor = palette.ink;
    Widget? trailingIcon;

    if (answered) {
      if (isSelected && isTargetCorrect) {
        backgroundColor = AppColors.tileMint;
        borderColor = AppColors.brandJade;
        letterBg = AppColors.brandJade;
        letterColor = Colors.white;
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.brandJade,
          size: 24,
        );
      } else if (isSelected && !isTargetCorrect) {
        backgroundColor = const Color(0xFFFDECEE);
        borderColor = AppColors.error;
        letterBg = AppColors.error;
        letterColor = Colors.white;
        trailingIcon = const Icon(
          Icons.cancel_rounded,
          color: AppColors.error,
          size: 24,
        );
      } else if (isTargetCorrect) {
        borderColor = AppColors.brandJade.withValues(alpha: .6);
        trailingIcon = const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.brandJade,
          size: 22,
        );
      }
    }

    return RiksaTapFeedback(
      enabled: !answered,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.largeBorder,
          onTap: answered
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onSelectAnswer(index, index == question.correctIndex);
                },
          child: AnimatedContainer(
            duration: RiksaMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadii.largeBorder,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: borderColor.withValues(alpha: .15),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: palette.ink,
                      fontSize: 15,
                    ),
                  ),
                ),
                ?trailingIcon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Kru AI Mascot cameo speech bubble.
class _KruAiReactionCameo extends StatelessWidget {
  const _KruAiReactionCameo({
    required this.isCorrect,
    required this.message,
    required this.lang,
  });

  final bool isCorrect;
  final String message;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: RiksaMotion.standard,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.tileMint
            : palette.surfaceRaised,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCorrect
                    ? [AppColors.brandJade, palette.brand]
                    : [palette.brand, AppColors.deepInkRaised],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 24,
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
                      lang == 'km' ? 'គ្រូ AI (Kru AI)' : 'Kru AI Tutor',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isCorrect ? AppColors.brandJadeStrong : palette.brand,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.brandJade.withValues(alpha: .15)
                            : palette.brand.withValues(alpha: .12),
                        borderRadius: AppRadii.fullBorder,
                      ),
                      child: Text(
                        isCorrect
                            ? (lang == 'km' ? 'ពូកែណាស់!' : 'Brilliant!')
                            : (lang == 'km' ? 'ការណែនាំ' : 'Hint'),
                        style: TextStyle(
                          color: isCorrect
                              ? AppColors.brandJadeStrong
                              : palette.brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCorrect
                        ? AppColors.brandJadeStrong
                        : palette.ink,
                    height: 1.4,
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

/// Phase 3: Streak flame reward & frictionless 1-tap conversion screen.
class _PayoffStep extends StatelessWidget {
  const _PayoffStep({
    super.key,
    required this.setup,
    required this.lang,
    required this.submitting,
    required this.onSaveTelegram,
    required this.onSaveGoogle,
    required this.onSaveEmail,
    required this.onLogin,
  });

  final OnboardingSetupData setup;
  final String lang;
  final bool submitting;
  final VoidCallback onSaveTelegram;
  final VoidCallback onSaveGoogle;
  final VoidCallback onSaveEmail;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final provinceName = lang == 'km'
        ? (setup.provinceNameKhmer ?? 'កម្ពុជា')
        : (setup.provinceNameLatin ?? 'Cambodia');
    final earnedXp = setup.earnedXp > 0 ? setup.earnedXp : 20;

    return ListView(
      children: [
        const SizedBox(height: 10),
        // 1. Streak Flame Hero Badge
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF9800),
                  Color(0xFFFF5722),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5722).withValues(alpha: .35),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 54,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          lang == 'km'
              ? 'Streak ថ្ងៃទី ១ បានចាប់ផ្តើម! 🔥'
              : 'Day 1 Streak Started! 🔥',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lang == 'km'
              ? 'អ្នកបានដោះស្រាយការសាកល្បងដោយជោគជ័យ និងបង្កើតទម្លាប់សិក្សាថ្មី!'
              : 'You completed your first challenge and took your first learning step!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.inkMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // 2. XP & Province Pride Reward Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadii.largeBorder,
            border: Border.all(color: palette.outline),
            boxShadow: [
              BoxShadow(
                color: palette.brand.withValues(alpha: .06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: AppRadii.mediumBorder,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.limeInk,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+$earnedXp XP',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: palette.brand,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang == 'km'
                          ? 'បានរួមចំណែកដល់ខេត្ត $provinceName 🇰🇭'
                          : 'Contributed to $provinceName leaderboard 🇰🇭',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Goal & Plan Summary Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadii.mediumBorder,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context: context,
                  icon: Icons.school_rounded,
                  label: setup.goal != null
                      ? (lang == 'km' ? 'ផែនការ Grade A' : 'Grade A Plan')
                      : (lang == 'km' ? 'ផែនការសិក្សា' : 'Study Plan'),
                ),
              ),
              Container(width: 1, height: 20, color: palette.outline),
              Expanded(
                child: _buildSummaryItem(
                  context: context,
                  icon: Icons.timer_outlined,
                  label: '${setup.pace?.minutes ?? 10}m / day',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 4. Save Progress & 1-Tap Conversion Actions
        Text(
          lang == 'km'
              ? 'រក្សាទុកពិន្ទុ និងបន្ត Streak របស់អ្នក'
              : 'Save your streak & progress',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 14),

        // Telegram 1-Tap Primary Button
        FilledButton(
          key: const Key('onboarding_save_telegram'),
          onPressed: submitting ? null : onSaveTelegram,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2AABEE),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.largeBorder,
            ),
          ),
          child: submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TelegramLogo(size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        lang == 'km'
                            ? 'រក្សាទុកតាម Telegram (១-Tap)'
                            : 'Save with Telegram (1-Tap)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),

        // Google Button
        OutlinedButton(
          key: const Key('onboarding_save_google'),
          onPressed: submitting ? null : onSaveGoogle,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: BorderSide(color: palette.outline),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.largeBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoogleLogo(size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  lang == 'km'
                      ? 'បន្តជាមួយ Google'
                      : 'Continue with Google',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Email Sign-Up Link
        TextButton.icon(
          key: const Key('onboarding_save_email'),
          onPressed: submitting ? null : onSaveEmail,
          icon: Icon(Icons.mail_outline_rounded, size: 18, color: palette.inkMuted),
          label: Text(
            lang == 'km' ? 'ចុះឈ្មោះតាមអ៊ីមែល' : 'Sign up with Email',
            style: TextStyle(
              color: palette.inkMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),

        // Already have an account link
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text(
              lang == 'km' ? 'មានគណនីរួចហើយ?' : 'Already have an account?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.inkMuted,
              ),
            ),
            TextButton(
              key: const Key('onboarding_login_link'),
              onPressed: submitting ? null : onLogin,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                lang == 'km' ? 'ចូលគណនី' : 'Log In',
                style: TextStyle(
                  color: palette.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    final palette = context.riksa;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: palette.brand),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
