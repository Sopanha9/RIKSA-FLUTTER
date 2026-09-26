import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'riksa_glass.dart';

typedef RiksaSegment<T> = ({T value, String label, String semanticKey});

class RiksaSegmentedTabs<T> extends StatelessWidget {
  const RiksaSegmentedTabs({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 48,
    this.controlKey,
  }) : assert(segments.length >= 2);

  final List<RiksaSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Retains the legacy feed strip's 46px height while other strips use 48px.
  final double height;
  final Key? controlKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final duration = RiksaMotion.resolve(context, RiksaMotion.standard);
    final selectedIndex = segments.indexWhere(
      (segment) => segment.value == selected,
    );
    assert(selectedIndex >= 0, 'selected must match one of the segments');

    Widget tab(RiksaSegment<T> segment) {
      final isSelected = segment.value == selected;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          child: InkWell(
            key: ValueKey(segment.semanticKey),
            onTap: () => onChanged(segment.value),
            borderRadius: AppRadii.fullBorder,
            child: Center(
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  segment.label,
                  Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? palette.brand : palette.inkMuted,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      key: controlKey,
      height: height,
      child: RiksaGlassSurface(
        borderRadius: AppRadii.fullBorder,
        blurSigma: context.riksaGlass.blurSigma,
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / segments.length;
            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  start: selectedIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: const RiksaGlassSelection(
                    borderRadius: AppRadii.fullBorder,
                  ),
                ),
                Row(children: segments.map(tab).toList()),
              ],
            );
          },
        ),
      ),
    );
  }
}
