import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum RiksaSubjectKind {
  math,
  science,
  language,
  technology,
  humanities,
  general,
}

RiksaSubjectKind subjectKindFor(String value) {
  final subject = value.toLowerCase();
  if (subject.contains('math') || subject.contains('គណិត')) {
    return RiksaSubjectKind.math;
  }
  if (subject.contains('science') ||
      subject.contains('physics') ||
      subject.contains('chem') ||
      subject.contains('bio') ||
      subject.contains('វិទ្យាសាស្ត្រ') ||
      subject.contains('គីមី') ||
      subject.contains('ជីវ')) {
    return RiksaSubjectKind.science;
  }
  if (subject.contains('english') ||
      subject.contains('khmer') ||
      subject.contains('language') ||
      subject.contains('ភាសា')) {
    return RiksaSubjectKind.language;
  }
  if (subject.contains('computer') ||
      subject.contains('tech') ||
      subject.contains('coding') ||
      subject.contains('កុំព្យូទ័រ') ||
      subject.contains('បច្ចេក')) {
    return RiksaSubjectKind.technology;
  }
  if (subject.contains('history') ||
      subject.contains('social') ||
      subject.contains('geography') ||
      subject.contains('ប្រវត្តិ') ||
      subject.contains('ភូមិ')) {
    return RiksaSubjectKind.humanities;
  }
  return RiksaSubjectKind.general;
}

Color subjectColor(BuildContext context, RiksaSubjectKind kind) {
  final palette = context.riksa;
  return switch (kind) {
    RiksaSubjectKind.math => palette.math,
    RiksaSubjectKind.science => palette.science,
    RiksaSubjectKind.language => palette.language,
    RiksaSubjectKind.technology => palette.technology,
    RiksaSubjectKind.humanities => palette.humanities,
    RiksaSubjectKind.general => palette.general,
  };
}

enum RiksaPastelTone { jade, saffron, blush, cream, surface }

Color riksaPastelColor(BuildContext context, RiksaPastelTone tone) {
  final palette = context.riksa;
  return switch (tone) {
    RiksaPastelTone.jade => palette.jadeSoft,
    RiksaPastelTone.saffron => palette.saffronSoft,
    RiksaPastelTone.blush => palette.blushSoft,
    RiksaPastelTone.cream => palette.creamSoft,
    RiksaPastelTone.surface => palette.surface,
  };
}

class RiksaRoundedIconButton extends StatelessWidget {
  const RiksaRoundedIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    style: IconButton.styleFrom(
      minimumSize: const Size.square(48),
      backgroundColor: backgroundColor ?? context.riksa.surfaceRaised,
      foregroundColor: foregroundColor ?? context.riksa.ink,
      shape: const CircleBorder(),
    ),
    icon: Icon(icon, size: 22),
  );
}

class RiksaSearchField extends StatelessWidget {
  const RiksaSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: trailing,
      filled: true,
      fillColor: context.riksa.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
      border: const OutlineInputBorder(
        borderRadius: AppRadii.fullBorder,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadii.fullBorder,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.fullBorder,
        borderSide: BorderSide(color: context.riksa.jade, width: 1.5),
      ),
    ),
  );
}

class RiksaPastelCard extends StatelessWidget {
  const RiksaPastelCard({
    super.key,
    required this.child,
    this.tone = RiksaPastelTone.surface,
    this.padding = const EdgeInsets.all(RiksaSpacing.md),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final RiksaPastelTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: riksaPastelColor(context, tone),
        borderRadius: AppRadii.extraLargeBorder,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: AppRadii.extraLargeBorder,
                child: content,
              ),
      ),
    );
  }
}

class RiksaSectionHeader extends StatelessWidget {
  const RiksaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: RiksaSpacing.xxs),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      if (actionLabel != null && onAction != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class RiksaChoicePill extends StatelessWidget {
  const RiksaChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    avatar: icon == null ? null : Icon(icon, size: 17),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.sm),
  );
}

class RiksaStateView extends StatelessWidget {
  const RiksaStateView({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Padding(
        padding: const EdgeInsets.all(RiksaSpacing.md),
        child: RiksaPastelCard(
          tone: RiksaPastelTone.cream,
          padding: const EdgeInsets.all(RiksaSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Icon(icon, size: 42, color: context.riksa.jadeStrong),
              const SizedBox(height: RiksaSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: RiksaSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: RiksaSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class RiksaPageHeader extends StatelessWidget {
  const RiksaPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        RiksaSpacing.md,
        RiksaSpacing.sm,
        RiksaSpacing.md,
        RiksaSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: RiksaSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: RiksaSpacing.xxs),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: RiksaSpacing.sm),
            trailing!,
          ],
        ],
      ),
    ),
  );
}

