import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/learning_models.dart';
import '../providers/learning_home_provider.dart';
import '../providers/learning_roadmap_provider.dart';
import '../providers/lesson_catalog_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LessonLoadFailure(
          onRetry: () => ref.invalidate(lessonDetailProvider(widget.lessonId)),
        ),
        data: _buildLesson,
      ),
    );
  }

  Widget _buildLesson(LessonDetail detail) {
    _restoreCompletedExercises(detail);
    final sections = _sectionsFor(detail);
    if (sections.isEmpty) return _emptyLesson(detail);
    final activeIndex =
        _activeSectionIndex ?? _firstIncompleteSection(sections);
    final section = sections.firstWhere((item) => item.index == activeIndex);
    final subject = detail.categoryName.trim().isEmpty
        ? AppLocalizations.of(context)!.generalSubject
        : detail.categoryName;
    final color = subjectColor(context, subjectKindFor(subject));
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _LessonHeader(
            id: detail.id,
            title: detail.title,
            subject: subject,
            baseXp: detail.baseXp,
            exerciseCount: detail.exercises.length,
            color: color,
          ),
          const SizedBox(height: 24),
          _SectionProgress(
            sections: sections,
            activeIndex: section.index,
            results: _results,
          ),
          const SizedBox(height: 24),
          if (_showPractice)
            _practiceView(detail, sections, section)
          else
            _contentView(section),
        ],
      ),
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

  Widget _contentView(_LessonSection section) {
    final finalReview = section.index == 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          finalReview
              ? 'Final Review'
              : 'Section ${section.index}: ${section.title}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          finalReview
              ? 'Lesson challenge: apply every idea you have learned.'
              : 'Read the idea, then prove it in practice.',
          style: TextStyle(color: context.riksa.inkMuted),
        ),
        if (section.content.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          MarkdownBody(
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
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          key: ValueKey('start-section-${section.index}'),
          onPressed: () => setState(() => _showPractice = true),
          icon: Icon(
            finalReview ? Icons.emoji_events_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(
            finalReview ? 'Start final review' : 'Practice this section',
          ),
        ),
      ],
    );
  }

  Widget _practiceView(
    LessonDetail detail,
    List<_LessonSection> sections,
    _LessonSection section,
  ) {
    final next = section.exercises
        .where((exercise) => !_isCorrect(exercise))
        .firstOrNull;
    if (next == null) {
      final following = sections
          .where((item) => item.index > section.index)
          .firstOrNull;
      return following == null
          ? _reflectionView(detail)
          : _sectionPassedView(following);
    }
    final number =
        detail.exercises.indexWhere((item) => item.id == next.id) + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.index == 4
              ? 'Final Review'
              : 'Section ${section.index} practice',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          '${section.exercises.where(_isCorrect).length} of ${section.exercises.length} correct',
          style: TextStyle(color: context.riksa.inkMuted),
        ),
        const SizedBox(height: 14),
        _ExerciseCard(
          number: number,
          exercise: next,
          controller: _answers.putIfAbsent(next.id, TextEditingController.new),
          result: _results[next.id],
          submitting: _submitting.contains(next.id),
          onSubmit: () => _submitAnswer(next),
        ),
      ],
    );
  }

  Widget _sectionPassedView(_LessonSection next) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.check_circle_rounded, color: context.riksa.jade, size: 44),
      const SizedBox(height: 10),
      Text(
        'Section complete!',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      Text(
        'Nice work. You are ready for ${next.index == 4 ? 'the Final Review' : 'Section ${next.index}: ${next.title}'}.',
        style: TextStyle(color: context.riksa.inkMuted),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => setState(() {
          _activeSectionIndex = next.index;
          _showPractice = false;
        }),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Continue'),
      ),
    ],
  );

  Widget _reflectionView(LessonDetail detail) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.check_circle_rounded, color: context.riksa.jade, size: 44),
      const SizedBox(height: 10),
      Text(
        'Final Review complete!',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 18),
      Text(
        'Reflection',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Text(
        detail.reflectionPrompt.trim().isEmpty
            ? 'What did you learn, and where could you use it?'
            : detail.reflectionPrompt,
        style: TextStyle(color: context.riksa.inkMuted),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('lesson-reflection'),
        controller: _reflection,
        minLines: 4,
        maxLines: 7,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Write at least 10 thoughtful words...',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        key: const ValueKey('complete-lesson'),
        onPressed:
            !_completing &&
                _wordCount(_reflection.text) >= 10 &&
                detail.state != LessonProgressState.completed
            ? () => _complete(detail)
            : null,
        icon: _completing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.emoji_events_rounded),
        label: Text(
          detail.state == LessonProgressState.completed
              ? 'Lesson completed'
              : 'Complete lesson & earn XP',
        ),
      ),
    ],
  );

  Widget _emptyLesson(LessonDetail detail) => SafeArea(
    top: false,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(detail.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const _NoExercises(),
      ],
    ),
  );

  Future<void> _submitAnswer(LessonExercise exercise) async {
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
      if (mounted) setState(() => _results[exercise.id] = result);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _submitting.remove(exercise.id));
    }
  }

  Future<void> _complete(LessonDetail detail) async {
    setState(() => _completing = true);
    try {
      final result = await ref
          .read(learningApiProvider)
          .completeLesson(
            lessonId: widget.lessonId,
            reflectionText: _reflection.text.trim(),
          );
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
        context.go('/learn/completion$suffix', extra: result.xpEarned);
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

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.id,
    required this.title,
    required this.subject,
    required this.baseXp,
    required this.exerciseCount,
    required this.color,
  });
  final String id;
  final String title;
  final String subject;
  final int baseXp;
  final int exerciseCount;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RiksaSharedElement(
        tag: 'lesson-art-$id',
        child: SubjectArtwork(
          kind: subjectKindFor(subject),
          color: color,
          size: 88,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        subject.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, letterSpacing: .7),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: RiksaTypography.titleStyleFor(
          title,
          Theme.of(context).textTheme.displaySmall,
          khmerHeight: 1.35,
        ),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Fact(icon: Icons.bolt_rounded, label: '$baseXp+ XP'),
          _Fact(
            icon: Icons.edit_note_rounded,
            label: '$exerciseCount exercises',
          ),
        ],
      ),
    ],
  );
}

