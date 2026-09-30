import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/riksa_interactions.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../mascot/domain/buddy_behavior.dart';
import '../../../../mascot/presentation/widgets/buddy_companion.dart';
import '../../../data/learning_models.dart';

class LessonChoiceAnswers extends StatefulWidget {
  const LessonChoiceAnswers({
    super.key,
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
  State<LessonChoiceAnswers> createState() => _LessonChoiceAnswersState();
}

class _LessonChoiceAnswersState extends State<LessonChoiceAnswers> {
  static const _labels = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final isTrueFalse = widget.exercise.type == LessonExerciseType.trueFalse;
    final options = isTrueFalse
        ? const ['True', 'False']
        : widget.exercise.options;
    final selectedAnswer = widget.controller.text;
    final correctAnswer = _correctChoice(options, selectedAnswer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: RiksaSpacing.xs),
          _buildOptionRow(
            context: context,
            index: i,
            option: options[i],
            isTrueFalse: isTrueFalse,
            isSelected: selectedAnswer == options[i],
            isCorrect: correctAnswer == options[i],
          ),
        ],
      ],
    );
  }

  String? _correctChoice(List<String> options, String selectedAnswer) {
    final result = widget.result;
    if (result == null) return null;
    if (result.correct) return selectedAnswer;

    final answerText = [
      result.message,
      result.explanation,
    ].whereType<String>().join(' ').toLowerCase();
    // LessonAnswerResult has no structured correct-answer field. Only accept
    // an explicit answer declaration from the API; a passing mention in an
    // explanation is not enough to color a choice as correct.
    bool isMentioned(String option) {
      final normalized = option.trim().toLowerCase();
      if (normalized.isEmpty) return false;

      final escaped = RegExp.escape(normalized);
      if (normalized.length == 1) {
        // A one-letter option must be identified as an answer, not merely
        // mentioned as an article or unit in the explanation.
        return RegExp(
          '(?:^|[^a-z0-9])(?:correct\\s+)?(?:answer|option|choice)'
          '\\s*(?:is|:|=)\\s*$escaped(?![a-z0-9])',
        ).hasMatch(answerText);
      }

      final phrase = normalized
          .split(RegExp(r'\s+'))
          .map(RegExp.escape)
          .join(r'\s+');
      return RegExp(
        '(?:^|[^a-z0-9])(?:the\\s+)?(?:correct\\s+)?'
        '(?:answer|option|choice)\\s*(?:is|:|=)\\s*'
        '$phrase(?![a-z0-9])',
      ).hasMatch(answerText);
    }

    final matches = options
        .where((option) => option != selectedAnswer && isMentioned(option))
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  Widget _buildOptionRow({
    required BuildContext context,
    required int index,
    required String option,
    required bool isTrueFalse,
    required bool isSelected,
    required bool isCorrect,
  }) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final result = widget.result;
    final isWrong = result != null && isSelected && !result.correct;
    final badgeLabel = isTrueFalse
        ? (index == 0 ? 'T' : 'F')
        : (index < _labels.length ? _labels[index] : '${index + 1}');

    var fill = palette.canvas;
    var border = palette.outline;
    var badgeFill = palette.surface;
    var badgeInk = palette.inkMuted;
    var ink = palette.ink;
    Widget? trailing;

    if (isWrong) {
      fill = palette.semantic.errorContainer;
      border = palette.semantic.error;
      badgeFill = palette.semantic.error;
      badgeInk = palette.semantic.onError;
      ink = palette.semantic.onErrorContainer;
      trailing = Icon(
        Icons.close_rounded,
        color: palette.semantic.error,
        size: 20,
      );
    } else if (isCorrect) {
      fill = palette.semantic.successContainer;
      border = palette.semantic.success;
      badgeFill = palette.semantic.success;
      badgeInk = palette.semantic.onSuccess;
      ink = palette.semantic.onSuccessContainer;
      trailing = Icon(
        Icons.check_rounded,
        color: palette.semantic.success,
        size: 20,
      );
    } else if (isSelected) {
      fill = palette.brandSoft;
      border = palette.brand;
      badgeFill = palette.brand;
      badgeInk = palette.onBrand;
    }

    return RiksaTapFeedback(
      enabled: widget.enabled,
      child: Semantics(
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('lesson-option-$index'),
            onTap: widget.enabled
                ? () {
                    setState(() => widget.controller.text = option);
                    widget.onChanged();
                  }
                : null,
            borderRadius: AppRadii.mediumBorder,
            child: AnimatedContainer(
              key: ValueKey('lesson-option-row-$index'),
              duration: RiksaMotion.resolve(context, RiksaMotion.fast),
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(
                horizontal: RiksaSpacing.md,
                vertical: RiksaSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadii.mediumBorder,
                border: Border.all(color: border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeFill,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
                          height: RiksaTypography.containsKhmer(option)
                              ? 1.6
                              : null,
                        ),
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LessonAnswerFeedbackPanel extends StatelessWidget {
  const LessonAnswerFeedbackPanel({
    super.key,
    required this.exercise,
    required this.result,
  });

  final LessonExercise? exercise;
  final LessonAnswerResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final exercise = this.exercise;

    return AnimatedSwitcher(
      duration: RiksaMotion.resolve(context, RiksaMotion.standard),
      switchInCurve: RiksaMotion.standardCurve,
      switchOutCurve: RiksaMotion.standardCurve,
      transitionBuilder: (child, animation) => SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(0, .16), end: Offset.zero),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: result == null || exercise == null
          ? const SizedBox.shrink(key: ValueKey('lesson-feedback-empty'))
          : ConstrainedBox(
              key: ValueKey('lesson-feedback-scroll-${exercise.id}'),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .4,
              ),
              child: SingleChildScrollView(
                child: _buildPanel(context, result, exercise),
              ),
            ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    LessonAnswerResult result,
    LessonExercise exercise,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final theme = Theme.of(context);
    final correct = result.correct;
    final status = _feedbackStatus(context, result);
    final explanation = [
      result.explanation?.trim(),
      if (result.explanation?.trim().isNotEmpty != true &&
          exercise.explanation?.trim().isNotEmpty == true)
        exercise.explanation!.trim(),
      if (result.hint?.trim().isNotEmpty == true) result.hint!.trim(),
      if (result.hint?.trim().isNotEmpty != true &&
          exercise.hint?.trim().isNotEmpty == true)
        exercise.hint!.trim(),
    ].whereType<String>().where((text) => text.isNotEmpty).join('\n\n');
    final tint = correct
        ? palette.semantic.successContainer
        : palette.semantic.errorContainer;
    final ink = correct
        ? palette.semantic.onSuccessContainer
        : palette.semantic.onErrorContainer;

    return Semantics(
      key: ValueKey('lesson-feedback-result-${exercise.id}'),
      container: true,
      liveRegion: true,
      label: status,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, RiksaSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: RiksaSpacing.md,
              vertical: RiksaSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: AppRadii.largeBorder,
              border: Border.all(
                color: correct
                    ? palette.semantic.success.withValues(alpha: .34)
                    : palette.semantic.error.withValues(alpha: .34),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: BuddyFaceReaction(
                    key: ValueKey(
                      correct
                          ? 'lesson-buddy-correct'
                          : 'lesson-buddy-retry',
                    ),
                    face: BuddyBehavior.resolve(
                      correct
                          ? BuddyEvent.answerCorrect
                          : BuddyEvent.answerIncorrect,
                    ).face,
                    size: 34,
                  ),
                ),
                const SizedBox(width: RiksaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ExcludeSemantics(
                          child: Text(
                            status,
                            key: const ValueKey('lesson-feedback-summary'),
                            style: RiksaTypography.bodyStyleFor(
                              status,
                              theme.textTheme.titleSmall?.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                height: RiksaTypography.containsKhmer(status)
                                    ? 1.6
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (explanation.isNotEmpty)
                        Material(
                          type: MaterialType.transparency,
                          child: ExpansionTile(
                            key: const ValueKey('lesson-feedback-why'),
                            expansionAnimationStyle: AnimationStyle(
                              duration: RiksaMotion.resolve(
                                context,
                                RiksaMotion.standard,
                              ),
                              reverseDuration: RiksaMotion.resolve(
                                context,
                                RiksaMotion.standard,
                              ),
                              curve: RiksaMotion.standardCurve,
                              reverseCurve: RiksaMotion.standardCurve,
                            ),
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            initiallyExpanded: false,
                            title: Text(
                              l10n.lessonWhy,
                              style: RiksaTypography.bodyStyleFor(
                                l10n.lessonWhy,
                                theme.textTheme.labelLarge?.copyWith(
                                  color: ink,
                                  height: RiksaTypography.containsKhmer(
                                    l10n.lessonWhy,
                                  )
                                      ? 1.6
                                      : null,
                                ),
                              ),
                            ),
                            children: [
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  explanation,
                                  style: _lessonBodyStyle(
                                    explanation,
                                    theme.textTheme.bodyMedium?.copyWith(
                                      color: ink,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _feedbackStatus(BuildContext context, LessonAnswerResult result) {
  final l10n = AppLocalizations.of(context)!;
  final fallback = result.correct
      ? l10n.lessonAnswerSuccess
      : l10n.lessonAnswerRetry;
  final message = result.message.trim();
  if (message.isEmpty) return fallback;
  final genericCharacters = RegExp(r'[^a-z0-9\u1780-\u17ff]');
  final normalized = message.toLowerCase().replaceAll(genericCharacters, '');
  final genericMessages = {
    'correct',
    'correctanswer',
    'tryagain',
    'notquite',
    fallback.toLowerCase().replaceAll(genericCharacters, ''),
  };
  return genericMessages.contains(normalized) ? fallback : message;
}

TextStyle? _lessonBodyStyle(String text, TextStyle? style) {
  final resolved = RiksaTypography.bodyStyleFor(text, style);
  if (!RiksaTypography.containsKhmer(text)) return resolved;
  final height = resolved?.height;
  return resolved?.copyWith(
    height: height == null || height < 1.5 ? 1.6 : height,
  );
}