class DailyMissionCard extends StatelessWidget {
  const DailyMissionCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.subject,
    required this.onPressed,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String actionLabel;
  final String subject;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final kind = subjectKindFor(subject);
    final color = subjectColor(context, kind);
    return Semantics(
      container: true,
      label: '$eyebrow. $title. $body',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: AppRadii.largeBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.all(RiksaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.saffron,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: RiksaSpacing.xs),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: RiksaSpacing.xxs),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: RiksaSpacing.sm),
                    FilledButton.icon(
                      key: const ValueKey('daily-mission-action'),
                      onPressed: onPressed,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(actionLabel),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: RiksaSpacing.sm),
              SubjectArtwork(kind: kind, color: color, size: 86),
            ],
          ),
        ),
      ),
    );
  }
}

class SubjectTile extends StatelessWidget {
  const SubjectTile({
    super.key,
    required this.label,
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final kind = subjectKindFor(subject);
    final color = subjectColor(context, kind);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? color.withValues(alpha: .14) : palette.surfaceRaised,
        borderRadius: AppRadii.mediumBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mediumBorder,
          child: SizedBox(
            width: 108,
            child: Padding(
              padding: const EdgeInsets.all(RiksaSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SubjectArtwork(kind: kind, color: color, size: 62),
                  const SizedBox(height: RiksaSpacing.xs),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? color : palette.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.heroTag,
    required this.subject,
    required this.title,
    required this.durationLabel,
    required this.difficultyLabel,
    required this.exerciseLabel,
    required this.progress,
    required this.completedLabel,
    required this.onTap,
  });

  final Object heroTag;
  final String subject;
  final String title;
  final String durationLabel;
  final String difficultyLabel;
  final String exerciseLabel;
  final double progress;
  final String completedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final kind = subjectKindFor(subject);
    final color = subjectColor(context, kind);
    final complete = progress >= 1;
    return RiksaPressableScale(
      onTap: onTap,
      semanticLabel: '$subject. $title. $durationLabel. $difficultyLabel',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadii.largeBorder,
          border: BorderDirectional(start: BorderSide(color: color, width: 7)),
          boxShadow: RiksaElevation.low(Theme.of(context).brightness),
        ),
        child: ClipRRect(
          borderRadius: AppRadii.largeBorder,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(RiksaSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RiksaSharedElement(
                        tag: heroTag,
                        child: SubjectArtwork(
                          kind: kind,
                          color: color,
                          size: 70,
                        ),
                      ),
                      const SizedBox(width: RiksaSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(color: color),
                            ),
                            const SizedBox(height: RiksaSpacing.xxs),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: RiksaSpacing.xs),
                            Wrap(
                              spacing: RiksaSpacing.sm,
                              runSpacing: RiksaSpacing.xxs,
                              children: [
                                _Metadata(
                                  icon: Icons.schedule_rounded,
                                  label: durationLabel,
                                ),
                                _Metadata(
                                  icon: Icons.edit_note_rounded,
                                  label: exerciseLabel,
                                ),
                                _Tag(
                                  label: complete
                                      ? completedLabel
                                      : difficultyLabel,
                                  color: complete ? palette.jade : color,
                                  icon: complete ? Icons.check_rounded : null,
                                ),
                              ],
                            ),
                            if (progress > 0 && !complete) ...[
                              const SizedBox(height: RiksaSpacing.sm),
                              AnimatedRiksaProgress(
                                value: progress,
                                color: color,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: RiksaSpacing.xs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: palette.inkMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: context.riksa.inkMuted),
      const SizedBox(width: RiksaSpacing.xxs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: color.withValues(alpha: .13),
      shape: const StadiumBorder(),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    ),
  );
}

class ActiveFilterChip extends StatelessWidget {
  const ActiveFilterChip({
    super.key,
    required this.label,
    required this.removeSemanticLabel,
    required this.onRemoved,
  });

  final String label;
  final String removeSemanticLabel;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) => InputChip(
    label: Text(label),
    onDeleted: onRemoved,
    deleteButtonTooltipMessage: removeSemanticLabel,
    deleteIcon: const Icon(Icons.close_rounded, size: 16),
    visualDensity: VisualDensity.compact,
  );
}

@immutable
class RiksaFilterOption {
  const RiksaFilterOption({required this.id, required this.label});
  final String id;
  final String label;
}

@immutable
class RiksaFilterSelection {
  const RiksaFilterSelection({this.grade, this.subject, this.difficulty});
  final String? grade;
  final String? subject;
  final String? difficulty;
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.gradeTitle,
    required this.subjectTitle,
    required this.difficultyTitle,
    required this.applyLabel,
    required this.resetLabel,
    required this.grades,
    required this.subjects,
    required this.difficulties,
    required this.selection,
    required this.onApply,
  });

  final String title;
  final String gradeTitle;
  final String subjectTitle;
  final String difficultyTitle;
  final String applyLabel;
  final String resetLabel;
  final List<RiksaFilterOption> grades;
  final List<RiksaFilterOption> subjects;
  final List<RiksaFilterOption> difficulties;
  final RiksaFilterSelection selection;
  final ValueChanged<RiksaFilterSelection> onApply;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _grade = widget.selection.grade;
  late String? _subject = widget.selection.subject;
  late String? _difficulty = widget.selection.difficulty;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          RiksaSpacing.md,
          RiksaSpacing.sm,
          RiksaSpacing.md,
          RiksaSpacing.md + bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.riksa.outline,
                    borderRadius: AppRadii.fullBorder,
                  ),
                ),
              ),
              const SizedBox(height: RiksaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _grade = null;
                      _subject = null;
                      _difficulty = null;
                    }),
                    child: Text(widget.resetLabel),
                  ),
                ],
              ),
              const SizedBox(height: RiksaSpacing.md),
              if (widget.grades.isNotEmpty) ...[
                _FilterSection(
                  title: widget.gradeTitle,
                  options: widget.grades,
                  selected: _grade,
                  onSelected: (value) => setState(() => _grade = value),
                ),
                const SizedBox(height: RiksaSpacing.lg),
              ],
              Text(
                widget.subjectTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: RiksaSpacing.sm),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.subjects.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: RiksaSpacing.xs),
                  itemBuilder: (context, index) {
                    final option = widget.subjects[index];
                    return SubjectTile(
                      label: option.label,
                      subject: option.label,
                      selected: _subject == option.id,
                      onTap: () => setState(
                        () =>
                            _subject = _subject == option.id ? null : option.id,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: RiksaSpacing.lg),
              _FilterSection(
                title: widget.difficultyTitle,
                options: widget.difficulties,
                selected: _difficulty,
                onSelected: (value) => setState(() => _difficulty = value),
              ),
              const SizedBox(height: RiksaSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('apply-filters'),
                  onPressed: () {
                    widget.onApply(
                      RiksaFilterSelection(
                        grade: _grade,
                        subject: _subject,
                        difficulty: _difficulty,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(widget.applyLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });
  final String title;
  final List<RiksaFilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: RiksaSpacing.sm),
      Wrap(
        spacing: RiksaSpacing.xs,
        runSpacing: RiksaSpacing.xs,
        children: [
          for (final option in options)
            ChoiceChip(
              label: Text(option.label),
              selected: selected == option.id,
              onSelected: (isSelected) =>
                  onSelected(isSelected ? option.id : null),
            ),
        ],
      ),
    ],
  );
}

class AnimatedRiksaProgress extends StatelessWidget {
  const AnimatedRiksaProgress({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    // Begins at empty so the bar fills on first paint instead of appearing
    // already full. Later value changes still animate from wherever it is.
    tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
    duration: RiksaMotion.resolve(context, RiksaMotion.standard),
    curve: RiksaMotion.standardCurve,
    builder: (context, animated, _) => Semantics(
      value: '${(animated * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppRadii.fullBorder,
        child: LinearProgressIndicator(
          value: animated,
          minHeight: height,
          color: color ?? context.riksa.jade,
          backgroundColor: (color ?? context.riksa.jade).withValues(alpha: .14),
        ),
      ),
    ),
  );
}

class RiksaSkeleton extends StatefulWidget {
  const RiksaSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = AppRadii.small,
  });
  final double height;
  final double width;
  final double radius;

  @override
  State<RiksaSkeleton> createState() => _RiksaSkeletonState();
}

