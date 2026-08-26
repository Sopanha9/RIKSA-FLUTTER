import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';
import '../../data/social_models.dart';

class SocialPostCard extends StatefulWidget {
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
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final post = widget.post;
    final date = DateFormat.MMMd(
      Localizations.localeOf(context).languageCode,
    ).format(post.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadii.mediumBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostHeader(
              post: post,
              date: date,
              onAuthorTap: widget.onAuthorTap,
            ),
            const SizedBox(height: 15),
            if (post.title.trim().isNotEmpty)
              Text(
                post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.35,
                  height: 1.28,
                ),
              ),
            if (post.content.trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                post.content,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.58,
                ),
              ),
              if (post.content.length > 180 && !_expanded)
                TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF625284),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.only(top: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Read more'),
                ),
            ],
            if (post.hasMedia) ...[
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                child: _PostMedia(post: post),
              ),
            ],
            const SizedBox(height: 8),
            _PostActions(
              post: post,
              onReact: widget.onReact,
              onComment: widget.onTap,
              onShare: widget.onShare,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Divider(height: 1, color: Color(0xFFE8E7E2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.date, this.onAuthorTap});

  final SocialPost post;
  final String date;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = post.author.displayName.trim().isEmpty
        ? post.author.username
        : post.author.displayName;
    return Row(
      children: [
        GestureDetector(
          key: ValueKey('author-avatar-${post.author.id}'),
          onTap: onAuthorTap,
          child: SocialAuthorAvatar(
            imageUrl: post.author.avatarUrl,
            label: name,
            seed: post.author.username.isEmpty
                ? post.author.id
                : post.author.username,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                key: ValueKey('author-name-${post.author.id}'),
                onTap: onAuthorTap,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${post.category.name} · $date',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 272),
      child: Image.network(
        post.mediaUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => Container(
          height: 190,
          color: colors.surfaceContainerLow,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onShare,
  });

  final SocialPost post;
  final VoidCallback onReact;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final reacted = post.myReaction != null;
    return Row(
      children: [
        _PostAction(
          key: ValueKey('react-${post.id}'),
          icon: reacted
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: '${post.reactionCount}',
          selected: reacted,
          onTap: onReact,
        ),
        const SizedBox(width: 18),
        _PostAction(
          icon: Icons.mode_comment_outlined,
          label: '${post.commentCount}',
          onTap: onComment,
        ),
        const SizedBox(width: 18),
        _PostAction(
          icon: Icons.auto_awesome_outlined,
          label: '${post.reactionCount} learned',
          onTap: onReact,
        ),
        const Spacer(),
        _PostAction(
          key: ValueKey('share-${post.id}'),
          icon: Icons.ios_share_outlined,
          onTap: onShare,
        ),
      ],
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.selected = false,
  });

  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? const Color(0xFF625284) : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.smallBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SocialAuthorAvatar extends StatelessWidget {
  const SocialAuthorAvatar({
    super.key,
    required this.imageUrl,
    required this.label,
    required this.seed,
    this.size = 40,
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
        border: Border.all(color: palette.background, width: 2),
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
