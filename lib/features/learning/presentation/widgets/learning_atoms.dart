/// The small building blocks shared by the learning home, the subject roadmap
/// and the lesson experience. They exist so the same badge, pill and progress
/// bar are literally the same widget everywhere, rather than three near-copies
/// that drift apart.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A rounded-square icon badge. Never a circle, never a square.
class LearningBadge extends StatelessWidget {
  const LearningBadge({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 38,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * .34),
    ),
    child: Icon(icon, size: size * .47, color: foreground),
  );
}

/// A metadata pill. Sits on a pastel surface, so it uses the plain surface
/// colour to lift off it rather than a border.
class LearningPill extends StatelessWidget {
  const LearningPill({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: background ?? context.riksa.surface,
      borderRadius: AppRadii.fullBorder,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: accent),
        const SizedBox(width: RiksaSpacing.xxs + 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.riksa.ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// A fully rounded progress bar. [value] is clamped, so an API that reports
/// progress above 1 or below 0 cannot overflow the track.
class LearningTrack extends StatelessWidget {
  const LearningTrack({
    super.key,
    required this.value,
    required this.color,
    required this.background,
    this.height = 7,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadii.fullBorder,
    child: TweenAnimationBuilder<double>(
      // Fills on arrival rather than appearing already filled: a track painted
      // straight at its value reads as a fact, not as progress.
      tween: Tween<double>(begin: 0, end: value.clamp(0, 1).toDouble()),
      duration: RiksaMotion.resolve(context, RiksaMotion.emphasisLong),
      curve: RiksaMotion.standardCurve,
      builder: (context, animated, _) => LinearProgressIndicator(
        value: animated,
        minHeight: height,
        color: color,
        backgroundColor: background,
      ),
    ),
  );
}

/// The one primary action shape in the learning feature: a full pill, 54 high.
class LearningPrimaryButton extends StatelessWidget {
  const LearningPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: RiksaTypography.bodyStyleFor(
        label,
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
    final style = FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      minimumSize: const Size.fromHeight(54),
      shape: const StadiumBorder(),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            iconAlignment: IconAlignment.end,
            icon: Icon(icon, size: 17),
            label: child,
          );
  }
}

/// A 44dp circular control for a drenched header, where a bordered icon button
/// would fight the flat pastel it sits on.
class LearningCircleButton extends StatelessWidget {
  const LearningCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.foreground,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: context.riksa.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: foreground ?? context.riksa.ink),
        ),
      ),
    ),
  );
}

/// The pinned pair of controls at the foot of a step-by-step flow: one quiet
/// way back, one loud way on.
///
/// It carries the primary action for the whole screen so a learner never has to
/// hunt for "what now" inside the scrolling content. The back control collapses
/// away rather than sitting there disabled, because a dead pill next to a live
/// one reads as a bug.
class LearningActionBar extends StatelessWidget {
  const LearningActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryKey,
    this.primaryIcon,
    this.busy = false,
    this.backLabel,
    this.onBack,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final Key? primaryKey;
  final IconData? primaryIcon;
  final bool busy;
  final String? backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final primary = busy
        ? FilledButton(
            key: primaryKey,
            onPressed: null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: const StadiumBorder(),
            ),
            child: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : LearningPrimaryButton(
            key: primaryKey,
            label: primaryLabel,
            onPressed: onPrimary,
            icon: primaryIcon,
          );

    return Container(
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(top: BorderSide(color: palette.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              if (onBack != null && backLabel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('learning-action-back'),
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: palette.outline),
                      foregroundColor: palette.ink,
                    ),
                    child: Text(
                      backLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        backLabel!,
                        const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: RiksaSpacing.sm),
              ],
              // The way on always gets the wider half of the bar.
              Expanded(flex: 2, child: primary),
            ],
          ),
        ),
      ),
    );
  }
}
