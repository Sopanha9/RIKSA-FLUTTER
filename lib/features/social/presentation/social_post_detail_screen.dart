import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';

class SocialPostDetailScreen extends ConsumerStatefulWidget {
  const SocialPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<SocialPostDetailScreen> createState() =>
      _SocialPostDetailScreenState();
}

class _SocialPostDetailScreenState
    extends ConsumerState<SocialPostDetailScreen> {
  static const _pageSize = 20;

  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  SocialPost? _post;
  List<SocialComment> _comments = const [];
  String? _endCursor;
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _submitting = false;

  bool get _hasMore => _endCursor != null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(socialApiProvider);
      final results = await Future.wait<Object>([
        api.post(widget.postId),
        api.comments(postId: widget.postId, limit: _pageSize),
      ]);
      if (!mounted) return;
      final page = results[1] as SocialCommentPage;
      setState(() {
        _post = results[0] as SocialPost;
        _comments = page.comments;
        _endCursor = page.hasNextPage ? page.endCursor : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is SocialApiException ? error.message : null;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _endCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(socialApiProvider)
          .comments(postId: widget.postId, cursor: cursor, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, ...page.comments];
        _endCursor = page.hasNextPage ? page.endCursor : null;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _showFailure();
    }
  }

  Future<void> _react() async {
    final post = _post;
    if (post == null) return;
    try {
      final updated = await ref
          .read(socialApiProvider)
          .react(postId: post.id, reaction: SocialReaction.upvote);
      if (!mounted) return;
      setState(() => _post = updated);
      ref.read(socialFeedProvider.notifier).syncPost(updated);
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  Future<void> _share() async {
    final post = _post;
    if (post == null) return;
    try {
      final updated = await ref.read(socialApiProvider).share(post.id);
      if (!mounted) return;
      setState(() => _post = updated);
      ref.read(socialFeedProvider.notifier).syncPost(updated);
      await Clipboard.setData(
        ClipboardData(text: 'https://riksa.app/community/posts/${post.id}'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.copiedLink)),
        );
    } catch (_) {
      if (mounted) _showFailure();
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final created = await ref
          .read(socialApiProvider)
          .createComment(postId: widget.postId, content: content);
      if (!mounted) return;
      final updatedPost = _post?.copyWith(
        commentCount: (_post?.commentCount ?? 0) + 1,
      );
      setState(() {
        _comments = [..._comments, created];
        _post = updatedPost;
        _submitting = false;
      });
      if (updatedPost != null) {
        ref.read(socialFeedProvider.notifier).syncPost(updatedPost);
      }
      _commentController.clear();
      _commentFocus.unfocus();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commentFailed)),
        );
    }
  }

  void _showFailure() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.actionFailed)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.postDetail,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
          ? _ErrorState(message: _error, onRetry: _load)
          : RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _PostBody(
                    post: _post!,
                    onAuthorTap: _authorTap(_post!.author),
                    onReact: _react,
                    onShare: _share,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        l10n.discussion,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CountBadge(count: _post!.commentCount),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_comments.isEmpty)
                    _EmptyComments(message: l10n.noComments)
                  else
                    for (final comment in _comments) ...[
                      _CommentCard(
                        comment: comment,
                        onAuthorTap: _authorTap(comment.author),
                      ),
                      const SizedBox(height: 10),
                    ],
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: OutlinedButton(
                        onPressed: _loadingMore ? null : _loadMore,
                        child: _loadingMore
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.loadMore),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: _post == null
          ? null
          : _CommentComposer(
              controller: _commentController,
              focusNode: _commentFocus,
              submitting: _submitting,
              hint: l10n.addComment,
              sendLabel: l10n.sendComment,
              onSend: _submitComment,
            ),
    );
  }

  VoidCallback? _authorTap(SocialAuthor author) {
    final path = publicProfilePath(author.id);
    return path == null ? null : () => context.push(path);
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({
    required this.post,
    this.onAuthorTap,
    required this.onReact,
    required this.onShare,
  });

  final SocialPost post;
  final VoidCallback? onAuthorTap;
  final VoidCallback onReact;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorLine(
            author: post.author,
            createdAt: post.createdAt,
            onAuthorTap: onAuthorTap,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: AppRadii.smallBorder,
            ),
            child: Text(
              post.category.name,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          if (post.content.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
          if (post.hasMedia) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: AppRadii.mediumBorder,
              child: Image.network(
                post.mediaUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: colors.surfaceContainer,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colors.onSurfaceVariant,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: colors.outline),
          const SizedBox(height: 8),
          Row(
            children: [
              _DetailAction(
                icon: post.myReaction == null
                    ? Icons.arrow_upward_outlined
                    : Icons.arrow_upward_rounded,
                count: post.reactionCount,
                selected: post.myReaction != null,
                onTap: onReact,
              ),
              const SizedBox(width: 10),
              _DetailAction(
                icon: Icons.mode_comment_outlined,
                count: post.commentCount,
              ),
              const Spacer(),
              _DetailAction(
                icon: Icons.ios_share_rounded,
                count: post.shareCount,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.author,
    required this.createdAt,
    this.onAuthorTap,
  });

  final SocialAuthor author;
  final DateTime createdAt;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = author.displayName.isEmpty
        ? author.username
        : author.displayName;
    return Row(
      children: [
        _Avatar(author: author, onTap: onAuthorTap),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                key: ValueKey('detail-author-name-${author.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: onAuthorTap,
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${author.username} · ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(createdAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, this.onAuthorTap});

  final SocialComment comment;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = comment.author.displayName.isEmpty
        ? comment.author.username
        : comment.author.displayName;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outline),
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(author: comment.author, radius: 18, onTap: onAuthorTap),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        key: ValueKey(
                          'comment-author-name-${comment.author.id}',
                        ),
                        behavior: HitTestBehavior.opaque,
                        onTap: onAuthorTap,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      DateFormat.MMMd(
                        Localizations.localeOf(context).languageCode,
                      ).format(comment.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.author, this.radius = 22, this.onTap});

  final SocialAuthor author;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = author.displayName.isEmpty
        ? author.username
        : author.displayName;
    return GestureDetector(
      key: ValueKey('detail-author-avatar-${author.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: RiksaAvatarImage(
        value: author.avatarUrl,
        label: label,
        size: radius * 2,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  const _DetailAction({
    required this.icon,
    required this.count,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? AppColors.brandPrimary : colors.onSurfaceVariant;
    return InkWell(
      borderRadius: AppRadii.fullBorder,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .12)
              : colors.surfaceContainerLow,
          borderRadius: AppRadii.fullBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: AppRadii.smallBorder,
    ),
    child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: AppRadii.mediumBorder,
    ),
    child: Column(
      children: [
        Icon(
          Icons.chat_bubble_outline_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article_outlined, size: 44),
            const SizedBox(height: 14),
            Text(
              l10n.postUnavailable,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.postUnavailableMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
          ],
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.submitting,
    required this.hint,
    required this.sendLabel,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool submitting;
  final String hint;
  final String sendLabel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 10,
      shadowColor: colors.shadow.withValues(alpha: .12),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('comment-composer'),
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: sendLabel,
                child: IconButton.filled(
                  onPressed: submitting ? null : onSend,
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