class _RiksaSkeletonState extends State<RiksaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RiksaMotion.emphasis,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disabled) {
      _controller
        ..stop()
        ..value = .5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Opacity(
      opacity: .45 + (_controller.value * .35),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.riksa.outline,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

class LessonCardSkeleton extends StatelessWidget {
  const LessonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.riksa.surface,
      borderRadius: AppRadii.largeBorder,
    ),
    child: const Padding(
      padding: EdgeInsets.all(RiksaSpacing.md),
      child: Row(
        children: [
          RiksaSkeleton(width: 70, height: 70, radius: AppRadii.medium),
          SizedBox(width: RiksaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiksaSkeleton(width: 88, height: 10),
                SizedBox(height: RiksaSpacing.xs),
                RiksaSkeleton(height: 18),
                SizedBox(height: RiksaSpacing.xs),
                RiksaSkeleton(width: 170, height: 12),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(RiksaSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SubjectArtwork(
            kind: RiksaSubjectKind.general,
            color: context.riksa.saffron,
            size: 112,
          ),
          const SizedBox(height: RiksaSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: RiksaSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: RiksaSpacing.md),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class RiksaPressableScale extends StatefulWidget {
  const RiksaPressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  State<RiksaPressableScale> createState() => _RiksaPressableScaleState();
}

class RiksaSharedElement extends StatelessWidget {
  const RiksaSharedElement({super.key, required this.tag, required this.child});
  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false
      ? child
      : Hero(tag: tag, child: child);
}

class _RiksaPressableScaleState extends State<RiksaPressableScale> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.semanticLabel,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: RiksaMotion.resolve(context, RiksaMotion.fast),
        curve: RiksaMotion.standardCurve,
        child: widget.child,
      ),
    ),
  );
}

class SubjectArtwork extends StatelessWidget {
  const SubjectArtwork({
    super.key,
    required this.kind,
    required this.color,
    required this.size,
  });
  final RiksaSubjectKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _SubjectArtworkPainter(
        kind: kind,
        color: color,
        background: color.withValues(alpha: .13),
      ),
    ),
  );
}

class _SubjectArtworkPainter extends CustomPainter {
  const _SubjectArtworkPainter({
    required this.kind,
    required this.color,
    required this.background,
  });
  final RiksaSubjectKind kind;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    final fill = Paint()..color = background;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = color;
    final blob = Path()
      ..moveTo(14 * scale, 43 * scale)
      ..cubicTo(
        10 * scale,
        19 * scale,
        34 * scale,
        5 * scale,
        59 * scale,
        13 * scale,
      )
      ..cubicTo(
        88 * scale,
        6 * scale,
        99 * scale,
        35 * scale,
        88 * scale,
        57 * scale,
      )
      ..cubicTo(
        91 * scale,
        83 * scale,
        61 * scale,
        99 * scale,
        39 * scale,
        86 * scale,
      )
      ..cubicTo(
        14 * scale,
        91 * scale,
        3 * scale,
        65 * scale,
        14 * scale,
        43 * scale,
      )
      ..close();
    canvas.drawPath(blob, fill);
    canvas.save();
    canvas.scale(scale, scale);
    switch (kind) {
      case RiksaSubjectKind.math:
        canvas.drawCircle(const Offset(38, 51), 16, line);
        canvas.drawPath(
          Path()
            ..moveTo(50, 62)
            ..lineTo(72, 32)
            ..lineTo(79, 69)
            ..close(),
          line,
        );
        canvas.drawCircle(const Offset(28, 29), 3.5, dot);
      case RiksaSubjectKind.science:
        canvas.drawPath(
          Path()
            ..moveTo(42, 25)
            ..lineTo(58, 25)
            ..moveTo(46, 26)
            ..lineTo(46, 45)
            ..lineTo(30, 72)
            ..quadraticBezierTo(50, 84, 70, 72)
            ..lineTo(54, 45)
            ..lineTo(54, 26),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(36, 64)
            ..quadraticBezierTo(50, 57, 64, 64),
          line,
        );
        canvas.drawCircle(const Offset(65, 31), 4, line);
      case RiksaSubjectKind.language:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(23, 28, 55, 41),
            const Radius.circular(11),
          ),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(40, 69)
            ..lineTo(34, 80)
            ..lineTo(51, 69),
          line,
        );
        canvas.drawLine(const Offset(35, 43), const Offset(66, 43), line);
        canvas.drawLine(const Offset(35, 54), const Offset(57, 54), line);
      case RiksaSubjectKind.technology:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(30, 28, 42, 45),
            const Radius.circular(8),
          ),
          line,
        );
        for (final point in const [
          Offset(23, 38),
          Offset(23, 61),
          Offset(79, 38),
          Offset(79, 61),
        ]) {
          canvas.drawCircle(point, 3, dot);
          canvas.drawLine(
            point,
            Offset(point.dx < 50 ? 30 : 72, point.dy),
            line,
          );
        }
        canvas.drawPath(
          Path()
            ..moveTo(42, 57)
            ..lineTo(50, 42)
            ..lineTo(58, 57),
          line,
        );
      case RiksaSubjectKind.humanities:
        canvas.drawPath(
          Path()
            ..moveTo(22, 43)
            ..lineTo(50, 25)
            ..lineTo(78, 43),
          line,
        );
        canvas.drawLine(const Offset(27, 46), const Offset(73, 46), line);
        for (final x in const [34.0, 50.0, 66.0]) {
          canvas.drawLine(Offset(x, 48), Offset(x, 70), line);
        }
        canvas.drawLine(const Offset(24, 73), const Offset(76, 73), line);
      case RiksaSubjectKind.general:
        canvas.drawPath(
          Path()
            ..moveTo(19, 35)
            ..quadraticBezierTo(35, 27, 49, 39)
            ..lineTo(49, 75)
            ..quadraticBezierTo(35, 63, 19, 70)
            ..close(),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(81, 35)
            ..quadraticBezierTo(65, 27, 51, 39)
            ..lineTo(51, 75)
            ..quadraticBezierTo(65, 63, 81, 70)
            ..close(),
          line,
        );
        canvas.drawCircle(const Offset(72, 25), 3.5, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SubjectArtworkPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.background != background;
}