class _SectionProgress extends StatelessWidget {
  const _SectionProgress({
    required this.sections,
    required this.activeIndex,
    required this.results,
  });
  final List<_LessonSection> sections;
  final int activeIndex;
  final Map<String, LessonAnswerResult> results;
  @override
  Widget build(BuildContext context) => Row(
    children: sections.map((section) {
      final complete = section.exercises.every(
        (exercise) => results[exercise.id]?.correct == true,
      );
      final active = section.index == activeIndex;
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: section == sections.last ? 0 : 6),
          height: 7,
          decoration: BoxDecoration(
            color: complete || active
                ? context.riksa.jade
                : context.riksa.outline,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );
    }).toList(),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.number,
    required this.exercise,
    required this.controller,
    required this.result,
    required this.submitting,
    required this.onSubmit,
  });
  final int number;
  final LessonExercise exercise;
  final TextEditingController controller;
  final LessonAnswerResult? result;
  final bool submitting;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    final correct = result?.correct == true;
    final incorrect = result != null && !correct;
    final border = correct
        ? context.riksa.jade
        : incorrect
        ? Theme.of(context).colorScheme.error
        : context.riksa.outline;
    return Container(
      key: ValueKey('lesson-exercise-${exercise.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.riksa.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border.withValues(alpha: correct || incorrect ? .6 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Exercise $number',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '+${exercise.points} lesson XP',
                style: TextStyle(
                  color: context.riksa.math,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: exercise.question,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context),
            ).copyWith(p: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: 14),
          if (exercise.type == LessonExerciseType.text)
            TextField(
              controller: controller,
              enabled: !correct && !submitting,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(hintText: 'Your answer'),
            )
          else
            _ChoiceAnswers(
              exercise: exercise,
              controller: controller,
              enabled: !correct && !submitting,
            ),
          const SizedBox(height: 12),
          if (!correct)
            FilledButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Check answer'),
            ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Text(
              result!.message,
              style: TextStyle(
                color: correct
                    ? context.riksa.jade
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (correct)
              Text(
                'This counts toward +${exercise.points} lesson XP when you complete the lesson.',
                style: TextStyle(color: context.riksa.inkMuted, fontSize: 12),
              ),
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
  });
  final LessonExercise exercise;
  final TextEditingController controller;
  final bool enabled;
  @override
  State<_ChoiceAnswers> createState() => _ChoiceAnswersState();
}

class _ChoiceAnswersState extends State<_ChoiceAnswers> {
  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.type == LessonExerciseType.trueFalse
        ? const ['True', 'False']
        : widget.exercise.options;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(option),
              selected: widget.controller.text == option,
              onSelected: widget.enabled
                  ? (_) => setState(() => widget.controller.text = option)
                  : null,
            ),
          )
          .toList(),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.label, required this.text});
  final String label;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      '$label: $text',
      style: TextStyle(color: context.riksa.inkMuted, fontSize: 13),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: context.riksa.surfaceRaised,
      shape: const StadiumBorder(),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.riksa.inkMuted),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}

class _NoExercises extends StatelessWidget {
  const _NoExercises();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.riksa.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
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

int _wordCount(String text) =>
    text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
String _friendlyLessonError(Object error) {
  final text = error.toString();
  if (text.contains('already completed')) {
    return 'This lesson is already complete.';
  }
  if (text.contains('too short')) {
    return 'Write at least 10 words in your reflection.';
  }
  if (text.contains('Cannot complete lesson')) {
    return 'Answer every exercise correctly before completing the lesson.';
  }
  return 'We could not save that yet. Please try again.';
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
