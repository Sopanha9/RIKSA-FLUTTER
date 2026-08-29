import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/learning_models.dart';
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
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_markStarted);
  }

  Future<void> _markStarted() async {
    try {
      await ref.read(learningApiProvider).startLesson(widget.lessonId);
      final categoryId = widget.lesson?.categoryId;
      if (categoryId != null) {
        ref.invalidate(learningRoadmapProvider(categoryId));
      }
    } catch (_) {
      // The detail remains usable when progress tracking is temporarily down.
    }
  }

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
    final l10n = AppLocalizations.of(context)!;
    final subject = detail.categoryName.trim().isEmpty
        ? l10n.generalSubject
        : detail.categoryName;
    final kind = subjectKindFor(subject);
    final color = subjectColor(context, kind);
    for (final exercise in detail.exercises.where((item) => item.completed)) {
      _results.putIfAbsent(
        exercise.id,
        () => LessonAnswerResult(
          exerciseId: exercise.id,
          correct: true,
          points: exercise.points,
          message: 'Completed earlier — your progress was restored.',
        ),
      );
    }
    final allCorrect = detail.exercises.every(
      (exercise) => _results[exercise.id]?.correct == true,
    );

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: RiksaSharedElement(
              tag: 'lesson-art-${detail.id}',
              child: SubjectArtwork(kind: kind, color: color, size: 104),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            subject.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color, letterSpacing: .7),
          ),
          const SizedBox(height: 6),
          Text(detail.title, style: _lessonTitleStyle(context, detail.title)),
          if (detail.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            MarkdownBody(
              key: const ValueKey('lesson-description-markdown'),
              data: detail.description,
              selectable: true,
              softLineBreak: true,
              styleSheet: _lessonMarkdownStyleSheet(
                context,
                hasKhmer: _containsKhmer(detail.description),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Fact(icon: Icons.bolt_rounded, label: '${detail.baseXp}+ XP'),
              _Fact(
                icon: Icons.edit_note_rounded,
                label: '${detail.exercises.length} exercises',
              ),
              if (detail.difficulty != null)
                _Fact(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: _difficultyLabel(l10n, detail.difficulty!),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Practice',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Answer every exercise correctly. Your latest answer is saved to your learning progress.',
            style: TextStyle(color: context.riksa.inkMuted),
          ),
          const SizedBox(height: 14),
          if (detail.exercises.isEmpty)
            const _NoExercises()
          else
            for (var index = 0; index < detail.exercises.length; index++)
              _ExerciseCard(
                number: index + 1,
                exercise: detail.exercises[index],
                controller: _answers.putIfAbsent(
                  detail.exercises[index].id,
                  TextEditingController.new,
                ),
                result: _results[detail.exercises[index].id],
                submitting: _submitting.contains(detail.exercises[index].id),
                onSubmit: () => _submitAnswer(detail.exercises[index]),
              ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('lesson-reflection'),
            controller: _reflection,
            minLines: 4,
            maxLines: 7,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Write at least 10 thoughtful words…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('complete-lesson'),
            onPressed:
                !_completing &&
                    allCorrect &&
                    _wordCount(_reflection.text) >= 10 &&
                    widget.lesson?.completed != true
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
              widget.lesson?.completed == true
                  ? 'Lesson completed'
                  : allCorrect
                  ? 'Complete lesson & earn XP'
                  : 'Complete every exercise first',
            ),
          ),
        ],
      ),
    );
  }

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
      if (!mounted) return;
      setState(() => _results[exercise.id] = result);
      final categoryId = widget.lesson?.categoryId;
      if (categoryId != null) {
        ref.invalidate(learningRoadmapProvider(categoryId));
      }
    } catch (error) {
      if (!mounted) return;
      _showError(error);
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
      final categoryId = detail.categoryId ?? widget.lesson?.categoryId;
      if (categoryId != null) {
        ref.invalidate(learningRoadmapProvider(categoryId));
      }
      await ref.read(lessonCatalogProvider.notifier).load();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.emoji_events_rounded, color: context.riksa.saffron),
          title: const Text('Lesson completed!'),
          content: Text(
            'You earned ${result.xpEarned} XP. Your roadmap and streak are now up to date.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continue roadmap'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_friendlyLessonError(error))));
  }
}

bool _containsKhmer(String text) =>
    RegExp(r'[\u1780-\u17FF\u19E0-\u19FF]').hasMatch(text);

