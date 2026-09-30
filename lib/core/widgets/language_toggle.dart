import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Compact animated language selector used on authentication screens.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  static const _segmentWidth = 58.0;
  static const _height = 34.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider).locale.languageCode;
    final isEnglish = languageCode == 'en';
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);

    void select(String code) {
      if (languageCode == code) return;
      HapticFeedback.selectionClick();
      ref.read(localeProvider.notifier).setLocale(Locale(code));
    }

    return Container(
      // Include the 4 px padding on both sides and the 1 px outer border.
      width: _segmentWidth * 2 + 10,
      height: _height + 10,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.riksa.surface.withValues(alpha: .7),
        borderRadius: AppRadii.fullBorder,
        border: Border.all(color: context.riksa.outline),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            key: const Key('language_toggle_highlight'),
            alignment: isEnglish ? Alignment.centerLeft : Alignment.centerRight,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: Container(
              width: _segmentWidth,
              height: _height,
              decoration: BoxDecoration(
                color: context.riksa.brandSoft,
                borderRadius: AppRadii.fullBorder,
                border: Border.all(
                  color: context.riksa.brand.withValues(alpha: .35),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _LanguageSegment(
                label: 'EN',
                semanticLabel: 'English',
                selected: isEnglish,
                width: _segmentWidth,
                duration: duration,
                onTap: () => select('en'),
              ),
              _LanguageSegment(
                label: 'ខ្មែរ',
                semanticLabel: 'Khmer',
                selected: !isEnglish,
                width: _segmentWidth,
                duration: duration,
                onTap: () => select('km'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.width,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final double width;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.fullBorder,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOutCubic,
                // AnimatedDefaultTextStyle replaces the inherited style, so
                // the families have to be named here or Khmer loses its font.
                style: TextStyle(
                  fontFamily: RiksaTypography.latinFamily,
                  fontFamilyFallback: const [
                    RiksaTypography.khmerBodyFamily,
                    RiksaTypography.khmerFamily,
                  ],
                  color: selected
                      ? context.riksa.brand
                      : context.riksa.inkMuted,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