/// A number that counts up to its value the first time it is shown.
///
/// Progress the learner earned should arrive, not appear. A rank that is simply
/// painted at #3 reads as a fact about the database; a rank that climbs to #3
/// reads as something they did.
///
/// Assistive technology is given the final value only: announcing every
/// interpolated frame would be noise.
class RiksaCountUp extends StatelessWidget {
  const RiksaCountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.duration,
  });

  final int value;

  /// Renders one frame of the count. Called with interpolated values, so keep
  /// it cheap and free of side effects.
  final String Function(int) format;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final label = format(value);
    Widget text(String data) => Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    final resolved = RiksaMotion.resolve(
      context,
      duration ?? RiksaMotion.emphasisLong,
    );
    if (resolved == Duration.zero) return text(label);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        // A begin is what makes this animate on first paint. Without it the
        // builder starts at the end value and only moves on later changes,
        // which is exactly the inert case this widget exists to fix.
        tween: Tween<double>(begin: 0, end: value.toDouble()),
        duration: resolved,
        curve: RiksaMotion.standardCurve,
        builder: (context, animated, _) => text(format(animated.round())),
      ),
    );
  }
}

/// Fades and lifts one row into place, offset by its position in the list.
///
/// [index] is the row's position, and the delay is capped so a long list still
/// finishes assembling promptly instead of trickling in for a second.
class RiksaEntrance extends StatefulWidget {
  const RiksaEntrance({
    super.key,
    required this.index,
    required this.child,
    this.rise = 12,
  });

  final int index;
  final Widget child;

  /// How far the row travels up into position, in logical pixels.
  final double rise;

  /// Rows past this position all start together.
  static const maxStaggered = 8;

  @override
  State<RiksaEntrance> createState() => _RiksaEntranceState();
}

class _RiksaEntranceState extends State<RiksaEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay =
        RiksaMotion.stagger * widget.index.clamp(0, RiksaEntrance.maxStaggered);
    final total = delay + RiksaMotion.standard;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: RiksaMotion.standardCurve,
      ),
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honoured here rather than by skipping the widget, so a learner who turns
    // reduced motion on mid-session still lands on the finished layout.
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, child) {
      // Once the row has landed it is handed back unwrapped. Opacity composites
      // through a saveLayer even at 1.0, and a feed of fifty posts should not
      // carry fifty of those for the rest of the session on a cheap phone.
      if (_progress.isCompleted) return child!;
      return Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _progress.value) * widget.rise),
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}
