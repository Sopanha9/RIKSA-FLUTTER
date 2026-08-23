import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/social_models.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onReact,
    required this.onShare,
  });

  final SocialPost post;
  final VoidCallback onTap;
  final VoidCallback onReact;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isReacted = post.myReaction != null;

    return Semantics(
      container: true,
      label: '${post.author.displayName}: ${post.title}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 11),
        child: Material(
          key: ValueKey('post-${post.id}'),
          color: colors.surface,
          elevation: 3,
          shadowColor: colors.shadow.withValues(alpha: .14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: .56),
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
                  _PostMetadata(post: post),
                  const SizedBox(height: 16),
                  Text(
                    post.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.24,
                      letterSpacing: -.25,
                    ),
                  ),
                  if (post.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ],
                  if (post.hasMedia) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
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
                                  color: colors.onSurfaceVariant,
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
                      const SizedBox(width: 14),
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
  const _PostMetadata({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final date = DateFormat.MMMd(
      Localizations.localeOf(context).languageCode,
    ).format(post.createdAt.toLocal());
    final authorName = post.author.displayName.trim().isEmpty
        ? post.author.username
        : post.author.displayName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _NetworkAvatar(imageUrl: post.author.avatarUrl, label: authorName),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: categoryPrefix(post.category),
                  style: TextStyle(
                    color: AppColors.brandPrimaryPressed,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                TextSpan(
                  text: ' $authorName',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: ' · $date',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.25),
          ),
        ),
      ],
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

class _NetworkAvatar extends StatelessWidget {
  const _NetworkAvatar({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = label.trim().isEmpty ? 'R' : label.trim()[0].toUpperCase();
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: .2)),
      ),
      child: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        foregroundImage: imageUrl.trim().isEmpty
            ? null
            : NetworkImage(imageUrl),
        onForegroundImageError: imageUrl.trim().isEmpty
            ? null
            : (exception, stackTrace) {},
        child: Text(
          initial,
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
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
    final foreground = selected ? Colors.white : AppColors.brandPrimaryPressed;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.brandPrimary
            : AppColors.brandPrimary.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                  size: 18,
                  color: foreground,
                ),
                const SizedBox(width: 7),
                Text(
                  _compactCount(count),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
    final colors = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            _compactCount(count),
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onPressed == null) return content;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: content,
      ),
    );
  }
}

String _compactCount(int count) {
  if (count < 1000) return '$count';
  final compact = count / 1000;
  return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}K';
}
