import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rank artwork selected by the server's tier name, never by XP or board place.
/// Unknown tiers use a neutral shield rather than awarding a different rank.
class RiksaRankBadge extends StatelessWidget {
  const RiksaRankBadge({
    super.key,
    required this.tier,
    this.size = 40,
    this.semanticLabel,
  });

  final String? tier;
  final double size;
  final String? semanticLabel;

  // Visible shield bounds in the original 1254px square PNGs. Rendering these
  // regions in a shared frame removes the generator's inconsistent padding
  // without changing the source artwork or clipping a shield's outline.
  static const _bounds = <String, Rect>{
    'BRONZE': Rect.fromLTRB(239, 179, 1015, 1072),
    'SILVER': Rect.fromLTRB(234, 169, 1020, 1084),
    'GOLD': Rect.fromLTRB(238, 180, 1016, 1071),
    'PLATINUM': Rect.fromLTRB(191, 108, 1063, 1122),
    'DIAMOND': Rect.fromLTRB(239, 181, 1015, 1072),
    'LEGEND': Rect.fromLTRB(157, 66, 1097, 1169),
  };

  @override
  Widget build(BuildContext context) {
    final name = tier?.trim().toUpperCase();
    final bounds = _bounds[name];
    final fallback = Icon(
      Icons.shield_outlined,
      size: size * .8,
      color: context.riksa.inkMuted,
    );

    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: bounds == null
            ? fallback
            : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size * .1172,
                  vertical: size * .06,
                ),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: bounds.width,
                    height: bounds.height,
                    child: Stack(
                      children: [
                        Positioned(
                          left: -bounds.left,
                          top: -bounds.top,
                          width: 1254,
                          height: 1254,
                          child: Image.asset(
                            'assets/images/ranks/${name!.toLowerCase()}.png',
                            excludeFromSemantics: true,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
