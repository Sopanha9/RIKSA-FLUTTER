import 'package:flutter/material.dart';

import '../../../learning/presentation/learning_design.dart';
import '../../data/social_models.dart';

/// A community's square icon.
///
/// Subjects keep their pixel-art tile so they match the learning screens. Any
/// other community shows the image its creator set, and falls back to the
/// plain subject tile when there is none or it fails to load.
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.community,
    required this.size,
  });

  final SocialCategory community;
  final double size;

  @override
  Widget build(BuildContext context) {
    final subject = stemSubjectFor(community.name);
    final tile = StemSubjectTile(subject: subject, size: size);
    final url = community.iconUrl?.trim() ?? '';
    if (subject != StemSubject.other || url.isEmpty) return tile;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .26),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => tile,
        loadingBuilder: (_, child, progress) => progress == null ? child : tile,
      ),
    );
  }
}
