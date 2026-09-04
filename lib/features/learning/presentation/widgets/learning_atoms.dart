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
    child: LinearProgressIndicator(
      value: value.clamp(0, 1).toDouble(),
      minHeight: height,
      color: color,
      backgroundColor: background,
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
