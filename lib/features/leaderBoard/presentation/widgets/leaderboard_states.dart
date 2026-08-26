import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/data/auth_api.dart';
import '../../../social/data/social_api.dart';
import '../../../userProfile/presentation/widgets/profile_ui.dart';

class PodiumLoadingShimmer extends StatelessWidget {
  const PodiumLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ProvincePrompt extends StatelessWidget {
  const ProvincePrompt({super.key, required this.onSelectProvince});

  final VoidCallback onSelectProvince;

  @override
  Widget build(BuildContext context) {
    return ProfilePanel(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.location_on_outlined, size: 36, color: context.riksa.jade),
          const SizedBox(height: 8),
          const Text(
            'Select your province to see your local community leaderboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onSelectProvince,
            child: const Text('Set Province'),
          ),
        ],
      ),
    );
  }
}

class RankGapIndicator extends StatelessWidget {
  const RankGapIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '• • •',
          style: TextStyle(
            color: Color(0xFF70695E),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class LeaderboardError extends StatelessWidget {
  const LeaderboardError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfilePanel(
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: Text(l10n.tryAgain)),
        ],
      ),
    );
  }
}

String leaderboardErrorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException) return dioErrorMessage(error);
  if (error is SocialApiException) return error.message;
  return l10n.profileLoadFailed;
}
