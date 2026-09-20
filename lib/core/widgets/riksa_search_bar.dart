import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared search treatment used by primary discovery screens.
///
/// A glass pill with a leading search icon. The filter control is optional and
/// sits inside the pill's trailing edge.
class RiksaSearchBar extends StatelessWidget {
  const RiksaSearchBar({
    super.key,
    required this.hintText,
    this.onFilter,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.filterCount = 0,
    this.filterKey,
    this.filterBadgeKey,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFilter;
  final bool readOnly;
  final int filterCount;
  final Key? filterKey;
  final Key? filterBadgeKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: isDark ? .34 : .68),
        Colors.white.withValues(alpha: isDark ? .16 : .42),
      ],
    );
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: .44)
        : const Color(0xFFD8D4E4);
    final glassStroke = BorderSide(color: glassBorder, width: 1.2);
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? .28 : .1),
      blurRadius: 22,
      offset: const Offset(0, 8),
    );
    final controlOuterFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.58);
    final controlInnerFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.54);
    final controlBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.72);

    return ClipRRect(
      borderRadius: AppRadii.fullBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 56,
          decoration: ShapeDecoration(
            gradient: glassGradient,
            shape: StadiumBorder(side: glassStroke),
            shadows: [shadow],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: RiksaTypography.bodyStyleFor(
                      hintText,
                      textTheme.bodyMedium?.copyWith(
                        color: palette.inkFaint,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 21,
                      color: palette.inkMuted,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: isDark ? .1 : .2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 17),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (onFilter != null)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox.square(
                    dimension: 44,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: controlOuterFill,
                        shape: CircleBorder(
                          side: BorderSide(color: controlBorder),
                        ),
                        shadows: [
                          BoxShadow(
                            color: palette.ink.withValues(
                              alpha: isDark ? 0.18 : 0.08,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: controlInnerFill,
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.36),
                                  ),
                                ),
                                shadows: [
                                  BoxShadow(
                                    color: palette.ink.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  key:
                                      filterKey ??
                                      const ValueKey('search-filter-control'),
                                  onTap: onFilter,
                                  customBorder: const CircleBorder(),
                                  child: Center(
                                    child: Badge(
                                      key: filterBadgeKey,
                                      isLabelVisible: filterCount > 0,
                                      label: Text('$filterCount'),
                                      backgroundColor: palette.brand,
                                      textColor: palette.onBrand,
                                      child: Icon(
                                        Icons.tune_rounded,
                                        size: 19,
                                        color: palette.brand,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
