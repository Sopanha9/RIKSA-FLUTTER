import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_glass.dart';
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
      child: ClipRRect(
        borderRadius: AppRadii.fullBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: ProfilePalette.panelSoft(context).withValues(alpha: 0.6),
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
                    _ProfileGlassActionCircle(
                      icon: Icons.add_rounded,
                      color: ProfilePalette.aubergine(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileGlassActionCircle extends StatelessWidget {
  const _ProfileGlassActionCircle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = context.riksaGlass;
    final outerFill = isDark
        ? glass.selectedFill
        : glass.fill;

    return SizedBox.square(
      dimension: 40,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: outerFill,
          shape: CircleBorder(side: BorderSide(color: glass.border)),
          shadows: RiksaElevation.overlay(theme.brightness),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: glass.blurSigma,
              sigmaY: glass.blurSigma,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: glass.selectedFill,
                  shape: CircleBorder(
                    side: BorderSide(color: glass.selectedBorder),
                  ),
                  shadows: RiksaElevation.raised(theme.brightness),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
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
          fontWeight: FontWeight.w600,
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
            ProfilePostsEmptyPixelIcon(
              color: ProfilePalette.green(context),
              accent: ProfilePalette.aubergine(context),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.noPostsYet,
              textAlign: TextAlign.center,
              style: TextStyle(color: ProfilePalette.muted(context)),
            ),
            const SizedBox(height: 14),
            _ProfileEmptyCreateButton(
              key: const ValueKey('profile-empty-create-post'),
              label: l10n.writeFirstPost,
              onTap: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEmptyCreateButton extends StatelessWidget {
  const _ProfileEmptyCreateButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 240,
        height: 46,
        child: RiksaGlassSurface(
          padding: const EdgeInsets.all(4),
          child: RiksaGlassSelection(
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadii.fullBorder,
              child: InkWell(
                borderRadius: AppRadii.fullBorder,
                onTap: onTap,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.bodyStyleFor(
                      label,
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePostsEmptyPixelIcon extends StatelessWidget {
  const ProfilePostsEmptyPixelIcon({
    super.key,
    required this.color,
    required this.accent,
    this.size = 58,
  });

  final Color color;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _ProfilePostsEmptyPixelPainter(color: color, accent: accent),
    ),
  );
}

class _ProfilePostsEmptyPixelPainter extends CustomPainter {
  const _ProfilePostsEmptyPixelPainter({
    required this.color,
    required this.accent,
  });

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 20;
    final outline = Paint()
      ..color = Color.lerp(color, Colors.black, .24)!
      ..style = PaintingStyle.fill;
    final fill = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.fill;
    final shade = Paint()
      ..color = color.withValues(alpha: .22)
      ..style = PaintingStyle.fill;
    final main = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final purple = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    final purpleSoft = Paint()
      ..color = accent.withValues(alpha: .26)
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = accent.withValues(alpha: .1)
      ..style = PaintingStyle.fill;

    void px(Paint paint, int x, int y, [int w = 1, int h = 1]) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    px(glow, 2, 3, 16, 14);
    px(purpleSoft, 3, 4, 14, 12);

    px(outline, 4, 3, 12, 1);
    px(outline, 3, 4, 1, 10);
    px(outline, 16, 4, 1, 9);
    px(outline, 4, 13, 7, 1);
    px(outline, 10, 14, 1, 2);
    px(outline, 11, 15, 3, 1);
    px(outline, 14, 13, 2, 1);

    px(fill, 4, 4, 12, 9);
    px(shade, 5, 5, 10, 1);
    px(shade, 5, 11, 8, 1);
    px(fill, 11, 13, 3, 2);

    px(main, 6, 7, 8, 1);
    px(main, 6, 9, 6, 1);
    px(main, 6, 11, 4, 1);
    px(purple, 13, 10, 1, 1);
    px(purple, 14, 9, 1, 1);

    px(outline, 2, 16, 3, 1);
    px(outline, 15, 16, 3, 1);
    px(main, 5, 17, 10, 1);
  }

  @override
  bool shouldRepaint(covariant _ProfilePostsEmptyPixelPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
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
                    fontWeight: FontWeight.w600,
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
