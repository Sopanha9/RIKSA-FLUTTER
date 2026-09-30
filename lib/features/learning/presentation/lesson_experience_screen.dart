import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sound/learning_sound.dart';
import '../../../core/sound/sound_provider.dart';
import '../../../core/notifications/streak_reminder_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/presentation/require_account.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mascot/domain/buddy_care.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/mascot_scene.dart';
import '../../mascot/presentation/widgets/mascot_face.dart';
import '../../mascot/presentation/widgets/mascot_view.dart';
import '../../mascot/providers/buddy_care_provider.dart';
import '../../mascot/providers/mascot_provider.dart';
import '../../resources/presentation/lesson_resources_sheet.dart';
import '../../resources/providers/lesson_resources_provider.dart';
import '../data/guest_answer_check_counter.dart';
import '../../quests/providers/today_quests_provider.dart';
import '../../userProfile/providers/profile_provider.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import '../providers/learning_roadmap_provider.dart';
import '../providers/lesson_catalog_provider.dart';
import '../providers/saved_lessons_provider.dart';
import 'learning_design.dart';
import 'widgets/learning_atoms.dart';
import 'widgets/lesson/lesson_answer_feedback.dart';
import 'widgets/learning_status_bar.dart';
import '../../../core/widgets/markdown_math.dart';

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
    required this.following,
    required this.progress,
  });

  final List<_LessonSection> sections;
  final _LessonSection section;
  final _LessonPhase phase;

  /// The exercise being answered, when [phase] is [_LessonPhase.practising].
  final LessonExercise? exercise;

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
  final _guestCorrectAnswers = <String, String>{};
  final _syncedGuestAnswers = <String>{};
  final _submitting = <String>{};
  final _reflection = TextEditingController();
  int? _activeSectionIndex;
  bool _showPractice = false;
  bool _completing = false;
  bool _showReflectionInput = false;
  Future<void>? _guestAnswerSync;
  final _working = <String, TextEditingController>{};
  final _comparedAnswers = <String>{};
  final _expandedWorking = <String>{};
  final _scroll = ScrollController();
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
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous is! Authenticated &&
          next is Authenticated &&
          _guestCorrectAnswers.isNotEmpty) {
        unawaited(
          _syncGuestCorrectAnswers().catchError((Object error) {
            if (mounted) _showError(error);
          }),
        );
      }
    });
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

    final sectionIndex = sections.indexOf(section);
    final sectionTotal = section.exercises.length;
    final sectionDone = section.exercises.where(_isCorrect).length;
    final sectionProgress = switch (phase) {
      _LessonPhase.reading => .08,
      _LessonPhase.practising =>
        .32 + .42 * (sectionTotal == 0 ? 0 : sectionDone / sectionTotal),
      _LessonPhase.answerChecked =>
        .34 + .42 * (sectionTotal == 0 ? 0 : sectionDone / sectionTotal),
      _LessonPhase.sectionPassed => .9,
      _LessonPhase.reflecting => 1,
    };
    return _LessonFlow(
      sections: sections,
      section: section,
      phase: phase,
      exercise: feedback ?? (phase == _LessonPhase.practising ? pending : null),
      following: following,
      // Each section moves through Read → Respond → Reflect, with correct
      // answers advancing the fill within Respond.
      progress: ((sectionIndex + sectionProgress) / sections.length).clamp(
        0.0,
        1.0,
      ).toDouble(),
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
          message: l10n.lessonRestoredProgress,
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
      '/ai/chat/new'
      '?lesson=${Uri.encodeQueryComponent(detail.title)}'
      '&context=${Uri.encodeQueryComponent('$subject - ${flow.section.title}')}',
      extra:
          'Lesson: ${detail.title}\n'
          'Subject: ${detail.categoryName}\n'
          'Content: ${detail.description}',
    );
    final content = CustomScrollView(
      controller: _scroll,
      slivers: [
        // Navigation and progress stay; the identity block does not. Reading is
        // the one place the product's chrome is supposed to retreat, and a
        // learner who is three paragraphs in already knows what they opened.
        SliverPersistentHeader(
          pinned: true,
          delegate: _LessonBarDelegate(
            flow: flow,
            topInset: MediaQuery.paddingOf(context).top,
            palette: context.riksa,
            onBack: () => _handleExit(flow),
            onOptions: () => _showLessonOptions(
              detail,
              flow,
              onAskAi: onAskAi,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(
                width: double.infinity,
                child: _LessonIdentity(title: detail.title, subject: subject),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 170),
          sliver: SliverList.list(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _JourneyStages(phase: flow.phase),
                      if (flow.phase == _LessonPhase.reading) ...[
                        const SizedBox(height: RiksaSpacing.md),
                        _LessonBuddyScene(subject: subject),
                      ],
                      SizedBox(
                        height: flow.phase == _LessonPhase.reading
                            ? RiksaSpacing.lg
                            : RiksaSpacing.md,
                      ),
                      RiksaContentReveal(
                        identity: (
                          flow.section.index,
                          flow.phase,
                          flow.exercise?.id,
                          _comparedAnswers.contains(flow.exercise?.id),
                        ),
                        child: switch (flow.phase) {
                          _LessonPhase.reading => _contentView(flow),
                          _LessonPhase.practising ||
                          _LessonPhase.answerChecked =>
                            _practiceView(detail, flow),
                          _LessonPhase.sectionPassed => _sectionPassedView(
                            flow.following!,
                          ),
                          _LessonPhase.reflecting => _reflectionView(detail),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final exercise = flow.exercise;
    final result = flow.phase == _LessonPhase.answerChecked && exercise != null
        ? _results[exercise.id]
        : null;
    return Stack(
      children: [
        content,
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: LessonAnswerFeedbackPanel(
            key: const ValueKey('lesson-feedback-panel'),
            exercise: exercise,
            result: result,
          ),
        ),
      ],
    );
  }

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
                style: RiksaTypography.titleStyleFor(
                  l10n.lessonSections,
                  Theme.of(context).textTheme.titleLarge,
                  khmerHeight: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              for (final section in flow.sections)
                ListTile(
                  key: ValueKey('lesson-step-${section.index}'),
                  title: Text(
                    section.title,
                    style: RiksaTypography.titleStyleFor(
                      section.title,
                      Theme.of(context).textTheme.titleMedium,
                      khmerHeight: 1.5,
                    ),
                  ),
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

  Future<void> _showLessonOptions(
    LessonDetail detail,
    _LessonFlow flow, {
    required VoidCallback onAskAi,
  }) async {
    final saved = ref.read(savedLessonsProvider).contains(detail.id);
    final soundEnabled = ref.read(soundEnabledProvider);
    final resourceCount =
        ref.read(lessonResourcesProvider(detail.id)).value?.resources.length ??
        0;
    final exercise = flow.exercise;
    Text optionLabel(String text) => Text(
      text,
      style: _lessonBodyStyle(text, Theme.of(context).textTheme.bodyLarge),
    );

    void openResources(BuildContext sheetContext) {
      Navigator.pop(sheetContext);
      showLessonResourcesSheet(
        context,
        lessonId: detail.id,
        lessonTitle: detail.title,
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                l10n.lessonOptions,
                style: RiksaTypography.titleStyleFor(
                  l10n.lessonOptions,
                  Theme.of(context).textTheme.titleMedium,
                  khmerHeight: 1.5,
                ),
              ),
            ),
            ListTile(
              key: const ValueKey('lesson-options-sections'),
              leading: const Icon(Icons.menu_book_outlined),
              title: optionLabel(l10n.lessonSections),
              onTap: () {
                Navigator.pop(sheetContext);
                _showSections(flow);
              },
            ),
            ListTile(
              key: const ValueKey('lesson-ask-ai'),
              leading: const Icon(Icons.auto_awesome_rounded),
              title: optionLabel(
                AppLocalizations.of(context)!.aiAskAboutLesson,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                onAskAi();
              },
            ),
            if (exercise != null &&
                (flow.phase == _LessonPhase.practising ||
                    flow.phase == _LessonPhase.answerChecked)) ...[
              ListTile(
                key: const ValueKey('lesson-ai-hint'),
                leading: const Icon(Icons.lightbulb_outline_rounded),
                title: optionLabel(l10n.lessonAiHint),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _askAiHint(context, exercise, detail.title);
                },
              ),
              if (exercise.type != LessonExerciseType.text)
                ListTile(
                  key: ValueKey('lesson-options-working-${exercise.id}'),
                  leading: const Icon(Icons.edit_outlined),
                  title: optionLabel(l10n.lessonAddWorkingOptional),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _expandedWorking.add(exercise.id));
                  },
                ),
              if (exercise.type != LessonExerciseType.text &&
                  !_comparedAnswers.contains(exercise.id))
                ListTile(
                  key: ValueKey('lesson-worked-on-paper-${exercise.id}'),
                  leading: const Icon(Icons.checklist_rounded),
                  title: optionLabel(l10n.lessonWorkedOnPaper),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _changeStep(() => _comparedAnswers.add(exercise.id));
                  },
                ),
              if (_results[exercise.id]?.correct == false)
                ListTile(
                  key: const ValueKey('lesson-explain-answer'),
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: optionLabel(l10n.lessonExplainAnswer),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _explainErrorWithAi(
                      context,
                      exercise,
                      detail.title,
                      _answers[exercise.id]?.text.trim() ?? '',
                    );
                  },
                ),
            ],
            ListTile(
              key: const ValueKey('lesson-resources-open'),
              leading: const Icon(Icons.library_books_outlined),
              title: optionLabel(l10n.resourceEntryCount(resourceCount)),
              onTap: () => openResources(sheetContext),
            ),
            ListTile(
              key: const ValueKey('lesson-report-resource'),
              leading: const Icon(Icons.flag_outlined),
              title: optionLabel(
                AppLocalizations.of(context)!.resourceReportAction,
              ),
              onTap: () => openResources(sheetContext),
            ),
            ListTile(
              key: const ValueKey('lesson-bookmark-toggle'),
              leading: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              ),
              title: optionLabel(saved ? l10n.lessonUnsave : l10n.lessonSave),
              onTap: () {
                if (requireAccount(context, ref, reason: 'save_lesson')) {
                  ref.read(savedLessonsProvider.notifier).toggle(detail.id);
                }
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              key: const ValueKey('lesson-sound-toggle'),
              leading: Icon(
                soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              ),
              title: optionLabel(
                soundEnabled ? l10n.lessonMute : l10n.lessonUnmute,
              ),
              onTap: () {
                ref.read(soundEnabledProvider.notifier).toggle();
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentView(_LessonFlow flow) {
    final section = flow.section;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: MarkdownBody(
        inlineSyntaxes: markdownMathSyntaxes,
        builders: markdownMathBuilders,
        key: ValueKey(
          section.index == 1
              ? 'lesson-description-markdown'
              : 'lesson-section-markdown-${section.index}',
        ),
        data: section.content.trim().isEmpty ? section.title : section.content,
        selectable: true,
        softLineBreak: true,
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
    final result = flow.phase == _LessonPhase.answerChecked
        ? _results[exercise.id]
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: RiksaTypography.bodyStyleFor(
            section.title,
            Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.riksa.inkMuted,
              height: RiksaTypography.containsKhmer(section.title) ? 1.6 : null,
            ),
          ),
        ),
        const SizedBox(height: RiksaSpacing.xs),
        _ExerciseCard(
          key: ValueKey('lesson-exercise-${exercise.id}'),
          exercise: exercise,
          controller: _answers.putIfAbsent(
            exercise.id,
            TextEditingController.new,
          ),
          working: _working.putIfAbsent(exercise.id, TextEditingController.new),
          showChoices: _comparedAnswers.contains(exercise.id),
          workingExpanded: _expandedWorking.contains(exercise.id),
          onExpandWorking: () =>
              setState(() => _expandedWorking.add(exercise.id)),
          onEditWorking: () =>
              _changeStep(() => _comparedAnswers.remove(exercise.id)),
          result: result,
          submitting: _submitting.contains(exercise.id),
          // The answer lives in a controller the action bar reads, so every
          // keystroke and every tapped choice has to reach this state or the
          // bar's "Check answer" would stay dead.
          onAnswerChanged: () => setState(() {
            if (_results[exercise.id]?.correct == false) {
              _results.remove(exercise.id);
              _feedbackExerciseId = null;
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
        style: RiksaTypography.titleStyleFor(
          l10n.lessonSectionComplete,
          Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          khmerHeight: 1.5,
        ),
      ),
      const SizedBox(height: RiksaSpacing.xxs + 2),
      Text(
        '${l10n.lessonUpNext}: ${next.title}',
        style: _lessonBodyStyle(
          '${l10n.lessonUpNext}: ${next.title}',
          Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.riksa.inkMuted,
          ),
        ),
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
            style: RiksaTypography.titleStyleFor(
              l10n.lessonCompletionReward,
              Theme.of(context).textTheme.headlineSmall,
              khmerHeight: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.lessonCompletedBody,
            style: _lessonBodyStyle(
              l10n.lessonCompletedBody,
              Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }
    final palette = context.riksa;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.lessonReflectionTitle,
          style: RiksaTypography.titleStyleFor(
            l10n.lessonReflectionTitle,
            theme.textTheme.headlineSmall,
            khmerHeight: 1.5,
          ),
        ),
        const SizedBox(height: RiksaSpacing.sm),
        Text(
          detail.reflectionPrompt.trim().isEmpty
              ? l10n.lessonReflectionBody
              : detail.reflectionPrompt,
          style: _lessonBodyStyle(
            detail.reflectionPrompt.trim().isEmpty
                ? l10n.lessonReflectionBody
                : detail.reflectionPrompt,
            theme.textTheme.bodyLarge?.copyWith(color: palette.inkMuted),
          ),
        ),
        const SizedBox(height: RiksaSpacing.lg),
        Text(
          l10n.lessonConfidencePrompt,
          style: RiksaTypography.titleStyleFor(
            l10n.lessonConfidencePrompt,
            theme.textTheme.titleMedium,
            khmerHeight: 1.5,
          ),
        ),
        const SizedBox(height: RiksaSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('lesson-reflection-confident'),
              label: Text(
                l10n.lessonConfident,
                style: _lessonBodyStyle(
                  l10n.lessonConfident,
                  theme.textTheme.labelLarge,
                ),
              ),
              selected: _needsReview == false,
              onSelected: (_) => setState(() => _needsReview = false),
            ),
            ChoiceChip(
              key: const ValueKey('lesson-reflection-review'),
              label: Text(
                l10n.lessonNeedsReview,
                style: _lessonBodyStyle(
                  l10n.lessonNeedsReview,
                  theme.textTheme.labelLarge,
                ),
              ),
              selected: _needsReview == true,
              onSelected: (_) => setState(() => _needsReview = true),
            ),
          ],
        ),
        const SizedBox(height: RiksaSpacing.md),
        ExpansionTile(
          key: const ValueKey('lesson-reflection-toggle'),
          expansionAnimationStyle: AnimationStyle(
            duration: RiksaMotion.resolve(context, RiksaMotion.standard),
            reverseDuration: RiksaMotion.resolve(
              context,
              RiksaMotion.standard,
            ),
            curve: RiksaMotion.standardCurve,
            reverseCurve: RiksaMotion.standardCurve,
          ),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(
            l10n.lessonReflectionAddOptional,
            style: _lessonBodyStyle(
              l10n.lessonReflectionAddOptional,
              theme.textTheme.titleMedium,
            ),
          ),
          initiallyExpanded: _showReflectionInput,
          onExpansionChanged: (expanded) =>
              setState(() => _showReflectionInput = expanded),
          children: [
            TextField(
              key: const ValueKey('lesson-reflection'),
              controller: _reflection,
              style: RiksaTypography.bodyStyleFor(
                l10n.lessonReflectionHint,
                theme.textTheme.bodyLarge,
              ),
              minLines: 3,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.lessonReflectionOptionalHint,
                hintStyle: _lessonBodyStyle(
                  l10n.lessonReflectionOptionalHint,
                  TextStyle(color: palette.inkMuted, fontSize: 13),
                ),
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
        ),
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
    final comparing =
        exercise != null &&
        exercise.type != LessonExerciseType.text &&
        !_comparedAnswers.contains(exercise.id);
    final working = exercise == null
        ? ''
        : _working[exercise.id]?.text.trim() ?? '';
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
        primaryKey: ValueKey(
          comparing
              ? (working.isEmpty ? 'show-choices' : 'compare-answers')
              : 'check-answer',
        ),
        primaryLabel: comparing
            ? (working.isEmpty
                  ? l10n.lessonShowChoices
                  : l10n.lessonCompareAnswers)
            : l10n.lessonCheckAnswer,
        busy: _submitting.contains(exercise!.id),
        onPrimary: comparing
            ? () => _changeStep(() => _comparedAnswers.add(exercise.id))
            : answer.isEmpty
            ? null
            : () => _submitAnswer(exercise, flow.section),
      ),
      _LessonPhase.answerChecked => LearningActionBar(
        primaryKey: const ValueKey('continue-after-answer'),
        primaryLabel: l10n.continueLabel,
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimary: () => _changeStep(() {
          final checkedExercise = flow.exercise;
          if (checkedExercise != null &&
              _results[checkedExercise.id]?.correct == false) {
            _results.remove(checkedExercise.id);
            _answers[checkedExercise.id]?.clear();
          }
          _feedbackExerciseId = null;
        }),
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
            : l10n.lessonFinishAction,
        primaryIcon: isCompleted ? null : Icons.check_rounded,
        busy: _completing,
        onPrimary: isCompleted
            ? () => _openCompletedRoadmap(detail.categoryId)
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

  // [force] skips the PopScope guard; maybePop would re-trigger the exit
  // dialog after the user already confirmed leaving.
  void _safePop({bool force = false}) {
    unawaited(
      RiksaBackButton.navigateBack(
        context,
        fallbackLocation: '/learn',
        saved: force,
      ),
    );
  }

  void _openCompletedRoadmap(String? categoryId) {
    if (categoryId == null) {
      context.go('/learn');
      return;
    }
    context.push('/learn/roadmap/${Uri.encodeComponent(categoryId)}');
  }

  Future<void> _handleExit(_LessonFlow? flow) async {
    if (!_hasActiveSessionProgress(flow)) {
      if (mounted) _safePop();
      return;
    }
    final shouldLeave = await _showExitConfirmationDialog();
    if (shouldLeave && mounted) {
      _safePop(force: true);
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
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
                l10n.lessonExitTitle,
                style: RiksaTypography.titleStyleFor(
                  l10n.lessonExitTitle,
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  khmerHeight: 1.5,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.lessonExitBody,
          style: _lessonBodyStyle(
            l10n.lessonExitBody,
            theme.textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            key: const ValueKey('leave-lesson-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.lessonKeepLearning,
              style: _lessonBodyStyle(
                l10n.lessonKeepLearning,
                TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
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
            child: Text(
              l10n.lessonLeaveAction,
              style: _lessonBodyStyle(
                l10n.lessonLeaveAction,
                Theme.of(dialogContext).textTheme.labelLarge,
              ),
            ),
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
    if (_submitting.contains(exercise.id)) return;
    final answer = _answers[exercise.id]?.text.trim() ?? '';
    if (answer.isEmpty) return;
    final authenticated = ref.read(authProvider) is Authenticated;
    setState(() => _submitting.add(exercise.id));
    try {
      if (!authenticated &&
          await ref.read(guestAnswerCheckCounterProvider).count() >= 3) {
        await _showSaveProgressPrompt();
        return;
      }
      final api = ref.read(learningApiProvider);
      final result = authenticated
          ? await api.submitAnswer(
              lessonId: widget.lessonId,
              exerciseId: exercise.id,
              answer: answer,
            )
          : await api.checkAnswer(
              lessonId: widget.lessonId,
              exerciseId: exercise.id,
              answer: answer,
            );
      if (authenticated && result.correct) {
        ref.read(questProgressSyncProvider).nudge();
      }
      final guestCheckCount = authenticated
          ? null
          : await ref.read(guestAnswerCheckCounterProvider).recordCheck();
      if (!authenticated && result.correct) {
        _guestCorrectAnswers[exercise.id] = answer;
      }
      if (mounted) {
        setState(() {
          _activeSectionIndex = section.index;
          _results[exercise.id] = result;
          _feedbackExerciseId = exercise.id;
        });
        _soundForAnswer(result, section);
      }
      if (!authenticated && result.correct && guestCheckCount! >= 3) {
        await _showSaveProgressPrompt();
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) {
        setState(() => _submitting.remove(exercise.id));
      } else {
        _submitting.remove(exercise.id);
      }
    }
  }

  Future<void> _complete(LessonDetail detail) async {
    if (_completing) return;
    if (ref.read(authProvider) is! Authenticated) {
      await _showSaveProgressPrompt();
      return;
    }
    final reminderNavigator = Navigator.of(context, rootNavigator: true);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _completing = true);
    try {
      await _syncGuestCorrectAnswers();
      final userNotes = _reflection.text.trim();
      final confidence = _needsReview == null
          ? null
          : _needsReview!
          ? l10n.lessonNeedsReview
          : l10n.lessonConfident;
      final reflectionPayload = [
        if (confidence != null) '[$confidence]',
        if (userNotes.isNotEmpty) userNotes,
      ].join('\n\n');
      final result = await ref
          .read(learningApiProvider)
          .completeLesson(
            lessonId: widget.lessonId,
            reflectionText: reflectionPayload,
          );
      await ref
          .read(buddyCareProvider.notifier)
          .recordLocalGain(BuddyCareSource.lesson, sourceId: detail.id);
      final buddyName =
          ref.read(mascotProvider).profile?.name ??
          MascotProfile.defaultName(MascotSpecies.crocodile);
      final streak =
          ref
              .read(profileDashboardProvider)
              .value
              ?.gamification
              .currentStreak ??
          0;
      final reminderTitle = streak > 0
          ? l10n.reminderNotificationTitle(buddyName, streak)
          : l10n.reminderNotificationTitleNoStreak(buddyName);
      final reminderBody = l10n.reminderNotificationBody;
      final reminderService = ref.read(streakReminderServiceProvider);
      unawaited(
        reminderService
            .recordLessonCompleted(title: reminderTitle, body: reminderBody)
            .catchError((Object error) {
              debugPrint('Streak reminder update failed: $error');
            }),
      );
      // Sounded before the awaits below: the fanfare should land with the tap,
      // not after the catalog and roadmaps have finished refetching.
      HapticFeedback.mediumImpact();
      ref.playSound(LearningSound.lessonComplete);
      ref
        ..invalidate(profileDashboardProvider)
        ..invalidate(profileRankProvider);
      ref.read(questProgressSyncProvider).nudge();
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!reminderNavigator.mounted) return;
          unawaited(
            _maybeOfferReminderPermission(
              navigator: reminderNavigator,
              strings: l10n,
              buddyName: buddyName,
              title: reminderTitle,
              body: reminderBody,
            ).catchError((Object error) {
              debugPrint('Streak reminder permission prompt failed: $error');
            }),
          );
        });
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _syncGuestCorrectAnswers() {
    final active = _guestAnswerSync;
    if (active != null) return active;
    final syncing = _performGuestAnswerSync();
    _guestAnswerSync = syncing;
    return syncing.whenComplete(() {
      if (identical(_guestAnswerSync, syncing)) _guestAnswerSync = null;
    });
  }

  Future<void> _performGuestAnswerSync() async {
    final api = ref.read(learningApiProvider);
    for (final entry in _guestCorrectAnswers.entries) {
      if (_syncedGuestAnswers.contains(entry.key)) continue;
      final result = await api.submitAnswer(
        lessonId: widget.lessonId,
        exerciseId: entry.key,
        answer: entry.value,
      );
      if (!result.correct) {
        throw StateError('A guest answer could not be saved to this account.');
      }
      _syncedGuestAnswers.add(entry.key);
      _results[entry.key] = result;
    }
  }

  Future<void> _showSaveProgressPrompt() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .82,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MascotFaceAvatar(
                  face: MascotFace.happy,
                  size: 68,
                  loops: 1,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.guestSaveProgressBuddyLine,
                  textAlign: TextAlign.center,
                  style: _lessonBodyStyle(
                    l10n.guestSaveProgressBuddyLine,
                    Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.guestSaveProgressTitle,
                  textAlign: TextAlign.center,
                  style: RiksaTypography.titleStyleFor(
                    l10n.guestSaveProgressTitle,
                    Theme.of(sheetContext).textTheme.headlineSmall,
                    khmerHeight: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.guestSaveProgressBody,
                  textAlign: TextAlign.center,
                  style: _lessonBodyStyle(
                    l10n.guestSaveProgressBody,
                    Theme.of(sheetContext).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('guest-save-progress-sign-in'),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          requireAccount(context, ref, reason: 'save_progress');
                        }
                      });
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: Text(
                      l10n.guestSaveProgressSignIn,
                      style: _lessonBodyStyle(
                        l10n.guestSaveProgressSignIn,
                        Theme.of(sheetContext).textTheme.labelLarge,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('guest-save-progress-later'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(
                    l10n.guestSaveProgressLater,
                    style: _lessonBodyStyle(
                      l10n.guestSaveProgressLater,
                      Theme.of(sheetContext).textTheme.labelLarge,
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

  Future<void> _maybeOfferReminderPermission({
    required NavigatorState navigator,
    required AppLocalizations strings,
    required String buddyName,
    required String title,
    required String body,
  }) async {
    final service = ref.read(streakReminderServiceProvider);
    final enabled = await service.isEnabled();
    final canRequest = await service.canRequestPermission();
    final hasPermission = await service.hasNotificationPermission();
    final canPrompt = await service.shouldShowPermissionPromptAfterLesson();
    if (!enabled ||
        !canRequest ||
        hasPermission ||
        !canPrompt ||
        !navigator.mounted) {
      return;
    }
    await service.markPermissionPromptShown();
    if (!navigator.mounted) return;
    final wantsReminder = await showModalBottomSheet<bool>(
      context: navigator.context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.reminderPermissionTitle,
                style: RiksaTypography.titleStyleFor(
                  strings.reminderPermissionTitle,
                  Theme.of(sheetContext).textTheme.titleLarge,
                  khmerHeight: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.reminderPermissionBody(buddyName),
                style: _lessonBodyStyle(
                  strings.reminderPermissionBody(buddyName),
                  Theme.of(sheetContext).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: Text(
                    strings.reminderPermissionAllow,
                    style: _lessonBodyStyle(
                      strings.reminderPermissionAllow,
                      Theme.of(sheetContext).textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('reminder-permission-cancel'),
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(
                  strings.cancel,
                  style: _lessonBodyStyle(
                    strings.cancel,
                    Theme.of(sheetContext).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (wantsReminder != true || !navigator.mounted) return;
    if (await service.requestPermission()) {
      await service.rescheduleIfEnabled(title: title, body: body);
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

  void _showError(Object error) {
    final message = _friendlyLessonError(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: _lessonBodyStyle(
            message,
            Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
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
    required this.flow,
    required this.topInset,
    required this.palette,
    required this.onBack,
    required this.onOptions,
  });
  final _LessonFlow flow;
  final double topInset;
  final RiksaPalette palette;
  final VoidCallback onBack, onOptions;

  @override
  double get maxExtent => topInset + 56;
  @override
  double get minExtent => maxExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: palette.canvas,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topInset + 4, 20, 4),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              RiksaBackButton(
                key: const ValueKey('lesson-back'),
                fallbackLocation: '/learn',
                onPressed: onBack,
                constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: palette.ink,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: RiksaSpacing.sm),
              Expanded(
                child: Semantics(
                  label: l10n.lessonSectionCounter(
                    flow.sections.indexOf(flow.section) + 1,
                    flow.sections.length,
                  ),
                  value: '${(flow.progress * 100).round()}%',
                  child: LearningTrack(
                    key: const ValueKey('lesson-progress-track'),
                    value: flow.progress,
                    color: palette.brand,
                    background: palette.surfaceRaised,
                    height: 3,
                  ),
                ),
              ),
              const SizedBox(width: RiksaSpacing.sm),
              IconButton(
                key: const ValueKey('lesson-options'),
                tooltip: l10n.lessonOptions,
                onPressed: onOptions,
                icon: const Icon(Icons.more_horiz_rounded),
                constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                color: palette.inkMuted,
              ),
            ],
          ),
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
            ).textTheme.labelMedium?.copyWith(
              color: context.riksa.inkMuted,
              height: RiksaTypography.containsKhmer(subject) ? 1.6 : null,
            ),
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
            khmerHeight: 1.5,
          ),
        ),
      ],
    ),
  );
}

/// A small, quiet mascot scene shown only on the lesson's Read step.
class _LessonBuddyScene extends ConsumerWidget {
  const _LessonBuddyScene({required this.subject});
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species =
        ref.watch(mascotProvider).profile?.species ?? MascotSpecies.crocodile;
    final stem = stemSubjectFor(subject);
    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('lesson-buddy-scene'),
        height: 116,
        decoration: const BoxDecoration(
          borderRadius: AppRadii.extraLargeBorder,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // The art directly rather than MascotSceneBackdrop: that one also
            // sets the status bar style, which would flip as this band scrolls
            // under the pinned header.
            Positioned.fill(
              child: Image.asset(
                MascotScenes.asset(species, Theme.of(context).brightness),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned(
              left: RiksaSpacing.md,
              top: RiksaSpacing.sm,
              child: StemSubjectTile(subject: stem, size: 42),
            ),
            Align(
              alignment: const Alignment(0, 1.08),
              child: MascotView(
                species: species,
                mood: MascotMood.idle,
                size: 88,
                alive: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Semantics(
      label: labels.join(', '),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: RiksaSpacing.xs,
        runSpacing: 2,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Text('·', style: TextStyle(color: palette.inkFaint)),
              ),
            Semantics(
              selected: i == active,
              child: Text(
                labels[i],
                style: RiksaTypography.bodyStyleFor(
                  labels[i],
                  TextStyle(
                    fontSize: 12,
                    fontWeight: i == active
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == active ? palette.brand : palette.inkFaint,
                    height: RiksaTypography.containsKhmer(labels[i])
                        ? 1.6
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ],
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
    super.key,
    required this.exercise,
    required this.controller,
    required this.result,
    required this.submitting,
    required this.onAnswerChanged,
    required this.working,
    required this.showChoices,
    required this.workingExpanded,
    required this.onExpandWorking,
    required this.onEditWorking,
  });
  final LessonExercise exercise;
  final TextEditingController controller;
  final LessonAnswerResult? result;
  final bool submitting;
  final VoidCallback onAnswerChanged;
  final TextEditingController working;
  final bool showChoices;
  final bool workingExpanded;
  final VoidCallback onExpandWorking;
  final VoidCallback onEditWorking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[
      MarkdownBody(
        key: ValueKey('lesson-question-${exercise.id}'),
        inlineSyntaxes: markdownMathSyntaxes,
        builders: markdownMathBuilders,
        data: exercise.question,
        styleSheet: _lessonMarkdownStyleSheet(
          context,
          hasKhmer: RiksaTypography.containsKhmer(exercise.question),
          questionHero: true,
        ),
      ),
      const SizedBox(height: RiksaSpacing.md),
    ];

    if (exercise.type == LessonExerciseType.text) {
      children.add(
        TextField(
          key: ValueKey('lesson-answer-${exercise.id}'),
          minLines: 2,
          maxLines: 6,
          controller: controller,
          enabled: result == null && !submitting,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onAnswerChanged(),
          style: _lessonBodyStyle(
            controller.text,
            Theme.of(context).textTheme.bodyLarge,
          ),
          decoration: InputDecoration(
            hintText: l10n.lessonAnswerHint,
            hintStyle: _lessonBodyStyle(
              l10n.lessonAnswerHint,
              TextStyle(color: context.riksa.inkMuted),
            ),
            filled: true,
            fillColor: context.riksa.surface,
          ),
        ),
      );
    } else if (showChoices) {
      if (working.text.trim().isNotEmpty) {
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: RiksaSpacing.xs),
                  child: Text(
                    working.text,
                    style: _lessonBodyStyle(
                      working.text,
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.riksa.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
              if (result == null)
                IconButton(
                  key: ValueKey('lesson-edit-working-${exercise.id}'),
                  tooltip: l10n.lessonEditWorking,
                  onPressed: onEditWorking,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                ),
            ],
          ),
        );
        children.add(const SizedBox(height: RiksaSpacing.xs));
      }
      children.add(
        LessonChoiceAnswers(
          exercise: exercise,
          controller: controller,
          enabled: result == null && !submitting,
          result: result,
          onChanged: onAnswerChanged,
        ),
      );
    } else {
      if (workingExpanded) {
        children.add(
          TextField(
            key: ValueKey('lesson-working-${exercise.id}'),
            controller: working,
            style: _lessonBodyStyle(
              l10n.lessonWorkHint,
              Theme.of(context).textTheme.bodyLarge,
            ),
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => onAnswerChanged(),
            decoration: InputDecoration(
              hintText: l10n.lessonWorkHint,
              filled: true,
              fillColor: context.riksa.surface,
            ),
          ),
        );
      } else {
        children.add(
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: ValueKey('lesson-add-working-${exercise.id}'),
              onPressed: onExpandWorking,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                l10n.lessonWriteWorking,
                style: _lessonBodyStyle(
                  l10n.lessonWriteWorking,
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.riksa.inkMuted,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                alignment: AlignmentDirectional.centerStart,
                foregroundColor: context.riksa.inkMuted,
                side: BorderSide(color: context.riksa.outline),
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(
                  horizontal: RiksaSpacing.md,
                  vertical: RiksaSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.mediumBorder,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

void _askAiHint(
  BuildContext context,
  LessonExercise exercise,
  String lessonTitle,
) {
  final optionsText = exercise.options.isNotEmpty
      ? '\nOptions: ${exercise.options.join(", ")}'
      : '';
  final hintContext =
      '''
Exercise Hint Request:
Lesson: $lessonTitle
Question: ${exercise.question}
Type: ${exercise.type.name}$optionsText

Learner Goal: Provide a progressive Socratic hint in Khmer/English to help the student think through this question without giving away the direct answer.
''';
  context.push('/ai/chat/new', extra: hintContext);
}

void _explainErrorWithAi(
  BuildContext context,
  LessonExercise exercise,
  String lessonTitle,
  String userAnswer,
) {
  final selectedAnswer = userAnswer.isEmpty ? 'None selected' : userAnswer;
  final explainContext =
      '''
Exercise Error Analysis:
Lesson: $lessonTitle
Question: ${exercise.question}
Learner Selected Answer: $selectedAnswer
${exercise.hint != null ? "Static Hint: ${exercise.hint}" : ""}

Learner Goal: Explain why '$selectedAnswer' is incorrect, breakdown the core concept step-by-step in Khmer/English, and guide the student to the correct solution.
''';
  context.push('/ai/chat/new', extra: explainContext);
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
  bool questionHero = false,
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
    height: hasKhmer && (style?.height ?? 0) < 1.5
        ? 1.6
        : style?.height,
  );
  TextStyle heading(TextStyle? style) => (style ?? const TextStyle()).copyWith(
    fontFamily: titleFont,
    fontFamilyFallback: hasKhmer
        ? RiksaTypography.khmerTitleFallback
        : RiksaTypography.fallback,
    fontWeight: hasKhmer ? FontWeight.w400 : style?.fontWeight,
  );
  final paragraph = body(
    theme.textTheme.bodyLarge?.copyWith(
      fontSize: questionHero ? 20 : null,
      fontWeight: questionHero ? FontWeight.w600 : null,
      height: questionHero ? (hasKhmer ? 1.7 : 1.4) : 1.75,
    ),
  );
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 4),
    h1: heading(
      theme.textTheme.headlineLarge?.copyWith(
        height: hasKhmer ? 1.6 : 1.4,
        fontSize: questionHero ? 22 : null,
      ),
    ),
    h2: heading(
      theme.textTheme.headlineMedium?.copyWith(
        height: hasKhmer ? 1.6 : 1.4,
        fontSize: questionHero ? 21 : null,
      ),
    ),
    h3: heading(
      theme.textTheme.titleLarge?.copyWith(height: hasKhmer ? 1.6 : 1.5),
    ),
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

TextStyle? _lessonBodyStyle(String text, TextStyle? style) {
  final resolved = RiksaTypography.bodyStyleFor(text, style);
  if (!RiksaTypography.containsKhmer(text)) return resolved;
  final height = resolved?.height;
  return resolved?.copyWith(height: height == null || height < 1.5 ? 1.6 : height);
}
