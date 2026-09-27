import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/social_models.dart';

/// One selected image and the state of its immediate upload.
class PostImageDraft {
  const PostImageDraft({
    required this.id,
    required this.path,
    this.remote = false,
    this.media,
    this.progress,
    this.error,
  });

  final String id;
  final String path;
  final bool remote;
  final SocialPostMedia? media;
  final double? progress;
  final String? error;

  bool get uploading => media == null && error == null;
  bool get uploaded => media != null;
}

/// Ordered photo thumbnails with independent upload status and retry/remove
/// actions. Upload work itself stays in the composer.
class PostImageField extends StatelessWidget {
  const PostImageField({
    super.key,
    required this.photos,
    required this.onRemove,
    required this.onRetry,
    required this.onReorder,
    this.enabled = true,
  });

  final List<PostImageDraft> photos;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onRetry;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final limitReached = photos.length >= 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty)
          SizedBox(
            height: 124,
            child: ReorderableListView.builder(
              key: const ValueKey('post-photos-reorder-list'),
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              // ignore: deprecated_member_use
              onReorder: onReorder,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return SizedBox(
                  key: ValueKey('post-photo-item-${photo.id}'),
                  width: 116,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _PhotoThumbnail(
                      photo: photo,
                      index: index,
                      enabled: enabled,
                      onRemove: () => onRemove(photo.id),
                      onRetry: () => onRetry(photo.id),
                    ),
                  ),
                );
              },
            ),
          ),
        if (limitReached)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.postPhotosLimitReached,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.riksa.inkMuted),
            ),
          ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.index,
    required this.enabled,
    required this.onRemove,
    required this.onRetry,
  });

  final PostImageDraft photo;
  final int index;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final borderRadius = BorderRadius.circular(12);
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: borderRadius,
                child: _previewImage(
                  photo.path,
                  palette.surfaceRaised,
                  remote: photo.remote,
                ),
              ),
              if (photo.uploading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: .36),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          value: photo.progress,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (photo.error != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: .68),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          photo.error ?? l10n.postPhotosUploadFailed,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        TextButton(
                          key: ValueKey('post-photo-retry-${photo.id}'),
                          onPressed: enabled ? onRetry : null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(44, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.postPhotosRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: IconButton.filledTonal(
                  key: ValueKey('post-photo-remove-${photo.id}'),
                  tooltip: l10n.postPhotosRemove,
                  onPressed: enabled ? onRemove : null,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.black.withValues(alpha: .58),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 17),
                ),
              ),
              if (photo.uploaded)
                const PositionedDirectional(
                  top: 5,
                  start: 5,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ReorderableDelayedDragStartListener(
                key: ValueKey('post-photo-reorder-${photo.id}'),
                index: index,
                // Not a Tooltip: its long-press would win over the delayed
                // drag and the handle could never start a reorder.
                child: Semantics(
                  label: l10n.postPhotosReorder,
                  child: const Icon(Icons.drag_indicator_rounded, size: 18),
                ),
              ),
              if (photo.uploading)
                Text(
                  l10n.postPhotosUploading(
                    ((photo.progress ?? 0) * 100).round(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: palette.inkMuted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewImage(String path, Color placeholder, {required bool remote}) {
    if (remote || kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(color: placeholder),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(color: placeholder),
    );
  }
}
