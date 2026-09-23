import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/social_models.dart';
import 'social_owner_menu.dart';

/// One post as a timeline row, on the X layout: the avatar owns a left column,
/// everything else hangs off it, and rows are separated by a hairline rather
/// than boxed into cards.
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

  /// Whether an official Riksa post shows its verified mark.
  ///
  /// The mark exists to pick official posts out of a mixed feed. On a profile
  /// whose owner is already named in the header it says nothing.
  final bool highlightOfficial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final isReacted = post.myReaction != null;
    final preview = post.plainTextPreview;
    final authorName = post.author.displayName.trim().isEmpty
        ? post.author.username
        : post.author.displayName;

    return Semantics(
      container: true,
      label: '${post.author.displayName}: ${post.title}',
      child: Material(
        key: ValueKey('post-${post.id}'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.outline)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    enabled: onAuthorTap != null,
                    label: l10n.socialOpenProfile(authorName),
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('author-avatar-${post.author.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onAuthorTap,
                      child: SocialAuthorAvatar(
                        imageUrl: post.author.avatarUrl,
                        label: authorName,
                        seed: post.author.username.isEmpty
                            ? post.author.id
                            : post.author.username,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PostMetadata(
                          post: post,
                          showOfficial: highlightOfficial,
                          onAuthorTap: onAuthorTap,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                        _CommunityLine(category: post.category),
                        const SizedBox(height: 6),
                        Text(
                          post.title,
                          style: RiksaTypography.bodyStyleFor(
                            post.title,
                            theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              letterSpacing: 0,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        if (post.content.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            preview,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: RiksaTypography.bodyStyleFor(
                              preview,
                              theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 15,
                                height: 1.42,
                                color: palette.ink,
                              ),
                            ),
                          ),
                        ],
                        if (post.hasMedia) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: palette.outline),
                              ),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  post.mediaUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      ColoredBox(
                                        color: palette.surfaceRaised,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: palette.inkMuted,
                                          size: 32,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        // The first icon lines up under the text above, as on
                        // X: pull the row left by the button's inner padding.
                        Transform.translate(
                          offset: const Offset(-10, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _LightAction(
                                    key: ValueKey('comment-${post.id}'),
                                    icon: Icons.chat_bubble_outline_rounded,
                                    count: post.commentCount,
                                    semanticLabel: l10n.socialCommentLabel(
                                      post.commentCount,
                                    ),
                                    onPressed: onTap,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _PrimaryReactionButton(
                                    key: ValueKey('react-${post.id}'),
                                    count: post.reactionCount,
                                    selected: isReacted,
                                    semanticLabel: l10n.socialLikeLabel(
                                      post.reactionCount,
                                    ),
                                    onPressed: onReact,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _LightAction(
                                    key: ValueKey('share-${post.id}'),
                                    icon: Icons.ios_share_rounded,
                                    count: post.shareCount,
                                    semanticLabel: l10n.socialShareLabel(
                                      post.shareCount,
                                    ),
                                    onPressed: onShare,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

/// "5m", "3h", "2d", then a date: how old a post is, the way a timeline says
/// it.
String socialRelativeTime(BuildContext context, DateTime createdAt) {
  final language = Localizations.localeOf(context).languageCode;
  final km = language == 'km';
  final age = DateTime.now().difference(createdAt.toLocal());
  if (age.inMinutes < 1) return km ? 'ឥឡូវ' : 'now';
  if (age.inMinutes < 60) {
    return km ? '${age.inMinutes} នាទី' : '${age.inMinutes}m';
  }
  if (age.inHours < 24) return km ? '${age.inHours} ម៉ោង' : '${age.inHours}h';
  if (age.inDays < 7) return km ? '${age.inDays} ថ្ងៃ' : '${age.inDays}d';
  return DateFormat.MMMd(language).format(createdAt.toLocal());
}

class _PostMetadata extends StatelessWidget {
  const _PostMetadata({
    required this.post,
    required this.showOfficial,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
  });

  final SocialPost post;
  final bool showOfficial;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final authorName = post.author.displayName.trim().isEmpty
        ? post.author.username
        : post.author.displayName;
    final handle = post.author.username.isEmpty
        ? ''
        : '@${post.author.username} · ';
    final isOfficial = showOfficial && isOfficialRiksaAuthor(post.author);

    // The name, badge and handle share one inner row so the menu is pushed to
    // the far edge, where X keeps it; as siblings of the menu, a short name
    // left its unused share of the width sitting between them.
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  button: true,
                  enabled: onAuthorTap != null,
                  label: AppLocalizations.of(
                    context,
                  )!.socialOpenProfile(authorName),
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: ValueKey('author-name-${post.author.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onAuthorTap,
                    child: Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        authorName,
                        theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          color: palette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isOfficial) ...[
                const SizedBox(width: 3),
                const _OfficialBadge(),
              ],
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$handle${socialRelativeTime(context, post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
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

/// Which community a post lives in, under the author line.
class _CommunityLine extends StatelessWidget {
  const _CommunityLine({required this.category});
  final SocialCategory category;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final style = Theme.of(context).textTheme.labelMedium;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Icon(
                  Icons.groups_2_outlined,
                  size: 14,
                  color: palette.inkMuted,
                ),
              ),
            ),
            TextSpan(
              text: categoryPrefix(category),
              style: TextStyle(
                color: palette.brandStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: ' ${category.name}',
              style: TextStyle(color: palette.inkMuted),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: RiksaTypography.bodyStyleFor(category.name, style),
      ),
    );
  }
}

class _OfficialBadge extends StatelessWidget {
  const _OfficialBadge();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: AppLocalizations.of(context)!.official,
    child: Icon(
      Icons.verified_rounded,
      key: const ValueKey('official-account-badge'),
      size: 17,
      color: context.riksa.brand,
      semanticLabel: AppLocalizations.of(context)!.official,
    ),
  );
}

// Compact community label used in the dense post metadata line.
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
              context.riksa.surface,
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
                  color: isSelected
                      ? AppColors.socialLike
                      : context.riksa.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  _compactCount(count),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.socialLike
                        : context.riksa.inkMuted,
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
    final mutedColor = context.riksa.inkMuted;
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
