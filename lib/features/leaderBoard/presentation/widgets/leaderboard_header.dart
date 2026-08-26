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
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? context.riksa.surfaceRaised : AppColors.ink,
            shape: BoxShape.circle,
            boxShadow: RiksaElevation.low(Theme.of(context).brightness),
          ),
          child: IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? context.riksa.ink : Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
