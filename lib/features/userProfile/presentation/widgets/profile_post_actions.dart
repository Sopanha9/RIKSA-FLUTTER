import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/data/auth_models.dart';
import 'profile_ui.dart';

/// Write, edit and delete affordances for the author's own posts, gathered on
/// the profile so the whole lifecycle of a post lives where the author already
/// goes to look at it.

/// Doorway to the composer, sitting at the top of the profile's posts tab in
/// the same shape the community feed uses, so the gesture transfers.
class ProfileComposerPrompt extends StatelessWidget {
  const ProfileComposerPrompt({
    super.key,
    required this.user,
    required this.avatarPath,
    required this.onTap,
    this.frameTier,
  });

  final AuthUser user;
  final String? avatarPath;
  final VoidCallback onTap;
  final String? frameTier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.profileComposerPrompt,
      child: Material(
        color: ProfilePalette.panelSoft(context),
        borderRadius: AppRadii.fullBorder,
        child: InkWell(
          key: const ValueKey('profile-create-post'),
          onTap: onTap,
          borderRadius: AppRadii.fullBorder,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                RiksaProfileAvatar(
                  user: user,
                  radius: 19,
                  avatarPath: avatarPath,
                  borderColor: ProfilePalette.border(context),
                  ringColor: ProfilePalette.panel(context),
                  frameTier: frameTier,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    l10n.profileComposerPrompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ProfilePalette.muted(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ProfilePalette.aubergine(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 21,
                    color: ProfilePalette.onAubergine(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet count labelling the list below. The composer sits directly above
/// it, so this carries no action of its own.
class ProfilePostsSummary extends StatelessWidget {
  const ProfilePostsSummary({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        l10n.profilePostCount(count),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ProfilePalette.muted(context),
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

/// The posts tab with nothing in it yet. Unlike a plain empty panel this one
/// carries the action that fills it.
class ProfilePostsEmpty extends StatelessWidget {
  const ProfilePostsEmpty({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfilePanel(
      key: const ValueKey('profile-posts-empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(
              Icons.forum_outlined,
              color: ProfilePalette.green(context),
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.noPostsYet,
              textAlign: TextAlign.center,
              style: TextStyle(color: ProfilePalette.muted(context)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('profile-empty-create-post'),
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: ProfilePalette.aubergine(context),
                foregroundColor: ProfilePalette.onAubergine(context),
                minimumSize: const Size(0, 46),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.fullBorder,
                ),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                l10n.writeFirstPost,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ProfilePostAction { edit, delete }

/// Edit and delete as full-width rows, opened by long-pressing a post.
///
/// The same actions live in the card's overflow menu; this second path exists
/// because a long press is the gesture people already reach for on their own
/// content, and it gives the destructive choice a target big enough to be
/// deliberate.
Future<ProfilePostAction?> showProfilePostActions(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<ProfilePostAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.large),
        ),
        // A Material, not a plain coloured box: the rows below are ListTiles
        // and paint their ink on the nearest Material ancestor.
        child: Material(
          color: ProfilePalette.panel(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              20 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ProfilePalette.border(context),
                      borderRadius: AppRadii.fullBorder,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title.trim().isEmpty ? l10n.managePost : title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ProfilePalette.text(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const ValueKey('profile-post-action-edit'),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.mediumBorder,
                  ),
                  leading: Icon(
                    Icons.edit_outlined,
                    color: ProfilePalette.text(context),
                  ),
                  title: Text(
                    l10n.editPost,
                    style: TextStyle(
                      color: ProfilePalette.text(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ProfilePostAction.edit),
                ),
                ListTile(
                  key: const ValueKey('profile-post-action-delete'),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.mediumBorder,
                  ),
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    l10n.deletePost,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ProfilePostAction.delete),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
