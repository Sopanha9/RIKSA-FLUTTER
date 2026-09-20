import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/social_models.dart';
import 'social_owner_menu.dart';
import 'social_palette.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onReact,
    required this.onShare,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
    this.highlightOfficial = true,
  });

  final SocialPost post;
  final VoidCallback onTap;
  final VoidCallback onReact;
  final VoidCallback onShare;
  final VoidCallback? onAuthorTap;

  /// Set only for the reader's own posts; both together show the owner menu.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Whether an official Riksa post gets its tinted surface.
  ///
  /// The tint exists to pick official posts out of a mixed feed. On a profile
  /// whose owner is already named in the header it says nothing, so the author's
  /// own list renders every card the same way readers see everyone else's.
  final bool highlightOfficial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isReacted = post.myReaction != null;
    final isOfficial = isOfficialRiksaAuthor(post.author);
    final tinted = isOfficial && highlightOfficial;

    return Semantics(
      container: true,
      label: '${post.author.displayName}: ${post.title}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Material(
          key: ValueKey('post-${post.id}'),
          color: tinted
              ? (isDark
                    ? SocialPalette.editorialSurface(context)
                    : Color.lerp(
                        SocialPalette.surface(context),
                        SocialPalette.pinkSoft(context),
                        .18,
                      ))
              : SocialPalette.surface(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.largeBorder,
            side: BorderSide(color: context.riksa.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostMetadata(
                    post: post,
                    onAuthorTap: onAuthorTap,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    post.title,
                    style: RiksaTypography.bodyStyleFor(
                      post.title,
                      theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: 0,
                        color: SocialPalette.text(context),
                      ),
                    ),
                  ),
                  if (post.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      post.plainTextPreview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        post.plainTextPreview,
                        theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: SocialPalette.muted(context),
                          height: 1.42,
                        ),
                      ),
                    ),
                  ],
                  if (post.hasMedia) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: AppRadii.mediumBorder,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          post.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                                color: colors.surfaceContainer,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: SocialPalette.muted(context),
                                  size: 32,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _PrimaryReactionButton(
                        key: ValueKey('react-${post.id}'),
                        count: post.reactionCount,
                        selected: isReacted,
                        semanticLabel: l10n.socialLikeLabel(post.reactionCount),
                        onPressed: onReact,
                      ),
                      const SizedBox(width: 10),
                      _LightAction(
                        key: ValueKey('comment-${post.id}'),
                        icon: CupertinoIcons.chat_bubble,
                        count: post.commentCount,
                        semanticLabel: l10n.socialCommentLabel(
                          post.commentCount,
                        ),
                        onPressed: onTap,
                      ),
                      const Spacer(),
                      _LightAction(
                        key: ValueKey('share-${post.id}'),
                        icon: Icons.share_rounded,
                        count: post.shareCount,
                        semanticLabel: l10n.socialShareLabel(post.shareCount),
                        onPressed: onShare,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostMetadata extends StatelessWidget {
  const _PostMetadata({
    required this.post,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
  });

  final SocialPost post;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat.MMMd(
      Localizations.localeOf(context).languageCode,
    ).format(post.createdAt.toLocal());
    final authorName = post.author.displayName.trim().isEmpty
        ? post.author.username
        : post.author.displayName;
    final isOfficial = isOfficialRiksaAuthor(post.author);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          key: ValueKey('author-avatar-${post.author.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: onAuthorTap,
          child: SocialAuthorAvatar(
            imageUrl: post.author.avatarUrl,
            label: authorName,
            seed: post.author.username.isEmpty
                ? post.author.id
                : post.author.username,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      key: ValueKey('author-name-${post.author.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onAuthorTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: SocialPalette.text(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isOfficial) ...[
                    const SizedBox(width: 7),
                    const _OfficialBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: categoryPrefix(post.category),
                      style: TextStyle(
                        color: SocialPalette.text(context),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    TextSpan(
                      text: ' ${post.category.name} · $date',
                      style: TextStyle(
                        color: SocialPalette.muted(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
              ),
            ],
          ),
        ),
        if (onEdit != null && onDelete != null)
          SocialOwnerMenu(
            postId: post.id,
            onEdit: onEdit!,
            onDelete: onDelete!,
          ),
      ],
    );
  }
}

class _OfficialBadge extends StatelessWidget {
  const _OfficialBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('official-account-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SocialPalette.pinkSoft(context),
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 12,
            color: SocialPalette.pink(context),
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.official,
            style: theme.textTheme.labelSmall?.copyWith(
              color: SocialPalette.aubergine(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact community label used in the dense post metadata line.
String categoryPrefix(SocialCategory category) {
  final normalizedName = _normalizeCategory(category.name);
  final normalizedSlug = _normalizeCategory(category.slug);
  final key = normalizedSlug.isNotEmpty ? normalizedSlug : normalizedName;
  const prefixes = <String, String>{
    'mathematics': 'math',
    'math': 'math',
    'biology': 'bio',
    'bio': 'bio',
    'chemistry': 'chem',
    'chem': 'chem',
    'computer science': 'cs',
    'computerscience': 'cs',
    'cs': 'cs',
    'physics': 'phys',
    'environmental science': 'env',
    'environmentalscience': 'env',
    'earth science': 'earth',
    'earthscience': 'earth',
    'study skills': 'study',
    'studyskills': 'study',
    'english': 'eng',
    'khmer': 'kh',
    'history': 'hist',
    'geography': 'geo',
    'economics': 'econ',
    'technology': 'tech',
    'engineering': 'engr',
    'astronomy': 'astro',
    'general': 'general',
  };

  final known = prefixes[key] ?? prefixes[normalizedName];
  if (known != null) return '$known/';

  final words = category.name
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length > 1) {
    final initials = words.map((word) => word[0]).join();
    return '${initials.substring(0, initials.length.clamp(1, 6))}/';
  }
  final fallback = key.replaceAll(' ', '');
  return '${fallback.isEmpty ? 'topic' : fallback.substring(0, fallback.length.clamp(1, 8))}/';
}

String _normalizeCategory(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[-_]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool isOfficialRiksaAuthor(SocialAuthor author) {
  final username = author.username.toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  final displayName = author.displayName.toLowerCase().trim();
  return username == 'riksa' ||
      username == 'riksaadmin' ||
      username == 'adminriksa' ||
      displayName == 'riksa admin';
}

class SocialAuthorAvatar extends StatelessWidget {
  const SocialAuthorAvatar({
    super.key,
    required this.imageUrl,
    required this.label,
    required this.seed,
    this.size = 44,
  });

  final String imageUrl;
  final String label;
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final light = socialAvatarPalette(seed);
    // Pastel discs glare on a dark feed; there the tint deepens and the
    // letter takes the pastel instead.
    final palette = Theme.of(context).brightness == Brightness.dark
        ? (
            background: Color.alphaBlend(
              light.foreground.withValues(alpha: .35),
              SocialPalette.surface(context),
            ),
            foreground: light.background,
          )
        : light;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.foreground.withValues(alpha: .2)),
      ),
      child: RiksaAvatarImage(
        value: imageUrl,
        label: label,
        size: size - 4,
        backgroundColor: palette.background,
        foregroundColor: palette.foreground,
      ),
    );
  }
}

({Color background, Color foreground}) socialAvatarPalette(String seed) {
  const palettes = [
    (background: Color(0xFFEDE9FE), foreground: Color(0xFF6D28D9)),
    (background: Color(0xFFDBEAFE), foreground: Color(0xFF1D4ED8)),
    (background: Color(0xFFFCE7F3), foreground: Color(0xFFBE185D)),
    (background: Color(0xFFFEF3C7), foreground: Color(0xFFB45309)),
    (background: Color(0xFFCFFAFE), foreground: Color(0xFF0E7490)),
    (background: Color(0xFFE0E7FF), foreground: Color(0xFF4338CA)),
    (background: Color(0xFFFFEDD5), foreground: Color(0xFFC2410C)),
    (background: Color(0xFFDCFCE7), foreground: Color(0xFF166534)),
  ];
  var hash = 0x811C9DC5;
  for (final unit in seed.toLowerCase().codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
  }
  return palettes[hash % palettes.length];
}

class _PrimaryReactionButton extends StatelessWidget {
  const _PrimaryReactionButton({
    super.key,
    required this.count,
    required this.selected,
    required this.semanticLabel,
    required this.onPressed,
  });

  final int count;
  final bool selected;

  /// What a screen reader says: the count alone never explains the action.
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected;
    return Semantics(
      button: true,
      toggled: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.fullBorder,
        child: InkWell(
          borderRadius: AppRadii.fullBorder,
          onTap: onPressed,
          child: Container(
            // The icon stays small; the target a thumb has to hit does not.
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 17,
                  color: isSelected ? Colors.red : SocialPalette.muted(context),
                ),
                const SizedBox(width: 6),
                Text(
                  _compactCount(count),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.red
                        : SocialPalette.muted(context),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
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

class _LightAction extends StatelessWidget {
  const _LightAction({
    super.key,
    required this.icon,
    required this.count,
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final int count;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final mutedColor = SocialPalette.muted(context);
    final content = Material(
      color: Colors.transparent,
      borderRadius: AppRadii.fullBorder,
      child: InkWell(
        borderRadius: AppRadii.fullBorder,
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                _compactCount(count),
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onPressed == null) return ExcludeSemantics(child: content);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: content,
    );
  }
}

String _compactCount(int count) {
  if (count < 1000) return '$count';
  final compact = count / 1000;
  return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}K';
}
