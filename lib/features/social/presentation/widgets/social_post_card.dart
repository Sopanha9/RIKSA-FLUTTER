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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: ValueKey('post-${post.id}'),
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthorRow(post: post),
              const SizedBox(height: 15),
              Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (post.content.trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  post.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
              if (post.hasMedia) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
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
              const SizedBox(height: 13),
              Row(
                children: [
                  _ActionPill(
                    key: ValueKey('react-${post.id}'),
                    icon: isReacted
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_upward_outlined,
                    count: post.reactionCount,
                    selected: isReacted,
                    selectedColor: AppColors.brandPrimary,
                    onPressed: onReact,
                  ),
                  const SizedBox(width: 8),
                  _ActionPill(
                    icon: Icons.mode_comment_outlined,
                    count: post.commentCount,
                  ),
                  const Spacer(),
                  _ActionPill(
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
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final date = DateFormat.MMMd(
      Localizations.localeOf(context).languageCode,
    ).format(post.createdAt.toLocal());

    return Row(
      children: [
        _NetworkAvatar(
          imageUrl: post.author.avatarUrl,
          label: post.author.displayName,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.displayName.isEmpty
                    ? post.author.username
                    : post.author.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${post.author.username} · $date',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 112),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            post.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkAvatar extends StatelessWidget {
  const _NetworkAvatar({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = label.trim().isEmpty ? 'R' : label.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.primaryContainer,
      foregroundImage: imageUrl.trim().isEmpty ? null : NetworkImage(imageUrl),
      onForegroundImageError: imageUrl.trim().isEmpty
          ? null
          : (exception, stackTrace) {},
      child: Text(
        initial,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    super.key,
    required this.icon,
    required this.count,
    this.selected = false,
    this.selectedColor,
    this.onPressed,
  });

  final IconData icon;
  final int count;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected
        ? selectedColor ?? colors.primary
        : colors.onSurfaceVariant;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: .12)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Text(
              _compactCount(count),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
    if (onPressed == null) return child;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: child,
      ),
    );
  }

  static String _compactCount(int count) {
    if (count < 1000) return '$count';
    final compact = count / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}K';
  }
}
