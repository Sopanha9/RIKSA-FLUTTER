import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riksa_app/core/theme/app_theme.dart';

void main() {
  group('RIKSA color system', () {
    test('keeps generic controls violet and feature accents explicit', () {
      final scheme = AppTheme.light.colorScheme;
      const palette = RiksaPalette.light;

      expect(scheme.primary, palette.brand);
      expect(scheme.secondary, palette.brandStrong);
      expect(scheme.secondary, isNot(palette.reward));
      expect(scheme.tertiary, palette.learning);
      expect(scheme.tertiaryContainer, palette.learningSoft);
      expect(palette.learning, isNot(palette.brand));
      expect(palette.reward, isNot(palette.brand));
    });

    test('maps error roles to the semantic palette in both modes', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final palette = theme.extension<RiksaPalette>()!;
        final scheme = theme.colorScheme;

        expect(scheme.error, palette.semantic.error);
        expect(scheme.onError, palette.semantic.onError);
        expect(scheme.errorContainer, palette.semantic.errorContainer);
        expect(scheme.onErrorContainer, palette.semantic.onErrorContainer);
      }
    });

    test('filled interactive and status pairs meet normal-text contrast', () {
      for (final palette in [RiksaPalette.light, RiksaPalette.dark]) {
        final pairs = <(Color, Color)>[
          (palette.brand, palette.onBrand),
          (palette.learning, palette.onLearning),
          (palette.reward, palette.onReward),
          (palette.semantic.success, palette.semantic.onSuccess),
          (palette.semantic.warning, palette.semantic.onWarning),
          (palette.semantic.error, palette.semantic.onError),
          (palette.semantic.info, palette.semantic.onInfo),
        ];

        for (final pair in pairs) {
          expect(
            _contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason:
                '${pair.$1.toARGB32().toRadixString(16)} and '
                '${pair.$2.toARGB32().toRadixString(16)}',
          );
        }
      }
    });

    test('light and dark neutrals remain theme-specific', () {
      expect(RiksaPalette.light.canvas, const Color(0xFFF7F7F9));
      expect(RiksaPalette.light.surface, Colors.white);
      expect(RiksaPalette.dark.canvas, const Color(0xFF101116));
      expect(RiksaPalette.dark.surface, const Color(0xFF18191F));
    });
  });
}

double _contrast(Color first, Color second) {
  final lighter = math.max(first.computeLuminance(), second.computeLuminance());
  final darker = math.min(first.computeLuminance(), second.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}
