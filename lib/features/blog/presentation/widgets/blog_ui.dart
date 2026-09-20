import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../core/widgets/riksa_components.dart';
import '../../../userProfile/data/public_profile.dart';
import '../../providers/blog_provider.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Shared metrics for the timeline-style blog surfaces.
///
/// The blog reads as one continuous sheet: rows sit directly on the surface
/// colour and are separated by a hairline instead of by cards.
abstract final class BlogMetrics {
  static const double gutter = 16;
  static const double rowAvatar = 40;
  static const double detailAvatar = 44;
  static const double hairline = 1;
  static const double readingWidth = 720;
}

/// Surface the blog sheet sits on. Rows have no card of their own.
Color blogSheetColor(BuildContext context) => context.riksa.canvas;

Color blogAvatarBackground(BuildContext context) => context.riksa.blushSoft;

Color blogAvatarForeground(BuildContext context) =>
    Theme.of(context).colorScheme.primary;

/// Name shown for an author whose public profile could not be resolved.
String blogAuthorName(BuildContext context, PublicProfile? profile) =>
    profile?.preferredName.isNotEmpty ?? false
    ? profile!.preferredName
    : AppLocalizations.of(context)!.blogUnknownAuthor;

/// Short relative stamp in the shape X uses: `4m`, `7h`, `12 Jan`.
String blogTimeLabel(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final elapsed = DateTime.now().difference(local);
  final language = Localizations.localeOf(context).languageCode;
  if (elapsed.isNegative || elapsed.inMinutes < 1) return 'now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d';
  if (local.year == DateTime.now().year) {
    return DateFormat.MMMd(language).format(local);
  }
  return DateFormat.yMMMd(language).format(local);
}

/// Full date for the article header, where the reader has room for it.
String blogFullDate(BuildContext context, DateTime date) => DateFormat.yMMMd(
  Localizations.localeOf(context).languageCode,
).format(date.toLocal());

/// Compact metric label: `938`, `1.2K`, `3.4M`.
String blogCountLabel(int value) {
  if (value < 1000) return '$value';
  if (value < 1000000) return '${_trimmed(value / 1000)}K';
  return '${_trimmed(value / 1000000)}M';
}

String _trimmed(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// Round author avatar with the Riksa fallback initial.
class BlogAvatar extends StatelessWidget {
  const BlogAvatar({
    super.key,
    required this.profile,
    required this.size,
    this.onTap,
  });

  final PublicProfile? profile;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = RiksaAvatarImage(
      value: profile?.avatarUrl,
      label: blogAuthorName(context, profile),
      size: size,
      backgroundColor: blogAvatarBackground(context),
      foregroundColor: blogAvatarForeground(context),
      frameTier: profile?.currentTier,
    );
    if (onTap == null) return avatar;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: avatar,
    );
  }
}

/// `Name ✓ @handle · 7h` on a single line, as it reads in a timeline row.
class BlogAuthorMetaLine extends StatelessWidget {
  const BlogAuthorMetaLine({
    super.key,
    required this.profile,
    required this.createdAt,
  });

  final PublicProfile? profile;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final name = blogAuthorName(context, profile);
    final handle = profile?.username.trim() ?? '';
    final trailing = handle.isEmpty
        ? blogTimeLabel(context, createdAt)
        : '@$handle · ${blogTimeLabel(context, createdAt)}';

    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RiksaTypography.bodyStyleFor(
              name,
              theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ),
        ),
        if (profile?.isVerified ?? false) ...[
          const SizedBox(width: 4),
          const BlogVerifiedBadge(size: 15),
        ],
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            trailing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.inkMuted),
          ),
        ),
      ],
    );
  }
}

