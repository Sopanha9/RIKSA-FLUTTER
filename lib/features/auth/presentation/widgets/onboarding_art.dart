import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart' as rive;

enum OnboardingScene { learning, achievement, community }

/// Displays the branded onboarding artwork without exposing its renderer.
///
/// Rive is used when the authored asset is bundled and motion is enabled.
/// Otherwise the existing PNG artwork remains a deterministic fallback.
class OnboardingArt extends StatefulWidget {
  const OnboardingArt({
    super.key,
    required this.scene,
    required this.active,
    required this.semanticLabel,
  });

  final OnboardingScene scene;
  final bool active;
  final String semanticLabel;

  @override
  State<OnboardingArt> createState() => _OnboardingArtState();
}

class _OnboardingArtState extends State<OnboardingArt> {
  static const _riveAsset = 'assets/rive/onboarding.riv';

  late final Future<bool> _riveAssetAvailable = _isRiveAssetBundled();

  Future<bool> _isRiveAssetBundled() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains(_riveAsset);
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      key: ValueKey('onboarding-art-${widget.scene.name}'),
      image: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: reduceMotion
            ? _StaticOnboardingArt(scene: widget.scene)
            : FutureBuilder<bool>(
                future: _riveAssetAvailable,
                builder: (context, snapshot) {
                  if (snapshot.data != true) {
                    return _StaticOnboardingArt(scene: widget.scene);
                  }
                  return _RiveOnboardingArt(
                    asset: _riveAsset,
                    artboard: widget.scene.artboardName,
                    active: widget.active,
                    fallback: _StaticOnboardingArt(scene: widget.scene),
                  );
                },
              ),
      ),
    );
  }
}

class _RiveOnboardingArt extends StatefulWidget {
  const _RiveOnboardingArt({
    required this.asset,
    required this.artboard,
    required this.active,
    required this.fallback,
  });

  final String asset;
  final String artboard;
  final bool active;
  final Widget fallback;

  @override
  State<_RiveOnboardingArt> createState() => _RiveOnboardingArtState();
}

class _RiveOnboardingArtState extends State<_RiveOnboardingArt> {
  late final rive.FileLoader _fileLoader = rive.FileLoader.fromAsset(
    widget.asset,
    riveFactory: rive.Factory.rive,
  );
  rive.RiveWidgetController? _controller;

  @override
  void didUpdateWidget(_RiveOnboardingArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _controller?.active = widget.active;
    }
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => rive.RiveWidgetBuilder(
    fileLoader: _fileLoader,
    artboardSelector: rive.ArtboardSelector.byName(widget.artboard),
    stateMachineSelector: rive.StateMachineSelector.byName('Onboarding'),
    onLoaded: (state) {
      _controller = state.controller..active = widget.active;
    },
    builder: (context, state) => switch (state) {
      rive.RiveLoaded() => rive.RiveWidget(
        controller: state.controller,
        fit: rive.Fit.contain,
      ),
      rive.RiveLoading() || rive.RiveFailed() => widget.fallback,
    },
  );
}

class _StaticOnboardingArt extends StatelessWidget {
  const _StaticOnboardingArt({required this.scene});

  final OnboardingScene scene;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    scene.fallbackAsset,
    key: ValueKey(scene.fallbackAsset),
    fit: BoxFit.contain,
    colorMapper: const _VioletArtMapper(),
  );
}

/// The artwork was drawn in the old aubergine and pink. This maps those inks
/// onto the violet system so the illustrations match the rest of the app.
class _VioletArtMapper extends ColorMapper {
  const _VioletArtMapper();

  static const _map = {
    0xFF2A061D: Color(0xFF2B2247),
    0xFF3A0A29: Color(0xFF3B2E66),
    0xFFEE8FD0: Color(0xFF7657EE),
    0xFFE6E6E6: Color(0xFFB7A6ED),
  };

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => _map[color.toARGB32()] ?? color;
}

extension on OnboardingScene {
  String get artboardName => switch (this) {
    OnboardingScene.learning => 'Learning',
    OnboardingScene.achievement => 'Achievement',
    OnboardingScene.community => 'Community',
  };

  String get fallbackAsset => switch (this) {
    OnboardingScene.learning => 'assets/images/onboarding/learning.svg',
    OnboardingScene.achievement => 'assets/images/onboarding/achievement.svg',
    OnboardingScene.community => 'assets/images/onboarding/community.svg',
  };
}
