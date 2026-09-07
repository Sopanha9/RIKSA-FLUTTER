import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'riksa_rank_badge.dart';

/// Artwork follows stable backend icon identifiers, never localized names or XP.
class RiksaAchievementImage extends StatelessWidget {
  const RiksaAchievementImage({
    super.key,
    required this.iconUrl,
    this.size = 48,
    this.semanticLabel,
  });

  final String? iconUrl;
  final double size;
  final String? semanticLabel;

  static const bundledAssets = <String, String>{
    '/icons/ach-first-lesson.png':
        'assets/images/achievements/ach-first-lesson.png',
    '/icons/ach-quick-learner.png':
        'assets/images/achievements/ach-quick-learner.png',
    '/icons/ach-dedicated.png': 'assets/images/achievements/ach-dedicated.png',
    '/icons/ach-century.png': 'assets/images/achievements/ach-century.png',
    '/icons/ach-hard-mode.png': 'assets/images/achievements/ach-hard-mode.png',
    '/icons/ach-difficult.png': 'assets/images/achievements/ach-difficult.png',
    '/icons/ach-explorer.png': 'assets/images/achievements/ach-explorer.png',
    '/icons/ach-completionist.png':
        'assets/images/achievements/ach-completionist.png',
    '/icons/ach-xp-hunter.png': 'assets/images/achievements/ach-xp-hunter.png',
    '/icons/ach-xp-master.png': 'assets/images/achievements/ach-xp-master.png',
    '/icons/ach-streak-3.png': 'assets/images/achievements/ach-streak-3.png',
    '/icons/ach-streak-7.png': 'assets/images/achievements/ach-streak-7.png',
    '/icons/ach-streak-14.png': 'assets/images/achievements/ach-streak-14.png',
    '/icons/ach-streak-30.png': 'assets/images/achievements/ach-streak-30.png',
    '/icons/ach-streak-90.png': 'assets/images/achievements/ach-streak-90.png',
    '/icons/ach-streak-365.png':
        'assets/images/achievements/ach-streak-365.png',
    '/icons/ach-first-post.png':
        'assets/images/achievements/ach-first-post.png',
    '/icons/ach-contributor.png':
        'assets/images/achievements/ach-contributor.png',
    '/icons/ach-pillar.png': 'assets/images/achievements/ach-pillar.png',
    '/icons/ach-noticed.png': 'assets/images/achievements/ach-noticed.png',
    '/icons/ach-popular.png': 'assets/images/achievements/ach-popular.png',
    '/icons/ach-first-blog.png':
        'assets/images/achievements/ach-first-blog.png',
    '/icons/ach-blogger.png': 'assets/images/achievements/ach-blogger.png',
    '/icons/ach-prolific.png': 'assets/images/achievements/ach-prolific.png',
    '/icons/ach-rising-author.png':
        'assets/images/achievements/ach-rising-author.png',
    '/icons/ach-beloved.png': 'assets/images/achievements/ach-beloved.png',
  };

  static const rankTiers = <String, String>{
    '/icons/ach-rank-silver.png': 'SILVER',
    '/icons/ach-rank-gold.png': 'GOLD',
    '/icons/ach-rank-platinum.png': 'PLATINUM',
    '/icons/ach-rank-diamond.png': 'DIAMOND',
    '/icons/ach-rank-legend.png': 'LEGEND',
  };

  // Visible alpha >= 16 bounds in the untouched 1254px source canvases.
  // Transform the whole image into an 88% frame; no pixels are clipped.
  // See tool/verify_achievement_artwork.py and the saved alpha audit.
  static const _visibleBounds = <String, Rect>{
    '/icons/ach-beloved.png': Rect.fromLTRB(38, 38, 1216, 1206),
    '/icons/ach-blogger.png': Rect.fromLTRB(42, 44, 1210, 1191),
    '/icons/ach-century.png': Rect.fromLTRB(30, 27, 1216, 1198),
    '/icons/ach-completionist.png': Rect.fromLTRB(56, 54, 1196, 1193),
    '/icons/ach-contributor.png': Rect.fromLTRB(57, 53, 1196, 1185),
    '/icons/ach-dedicated.png': Rect.fromLTRB(17, 15, 1232, 1215),
    '/icons/ach-difficult.png': Rect.fromLTRB(58, 58, 1192, 1173),
    '/icons/ach-explorer.png': Rect.fromLTRB(48, 48, 1204, 1193),
    '/icons/ach-first-blog.png': Rect.fromLTRB(39, 39, 1215, 1206),
    '/icons/ach-first-lesson.png': Rect.fromLTRB(20, 23, 1228, 1204),
    '/icons/ach-first-post.png': Rect.fromLTRB(47, 42, 1204, 1190),
    '/icons/ach-hard-mode.png': Rect.fromLTRB(43, 38, 1210, 1190),
    '/icons/ach-noticed.png': Rect.fromLTRB(75, 64, 1176, 1165),
    '/icons/ach-pillar.png': Rect.fromLTRB(38, 40, 1216, 1196),
    '/icons/ach-popular.png': Rect.fromLTRB(40, 42, 1213, 1195),
    '/icons/ach-prolific.png': Rect.fromLTRB(49, 41, 1205, 1192),
    '/icons/ach-quick-learner.png': Rect.fromLTRB(39, 36, 1209, 1187),
    '/icons/ach-rising-author.png': Rect.fromLTRB(48, 48, 1203, 1187),
    '/icons/ach-streak-14.png': Rect.fromLTRB(47, 40, 1205, 1201),
    '/icons/ach-streak-3.png': Rect.fromLTRB(60, 57, 1193, 1185),
    '/icons/ach-streak-30.png': Rect.fromLTRB(55, 53, 1197, 1190),
    '/icons/ach-streak-365.png': Rect.fromLTRB(45, 40, 1208, 1198),
    '/icons/ach-streak-7.png': Rect.fromLTRB(47, 41, 1205, 1191),
    '/icons/ach-streak-90.png': Rect.fromLTRB(52, 52, 1194, 1177),
    '/icons/ach-xp-hunter.png': Rect.fromLTRB(62, 56, 1192, 1180),
    '/icons/ach-xp-master.png': Rect.fromLTRB(64, 71, 1186, 1175),
  };

  @override
  Widget build(BuildContext context) {
    final value = iconUrl?.trim() ?? '';
    final uri = Uri.tryParse(value);
    // Absolute URLs belong to custom artwork, even if their basename happens
    // to match a catalog icon. Only the backend's relative identifiers map.
    final identifier = uri != null && !uri.hasScheme && !uri.hasAuthority
        ? uri.path
        : null;
    final asset = bundledAssets[identifier];
    final tier = rankTiers[identifier];
    final isCustomUrl =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    final fallback = Icon(
      Icons.image_outlined,
      size: size * .65,
      color: context.riksa.inkMuted,
    );

    final Widget artwork;
    if (tier != null) {
      artwork = RiksaRankBadge(tier: tier, size: size);
    } else if (asset != null) {
      final bounds = _visibleBounds[identifier]!;
      artwork = Transform.scale(
        scale: .88 * 1254 / bounds.longestSide,
        child: Transform.translate(
          offset: Offset(
            size * (627 - bounds.center.dx) / 1254,
            size * (627 - bounds.center.dy) / 1254,
          ),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => fallback,
          ),
        ),
      );
    } else if (isCustomUrl) {
      artwork = Image.network(
        value,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      artwork = fallback;
    }

    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox.square(dimension: size, child: artwork),
    );
  }
}
