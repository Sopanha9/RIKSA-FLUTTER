import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LeaderboardHeader extends StatelessWidget {
  const LeaderboardHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: isDark ? context.riksa.ink : AppColors.editorialAubergine,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(width: RiksaSpacing.sm),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? context.riksa.surfaceRaised
                : AppColors.editorialPinkSoft,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: Icon(
              Icons.notifications_none_rounded,
              color: isDark
                  ? AppColors.editorialPink
                  : AppColors.editorialAubergine,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
