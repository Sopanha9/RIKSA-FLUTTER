import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/social_models.dart';
import 'post_photo.dart';
import 'photo_viewer.dart';

/// Lays out all photos attached to a post and opens the selected photo in the
/// shared paged viewer.
class SocialPostMediaGrid extends StatelessWidget {
  const SocialPostMediaGrid({
    super.key,
    required this.postId,
    required this.media,
    required this.keyPrefix,
    this.singlePhotoFit = BoxFit.cover,
    this.singlePhotoMaxHeight,
  });

  final String postId;
  final List<SocialPostMedia> media;

  /// Keeps the historic single-photo finder keys stable for existing screens.
  final String keyPrefix;
  final BoxFit singlePhotoFit;
  final double? singlePhotoMaxHeight;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    if (media.length == 1) {
      final photo = media.single;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: singlePhotoMaxHeight ?? double.infinity,
        ),
        child: _photoTile(context, 0, photo, single: true),
      );
    }

    final collage = switch (media.length) {
      2 => AspectRatio(
        aspectRatio: 8 / 5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _photoTile(context, 0, media[0])),
            _gap(context, vertical: true),
            Expanded(child: _photoTile(context, 1, media[1])),
          ],
        ),
      ),
      3 => AspectRatio(
        aspectRatio: 5 / 4,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _photoTile(context, 0, media[0])),
            _gap(context, vertical: true),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _photoTile(context, 1, media[1])),
                  _gap(context),
                  Expanded(child: _photoTile(context, 2, media[2])),
                ],
              ),
            ),
          ],
        ),
      ),
      _ => AspectRatio(
        aspectRatio: 4 / 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _photoTile(context, 0, media[0])),
                  _gap(context, vertical: true),
                  Expanded(child: _photoTile(context, 1, media[1])),
                ],
              ),
            ),
            _gap(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _photoTile(context, 2, media[2])),
                  _gap(context, vertical: true),
                  Expanded(child: _photoTile(context, 3, media[3])),
                ],
              ),
            ),
          ],
        ),
      ),
    };

    return ClipRRect(
      borderRadius: AppRadii.mediumBorder,
      child: ColoredBox(color: context.riksa.canvas, child: collage),
    );
  }

  Widget _photoTile(
    BuildContext context,
    int index,
    SocialPostMedia item, {
    bool single = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final heroTag = postPhotoHeroTag(item.url, postId: postId, index: index);
    final key = media.length == 1 && index == 0
        ? ValueKey('$keyPrefix-$postId')
        : ValueKey('$keyPrefix-$postId-$index');

    return Semantics(
      button: true,
      label: l10n.postOpenPhoto,
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: () => openPhotoViewer(
          context,
          urls: [for (final photo in media) photo.url],
          initialIndex: index,
          heroTag: heroTag,
        ),
        child: PostPhoto(
          url: item.url,
          aspectRatio: item.aspectRatio,
          fit: single ? singlePhotoFit : BoxFit.cover,
          heroTag: heroTag,
          fillBounds: !single,
          borderRadius: single ? AppRadii.mediumBorder : BorderRadius.zero,
          showBorder: single,
        ),
      ),
    );
  }

  Widget _gap(BuildContext context, {bool vertical = false}) => SizedBox(
    width: vertical ? 2 : null,
    height: vertical ? null : 2,
    child: ColoredBox(color: context.riksa.canvas),
  );
}
