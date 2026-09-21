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
import '../../../core/widgets/riksa_brand.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_math_text.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../social/providers/social_feed_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import '../providers/learning_roadmap_provider.dart';
import '../providers/lesson_catalog_provider.dart';
import '../providers/saved_lessons_provider.dart';
import 'learning_design.dart';
import 'widgets/learning_atoms.dart';
import 'widgets/learning_status_bar.dart';

/// Where the learner is inside one lesson.
///
/// Reading, writing and feedback share one explicit state so the pinned action
/// always matches the visible content. Feedback stays until the learner continues.
enum _LessonPhase {
  reading,
  practising,
  answerChecked,
  sectionPassed,
  reflecting,
}

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

  /// Share of the lesson's exercises already answered correctly.
  final double progress;
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
  final _working = <String, TextEditingController>{};
  final _scroll = ScrollController();
  final _feedbackAnchor = GlobalKey();
  String? _feedbackExerciseId;
  bool? _needsReview;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  void _changeStep(VoidCallback update) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(update);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    for (final controller in _answers.values) {
      controller.dispose();
    }
    for (final controller in _working.values) {
      controller.dispose();
    }
    _scroll.dispose();
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
        // Content brings its own header; without content, keep a way out.
        appBar: flow == null
            ? LearningStatusBar(title: data?.title ?? widget.lesson?.title)
            : null,
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => SafeArea(
            top: false,
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
    final following =
        sections.where((item) => item.index > section.index).firstOrNull ??
        sections
            .where(
              (item) =>
                  item.index != section.index &&
                  item.exercises.any((exercise) => !_isCorrect(exercise)),
            )
            .firstOrNull;

    final feedback = section.exercises
        .where((exercise) => exercise.id == _feedbackExerciseId)
        .firstOrNull;
    final phase = feedback != null
        ? _LessonPhase.answerChecked
        : switch ((_showPractice, pending, following)) {
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
      exercise: feedback ?? (phase == _LessonPhase.practising ? pending : null),
      exerciseNumber: (feedback ?? pending) == null
          ? 0
          : detail.exercises.indexOf((feedback ?? pending)!) + 1,
      following: following,
      // With no exercises to count, position in the section list is the only
      // honest measure of progress left.
      progress: total == 0
          ? (phase == _LessonPhase.reflecting
                ? 1
                : sections.indexOf(section) / sections.length)
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
      controller: _scroll,
      slivers: [
        // Navigation and progress stay; the identity block does not. Reading is
        // the one place the product's chrome is supposed to retreat, and a
        // learner who is three paragraphs in already knows what they opened.
        SliverPersistentHeader(
          pinned: true,
          delegate: _LessonBarDelegate(
            lessonId: widget.lessonId,
            flow: flow,
            topInset: MediaQuery.paddingOf(context).top,
            // Measured rather than derived from a multiplier: a sliver header
            // must know its extent before it lays out, and a guess at the line
            // height of whichever font the locale selected overflows.
            controlsHeight: _textHeight(
              _StepCounter.styleFor(context),
              // The widest step label this lesson can show.
              '${flow.sections.length} / ${flow.sections.length}',
            ),
            palette: context.riksa,
            backTooltip: MaterialLocalizations.of(context).backButtonTooltip,
            askAiTooltip: AppLocalizations.of(context)!.aiAskAboutLesson,
            onBack: () => _handleExit(flow),
            onAskAi: onAskAi,
            onSections: () => _showSections(flow),
          ),
        ),
        SliverToBoxAdapter(
          child: _LessonIdentity(title: detail.title, subject: subject),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          sliver: SliverList.list(
            children: [
              _JourneyStages(phase: flow.phase),
              const SizedBox(height: RiksaSpacing.lg),
              if (flow.phase == _LessonPhase.reading) ...[
                _LessonArtCard(subject: subject),
                const SizedBox(height: RiksaSpacing.lg),
              ],
              RiksaContentReveal(
                identity: (
                  flow.section.index,
                  flow.phase,
                  flow.exercise?.id,
                ),
                child: switch (flow.phase) {
                  _LessonPhase.reading => _contentView(flow),
                  _LessonPhase.practising ||
                  _LessonPhase.answerChecked => _practiceView(detail, flow),
                  _LessonPhase.sectionPassed => _sectionPassedView(
                    flow.following!,
                  ),
                  _LessonPhase.reflecting => _reflectionView(detail),
                },
              ),
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

  void _showSections(_LessonFlow flow) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.lessonSections,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final section in flow.sections)
                ListTile(
                  key: ValueKey('lesson-step-${section.index}'),
                  title: Text(section.title),
                  leading: Text('${flow.sections.indexOf(section) + 1}'),
                  selected: section.index == flow.section.index,
                  trailing:
                      section.exercises.isNotEmpty &&
                          section.exercises.every(_isCorrect)
                      ? Icon(Icons.check_rounded, color: context.riksa.jade)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _changeStep(() {
                      _activeSectionIndex = section.index;
                      _showPractice = false;
                      _feedbackExerciseId = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contentView(_LessonFlow flow) {
    final section = flow.section;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: MarkdownBody(
        key: ValueKey(
          section.index == 1
              ? 'lesson-description-markdown'
              : 'lesson-section-markdown-${section.index}',
        ),
        data: section.content.trim().isEmpty ? section.title : section.content,
        selectable: true,
        softLineBreak: true,
        inlineSyntaxes: RiksaMathText.markdownSyntaxes,
        builders: RiksaMathText.markdownBuilders,
        styleSheet: _lessonMarkdownStyleSheet(
          context,
          hasKhmer: RiksaTypography.containsKhmer(section.content),
        ),
      ),
    );
  }

  Widget _practiceView(LessonDetail detail, _LessonFlow flow) {
    final section = flow.section;
    final exercise = flow.exercise!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: RiksaSpacing.xxs + 2),
        Text(
          l10n.lessonResponseProgress(
            section.exercises.where(_isCorrect).length,
            section.exercises.length,
          ),
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
          working: _working.putIfAbsent(exercise.id, TextEditingController.new),
          feedbackKey: _feedbackAnchor,
          result: _results[exercise.id],
          submitting: _submitting.contains(exercise.id),
          // The answer lives in a controller the action bar reads, so every
          // keystroke and every tapped choice has to reach this state or the
          // bar's "Check answer" would stay dead.
          onAnswerChanged: () => setState(() {
            if (_results[exercise.id]?.correct == false) {
              _results.remove(exercise.id);
            }
          }),
        ),
      ],
    );
  }

  Widget _sectionPassedView(_LessonSection next) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RiksaSuccessMark(label: l10n.lessonSectionComplete),
      const SizedBox(height: RiksaSpacing.sm),
      Text(
        l10n.lessonSectionComplete,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: RiksaSpacing.xxs + 2),
      Text(
        '${l10n.lessonUpNext}: ${next.title}',
        style: TextStyle(color: context.riksa.inkMuted),
      ),
    ],
  );

  Widget _reflectionView(LessonDetail detail) {
    if (detail.state == LessonProgressState.completed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lessonCompletionReward,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(l10n.lessonCompletedBody),
        ],
      );
    }
    final palette = context.riksa;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.lessonReflectionTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: RiksaSpacing.sm),
        Text(
          detail.reflectionPrompt.trim().isEmpty
              ? l10n.lessonReflectionBody
              : detail.reflectionPrompt,
          style: theme.textTheme.bodyLarge?.copyWith(color: palette.inkMuted),
        ),
        const SizedBox(height: RiksaSpacing.lg),
        TextField(
          key: const ValueKey('lesson-reflection'),
          controller: _reflection,
          style: RiksaTypography.bodyStyleFor(
            l10n.lessonReflectionHint,
            theme.textTheme.bodyLarge,
          ),
          minLines: 4,
          maxLines: 8,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.lessonReflectionHint,
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
        const SizedBox(height: RiksaSpacing.lg),
        Text(l10n.lessonConfidencePrompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: RiksaSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('lesson-reflection-confident'),
              label: Text(l10n.lessonConfident),
              selected: _needsReview == false,
              onSelected: (_) => setState(() => _needsReview = false),
            ),
            ChoiceChip(
              key: const ValueKey('lesson-reflection-review'),
              label: Text(l10n.lessonNeedsReview),
              selected: _needsReview == true,
              onSelected: (_) => setState(() => _needsReview = true),
            ),
          ],
        ),
        if (_reflection.text.trim().isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.lessonReflectionRequired,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.inkMuted),
          ),
        ],
      ],
    );
  }

  Widget _emptyLesson(LessonDetail detail) => SafeArea(
    top: false,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [const _NoExercises()],
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

    final exercise = flow.exercise;
    return switch (flow.phase) {
      _LessonPhase.reading => () {
        final hasPractice = flow.section.exercises.any((e) => !_isCorrect(e));
        final label = hasPractice
            ? l10n.lessonTrySection
            : flow.following == null
            ? l10n.lessonReflectAction
            : l10n.continueLabel;
        return LearningActionBar(
          primaryKey: ValueKey('start-section-${flow.section.index}'),
          primaryLabel: label,
          primaryIcon: hasPractice ? null : Icons.arrow_forward_rounded,
          onPrimary: () => _changeStep(() => _showPractice = true),
        );
      }(),
      _LessonPhase.practising => LearningActionBar(
        primaryKey: const ValueKey('check-answer'),
        primaryLabel: l10n.lessonCheckAnswer,
        busy: _submitting.contains(exercise!.id),
        onPrimary: answer.isEmpty
            ? null
            : () => _submitAnswer(exercise, flow.section),
      ),
      _LessonPhase.answerChecked => LearningActionBar(
        primaryKey: const ValueKey('continue-after-answer'),
        primaryLabel: l10n.continueLabel,
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimary: () => _changeStep(() => _feedbackExerciseId = null),
      ),
      _LessonPhase.sectionPassed => LearningActionBar(
        primaryKey: ValueKey('continue-to-section-${flow.following!.index}'),
        primaryLabel: l10n.continueReading,
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimary: () => _changeStep(() {
          _activeSectionIndex = flow.following!.index;
          _showPractice = false;
        }),
      ),
      _LessonPhase.reflecting => LearningActionBar(
        primaryKey: const ValueKey('complete-lesson'),
        primaryLabel: isCompleted
            ? l10n.lessonRoadmapAction
            : l10n.lessonSaveReflection,
        primaryIcon: isCompleted ? null : Icons.check_rounded,
        busy: _completing,
        onPrimary: isCompleted
            ? () => context.go(
                detail.categoryId == null
                    ? '/learn'
                    : '/learn/roadmap/${Uri.encodeComponent(detail.categoryId!)}',
              )
            : _reflection.text.trim().isEmpty
            ? null
            : () => _complete(detail),
      ),
    };
  }

  bool _hasActiveSessionProgress(_LessonFlow? flow) {
    if (_completing) return false;
    if (_working.values.any((c) => c.text.trim().isNotEmpty)) return true;
    if (_answers.values.any((c) => c.text.trim().isNotEmpty)) return true;
    if (_reflection.text.trim().isNotEmpty) return true;
    if (_showPractice) return true;

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
              child: Center(
                child: _PixelAlertIcon(
                  color: theme.colorScheme.error,
                  size: 24,
                ),
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
          l10n.lessonExitBody,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            key: const ValueKey('leave-lesson-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              isKhmer ? 'បន្តរៀន' : 'Keep Learning',
              style: TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
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
        setState(() {
          _activeSectionIndex = section.index;
          _results[exercise.id] = result;
          if (result.correct) _feedbackExerciseId = exercise.id;
        });
        _soundForAnswer(result, section);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final feedbackContext = _feedbackAnchor.currentContext;
          if (!mounted || feedbackContext == null) return;
          Scrollable.ensureVisible(
            feedbackContext,
            alignment: 0.3,
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            curve: RiksaMotion.standardCurve,
          );
        });
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _submitting.remove(exercise.id));
    }
  }

  Future<void> _complete(LessonDetail detail) async {
    if (_completing || _reflection.text.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _completing = true);
    try {
      final userNotes = _reflection.text.trim();
      final confidence = _needsReview == null
          ? null
          : _needsReview!
          ? l10n.lessonNeedsReview
          : l10n.lessonConfident;
      final reflectionPayload = [
        if (confidence != null) '[$confidence]',
        userNotes,
        for (final exercise in detail.exercises)
          if (_working[exercise.id]?.text.trim().isNotEmpty == true)
            '${exercise.question}\n${_working[exercise.id]!.text.trim()}',
      ].join('\n\n');
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
      ref
        ..invalidate(profileDashboardProvider)
        ..invalidate(profileRankProvider)
        ..invalidate(communityStreakProvider);
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
            : '?roadmapCategoryId=${Uri.encodeComponent(roadmapCategoryId)}';
        context.go(
          '/learn/completion$suffix',
          extra: {
            'xpEarned': result.xpEarned,
            'lessonTitle': detail.title,
            'categoryName': detail.categoryName,
            'totalExercises': detail.exercises.length,
            'reflection': userNotes,
            'needsReview': _needsReview == true,
            'lessonId': detail.id,
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
              index == 0 ? 0 : matches[index].start,
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
      l10n.lessonRespond;

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

class _PixelAlertIcon extends StatelessWidget {
  const _PixelAlertIcon({required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PixelAlertIconPainter(color)),
  );
}

class _PixelAlertIconPainter extends CustomPainter {
  const _PixelAlertIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 16;
    final outline = Paint()
      ..color = Color.lerp(color, Colors.black, .24)!
      ..style = PaintingStyle.fill;
    final fill = Paint()
      ..color = color.withValues(alpha: .2)
      ..style = PaintingStyle.fill;
    final main = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: .48)
      ..style = PaintingStyle.fill;

    void px(Paint paint, int x, int y, [int w = 1, int h = 1]) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    px(outline, 7, 1, 2, 1);
    px(outline, 6, 2, 4, 2);
    px(outline, 5, 4, 6, 2);
    px(outline, 4, 6, 8, 2);
    px(outline, 3, 8, 10, 2);
    px(outline, 2, 10, 12, 3);
    px(outline, 1, 13, 14, 2);

    px(fill, 7, 3, 2, 1);
    px(fill, 6, 4, 4, 2);
    px(fill, 5, 6, 6, 2);
    px(fill, 4, 8, 8, 2);
    px(fill, 3, 10, 10, 2);
    px(fill, 2, 13, 12, 1);

    px(main, 7, 5, 2, 5);
    px(main, 7, 12, 2, 2);
    px(shine, 6, 5, 1, 2);
    px(shine, 5, 8, 1, 1);
  }

  @override
  bool shouldRepaint(covariant _PixelAlertIconPainter oldDelegate) =>
      oldDelegate.color != color;
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

class _LessonBarDelegate extends SliverPersistentHeaderDelegate {
  const _LessonBarDelegate({
    required this.lessonId,
    required this.flow,
    required this.topInset,
    required this.controlsHeight,
    required this.palette,
    required this.backTooltip,
    required this.askAiTooltip,
    required this.onBack,
    required this.onAskAi,
    required this.onSections,
  });
  final String lessonId, backTooltip, askAiTooltip;
  final _LessonFlow flow;
  final double topInset, controlsHeight;
  final RiksaPalette palette;
  final VoidCallback onBack, onAskAi, onSections;

  double get _rowHeight => math.max(48, controlsHeight + 16);
  @override
  double get maxExtent => topInset + _rowHeight + 20;
  @override
  double get minExtent => maxExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final l10n = AppLocalizations.of(context)!;
    final position = flow.sections.indexOf(flow.section) + 1;
    return ColoredBox(
      color: palette.canvas,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topInset, 20, 8),
        child: Column(
          children: [
            SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  LearningCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: backTooltip,
                    onTap: onBack,
                  ),
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('lesson-sections'),
                      onPressed: onSections,
                      child: Semantics(
                        label: l10n.lessonSectionCounter(
                          position,
                          flow.sections.length,
                        ),
                        excludeSemantics: true,
                        child: Text(
                          '$position / ${flow.sections.length}',
                          style: _StepCounter.styleFor(context),
                        ),
                      ),
                    ),
                  ),
                  LearningCircleButton(
                    key: const ValueKey('lesson-ask-ai'),
                    icon: Icons.auto_awesome_rounded,
                    tooltip: askAiTooltip,
                    onTap: onAskAi,
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final saved = ref
                          .watch(savedLessonsProvider)
                          .contains(lessonId);
                      final sound = ref.watch(soundEnabledProvider);
                      return PopupMenuButton<String>(
                        key: const ValueKey('lesson-options'),
                        tooltip: l10n.lessonOptions,
                        icon: const Icon(Icons.more_horiz_rounded),
                        onSelected: (value) {
                          if (value == 'save') {
                            ref
                                .read(savedLessonsProvider.notifier)
                                .toggle(lessonId);
                          }
                          if (value == 'sound') {
                            ref.read(soundEnabledProvider.notifier).toggle();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'save',
                            key: const ValueKey('lesson-bookmark-toggle'),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                saved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                              ),
                              title: Text(
                                saved ? l10n.lessonUnsave : l10n.lessonSave,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'sound',
                            key: const ValueKey('lesson-sound-toggle'),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                sound
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                              ),
                              title: Text(
                                sound ? l10n.lessonMute : l10n.lessonUnmute,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              label: l10n.lessonSectionCounter(position, flow.sections.length),
              value: '${(flow.progress * 100).round()}%',
              child: LearningTrack(
                key: const ValueKey('lesson-progress-track'),
                value: flow.progress,
                color: AppColors.progressGreen,
                background: palette.surfaceRaised,
                height: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LessonBarDelegate oldDelegate) => true;
}

class _LessonIdentity extends StatelessWidget {
  const _LessonIdentity({required this.title, required this.subject});
  final String title, subject;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subject,
          style: RiksaTypography.bodyStyleFor(
            subject,
            Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: context.riksa.inkMuted),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: RiksaTypography.titleStyleFor(
            title,
            Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// The picture at the head of a reading step: the subject's pastel, its
/// icon drawn large, and the mascot taking notes.
class _LessonArtCard extends StatelessWidget {
  const _LessonArtCard({required this.subject});
  final String subject;

  @override
  Widget build(BuildContext context) {
    final stem = stemSubjectFor(subject);
    final tone = subjectTone(context, stem);
    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('lesson-art-card'),
        height: 164,
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: AppRadii.extraLargeBorder,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: -30,
              bottom: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.accent.withValues(alpha: .1),
                ),
              ),
            ),
            Positioned(
              left: 36,
              top: 26,
              child: StemSubjectTile(subject: stem, size: 108),
            ),
            const Positioned(
              right: 22,
              bottom: 12,
              child: RiksaMascot(size: 112, pose: RiksaMascotPose.pencil),
            ),
            Positioned(
              right: 28,
              top: 18,
              child: RiksaDoodle(
                RiksaDoodleKind.sparkle,
                size: 20,
                color: tone.accent,
              ),
            ),
            const Positioned(
              left: 150,
              top: 22,
              child: RiksaDoodle(
                RiksaDoodleKind.squiggle,
                size: 26,
                color: AppColors.lime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCounter {
  static TextStyle styleFor(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: context.riksa.ink,
  );
}

class _JourneyStages extends StatelessWidget {
  const _JourneyStages({required this.phase});
  final _LessonPhase phase;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = switch (phase) {
      _LessonPhase.reading => 0,
      _LessonPhase.reflecting => 2,
      _ => 1,
    };
    final labels = [l10n.lessonRead, l10n.lessonRespond, l10n.lessonReflect];
    final palette = context.riksa;
    // Numbered circles joined by a rail, as on the reference step indicator.
    // Labels give way first when space runs out, so large text never pushes
    // the row past the screen edge.
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i <= active ? palette.brand : palette.outline,
              ),
            ),
          Flexible(
            flex: 4,
            child: Semantics(
              selected: i == active,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MediaQuery.withNoTextScaling(
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= active ? palette.brand : palette.surface,
                        border: Border.all(
                          color: i <= active ? palette.brand : palette.outline,
                        ),
                      ),
                      child: i < active
                          ? Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: palette.onBrand,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: i == active
                                    ? palette.onBrand
                                    : palette.inkMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        labels[i],
                        TextStyle(
                          fontSize: 12,
                          fontWeight: i == active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: i == active ? palette.ink : palette.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    required this.number,
    required this.exercise,
    this.lessonTitle,
    required this.controller,
    required this.result,
    required this.submitting,
    required this.onAnswerChanged,
    required this.working,
    required this.feedbackKey,
  });
  final int number;
  final LessonExercise exercise;
  final String? lessonTitle;
  final TextEditingController controller;
  final LessonAnswerResult? result;
  final bool submitting;
  final VoidCallback onAnswerChanged;
  final TextEditingController working;
  final Key feedbackKey;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _scratchpadOpen = false;

  void _askAiHint(BuildContext context) {
    final optionsText = widget.exercise.options.isNotEmpty
        ? '\nOptions: ${widget.exercise.options.join(", ")}'
        : '';
    final hintContext =
        '''
Exercise Hint Request:
Lesson: ${widget.lessonTitle ?? "STEM Lesson"}
Question: ${widget.exercise.question}
Type: ${widget.exercise.type.name}$optionsText

Learner Goal: Provide a progressive Socratic hint in Khmer/English to help the student think through this question without giving away the direct answer.
''';
    context.push('/ai/chat/new', extra: hintContext);
  }

  void _explainErrorWithAi(BuildContext context) {
    final userAnswer = widget.controller.text.trim();
    final explainContext =
        '''
Exercise Error Analysis:
Lesson: ${widget.lessonTitle ?? "STEM Lesson"}
Question: ${widget.exercise.question}
Learner Selected Answer: ${userAnswer.isEmpty ? "None selected" : userAnswer}
${widget.exercise.hint != null ? "Static Hint: ${widget.exercise.hint}" : ""}

Learner Goal: Explain why '${userAnswer.isEmpty ? "the selected answer" : userAnswer}' is incorrect, breakdown the core concept step-by-step in Khmer/English, and guide the student to the correct solution.
''';
    context.push('/ai/chat/new', extra: explainContext);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final l10n = AppLocalizations.of(context)!;
    final correct = widget.result?.correct == true;
    final incorrect = widget.result != null && !correct;
    final isText = widget.exercise.type == LessonExerciseType.text;

    return Container(
      key: ValueKey('lesson-exercise-${widget.exercise.id}'),
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
                l10n.lessonExerciseNumber(widget.number),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: RiksaSpacing.sm),
          MarkdownBody(
            data: widget.exercise.question,
            inlineSyntaxes: RiksaMathText.markdownSyntaxes,
            builders: RiksaMathText.markdownBuilders,
            styleSheet: _lessonMarkdownStyleSheet(
              context,
              hasKhmer: RiksaTypography.containsKhmer(widget.exercise.question),
            ),
          ),
          const SizedBox(height: RiksaSpacing.md),
          if (isText) ...[
            TextField(
              key: ValueKey('lesson-answer-${widget.exercise.id}'),
              minLines: 2,
              maxLines: 6,
              controller: widget.controller,
              enabled: !correct && !widget.submitting,
              textInputAction: TextInputAction.done,
              onChanged: (_) => widget.onAnswerChanged(),
              decoration: InputDecoration(
                hintText: l10n.lessonAnswerHint,
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
          ] else ...[
            _ChoiceAnswers(
              exercise: widget.exercise,
              controller: widget.controller,
              enabled: !correct && !widget.submitting,
              result: widget.result,
              onChanged: widget.onAnswerChanged,
            ),
            const SizedBox(height: RiksaSpacing.xs),
            if (!correct) ...[
              if (!_scratchpadOpen && widget.working.text.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: ValueKey('toggle-working-${widget.exercise.id}'),
                    onPressed: () => setState(() => _scratchpadOpen = true),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(
                      l10n.lessonWorkFirst,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.inkMuted,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
              if (_scratchpadOpen || widget.working.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                TextField(
                  key: ValueKey('lesson-working-${widget.exercise.id}'),
                  controller: widget.working,
                  style: RiksaTypography.bodyStyleFor(
                    l10n.lessonWorkHint,
                    Theme.of(context).textTheme.bodyMedium,
                  ),
                  minLines: 2,
                  maxLines: 5,
                  onChanged: (_) => widget.onAnswerChanged(),
                  decoration: InputDecoration(
                    hintText: l10n.lessonWorkHint,
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
            ] else if (widget.working.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Feedback(
                label: l10n.lessonYourWork,
                text: widget.working.text,
              ),
            ],
          ],
          if (!correct) ...[
            const SizedBox(height: RiksaSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('lesson-ai-hint'),
                onPressed: () => _askAiHint(context),
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: Text(l10n.lessonAiHint),
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
          if (widget.result != null) ...[
            const SizedBox(height: RiksaSpacing.sm),
            Semantics(
              key: widget.feedbackKey,
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: correct ? palette.jadeSoft : palette.creamSoft,
                  borderRadius: AppRadii.largeBorder,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      correct
                          ? Icons.check_circle_rounded
                          : Icons.lightbulb_outline_rounded,
                      color: correct ? palette.jade : palette.saffron,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        correct
                            ? l10n.lessonAnswerSuccess
                            : l10n.lessonAnswerRetry,
                        style: RiksaTypography.bodyStyleFor(
                          correct
                              ? l10n.lessonAnswerSuccess
                              : l10n.lessonAnswerRetry,
                          Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.result!.message.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.result!.message,
                style: TextStyle(color: palette.inkMuted),
              ),
            ],
            if (incorrect) ...[
              const SizedBox(height: RiksaSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _explainErrorWithAi(context),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(l10n.lessonExplainAnswer),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                ),
              ),
            ],
            if (incorrect &&
                (widget.result!.hint ?? widget.exercise.hint)?.trim().isNotEmpty == true)
              _Feedback(
                label: l10n.lessonHint,
                text: widget.result!.hint ?? widget.exercise.hint!,
              ),
            if ((incorrect || correct) &&
                (widget.result!.explanation ?? widget.exercise.explanation)
                        ?.trim()
                        .isNotEmpty ==
                    true)
              _Feedback(
                label: l10n.lessonWhy,
                text: widget.result!.explanation ?? widget.exercise.explanation!,
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

    return RiksaTapFeedback(
      enabled: widget.enabled,
      child: Material(
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
                  child: RiksaMathText(
                    text: option,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ink,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
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
    child: RiksaMathText(
      text: '$label: $text',
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IllustratedEmptyState(
      title: l10n.lessonDetailLoadFailed,
      body: l10n.loadFailedCheckConnection,
      actionLabel: l10n.tryAgain,
      onAction: onRetry,
      secondaryLabel: l10n.backToSubjects,
      onSecondary: () => context.go('/learn'),
    );
  }
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
        ? const [
            RiksaTypography.khmerLegacyBodyFamily,
            RiksaTypography.khmerFamily,
            RiksaTypography.latinFamily,
          ]
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
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}
