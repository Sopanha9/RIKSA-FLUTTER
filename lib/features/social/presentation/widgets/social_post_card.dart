import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../userProfile/presentation/widgets/profile_ui.dart';
import '../../data/social_models.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onReact,
    required this.onShare,
    this.onAuthorTap,
  });

  final SocialPost post;
  final VoidCallback onTap;
  final VoidCallback onReact;
  final VoidCallback onShare;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isReacted = post.myReaction != null;
    final isOfficial = isOfficialRiksaAuthor(post.author);

    return Semantics(
      container: true,
      label: '${post.author.displayName}: ${post.title}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Material(
          key: ValueKey('post-${post.id}'),
          color: isOfficial
              ? (isDark
                  ? ProfilePalette.editorialSurface(context)
                  : ProfilePalette.pinkSoft(context).withValues(alpha: .28))
              : (isDark ? ProfilePalette.panel(context) : Colors.white),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.largeBorder,
            side: BorderSide(
              color: isOfficial
                  ? ProfilePalette.pink(context).withValues(alpha: .4)
                  : ProfilePalette.border(context).withValues(alpha: .35),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostMetadata(post: post, onAuthorTap: onAuthorTap),
                  const SizedBox(height: 16),
                  Text(
                    post.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -.35,
                      color: ProfilePalette.text(context),
                    ),
                  ),
                  if (post.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ProfilePalette.muted(context),
                        height: 1.55,
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
                                  color: ProfilePalette.muted(context),
                                  size: 32,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      _PrimaryReactionButton(
                        key: ValueKey('react-${post.id}'),
                        count: post.reactionCount,
                        selected: isReacted,
                        onPressed: onReact,
                      ),
                      const SizedBox(width: 10),
                      _LightAction(
                        icon: Icons.mode_comment_outlined,
                        count: post.commentCount,
                      ),
                      const Spacer(),
                      _LightAction(
                        key: ValueKey('share-${post.id}'),
                        icon: Icons.ios_share_rounded,
                        count: post.shareCount,
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
  const _PostMetadata({required this.post, this.onAuthorTap});

  final SocialPost post;
  final VoidCallback? onAuthorTap;

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
                            color: ProfilePalette.text(context),
                            fontWeight: FontWeight.w800,
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
                        color: ProfilePalette.pink(context),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                    ),
                    TextSpan(
                      text: ' ${post.category.name} · $date',
                      style: TextStyle(
                        color: ProfilePalette.muted(context),
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
        color: ProfilePalette.pinkSoft(context),
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 12,
            color: ProfilePalette.pink(context),
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.official,
            style: theme.textTheme.labelSmall?.copyWith(
              color: ProfilePalette.aubergine(context),
              fontSize: 10,
              fontWeight: FontWeight.w900,
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
    final palette = socialAvatarPalette(seed);
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
    required this.onPressed,
  });

  final int count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected
            ? ProfilePalette.pinkSoft(context)
            : Colors.transparent,
        borderRadius: AppRadii.fullBorder,
        child: InkWell(
          borderRadius: AppRadii.fullBorder,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.thumb_up_rounded
                      : Icons.thumb_up_outlined,
                  size: 17,
                  color: isSelected
                      ? ProfilePalette.pink(context)
                      : ProfilePalette.muted(context),
                ),
                const SizedBox(width: 6),
                Text(
                  _compactCount(count),
                  style: TextStyle(
                    color: isSelected
                        ? ProfilePalette.aubergine(context)
                        : ProfilePalette.muted(context),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
    this.onPressed,
  });

  final IconData icon;
  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final mutedColor = ProfilePalette.muted(context);
    final content = Material(
      color: Colors.transparent,
      borderRadius: AppRadii.fullBorder,
      child: InkWell(
        borderRadius: AppRadii.fullBorder,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    if (onPressed == null) return content;
    return Semantics(
      button: true,
      child: content,
    );
  }
}

String _compactCount(int count) {
  if (count < 1000) return '$count';
  final compact = count / 1000;
  return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}K';
}
