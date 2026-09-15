import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared search treatment used by primary discovery screens.
///
/// A white pill with a hairline border and a leading search icon. The filter
/// control is optional and sits inside the pill's trailing edge.
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: palette.outline),
      ),
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
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (onFilter != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Material(
                color: palette.brandSoft,
                shape: const CircleBorder(),
                child: InkWell(
                  key: filterKey ?? const ValueKey('search-filter-control'),
                  onTap: onFilter,
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: 40,
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
        ],
      ),
    );
  }
}
