import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LeaderboardHeader extends StatelessWidget {
  const LeaderboardHeader({super.key, required this.title, this.periodLabel});
  final String title;
  final String? periodLabel;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: context.riksa.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