class BlogVerifiedBadge extends StatelessWidget {
  const BlogVerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context)!.blogVerified,
    child: Icon(
      Icons.verified_rounded,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

/// Quiet icon + count action used across the timeline and the article bar.
class BlogAction extends StatelessWidget {
  const BlogAction({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.activeIcon,
    this.selected = false,
    this.selectedColor,
    this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String semanticLabel;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final active = selectedColor ?? Theme.of(context).colorScheme.primary;
    final color = selected ? active : palette.inkMuted;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? (activeIcon ?? icon) : icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small category label. The tab strip carries filtering, so this only names
/// where a post lives.
class BlogCategoryTag extends ConsumerWidget {
  const BlogCategoryTag({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(blogCategoryProvider(categoryId));
    if (category == null) return const SizedBox.shrink();
    final palette = context.riksa;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surfaceRaised,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: palette.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Full-bleed hairline used between timeline rows.
class BlogDivider extends StatelessWidget {
  const BlogDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
    height: BlogMetrics.hairline,
    thickness: BlogMetrics.hairline,
    indent: indent,
    color: context.riksa.outline,
  );
}

/// Slim header for the blog surfaces: back control, bold title, optional
/// trailing action. Deliberately lighter than the app-wide page header so the
/// timeline stays the loudest thing on screen.
class BlogTopBar extends StatelessWidget {
  const BlogTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: RiksaSpacing.xs),
            IconButton(
              onPressed: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: palette.ink,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
            const SizedBox(width: RiksaSpacing.xxs),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  title,
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            ?trailing,
            const SizedBox(width: RiksaSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// Underline tab, in the shape of the X timeline switcher.
class BlogTab extends StatelessWidget {
  const BlogTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    // A pill, filled lavender when selected, as on the reference blog tabs.
    return Semantics(
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.fullBorder,
          child: AnimatedContainer(
            duration: RiksaMotion.resolve(context, RiksaMotion.fast),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? palette.brandSoft : Colors.transparent,
              borderRadius: AppRadii.fullBorder,
            ),
            child: Text(
              label,
              style: RiksaTypography.bodyStyleFor(
                label,
                theme.textTheme.labelLarge?.copyWith(
                  color: selected ? palette.brand : palette.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Edit and delete affordances for a post the signed-in user owns.
class BlogOwnerMenu extends StatelessWidget {
  const BlogOwnerMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.onImage = false,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// True when the control sits on top of a cover photo and needs its own
  /// contrast instead of the sheet's.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: .48)
            : Colors.transparent,
        shape: const CircleBorder(),
      ),
      child: PopupMenuButton<_OwnerAction>(
        tooltip: AppLocalizations.of(context)!.blogPostOptions,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 22,
          color: onImage ? Colors.white : palette.inkMuted,
        ),
        color: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mediumBorder,
        ),
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
              title: Text(AppLocalizations.of(context)!.blogEditPost),
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
                AppLocalizations.of(context)!.blogDeletePost,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OwnerAction { edit, delete }

/// Deleting is permanent on the server, so it always goes through here.
Future<bool> confirmBlogPostDeletion(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.blogDeleteConfirmTitle),
      content: Text(l10n.blogDeleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.blogKeepPost),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.discardAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Rounded media frame shared by the timeline row and the composer preview.
class BlogCoverImage extends StatelessWidget {
  const BlogCoverImage({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
    this.borderRadius = AppRadii.largeBorder,
  });

  final String url;
  final double aspectRatio;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: palette.outline),
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: palette.surfaceRaised,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: palette.inkMuted,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet full-screen message. Deliberately container-free so it matches the
/// timeline rather than the pastel cards used elsewhere in the app.
class BlogNotice extends StatelessWidget {
  const BlogNotice({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional quieter action shown beside the primary one.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(RiksaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: palette.inkMuted),
              const SizedBox(height: RiksaSpacing.md),
              Text(
                title,
                style: RiksaTypography.titleStyleFor(
                  title,
                  theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: RiksaSpacing.xs),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: RiksaSpacing.lg),
                Row(
                  children: [
                    FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(width: RiksaSpacing.xs),
                      TextButton(
                        onPressed: onSecondary,
                        child: Text(secondaryLabel!),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Timeline placeholder while the first page loads.
class BlogRowSkeleton extends StatelessWidget {
  const BlogRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      BlogMetrics.gutter,
      14,
      BlogMetrics.gutter,
      14,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RiksaSkeletonCircle(size: BlogMetrics.rowAvatar),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              RiksaSkeleton(height: 12, width: 160, radius: AppRadii.full),
              SizedBox(height: 12),
              RiksaSkeleton(height: 15, radius: AppRadii.full),
              SizedBox(height: 8),
              RiksaSkeleton(height: 12, width: 220, radius: AppRadii.full),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Circular variant of [RiksaSkeleton] for avatar placeholders.
class RiksaSkeletonCircle extends StatelessWidget {
  const RiksaSkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      RiksaSkeleton(height: size, width: size, radius: size / 2);
}

/// Reading typography for the article body.
MarkdownStyleSheet blogMarkdownStyleSheet(
  BuildContext context,
  String content, {
  double textScale = 1.0,
}) {
  final theme = Theme.of(context);
  final palette = context.riksa;
  final hasKhmer = RiksaTypography.containsKhmer(content);

  TextStyle blogStyle(TextStyle? style) =>
      RiksaTypography.bodyStyleFor(content, style) ?? const TextStyle();

  final paragraph = blogStyle(
    theme.textTheme.bodyLarge?.copyWith(
      color: palette.ink,
      fontSize: 15 * textScale,
      height: 1.75,
    ),
  );
  final heading = blogStyle(
    theme.textTheme.titleLarge?.copyWith(
      color: palette.ink,
      fontWeight: FontWeight.w600,
      height: hasKhmer ? 1.5 : 1.35,
      letterSpacing: 0,
    ),
  );

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 6),
    h1: heading.copyWith(fontSize: 21 * textScale),
    h2: heading.copyWith(fontSize: 19 * textScale),
    h3: heading.copyWith(fontSize: 17 * textScale),
    h1Padding: const EdgeInsets.only(top: 14, bottom: 6),
    h2Padding: const EdgeInsets.only(top: 12, bottom: 5),
    h3Padding: const EdgeInsets.only(top: 10, bottom: 4),
    strong: blogStyle(const TextStyle(fontWeight: FontWeight.w700)),
    em: blogStyle(const TextStyle(fontStyle: FontStyle.italic)),
    code: blogStyle(
      theme.textTheme.bodyMedium?.copyWith(
        color: palette.ink,
        fontSize: 13 * textScale,
        backgroundColor: palette.surfaceRaised,
      ),
    ),
    codeblockDecoration: BoxDecoration(
      color: palette.surfaceRaised,
      borderRadius: AppRadii.mediumBorder,
      border: Border.all(color: palette.outline),
    ),
    codeblockPadding: const EdgeInsets.all(RiksaSpacing.sm),
    blockquote: paragraph.copyWith(color: palette.inkMuted),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: theme.colorScheme.primary, width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(left: RiksaSpacing.md),
    listBullet: paragraph,
    blockSpacing: 12,
    listIndent: 22,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: palette.outline)),
    ),
  );
}
