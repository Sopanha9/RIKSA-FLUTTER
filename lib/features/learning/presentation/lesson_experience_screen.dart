import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sound/learning_sound.dart';
import '../../../core/sound/sound_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import '../providers/learning_roadmap_provider.dart';
import '../providers/lesson_catalog_provider.dart';
import 'learning_design.dart';
import 'widgets/learning_atoms.dart';

/// Where the learner is inside one lesson.
///
/// The screen is a four-step loop rather than one long scroll: read the idea,
/// prove it, bank the section, reflect. Naming the step explicitly is what lets
/// the pinned action bar and the drenched header agree on what "next" means
/// without either of them re-deriving it.
enum _LessonPhase { reading, practising, sectionPassed, reflecting }

/// Everything the header, the sheet and the action bar need, derived once.
///
/// Computing this in one place is deliberate: the action bar lives outside the
/// scrolling body, so without a shared snapshot the two halves of the screen
/// would each walk the section list and could disagree about the active step.
class _LessonFlow {
  const _LessonFlow({
    required this.sections,
    required this.section,
    required this.phase,
    required this.exercise,
    required this.exerciseNumber,
    required this.following,
    required this.previous,
    required this.progress,
  });

  final List<_LessonSection> sections;
  final _LessonSection section;
  final _LessonPhase phase;

  /// The exercise being answered, when [phase] is [_LessonPhase.practising].
  final LessonExercise? exercise;

  /// Its position across the whole lesson, not just this section.
  final int exerciseNumber;
  final _LessonSection? following;
  final _LessonSection? previous;

  /// Share of the lesson's exercises already answered correctly.
  final double progress;

  bool get isFinalReview => section.index == 4;
}

class LessonExperienceScreen extends ConsumerStatefulWidget {
  const LessonExperienceScreen({
    super.key,
    required this.lessonId,
    this.lesson,
  });
  final String lessonId;
  final LessonSummary? lesson;
  @override
  ConsumerState<LessonExperienceScreen> createState() =>
      _LessonExperienceScreenState();
}

