import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// The image attached to a post being written, in one of three states:
/// absent, uploading, or held as a URL the API returned.
///
/// The widget owns no upload logic — the composer does — so the same field can
/// sit on any screen that needs a picture.
class PostImageField extends StatelessWidget {
  const PostImageField({
    super.key,
    required this.imageUrl,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
    this.enabled = true,
  });

  /// The uploaded image's URL, or null when none is attached yet.
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool enabled;

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (uploading) {
      return _Frame(
        key: const ValueKey('post-image-uploading'),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(l10n.photoUploading, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (!_hasImage) {
      return OutlinedButton.icon(
        key: const ValueKey('post-image-add'),
        onPressed: enabled ? onPick : null,
        icon: const Icon(Icons.image_outlined),
        label: Text(l10n.addPhoto),
      );
    }

    return Column(
      key: const ValueKey('post-image-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadii.mediumBorder,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => ColoredBox(
                color: theme.colorScheme.surfaceContainer,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.riksa.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              key: const ValueKey('post-image-change'),
              onPressed: enabled ? onPick : null,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(l10n.changePhoto),
            ),
            const Spacer(),
            TextButton.icon(
              key: const ValueKey('post-image-remove'),
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(l10n.removePhoto),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      borderRadius: AppRadii.mediumBorder,
      border: Border.all(color: context.riksa.inkMuted.withValues(alpha: .3)),
    ),
    child: child,
  );
}
