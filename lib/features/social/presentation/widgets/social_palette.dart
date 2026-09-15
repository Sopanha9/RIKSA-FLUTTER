import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

abstract final class SocialPalette {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvas(BuildContext context) => _isDark(context)
      ? context.riksa.canvas
      : AppColors.editorialNeutralCanvas;

  static Color surface(BuildContext context) => _isDark(context)
      ? context.riksa.surface
      : AppColors.editorialNeutralSurface;

  static Color surfaceRaised(BuildContext context) =>
      _isDark(context) ? context.riksa.surfaceRaised : AppColors.editorialField;

  static Color ink(BuildContext context) =>
      _isDark(context) ? context.riksa.ink : AppColors.editorialInk;

  static Color muted(BuildContext context) =>
      _isDark(context) ? context.riksa.inkMuted : AppColors.editorialMuted;

  static Color outline(BuildContext context) =>
      _isDark(context) ? context.riksa.outline : AppColors.editorialOutline;

  static Color aubergine(BuildContext context) => _isDark(context)
      ? AppColors.editorialAubergineRaised
      : AppColors.editorialAubergine;

  static Color pink(BuildContext context) => AppColors.editorialPink;

  static Color pinkSoft(BuildContext context) =>
      _isDark(context) ? context.riksa.brandSoft : AppColors.editorialPinkSoft;

  static Color onAubergine(BuildContext context) => const Color(0xFFFFF8FC);

  static Color green(BuildContext context) => pink(context);
  static Color panel(BuildContext context) => surface(context);
  static Color border(BuildContext context) => outline(context);
  static Color text(BuildContext context) => ink(context);
  static Color editorialSurface(BuildContext context) => surface(context);
}
