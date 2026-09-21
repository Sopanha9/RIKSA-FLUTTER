import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Social colors that intentionally have no value-identical [RiksaPalette]
/// token in both brightness modes.
abstract final class SocialPalette {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Always editorial pink (#9D86F7), which differs from
  /// [RiksaPalette.brand] in light mode.
  static Color pink(BuildContext context) => AppColors.editorialPink;

  /// Uses #FFF8FC in light mode and [AppColors.deepInk] in dark mode; both
  /// differ from [RiksaPalette.onBrand].
  static Color onAubergine(BuildContext context) =>
      _isDark(context) ? AppColors.deepInk : const Color(0xFFFFF8FC);
}