MarkdownStyleSheet _lessonMarkdownStyleSheet(
  BuildContext context, {
  required bool hasKhmer,
}) {
  final theme = Theme.of(context);
  final palette = context.riksa;
  final bodyFontFamily = hasKhmer
      ? RiksaTypography.khmerBodyFamily
      : RiksaTypography.latinFamily;
  final titleFontFamily = hasKhmer
      ? RiksaTypography.khmerTitleFamily
      : RiksaTypography.latinFamily;
  final bodyFallback = hasKhmer
      ? const [RiksaTypography.khmerFamily, RiksaTypography.latinFamily]
      : RiksaTypography.fallback;
  final titleFallback = hasKhmer
      ? const [
          RiksaTypography.khmerBodyFamily,
          RiksaTypography.khmerFamily,
          RiksaTypography.latinFamily,
        ]
      : RiksaTypography.fallback;

  TextStyle bodyStyle(TextStyle? style) => (style ?? const TextStyle())
      .copyWith(fontFamily: bodyFontFamily, fontFamilyFallback: bodyFallback);

  TextStyle titleStyle(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(
        fontFamily: titleFontFamily,
        fontFamilyFallback: titleFallback,
        fontWeight: hasKhmer ? FontWeight.w400 : style?.fontWeight,
        letterSpacing: hasKhmer ? 0 : style?.letterSpacing,
      );

  final paragraph = bodyStyle(
    theme.textTheme.bodyLarge?.copyWith(height: 1.75),
  );
  final heading1 = titleStyle(
    theme.textTheme.headlineLarge?.copyWith(height: 1.4),
  );
  final heading2 = titleStyle(
    theme.textTheme.headlineMedium?.copyWith(height: 1.4),
  );
  final heading3 = titleStyle(
    theme.textTheme.titleLarge?.copyWith(height: 1.5),
  );

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    a: paragraph.copyWith(
      color: palette.jadeStrong,
      decoration: TextDecoration.underline,
    ),
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 4),
    h1: heading1,
    h1Padding: const EdgeInsets.only(top: 8, bottom: 6),
    h2: heading2,
    h2Padding: const EdgeInsets.only(top: 8, bottom: 5),
    h3: heading3,
    h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
    h4: bodyStyle(theme.textTheme.titleMedium?.copyWith(height: 1.5)),
    h5: bodyStyle(theme.textTheme.titleSmall?.copyWith(height: 1.5)),
    h6: bodyStyle(theme.textTheme.labelLarge?.copyWith(height: 1.5)),
    strong: bodyStyle(const TextStyle(fontWeight: FontWeight.w700)),
    em: bodyStyle(const TextStyle(fontStyle: FontStyle.italic)),
    code: bodyStyle(
      theme.textTheme.bodyMedium?.copyWith(
        color: palette.ink,
        backgroundColor: palette.surfaceRaised,
      ),
    ),
    blockquote: paragraph.copyWith(color: palette.inkMuted),
    listBullet: paragraph,
    tableHead: bodyStyle(
      theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    tableBody: bodyStyle(theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
    tableBorder: TableBorder.all(color: palette.outline),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    blockSpacing: 12,
    listIndent: 22,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: palette.outline)),
    ),
  );
}

TextStyle? _lessonTitleStyle(BuildContext context, String title) {
  final style = Theme.of(context).textTheme.displaySmall;
  if (!_containsKhmer(title)) return style;
  return style?.copyWith(
    fontFamily: RiksaTypography.khmerTitleFamily,
    fontFamilyFallback: const [
      RiksaTypography.khmerBodyFamily,
      RiksaTypography.khmerFamily,
      RiksaTypography.latinFamily,
    ],
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.35,
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
    return Container(
      key: ValueKey('lesson-exercise-${exercise.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.riksa.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: correct
              ? context.riksa.jade.withValues(alpha: .55)
              : incorrect
              ? Theme.of(context).colorScheme.error.withValues(alpha: .45)
              : context.riksa.outline,
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
                '+${exercise.points} XP',
                style: TextStyle(
                  color: context.riksa.math,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(exercise.question),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !correct && !submitting,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: 'Your answer',
              suffixIcon: correct
                  ? Icon(Icons.check_circle_rounded, color: context.riksa.jade)
                  : IconButton(
                      onPressed: submitting ? null : onSubmit,
                      icon: submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                    ),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 8),
            Text(
              result!.message,
              style: TextStyle(
                color: correct
                    ? context.riksa.jade
                    : Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IllustratedEmptyState(
      title: l10n.lessonLoadFailed,
      body: 'The lesson detail could not be loaded from the learning service.',
      actionLabel: l10n.tryAgain,
      onAction: onRetry,
    );
  }
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
  return 'We couldn’t save that yet. Please try again.';
}

String _difficultyLabel(AppLocalizations l10n, LessonDifficulty difficulty) =>
    switch (difficulty) {
      LessonDifficulty.easy => l10n.difficultyEasy,
      LessonDifficulty.medium => l10n.difficultyMedium,
      LessonDifficulty.hard => l10n.difficultyHard,
      LessonDifficulty.difficult => l10n.difficultyDifficult,
    };
