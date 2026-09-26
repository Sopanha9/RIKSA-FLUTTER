import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Semantic colors shared by social surfaces.
abstract final class SocialPalette {
  static Color pink(BuildContext context) => context.riksa.brand;

  static Color onAubergine(BuildContext context) =>
      context.riksa.onBrand;
}
