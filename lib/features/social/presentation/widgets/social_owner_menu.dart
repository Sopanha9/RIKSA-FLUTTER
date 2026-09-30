import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

enum _OwnerAction { edit, delete }

/// Edit and delete affordances for a community post the reader wrote.
///
/// Shown only when the post's `author.id` matches the signed-in user; the
/// server is still the authority and answers owner-only mutations.
class SocialOwnerMenu extends StatelessWidget {
  const SocialOwnerMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.postId,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Used for a stable widget key in tests and in long lists.
  final String? postId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return PopupMenuButton<_OwnerAction>(
      key: postId == null ? null : ValueKey('post-options-$postId'),
      tooltip: l10n.postOptions,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: context.riksa.inkMuted,
      ),
      // A bare glyph, as on X: the theme's filled disc behind icon buttons
      // made it read as a second avatar in the author line.
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      color: context.riksa.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.mediumBorder),
      onSelected: (action) => switch (action) {
        _OwnerAction.edit => onEdit(),
        _OwnerAction.delete => onDelete(),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _OwnerAction.edit,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined, size: 20),
            title: Text(l10n.editPost),
          ),
        ),
        PopupMenuItem(
          value: _OwnerAction.delete,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l10n.deletePost,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }
}

/// Deleting is permanent for every reader, so it always goes through here.
Future<bool> confirmSocialPostDeletion(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deletePostTitle),
      content: Text(l10n.deletePostMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.keepPost),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