class _LessonExperienceScreenState
    extends ConsumerState<LessonExperienceScreen> {
  final _answers = <String, TextEditingController>{};
  final _results = <String, LessonAnswerResult>{};
  final _submitting = <String>{};
  final _reflection = TextEditingController();
  int? _activeSectionIndex;
  bool _showPractice = false;
  bool _completing = false;
  static const _quickReflections = [
    '🌟 Confident & Clear',
    '👍 Understood basics',
    '💡 Good challenge',
    '🤔 Need to review',
  ];
  String _selectedQuickReflection = '🌟 Confident & Clear';

  @override
  void dispose() {
    for (final controller in _answers.values) {
      controller.dispose();
    }
    _reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(lessonDetailProvider(widget.lessonId));
    final data = detail.value;
    final flow = data == null ? null : _flowFor(data);
    return PopScope(
      canPop: !_hasActiveSessionProgress(flow),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExit(flow);
      },
      child: Scaffold(
        backgroundColor: context.riksa.canvas,
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => SafeArea(
            child: _LessonLoadFailure(
              onRetry: () =>
                  ref.invalidate(lessonDetailProvider(widget.lessonId)),
            ),
          ),
          data: (value) =>
              flow == null ? _emptyLesson(value) : _buildLesson(value, flow),
        ),
        bottomNavigationBar: data == null || flow == null
            ? null
            : _actionBar(data, flow),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Flow
  // ---------------------------------------------------------------------------

  /// Returns null when the lesson has no sections at all, which is the one
  /// case the stepped layout cannot express.
  _LessonFlow? _flowFor(LessonDetail detail) {
    _restoreCompletedExercises(detail);
    final sections = _sectionsFor(detail);
    if (sections.isEmpty) return null;
    final activeIndex =
        _activeSectionIndex ?? _firstIncompleteSection(sections);
    final section = sections.firstWhere(
      (item) => item.index == activeIndex,
      orElse: () => sections.first,
    );
    final pending = section.exercises
        .where((exercise) => !_isCorrect(exercise))
        .firstOrNull;
    final following = sections
        .where((item) => item.index > section.index)
        .firstOrNull;
    final previous = sections
        .where((item) => item.index < section.index)
        .lastOrNull;

    final phase = switch ((_showPractice, pending, following)) {
      (false, _, _) => _LessonPhase.reading,
      (true, final LessonExercise _, _) => _LessonPhase.practising,
      (true, null, final _LessonSection _) => _LessonPhase.sectionPassed,
      (true, null, null) => _LessonPhase.reflecting,
    };

    final total = detail.exercises.length;
    final done = detail.exercises.where(_isCorrect).length;
    return _LessonFlow(
      sections: sections,
      section: section,
      phase: phase,
      exercise: phase == _LessonPhase.practising ? pending : null,
      exerciseNumber: pending == null
          ? 0
          : detail.exercises.indexWhere((item) => item.id == pending.id) + 1,
      following: following,
      previous: previous,
      // With no exercises to count, position in the section list is the only
      // honest measure of progress left.
      progress: total == 0
          ? sections.indexOf(section) / sections.length
          : done / total,
    );
  }

  void _restoreCompletedExercises(LessonDetail detail) {
    for (final exercise in detail.exercises.where(
      (exercise) => exercise.completed,
    )) {
      _results.putIfAbsent(
        exercise.id,
        () => LessonAnswerResult(
          exerciseId: exercise.id,
          correct: true,
          points: exercise.points,
          message: 'Completed earlier - your progress was restored.',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  Widget _buildLesson(LessonDetail detail, _LessonFlow flow) {
    final subject = detail.categoryName.trim().isEmpty
        ? AppLocalizations.of(context)!.generalSubject
        : detail.categoryName;
    void onAskAi() => context.push(
      '/ai/chat/new',
      extra:
          'Lesson: ${detail.title}\n'
          'Subject: ${detail.categoryName}\n'
          'Content: ${detail.description}',
    );
    return CustomScrollView(
      slivers: [
        // Navigation and progress stay; the identity block does not. Reading is
        // the one place the product's chrome is supposed to retreat, and a
        // learner who is three paragraphs in already knows what they opened.
        SliverPersistentHeader(
          pinned: true,
          delegate: _LessonBarDelegate(
            flow: flow,
            subject: subject,
            topInset: MediaQuery.paddingOf(context).top,
            // Measured rather than derived from a multiplier: a sliver header
            // must know its extent before it lays out, and a guess at the line
            // height of whichever font the locale selected overflows.
            controlsHeight: _textHeight(
              _StepCounter.styleFor(context),
              // The widest step label this lesson can show.
              'Section ${flow.sections.length} of ${flow.sections.length}',
            ),
            trackLabelHeight: _textHeight(
              Theme.of(context).textTheme.labelSmall,
              '100%',
            ),
            brightness: Theme.of(context).brightness,
            palette: context.riksa,
            backTooltip: MaterialLocalizations.of(context).backButtonTooltip,
            askAiTooltip: AppLocalizations.of(context)!.aiAskAboutLesson,
            onBack: () => _handleExit(flow),
            onAskAi: onAskAi,
          ),
        ),
        SliverToBoxAdapter(
          child: _LessonIdentity(
            id: detail.id,
            title: detail.title,
            subject: subject,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              _StepChips(
                flow: flow,
                results: _results,
                onSelect: (index) => setState(() {
                  _activeSectionIndex = index;
                  _showPractice = false;
                }),
              ),
              const SizedBox(height: RiksaSpacing.lg),
              switch (flow.phase) {
                _LessonPhase.reading => _contentView(flow),
                _LessonPhase.practising => _practiceView(detail, flow),
                _LessonPhase.sectionPassed => _sectionPassedView(
                  flow.following!,
                ),
                _LessonPhase.reflecting => _reflectionView(detail),
              },
              if (flow.phase == _LessonPhase.reading) ...[
                const SizedBox(height: RiksaSpacing.lg),
                _AskTutorButton(
                  lessonTitle: detail.title,
                  learningContext: '$subject - ${flow.section.title}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Laid-out height of [text] in [style], at the current text scale.
  double _textHeight(TextStyle? style, String text) => (TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout()).height;

  Widget _contentView(_LessonFlow flow) {
    final section = flow.section;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          flow.isFinalReview
              ? 'Final Review'
              : 'Section ${section.index}: ${section.title}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: RiksaSpacing.xs),
        Text(
          flow.isFinalReview
              ? 'Lesson challenge: apply every idea you have learned.'
              : 'Read the idea, then prove it in practice.',
          style: TextStyle(color: context.riksa.inkMuted),
        ),
        if (section.content.trim().isNotEmpty) ...[
          const SizedBox(height: RiksaSpacing.md),
          // Reading copy is capped near 68 characters so a wide phone or a
          // tablet does not stretch the measure past comfortable.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: MarkdownBody(
              key: ValueKey(
                section.index == 1
                    ? 'lesson-description-markdown'
                    : 'lesson-section-markdown-${section.index}',
              ),
              data: section.content,
              selectable: true,
              softLineBreak: true,
              styleSheet: _lessonMarkdownStyleSheet(
                context,
                hasKhmer: RiksaTypography.containsKhmer(section.content),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _practiceView(LessonDetail detail, _LessonFlow flow) {
    final section = flow.section;
    final exercise = flow.exercise!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          flow.isFinalReview
              ? 'Final Review'
              : 'Section ${section.index} practice',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: RiksaSpacing.xxs + 2),
        Text(
          '${section.exercises.where(_isCorrect).length} of ${section.exercises.length} correct',
          style: TextStyle(color: context.riksa.inkMuted),
        ),
        const SizedBox(height: RiksaSpacing.md),
        _ExerciseCard(
          number: flow.exerciseNumber,
          exercise: exercise,
          lessonTitle: detail.title,
          controller: _answers.putIfAbsent(
            exercise.id,
            TextEditingController.new,
          ),
          result: _results[exercise.id],
          submitting: _submitting.contains(exercise.id),
          // The answer lives in a controller the action bar reads, so every
          // keystroke and every tapped choice has to reach this state or the
          // bar's "Check answer" would stay dead.
          onAnswerChanged: () => setState(() {}),
        ),
      ],
    );
  }

  Widget _sectionPassedView(_LessonSection next) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LearningBadge(
        icon: Icons.check_rounded,
        foreground: context.riksa.onJade,
        background: context.riksa.jade,
        size: 48,
      ),
      const SizedBox(height: RiksaSpacing.sm),
      Text(
        'Section complete',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: RiksaSpacing.xxs + 2),
      Text(
        'Nice work. You are ready for '
        '${next.index == 4 ? 'the Final Review' : 'Section ${next.index}: ${next.title}'}.',
        style: TextStyle(color: context.riksa.inkMuted),
      ),
    ],
  );

  Widget _reflectionView(LessonDetail detail) {
    final palette = context.riksa;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The one loud moment of the flow: a single drenched card, no confetti
        // and no second big number competing with it.
        Container(
          padding: const EdgeInsets.all(RiksaSpacing.lg),
          decoration: BoxDecoration(
            color: palette.jadeSoft,
            borderRadius: AppRadii.featureBorder,
          ),
          child: Column(
            children: [
              LearningBadge(
                icon: Icons.emoji_events_rounded,
                foreground: palette.onJade,
                background: palette.jade,
                size: 56,
              ),
              const SizedBox(height: RiksaSpacing.sm),
              Text(
                'Lesson mastered',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: RiksaSpacing.xxs + 2),
              Text(
                'You proved every concept and finished the final review.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.inkMuted, fontSize: 14),
              ),
              const SizedBox(height: RiksaSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: RiksaSpacing.xs,
                runSpacing: RiksaSpacing.xs,
                children: [
                  LearningPill(
                    icon: Icons.bolt_rounded,
                    label: '+${detail.baseXp} XP',
                    accent: palette.saffron,
                  ),
                  LearningPill(
                    icon: Icons.check_rounded,
                    label: '${detail.exercises.length} exercises passed',
                    accent: palette.jade,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: RiksaSpacing.lg),
        Text(
          'How was this lesson for you?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: RiksaSpacing.xxs),
        Text(
          detail.reflectionPrompt.trim().isEmpty
              ? 'Tap your quick reflection:'
              : detail.reflectionPrompt,
          style: TextStyle(color: palette.inkMuted, fontSize: 13),
        ),
        const SizedBox(height: RiksaSpacing.sm),
        Wrap(
          spacing: RiksaSpacing.xs,
          runSpacing: RiksaSpacing.xs,
          children: _quickReflections
              .map(
                (label) => RiksaChoicePill(
                  label: label,
                  selected: _selectedQuickReflection == label,
                  onSelected: (_) =>
                      setState(() => _selectedQuickReflection = label),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: RiksaSpacing.md),
        TextField(
          key: const ValueKey('lesson-reflection'),
          controller: _reflection,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Any personal notes or key takeaways? (optional)',
            hintStyle: TextStyle(color: palette.inkMuted, fontSize: 13),
            alignLabelWithHint: true,
            filled: true,
            fillColor: palette.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: AppRadii.largeBorder,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.largeBorder,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyLesson(LessonDetail detail) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(detail.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: RiksaSpacing.md),
        const _NoExercises(),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // The pinned action bar
  // ---------------------------------------------------------------------------

  Widget _actionBar(LessonDetail detail, _LessonFlow flow) {
    final isCompleted = detail.state == LessonProgressState.completed;
    final answer = flow.exercise == null
        ? ''
        : _answers[flow.exercise!.id]?.text.trim() ?? '';

    return switch (flow.phase) {
      _LessonPhase.reading => LearningActionBar(
        primaryKey: ValueKey('start-section-${flow.section.index}'),
        primaryLabel: flow.isFinalReview
            ? 'Start final review'
            : 'Practice this section',
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimary: () => setState(() => _showPractice = true),
        backLabel: 'Back',
        onBack: _stepBack(flow),
      ),
      _LessonPhase.practising => LearningActionBar(
        primaryKey: const ValueKey('check-answer'),
        primaryLabel: 'Check answer',
        busy: _submitting.contains(flow.exercise!.id),
        onPrimary: answer.isEmpty
            ? null
            : () => _submitAnswer(flow.exercise!, flow.section),
        backLabel: 'Back',
        onBack: _stepBack(flow),
      ),
      _LessonPhase.sectionPassed => LearningActionBar(
        primaryKey: ValueKey('continue-to-section-${flow.following!.index}'),
        primaryLabel: 'Continue',
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimary: () => setState(() {
          _activeSectionIndex = flow.following!.index;
          _showPractice = false;
        }),
      ),
      _LessonPhase.reflecting => LearningActionBar(
        primaryKey: const ValueKey('complete-lesson'),
        primaryLabel: isCompleted
            ? 'Lesson completed'
            : 'Claim +${detail.baseXp} XP',
        primaryIcon: isCompleted ? null : Icons.emoji_events_rounded,
        busy: _completing,
        onPrimary: isCompleted ? null : () => _complete(detail),
      ),
    };
  }

  /// One step back through the flow, falling out of the lesson only when there
  /// is nothing left to step back to.
  VoidCallback? _stepBack(_LessonFlow flow) {
    if (flow.phase == _LessonPhase.practising) {
      return () => setState(() => _showPractice = false);
    }
    final previous = flow.previous;
    if (previous != null) {
      return () => setState(() {
        _activeSectionIndex = previous.index;
        _showPractice = false;
      });
    }
    // Asked of the Navigator rather than the router: this runs during build,
    // and a bare widget test has no GoRouter above it.
    return Navigator.of(context).canPop() ? () => _handleExit(flow) : null;
  }

  bool _hasActiveSessionProgress(_LessonFlow? flow) {
    if (_completing) return false;
    if (_results.isNotEmpty) return true;
    if (_answers.values.any((c) => c.text.trim().isNotEmpty)) return true;
    if (_reflection.text.trim().isNotEmpty) return true;
    if (_showPractice) return true;
    if (flow != null && (flow.section.index > 0 || flow.progress > 0)) {
      return true;
    }
    return false;
  }

  void _safePop() {
    final nav = Navigator.maybeOf(context);
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else {
      try {
        context.pop();
      } catch (_) {}
    }
  }

  Future<void> _handleExit(_LessonFlow? flow) async {
    if (!_hasActiveSessionProgress(flow)) {
      if (mounted) _safePop();
      return;
    }
    final shouldLeave = await _showExitConfirmationDialog();
    if (shouldLeave && mounted) {
      _safePop();
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    final palette = context.riksa;
    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.feature)),
        ),
        backgroundColor: palette.surface,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 22,
              ),
            ),
            const SizedBox(width: RiksaSpacing.sm),
            Expanded(
              child: Text(
                isKhmer ? 'ចាកចេញពីមេរៀន?' : 'Leave this lesson?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isKhmer
              ? 'វឌ្ឍនភាពនៃការអនុវត្តរបស់អ្នកនៅក្នុងវគ្គនេះនឹងមិនត្រូវបានរក្សាទុកទេ។ តើអ្នកពិតជាចង់ចាកចេញមែនទេ?'
              : 'Your progress in this practice session will not be saved. Are you sure you want to leave?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: palette.inkMuted,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            key: const ValueKey('leave-lesson-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              isKhmer ? 'បន្តរៀន' : 'Keep Learning',
              style: TextStyle(
                color: palette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            key: const ValueKey('leave-lesson-confirm-button'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isKhmer ? 'ចាកចេញ' : 'Leave Lesson'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> _submitAnswer(
    LessonExercise exercise,
    _LessonSection section,
  ) async {
    final answer = _answers[exercise.id]?.text.trim() ?? '';
    if (answer.isEmpty) return;
    setState(() => _submitting.add(exercise.id));
    try {
      final result = await ref
          .read(learningApiProvider)
          .submitAnswer(
            lessonId: widget.lessonId,
            exerciseId: exercise.id,
            answer: answer,
          );
      if (mounted) {
        setState(() => _results[exercise.id] = result);
        _soundForAnswer(result, section);
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _submitting.remove(exercise.id));
    }
  }

  Future<void> _complete(LessonDetail detail) async {
    setState(() => _completing = true);
    try {
      final userNotes = _reflection.text.trim();
      final reflectionPayload = userNotes.isNotEmpty
          ? '[$_selectedQuickReflection] $userNotes'
          : _selectedQuickReflection;
      final result = await ref
          .read(learningApiProvider)
          .completeLesson(
            lessonId: widget.lessonId,
            reflectionText: reflectionPayload,
          );
      // Sounded before the awaits below: the fanfare should land with the tap,
      // not after the catalog and roadmaps have finished refetching.
      HapticFeedback.mediumImpact();
      ref.playSound(LearningSound.lessonComplete);
      await ref.read(lessonCatalogProvider.notifier).load();
      // The roadmap owns this lesson's completed state, and the home screen
      // derives its counts and its resume target from every roadmap. Both are
      // stale the moment a lesson is finished, so drop them together.
      if (detail.categoryId != null) {
        ref.invalidate(learningRoadmapProvider(detail.categoryId!));
      }
      ref.invalidate(learningHomeProvider);
      if (mounted) {
        final roadmapCategoryId = detail.categoryId;
        final suffix = roadmapCategoryId == null
            ? ''
            : '?roadmapCategoryId=$roadmapCategoryId';
        context.go(
          '/learn/completion$suffix',
          extra: {
            'xpEarned': result.xpEarned,
            'lessonTitle': detail.title,
            'categoryName': detail.categoryName,
            'totalExercises': detail.exercises.length,
          },
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  List<_LessonSection> _sectionsFor(LessonDetail detail) {
    final byIndex = <int, List<LessonExercise>>{};
    for (final exercise in detail.exercises) {
      (byIndex[exercise.sectionIndex] ??= []).add(exercise);
    }
    final content = _markdownSections(detail.description);
    final indexes = {...byIndex.keys, ...content.keys}.toList()..sort();
    return indexes.map((index) {
      final markdown = content[index] ?? '';
      return _LessonSection(
        index: index,
        title: _sectionTitle(markdown, index),
        content: markdown,
        exercises: byIndex[index] ?? const [],
      );
    }).toList();
  }

  Map<int, String> _markdownSections(String markdown) {
    final matches = RegExp(
      r'^##\s+(.+)$',
      multiLine: true,
    ).allMatches(markdown).toList();
    if (matches.isEmpty) return {1: markdown};
    return {
      for (var index = 0; index < matches.length; index++)
        index + 1: markdown
            .substring(
              matches[index].start,
              index + 1 < matches.length
                  ? matches[index + 1].start
                  : markdown.length,
            )
            .trim(),
    };
  }

  String _sectionTitle(String markdown, int index) =>
      RegExp(
        r'^##\s+(.+)$',
        multiLine: true,
      ).firstMatch(markdown)?.group(1)?.trim() ??
      (index == 4 ? 'Final Review' : 'Practice');

  int _firstIncompleteSection(List<_LessonSection> sections) =>
      sections
          .where(
            (section) =>
                section.exercises.any((exercise) => !_isCorrect(exercise)),
          )
          .map((section) => section.index)
          .firstOrNull ??
      sections.first.index;

  /// Sounds the answer, promoting to the section cue when that answer was the
  /// one that finished the section.
  ///
  /// Only one cue plays: stacking "correct" under "section complete" muddles
  /// both, and the section cue already reads as a correct answer.
  void _soundForAnswer(LessonAnswerResult result, _LessonSection section) {
    if (!result.correct) {
      HapticFeedback.heavyImpact();
      ref.playSound(LearningSound.wrong);
      return;
    }
    // Reads the freshly stored results, so the answer just marked correct
    // counts towards finishing the section.
    final finishedSection = section.exercises.every(_isCorrect);
    if (finishedSection) {
      HapticFeedback.mediumImpact();
      ref.playSound(LearningSound.sectionComplete);
    } else {
      HapticFeedback.lightImpact();
      ref.playSound(LearningSound.correct);
    }
  }

  bool _isCorrect(LessonExercise exercise) =>
      _results[exercise.id]?.correct == true;

  void _showError(Object error) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(_friendlyLessonError(error))));
}

class _LessonSection {
  const _LessonSection({
    required this.index,
    required this.title,
    required this.content,
    required this.exercises,
  });
  final int index;
  final String title;
  final String content;
  final List<LessonExercise> exercises;
}

// -----------------------------------------------------------------------------
// The drenched header
// -----------------------------------------------------------------------------

/// The one pastel-filled surface on this screen.
///
/// It is fixed above the scrolling sheet so the progress track and the step
/// counter stay readable no matter how long the lesson's reading runs, which is
/// the whole reason a lesson does not simply scroll from title to reflection.
/// The part of the header that never leaves: back, step, tutor, progress.
///
/// Height is fixed rather than shrinking, because a header that interpolates
/// its own extent has to guess how many lines a Khmer title will take. Letting
/// the identity block scroll away underneath a constant bar gives the same
/// reclaimed reading space with none of that measurement.
class _LessonBarDelegate extends SliverPersistentHeaderDelegate {
  const _LessonBarDelegate({
    required this.flow,
    required this.subject,
    required this.topInset,
    required this.controlsHeight,
    required this.trackLabelHeight,
    required this.brightness,
    required this.palette,
    required this.backTooltip,
    required this.askAiTooltip,
    required this.onBack,
    required this.onAskAi,
  });

  final _LessonFlow flow;
  final String subject;
  final double topInset;

  /// Height of the step label, before the pill's own padding.
  final double controlsHeight;

  /// Height of the percentage beside the track.
  final double trackLabelHeight;

  final Brightness brightness;
  final RiksaPalette palette;
  final String backTooltip;
  final String askAiTooltip;
  final VoidCallback onBack;
  final VoidCallback onAskAi;

  static const _rowGap = 12.0;
  static const _trackHeight = 8.0;

  /// The controls row never drops below a 44dp touch target, and grows past it
  /// only when the step pill's own text needs the room.
  double get _rowHeight => math.max(44, controlsHeight + _StepCounter.padding);

  double get _trackRowHeight => math.max(_trackHeight, trackLabelHeight);

  double get _extent =>
      topInset + 4 + _rowHeight + _rowGap + _trackRowHeight + _rowGap;

  @override
  double get maxExtent => _extent;

  @override
  double get minExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final tone = subjectTone(context, stemSubjectFor(subject));
    final percent = (flow.progress.clamp(0, 1) * 100).round();
    return ColoredBox(
      color: tone.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topInset + 4, 20, _rowGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _rowHeight,
              child: NavigationToolbar(
                leading: LearningCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: backTooltip,
                  onTap: onBack,
                ),
                middle: _StepCounter(flow: flow, accent: tone.accent),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final soundEnabled = ref.watch(soundEnabledProvider);
                        final isKhmer =
                            Localizations.localeOf(context).languageCode == 'km';
                        final soundTooltip = soundEnabled
                            ? (isKhmer ? 'បិទសំឡេង' : 'Mute sound')
                            : (isKhmer ? 'បើកសំឡេង' : 'Unmute sound');
                        return LearningCircleButton(
                          key: const ValueKey('lesson-sound-toggle'),
                          icon: soundEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          tooltip: soundTooltip,
                          foreground: soundEnabled
                              ? tone.accent
                              : palette.ink.withValues(alpha: 0.45),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(soundEnabledProvider.notifier).toggle();
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    LearningCircleButton(
                      key: const ValueKey('lesson-ask-ai'),
                      icon: Icons.auto_awesome_rounded,
                      tooltip: askAiTooltip,
                      onTap: onAskAi,
                      foreground: tone.accent,
                    ),
                  ],
                ),
                centerMiddle: true,
              ),
            ),
            const SizedBox(height: _rowGap),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Lesson progress $percent%',
                    excludeSemantics: true,
                    child: LearningTrack(
                      key: const ValueKey('lesson-progress-track'),
                      value: flow.progress,
                      color: palette.ink,
                      background: tone.accent.withValues(alpha: .25),
                      height: _trackHeight,
                    ),
                  ),
                ),
                const SizedBox(width: RiksaSpacing.sm),
                RiksaCountUp(
                  value: percent,
                  format: (value) => '$value%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LessonBarDelegate oldDelegate) =>
      oldDelegate.flow.progress != flow.progress ||
      oldDelegate.flow.section.index != flow.section.index ||
      oldDelegate.flow.phase != flow.phase ||
      oldDelegate.subject != subject ||
      oldDelegate.topInset != topInset ||
      oldDelegate.controlsHeight != controlsHeight ||
      oldDelegate.trackLabelHeight != trackLabelHeight ||
      oldDelegate.brightness != brightness ||
      oldDelegate.palette != palette;
}

/// Subject mark, subject name and lesson title, on the same pastel as the bar.
///
/// This is what the learner trades away for reading room: it scrolls up behind
/// the bar, so the pastel region shrinks to the bar and the rounded bottom edge
/// travels with it.
class _LessonIdentity extends StatelessWidget {
  const _LessonIdentity({
    required this.id,
    required this.title,
    required this.subject,
  });

  final String id;
  final String title;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = subjectTone(context, stemSubjectFor(subject));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.feature + 2),
      ),
      child: ColoredBox(
        color: tone.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, RiksaSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RiksaSharedElement(
                tag: 'lesson-art-$id',
                child: SubjectArtwork(
                  kind: subjectKindFor(subject),
                  color: tone.accent,
                  size: 44,
                ),
              ),
              const SizedBox(width: RiksaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tone.accent,
                        letterSpacing: .7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: RiksaSpacing.xxs - 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.titleStyleFor(
                        title,
                        theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          height: 1.15,
                          letterSpacing: -.5,
                          fontWeight: FontWeight.w700,
                        ),
                        khmerHeight: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the learner is, in the position the inspiration gives a stopwatch.
///
/// A clock would push speed on a screen whose whole point is reading and
/// reflecting, so the same slot carries the step instead.
class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.flow, required this.accent});

  final _LessonFlow flow;
  final Color accent;

  /// Vertical padding the pill adds around its label. The header measures the
  /// label itself and adds this to reserve the row.
  static const padding = RiksaSpacing.xs * 2;

  static TextStyle styleFor(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: context.riksa.ink,
  );

  @override
  Widget build(BuildContext context) {
    final position = flow.sections.indexOf(flow.section) + 1;
    final label = flow.isFinalReview
        ? 'Final review'
        : 'Section $position of ${flow.sections.length}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RiksaSpacing.md,
        vertical: RiksaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.riksa.surface,
        borderRadius: AppRadii.fullBorder,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: styleFor(context),
      ),
    );
  }
}

/// The sections as a row of tappable pills.
///
/// This replaces a row of anonymous progress segments: a learner can now see
/// which section they are in, which ones are banked, and jump back to reread
/// one without losing their place in the current one.
class _StepChips extends StatelessWidget {
  const _StepChips({
    required this.flow,
    required this.results,
    required this.onSelect,
  });

  final _LessonFlow flow;
  final Map<String, LessonAnswerResult> results;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final anchor = learningAnchor(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: flow.sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: RiksaSpacing.xs),
        itemBuilder: (context, position) {
          final section = flow.sections[position];
          final active = section.index == flow.section.index;
          final done =
              section.exercises.isNotEmpty &&
              section.exercises.every(
                (exercise) => results[exercise.id]?.correct == true,
              );
          final label = section.index == 4
              ? 'Final review'
              : 'Section ${position + 1}';

          final background = active
              ? anchor
              : done
              ? palette.jadeSoft
              : palette.surface;
          final foreground = active
              ? onLearningAnchor(context)
              : done
              ? palette.jade
              : palette.inkMuted;

          return Material(
            color: background,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('lesson-step-${section.index}'),
              onTap: active ? null : () => onSelect(section.index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RiksaSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (done && !active) ...[
                      Icon(Icons.check_rounded, size: 14, color: foreground),
                      const SizedBox(width: RiksaSpacing.xxs + 2),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// The question
// -----------------------------------------------------------------------------

/// One question, with its feedback.
///
/// It deliberately does not own a submit button: the single "Check answer" for
/// the screen lives in the pinned bar, so the card never competes with it and
/// the action stays in the same place for every question in the lesson.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.number,
    required this.exercise,
    this.lessonTitle,
    required this.controller,
    required this.result,
    required this.submitting,
    required this.onAnswerChanged,
  });
  final int number;
  final LessonExercise exercise;
  final String? lessonTitle;
  final TextEditingController controller;
  final LessonAnswerResult? result;
  final bool submitting;
  final VoidCallback onAnswerChanged;

  void _askAiHint(BuildContext context) {
    final optionsText = exercise.options.isNotEmpty
        ? '\nOptions: ${exercise.options.join(", ")}'
        : '';
    final hintContext =
        '''
Exercise Hint Request:
Lesson: ${lessonTitle ?? "STEM Lesson"}
Question: ${exercise.question}
Type: ${exercise.type.name}$optionsText

Learner Goal: Provide a progressive Socratic hint in Khmer/English to help the student think through this question without giving away the direct answer.
''';
    context.push('/ai/chat/new', extra: hintContext);
  }

  void _explainErrorWithAi(BuildContext context) {
    final userAnswer = controller.text.trim();
    final explainContext =
        '''
Exercise Error Analysis:
Lesson: ${lessonTitle ?? "STEM Lesson"}
Question: ${exercise.question}
Learner Selected Answer: ${userAnswer.isEmpty ? "None selected" : userAnswer}
${exercise.hint != null ? "Static Hint: ${exercise.hint}" : ""}

Learner Goal: Explain why '${userAnswer.isEmpty ? "the selected answer" : userAnswer}' is incorrect, breakdown the core concept step-by-step in Khmer/English, and guide the student to the correct solution.
''';
    context.push('/ai/chat/new', extra: explainContext);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final correct = result?.correct == true;
    final incorrect = result != null && !correct;
    return Container(
      key: ValueKey('lesson-exercise-${exercise.id}'),
      padding: const EdgeInsets.all(RiksaSpacing.md + 2),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.extraLargeBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Exercise $number',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const Spacer(),
              Text(
                '+${exercise.points} XP',
                style: TextStyle(
                  color: palette.saffron,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: RiksaSpacing.sm),
          MarkdownBody(
            data: exercise.question,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(p: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: RiksaSpacing.md),
          if (exercise.type == LessonExerciseType.text)
            TextField(
              controller: controller,
              enabled: !correct && !submitting,
              textInputAction: TextInputAction.done,
              onChanged: (_) => onAnswerChanged(),
              decoration: InputDecoration(
                hintText: 'Your answer',
                filled: true,
                fillColor: palette.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: AppRadii.largeBorder,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadii.largeBorder,
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            _ChoiceAnswers(
              exercise: exercise,
              controller: controller,
              enabled: !correct && !submitting,
              result: result,
              onChanged: onAnswerChanged,
            ),
          if (!correct) ...[
            const SizedBox(height: RiksaSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('lesson-ai-hint'),
                onPressed: () => _askAiHint(context),
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: const Text('AI hint'),
                style: TextButton.styleFrom(
                  foregroundColor: palette.inkMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: RiksaSpacing.sm,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: RiksaSpacing.sm),
            Text(
              result!.message,
              style: TextStyle(
                color: correct
                    ? palette.jade
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (correct)
              Text(
                'This counts toward +${exercise.points} lesson XP when you '
                'complete the lesson.',
                style: TextStyle(color: palette.inkMuted, fontSize: 12),
              ),
            if (incorrect) ...[
              const SizedBox(height: RiksaSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _explainErrorWithAi(context),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Explain with AI'),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                ),
              ),
            ],
            if (incorrect &&
                (result!.hint ?? exercise.hint)?.trim().isNotEmpty == true)
              _Feedback(label: 'Hint', text: result!.hint ?? exercise.hint!),
            if ((incorrect || correct) &&
                (result!.explanation ?? exercise.explanation)
                        ?.trim()
                        .isNotEmpty ==
                    true)
              _Feedback(
                label: 'Why',
                text: result!.explanation ?? exercise.explanation!,
              ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceAnswers extends StatefulWidget {
  const _ChoiceAnswers({
    required this.exercise,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.result,
  });
  final LessonExercise exercise;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final LessonAnswerResult? result;
  @override
  State<_ChoiceAnswers> createState() => _ChoiceAnswersState();
}

class _ChoiceAnswersState extends State<_ChoiceAnswers> {
  static const _labels = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final isTrueFalse = widget.exercise.type == LessonExerciseType.trueFalse;
    final options = isTrueFalse
        ? const ['True', 'False']
        : widget.exercise.options;

    final selectedAnswer = widget.controller.text;
    final isAttempted = widget.result != null;
    final isCorrect = widget.result?.correct == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: RiksaSpacing.xs),
          _buildOptionCard(
            context: context,
            index: i,
            option: options[i],
            isTrueFalse: isTrueFalse,
            isSelected: selectedAnswer == options[i],
            isAttempted: isAttempted,
            isCorrect: isCorrect,
          ),
        ],
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required int index,
    required String option,
    required bool isTrueFalse,
    required bool isSelected,
    required bool isAttempted,
    required bool isCorrect,
  }) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final anchor = learningAnchor(context);
    final badgeLabel = isTrueFalse
        ? (index == 0 ? 'T' : 'F')
        : (index < _labels.length ? _labels[index] : '${index + 1}');

    // Unselected options are quiet fields. Only the chosen one takes colour,
    // and only after a check does that colour mean right or wrong.
    Color background = palette.surfaceRaised;
    Color badgeBackground = palette.surface;
    Color badgeInk = palette.inkMuted;
    Color ink = palette.ink;
    Widget? trailing;

    if (isSelected) {
      if (isAttempted && isCorrect) {
        background = palette.jadeSoft;
        badgeBackground = palette.jade;
        badgeInk = palette.onJade;
        trailing = Icon(Icons.check_rounded, color: palette.jade, size: 20);
      } else if (isAttempted) {
        background = theme.colorScheme.errorContainer;
        badgeBackground = theme.colorScheme.error;
        badgeInk = theme.colorScheme.onError;
        ink = theme.colorScheme.onErrorContainer;
        trailing = Icon(
          Icons.close_rounded,
          color: theme.colorScheme.error,
          size: 20,
        );
      } else {
        background = anchor;
        badgeBackground = onLearningAnchor(context);
        badgeInk = anchor;
        ink = onLearningAnchor(context);
      }
    }

    return Material(
      color: background,
      borderRadius: AppRadii.largeBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('lesson-option-$index'),
        onTap: widget.enabled
            ? () {
                setState(() => widget.controller.text = option);
                widget.onChanged();
              }
            : null,
        child: AnimatedPadding(
          duration: RiksaMotion.resolve(context, RiksaMotion.fast),
          padding: const EdgeInsets.symmetric(
            horizontal: RiksaSpacing.md - 2,
            vertical: RiksaSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: badgeInk,
                  ),
                ),
              ),
              const SizedBox(width: RiksaSpacing.sm),
              Expanded(
                child: Text(
                  option,
                  style: RiksaTypography.bodyStyleFor(
                    option,
                    theme.textTheme.bodyMedium?.copyWith(
                      color: ink,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.label, required this.text});
  final String label;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: RiksaSpacing.xs),
    child: Text(
      '$label: $text',
      style: TextStyle(color: context.riksa.inkMuted, fontSize: 13),
    ),
  );
}

class _NoExercises extends StatelessWidget {
  const _NoExercises();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(RiksaSpacing.md),
    decoration: BoxDecoration(
      color: context.riksa.surfaceRaised,
      borderRadius: AppRadii.largeBorder,
    ),
    child: const Text(
      'This lesson has no exercises. Add your reflection to complete it.',
    ),
  );
}

class _LessonLoadFailure extends StatelessWidget {
  const _LessonLoadFailure({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => IllustratedEmptyState(
    title: AppLocalizations.of(context)!.lessonLoadFailed,
    body: 'The lesson detail could not be loaded from the learning service.',
    actionLabel: AppLocalizations.of(context)!.tryAgain,
    onAction: onRetry,
  );
}

String _friendlyLessonError(Object error) {
  String text = error.toString();
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      text = data['message'] as String;
    }
  }
  if (text.contains('already completed')) {
    return 'This lesson is already complete.';
  }
  if (text.contains('too short')) {
    return 'Write at least 10 words in your reflection.';
  }
  if (text.contains('Cannot complete lesson')) {
    return 'Answer every exercise correctly before completing the lesson.';
  }
  if (text.contains('locked') || text.contains('previous lesson')) {
    return 'This lesson is locked until the previous lesson is completed.';
  }
  return text.isNotEmpty
      ? text
      : 'We could not save that yet. Please try again.';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

MarkdownStyleSheet _lessonMarkdownStyleSheet(
  BuildContext context, {
  required bool hasKhmer,
}) {
  final theme = Theme.of(context);
  final palette = context.riksa;
  final bodyFont = hasKhmer
      ? RiksaTypography.khmerBodyFamily
      : RiksaTypography.latinFamily;
  final titleFont = hasKhmer
      ? RiksaTypography.khmerTitleFamily
      : RiksaTypography.latinFamily;
  TextStyle body(TextStyle? style) => (style ?? const TextStyle()).copyWith(
    fontFamily: bodyFont,
    fontFamilyFallback: hasKhmer
        ? const [RiksaTypography.khmerFamily, RiksaTypography.latinFamily]
        : RiksaTypography.fallback,
  );
  TextStyle heading(TextStyle? style) => (style ?? const TextStyle()).copyWith(
    fontFamily: titleFont,
    fontFamilyFallback: hasKhmer
        ? RiksaTypography.khmerTitleFallback
        : RiksaTypography.fallback,
    fontWeight: hasKhmer ? FontWeight.w400 : style?.fontWeight,
  );
  final paragraph = body(theme.textTheme.bodyLarge?.copyWith(height: 1.75));
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 4),
    h1: heading(theme.textTheme.headlineLarge?.copyWith(height: 1.4)),
    h2: heading(theme.textTheme.headlineMedium?.copyWith(height: 1.4)),
    h3: heading(theme.textTheme.titleLarge?.copyWith(height: 1.5)),
    h1Padding: const EdgeInsets.only(top: 8, bottom: 6),
    h2Padding: const EdgeInsets.only(top: 8, bottom: 5),
    h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
    strong: body(const TextStyle(fontWeight: FontWeight.w700)),
    code: body(
      theme.textTheme.bodyMedium?.copyWith(
        color: palette.ink,
        backgroundColor: palette.surfaceRaised,
      ),
    ),
    listBullet: paragraph,
    blockSpacing: 12,
    listIndent: 22,
  );
}

/// Contextual way into the tutor: the student is stuck on this lesson, right
/// now, and the tutor is told which lesson that is.
class _AskTutorButton extends StatelessWidget {
  const _AskTutorButton({
    required this.lessonTitle,
    required this.learningContext,
  });

  final String lessonTitle;
  final String learningContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey('ask-tutor-about-lesson'),
        onPressed: () => context.push(
          '/ai/chat/new'
          '?lesson=${Uri.encodeQueryComponent(lessonTitle)}'
          '&context=${Uri.encodeQueryComponent(learningContext)}',
        ),
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(l10n.aiAskAboutLesson),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          side: BorderSide(color: context.riksa.outline),
          foregroundColor: context.riksa.ink,
        ),
      ),
    );
  }
}
