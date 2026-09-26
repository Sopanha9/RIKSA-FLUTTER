import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/mascot.dart';

/// Each buddy's home: the crocodile's pond and the capybara's riverside park,
/// by day in light mode and by night in dark mode.
abstract final class MascotScenes {
  static String asset(
    MascotSpecies species,
    Brightness brightness, {
    bool party = false,
  }) {
    final place = switch (species) {
      MascotSpecies.crocodile => 'pond',
      MascotSpecies.capybara => 'park',
    };
    final time = brightness == Brightness.dark ? 'night' : 'day';
    final variant = party ? '${place}_party_$time' : '${place}_$time';
    return 'assets/images/mascots/scenes/$variant.webp';
  }

  /// Warms the image cache so switching buddies does not flash.
  static void precacheAll(BuildContext context) {
    for (final species in MascotSpecies.values) {
      for (final brightness in Brightness.values) {
        for (final party in const [false, true]) {
          precacheImage(
            AssetImage(asset(species, brightness, party: party)),
            context,
          );
        }
      }
    }
  }
}

/// A buddy's scene filling the screen, crossfading when the buddy changes.
///
/// The art is tall; on other phone shapes it is cropped from the top so the
/// grass the buddy stands on always stays in view. It also sets the status
/// bar icons to read against the sky.
class MascotSceneBackdrop extends StatelessWidget {
  const MascotSceneBackdrop({
    super.key,
    required this.species,
    this.party = false,
  });

  final MascotSpecies species;
  final bool party;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final asset = MascotScenes.asset(species, brightness, party: party);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: RiksaMotion.resolve(
            context,
            const Duration(milliseconds: 450),
          ),
          child: Image.asset(
            asset,
            key: ValueKey(asset),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

/// The rounded panel that holds a scene screen's text and controls, so they
/// stay readable over the art.
class MascotSceneSheet extends StatelessWidget {
  const MascotSceneSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
