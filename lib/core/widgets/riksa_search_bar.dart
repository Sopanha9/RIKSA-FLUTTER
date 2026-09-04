import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared search treatment used by primary discovery screens.
///
/// The field and circular filter control intentionally read as one compact
/// unit, matching Riksa's quieter editorial direction.
class RiksaSearchBar extends StatelessWidget {
  const RiksaSearchBar({
    super.key,
    required this.hintText,
    required this.onFilter,
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
  final VoidCallback onFilter;
  final bool readOnly;
  final int filterCount;
  final Key? filterKey;
  final Key? filterBadgeKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final field = isDark
        ? context.riksa.surfaceRaised
        : AppColors.editorialField;
    final control = isDark ? context.riksa.surface : Colors.white;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: field,
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.riksa.ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.riksa.inkMuted,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 21,
                  color: context.riksa.ink,
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: control,
              shape: const CircleBorder(),
              child: InkWell(
                key: filterKey ?? const ValueKey('search-filter-control'),
                onTap: onFilter,
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: Badge(
                      key: filterBadgeKey,
                      isLabelVisible: filterCount > 0,
                      label: Text('$filterCount'),
                      backgroundColor: AppColors.editorialPink,
                      textColor: AppColors.editorialAubergine,
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 21,
                        color: context.riksa.ink,
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
