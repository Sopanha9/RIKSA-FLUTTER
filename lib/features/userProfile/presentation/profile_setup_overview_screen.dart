import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

/// Entry screen for the four-step profile setup flow.
///
/// This reproduces Figma frame `123:295` with the shared RIKSA color tokens.
class ProfileSetupOverviewScreen extends StatelessWidget {
  const ProfileSetupOverviewScreen({super.key, required this.onSetUpProfile});

  final VoidCallback onSetUpProfile;

  static const _background = AppColors.lightCanvas;
  static const _primary = AppColors.brandPrimary;
  static const _text = AppColors.neutralInk;

  static const _steps = <({String title, String description})>[
    (
      title: 'Avatar',
      description: 'Add a profile picture so people recognize you.',
    ),
    (
      title: 'Username',
      description: 'Pick a username, this is how others will find you.',
    ),
    (
      title: 'Gender',
      description: 'Let us know how to personalize your experience.',
    ),
    (title: 'Bio', description: 'Share a little about yourself.'),
  ];

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _background,
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
                          const Text(
                            'Set up your profile',
                            style: TextStyle(
                              color: _text,
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              height: 32 / 24,
                              letterSpacing: .48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Get started with your profile.',
                            style: TextStyle(
                              color: _text,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -.24,
                            ),
                          ),
                          const SizedBox(height: 63),
                          for (var index = 0; index < _steps.length; index++)
                            _ProfileStep(
                              number: index + 1,
                              title: _steps[index].title,
                              description: _steps[index].description,
                              showConnector: index < _steps.length - 1,
                              height: index == 0 ? 100 : 109,
                            ),
                          const Spacer(),
                          Semantics(
                            button: true,
                            label: 'Set up profile',
                            child: SizedBox(
                              height: 52,
                              child: FilledButton(
                                key: const Key('profile_setup_start'),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  onSetUpProfile();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: _background,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadii.mediumBorder,
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 24 / 16,
                                  ),
                                ),
                                child: const Text('Set up Profile'),
                              ),
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
    required this.height,
  });

  final int number;
  final String title;
  final String description;
  final bool showConnector;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 9,
            left: 0,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: ProfileSetupOverviewScreen._primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: ProfileSetupOverviewScreen._background,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 16 / 14,
                  letterSpacing: -.28,
                ),
              ),
            ),
          ),
          if (showConnector)
            Positioned(
              top: 39,
              left: 11,
              child: RotatedBox(
                quarterTurns: 1,
                child: SvgPicture.asset(
                  'assets/images/profile/profile_step_connector.svg',
                  width: 64,
                  height: 2,
                ),
              ),
            ),
          Positioned.fill(
            left: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ProfileSetupOverviewScreen._text,
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 24 / 18,
                    letterSpacing: -.36,
                  ),
                ),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ProfileSetupOverviewScreen._text,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -.24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
