import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_interactions.dart';

class LeaderboardHeader extends StatelessWidget {
  const LeaderboardHeader({super.key, required this.title, this.periodLabel});

  final String title;
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final defaultMonth = DateFormat.MMMM(locale).format(DateTime.now());
    final label = periodLabel ?? defaultMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month / Season pill matching inspiration top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
          decoration: BoxDecoration(
            color: AppColors.achievementSaffron,
            borderRadius: AppRadii.fullBorder,
            boxShadow: [
              BoxShadow(
                color: AppColors.achievementSaffron.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(width: RiksaSpacing.sm),
            RiksaTapFeedback(
              child: Container(
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
            ),
          ],
        ),
      ],
    );
  }
}
