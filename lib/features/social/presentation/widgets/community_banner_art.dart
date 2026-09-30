import 'package:flutter/material.dart';

import '../../../learning/presentation/learning_design.dart';
import 'community_banner_pattern.dart';

/// Colours an owner can pick for their banner, as #RRGGBB.
const communityBannerColors = [
  '#7C5CFF',
  '#FF5C8A',
  '#FF8A3D',
  '#F5B800',
  '#22C55E',
  '#14B8A6',
  '#3B82F6',
  '#1F2937',
];

Color? parseBannerColor(String? hex) {
  final value = hex?.trim() ?? '';
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) return null;
  return Color(int.parse('FF${value.substring(1)}', radix: 16));
}

/// A community's banner: the owner's photo, else their colour, else the
/// subject's pastel with its doodle pattern.
class CommunityBannerArt extends StatelessWidget {
  const CommunityBannerArt({
    super.key,
    required this.subject,
    this.bannerUrl,
    this.bannerColor,
  });

  final StemSubject subject;
  final String? bannerUrl;
  final String? bannerColor;

  @override
  Widget build(BuildContext context) {
    final tone = subjectTone(context, subject);
    final picked = parseBannerColor(bannerColor);

    final Widget fill = picked == null
        ? Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: tone.surface),
              CommunityBannerPattern(subject: subject, color: tone.accent),
              _wash(
                tone.accent.withValues(alpha: .05),
                tone.accent.withValues(alpha: .28),
              ),
            ],
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: picked),
              CommunityBannerPattern(
                subject: subject,
                color: Colors.white.withValues(alpha: .35),
              ),
              _wash(
                Colors.white.withValues(alpha: .12),
                Colors.black.withValues(alpha: .18),
              ),
            ],
          );

    final url = bannerUrl?.trim() ?? '';
    if (url.isEmpty) return fill;
    return Stack(
      fit: StackFit.expand,
      children: [
        fill,
        Image.network(
          url,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        // Keeps the round buttons readable on busy photos.
        _wash(
          Colors.black.withValues(alpha: .18),
          Colors.transparent,
          vertical: true,
        ),
      ],
    );
  }

  static Widget _wash(Color from, Color to, {bool vertical = false}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: vertical ? Alignment.topCenter : Alignment.topLeft,
            end: vertical ? Alignment.center : Alignment.bottomRight,
            colors: [from, to],
          ),
        ),
      );
}
