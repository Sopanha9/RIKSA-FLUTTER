import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Entry screen for the four-step profile setup flow.
///
/// This reproduces Figma frame `123:295` with the shared RIKSA color tokens.
class ProfileSetupOverviewScreen extends StatelessWidget {
  const ProfileSetupOverviewScreen({super.key, required this.onSetUpProfile});

  final VoidCallback onSetUpProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topInset = MediaQuery.paddingOf(context).top;
    final steps = <({String title, String description})>[
      (
        title: l10n.profileSetupStepPhotoTitle,
        description: l10n.profileSetupStepPhotoBody,
      ),
      (
        title: l10n.profileSetupStepNameTitle,
        description: l10n.profileSetupStepNameBody,
      ),
      (
        title: l10n.profileSetupStepBioTitle,
        description: l10n.profileSetupStepBioBody,
      ),
      (
        title: l10n.profileSetupStepProvinceTitle,
        description: l10n.profileSetupStepProvinceBody,
      ),
    ];

    return Scaffold(
      backgroundColor: context.riksa.canvas,
      body: SafeArea(
        minimum: const EdgeInsets.only(bottom: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: math.max(28.0, 84.0 - topInset)),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: RiksaBackButton(
                              key: const ValueKey('profile-setup-back'),
                              fallbackLocation: '/profile',
                            ),
                          ),
                          const SizedBox(height: RiksaSpacing.md),
                          Text(
                            l10n.profileSetupTitle,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: RiksaSpacing.xs),
                          Text(
                            l10n.profileSetupSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: RiksaSpacing.xl),
                          RiksaPastelCard(
                            tone: RiksaPastelTone.jade,
                            padding: const EdgeInsets.all(RiksaSpacing.lg),
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < steps.length;
                                  index++
                                )
                                  _ProfileStep(
                                    number: index + 1,
                                    title: steps[index].title,
                                    description: steps[index].description,
                                    showConnector: index < steps.length - 1,
                                  ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              key: const Key('profile_setup_start'),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onSetUpProfile();
                              },
                              child: Text(l10n.profileSetupCta),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.number,
    required this.title,
    required this.description,
    required this.showConnector,
  });

  final int number;
  final String title;
  final String description;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    // The row grows with its text: a fixed height clipped the description at
    // large text sizes, which is where it matters most.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.riksa.brand,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: context.riksa.brand.withValues(alpha: .55),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
