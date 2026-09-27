import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import '../../auth/data/external_link_opener.dart';
import 'widgets/social_owner_menu.dart';
import 'widgets/social_palette.dart';
import 'widgets/social_markdown_style.dart';
import 'widgets/social_post_media_grid.dart';

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

  final _scrollController = ScrollController();
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  SocialPost? _post;
  List<SocialComment> _comments = const [];
  SocialComment? _replyingTo;
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
    _scrollController.dispose();
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

  void _startReply(SocialComment comment) {
    HapticFeedback.selectionClick();
    setState(() => _replyingTo = comment);
    _commentFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final targetParent = _replyingTo;
    try {
      final created = await ref
          .read(socialApiProvider)
          .createComment(
            postId: widget.postId,
            content: content,
            parentId: targetParent?.id,
          );
      if (!mounted) return;
      final updatedPost = _post?.copyWith(
        commentCount: (_post?.commentCount ?? 0) + 1,
      );
      setState(() {
        _comments = [..._comments, created];
        _post = updatedPost;
        _replyingTo = null;
        _submitting = false;
      });
      if (updatedPost != null) {
        ref.read(socialFeedProvider.notifier).syncPost(updatedPost);
      }
      _commentController.clear();
      _commentFocus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
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

  Future<void> _deleteComment(SocialComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isKhmer =
            Localizations.localeOf(dialogContext).languageCode == 'km';
        return AlertDialog(
          title: Text(isKhmer ? 'លុបមតិ?' : 'Delete comment?'),
          content: Text(
            isKhmer
                ? 'តើអ្នកប្រាកដថាចង់លុបមតិនេះទេ?'
                : 'Are you sure you want to delete this comment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(isKhmer ? 'បោះបង់' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(isKhmer ? 'លុប' : 'Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(socialApiProvider).deleteComment(comment.id);
      if (!mounted) return;
      final updatedComments = _comments
          .where((c) => c.id != comment.id && c.parentId != comment.id)
          .toList();
      final removedCommentCount = _comments.length - updatedComments.length;
      final updatedPost = _post?.copyWith(
        commentCount: math.max(
          0,
          (_post?.commentCount ?? removedCommentCount) - removedCommentCount,
        ),
      );
      setState(() {
        _comments = updatedComments;
        _post = updatedPost;
      });
      if (updatedPost != null) {
        ref.read(socialFeedProvider.notifier).syncPost(updatedPost);
      }
      final isKhmer = Localizations.localeOf(context).languageCode == 'km';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(isKhmer ? 'បានលុបមតិដោយជោគជ័យ' : 'Comment deleted'),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      _showFailure();
    }
  }

  Future<void> _edit() async {
    final post = _post;
    if (post == null) return;
    final saved = await context.push<bool>(
      '/community/posts/${post.id}/edit',
      extra: post,
    );
    if (saved != true || !mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.postUpdated)),
      );
  }

  Future<void> _delete() async {
    final post = _post;
    if (post == null) return;
    if (!await confirmSocialPostDeletion(context)) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final failure = await ref
        .read(socialFeedProvider.notifier)
        .deletePost(post.id);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure ?? l10n.postDeleted)));
    // The post is gone, so the detail screen has nothing left to show.
    if (failure == null) context.pop();
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
    final composerClearance = _replyingTo == null ? 120.0 : 164.0;
    final content = _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.editorialPink),
          )
        : _post == null
        ? _ErrorState(message: _error, onRetry: _load)
        : RefreshIndicator(
            color: AppColors.editorialPink,
            onRefresh: _load,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, composerClearance),
              children: [
                _PostBody(
                  post: _post!,
                  onAuthorTap: _authorTap(_post!.author),
                  onReact: _react,
                  onComment: _commentFocus.requestFocus,
                  onShare: _share,
                  onTapLink: _openPostLink,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      l10n.discussion,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.riksa.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CountBadge(
                      key: const ValueKey('post-detail-comment-count'),
                      count: _post!.commentCount,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_comments.isEmpty)
                  _EmptyComments(message: l10n.noComments)
                else
                  for (final thread in _buildCommentThreads(_comments)) ...[
                    () {
                      final currentUserId = ref.watch(currentUserIdProvider);
                      final canDeleteRoot =
                          thread.root.author.id == currentUserId;
                      return _CommentCard(
                        comment: thread.root,
                        onAuthorTap: _authorTap(thread.root.author),
                        onReply: () => _startReply(thread.root),
                        onDelete: canDeleteRoot
                            ? () => _deleteComment(thread.root)
                            : null,
                      );
                    }(),
                    if (thread.replies.isNotEmpty) ...[
                      for (final reply in thread.replies) ...[
                        () {
                          final currentUserId = ref.watch(
                            currentUserIdProvider,
                          );
                          final canDeleteReply =
                              reply.author.id == currentUserId;
                          SocialComment? parentComment;
                          for (final c in _comments) {
                            if (c.id == reply.parentId) {
                              parentComment = c;
                              break;
                            }
                          }
                          final replyingTo = parentComment?.author.username;
                          return _CommentCard(
                            comment: reply,
                            replyingToUsername: replyingTo,
                            isReply: true,
                            onAuthorTap: _authorTap(reply.author),
                            onReply: () => _startReply(reply),
                            onDelete: canDeleteReply
                                ? () => _deleteComment(reply)
                                : null,
                          );
                        }(),
                      ],
                    ],
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.loadMore),
                    ),
                  ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: context.riksa.canvas,
      appBar: AppBar(
        backgroundColor: context.riksa.canvas,
        foregroundColor: context.riksa.brand,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: _post == null
            ? Text(
                l10n.postDetail,
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            : _AuthorLine(
                author: _post!.author,
                createdAt: _post!.createdAt,
                categoryName: _post!.category.name,
                onAuthorTap: _authorTap(_post!.author),
              ),
        actions: [
          if (_post != null &&
              _post!.author.id == ref.watch(currentUserIdProvider))
            SocialOwnerMenu(
              postId: _post!.id,
              onEdit: _edit,
              onDelete: _delete,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: content),
          if (_post != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.viewInsetsOf(context).bottom,
              child: _CommentComposer(
                controller: _commentController,
                focusNode: _commentFocus,
                submitting: _submitting,
                replyingTo: _replyingTo,
                onCancelReply: _cancelReply,
                hint: _replyingTo != null
                    ? '${l10n.reply}...'
                    : l10n.addComment,
                sendLabel: l10n.sendComment,
                onSend: _submitComment,
              ),
            ),
        ],
      ),
    );
  }

  VoidCallback? _authorTap(SocialAuthor author) {
    return publicProfilePath(author.id) == null
        ? null
        : () => openUserProfile(context, author.id);
  }

  void _openPostLink(String? href) {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.hasAuthority) {
      return;
    }
    unawaited(ref.read(externalLinkOpenerProvider)(uri));
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({
    required this.post,
    this.onAuthorTap,
    required this.onReact,
    required this.onComment,
    required this.onShare,
    required this.onTapLink,
  });

  final SocialPost post;
  final VoidCallback? onAuthorTap;
  final VoidCallback onReact;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final ValueChanged<String?> onTapLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTitle = post.title.trim().isNotEmpty;
    final fallbackTitle = post.plainTextPreview.split('\n').firstOrNull ?? '';
    final displayedTitle = hasTitle ? post.title : fallbackTitle;
    final body = !hasTitle && fallbackTitle.isNotEmpty
        ? post.markdownContent.split('\n').skip(1).join('\n').trim()
        : post.markdownContent;
    return Padding(
      key: const ValueKey('post-detail-body'),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayedTitle.isNotEmpty)
            Text(
              displayedTitle,
              style: RiksaTypography.bodyStyleFor(
                displayedTitle,
                theme.textTheme.headlineSmall?.copyWith(
                  color: context.riksa.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            MarkdownBody(
              key: const ValueKey('social-post-markdown'),
              data: body,
              selectable: true,
              softLineBreak: true,
              onTapLink: (text, href, title) => onTapLink(href),
              styleSheet: socialMarkdownStyleSheet(context, body),
            ),
          ],
          if (post.hasMedia) ...[
            const SizedBox(height: 16),
            SocialPostMediaGrid(
              postId: post.id,
              media: post.media,
              keyPrefix: 'post-detail-photo',
              singlePhotoFit: BoxFit.contain,
              singlePhotoMaxHeight: MediaQuery.sizeOf(context).height * .7,
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: context.riksa.outline),
          const SizedBox(height: 8),
          Row(
            children: [
              _DetailAction(
                icon: post.myReaction == null
                    ? Icons.favorite_border_rounded
                    : Icons.favorite_rounded,
                count: post.reactionCount,
                selected: post.myReaction != null,
                onTap: onReact,
              ),
              _DetailAction(
                key: const ValueKey('post-detail-comment-button'),
                icon: Icons.mode_comment_outlined,
                count: post.commentCount,
                onTap: onComment,
              ),
              const Spacer(),
              _DetailAction(
                icon: Icons.share_rounded,
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
    required this.categoryName,
    this.onAuthorTap,
  });

  final SocialAuthor author;
  final DateTime createdAt;
  final String categoryName;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    color: context.riksa.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${author.username} / $categoryName · ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(createdAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.riksa.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentThread {
  const _CommentThread({required this.root, required this.replies});

  final SocialComment root;
  final List<SocialComment> replies;
}

List<_CommentThread> _buildCommentThreads(List<SocialComment> comments) {
  final byId = {for (final c in comments) c.id: c};
  final repliesByParent = <String, List<SocialComment>>{};
  final roots = <SocialComment>[];

  for (final comment in comments) {
    final pid = comment.parentId;
    if (pid == null || pid.isEmpty || !byId.containsKey(pid)) {
      roots.add(comment);
    } else {
      repliesByParent.putIfAbsent(pid, () => []).add(comment);
    }
  }

  List<SocialComment> collectReplies(String parentId) {
    final direct = repliesByParent[parentId] ?? const [];
    final all = <SocialComment>[];
    for (final reply in direct) {
      all.add(reply);
      all.addAll(collectReplies(reply.id));
    }
    return all;
  }

  return roots.map((root) {
    return _CommentThread(root: root, replies: collectReplies(root.id));
  }).toList();
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    this.replyingToUsername,
    this.onAuthorTap,
    this.onReply,
    this.onDelete,
    this.isReply = false,
  });

  final SocialComment comment;
  final String? replyingToUsername;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    final name = comment.author.displayName.isEmpty
        ? comment.author.username
        : comment.author.displayName;
    final avatarRadius = isReply ? 18.0 : 21.0;
    final horizontalGap = isReply ? 10.0 : 12.0;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          author: comment.author,
          radius: avatarRadius,
          onTap: onAuthorTap,
        ),
        SizedBox(width: horizontalGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('comment-author-name-${comment.author.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onAuthorTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@$name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: context.riksa.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (replyingToUsername != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${AppLocalizations.of(context)!.replyingTo} @$replyingToUsername',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: context.riksa.inkMuted.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _relativeCommentAge(context, comment.createdAt),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: context.riksa.inkMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: isReply ? 12 : 13,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isReply ? 8 : 10),
              Text(
                comment.content,
                style: RiksaTypography.bodyStyleFor(
                  comment.content,
                  theme.textTheme.bodyMedium?.copyWith(
                    color: context.riksa.ink,
                    height: 1.38,
                    fontSize: isReply ? 12 : 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: isReply ? 8 : 10),
              _CommentActionRow(
                commentId: comment.id,
                isKhmer: isKhmer,
                onReply: onReply,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      key: ValueKey('comment-card-${comment.id}'),
      padding: EdgeInsets.only(
        top: isReply ? 12 : 18,
        bottom: isReply ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: context.riksa.surface,
        border: isReply
            ? null
            : Border(top: BorderSide(color: context.riksa.outline)),
      ),
      child: isReply
          ? Padding(padding: const EdgeInsets.only(left: 42), child: content)
          : content,
    );
  }
}

class _CommentActionRow extends StatelessWidget {
  const _CommentActionRow({
    required this.commentId,
    required this.isKhmer,
    this.onReply,
    this.onDelete,
  });

  final String commentId;
  final bool isKhmer;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionStyle = theme.textTheme.labelLarge?.copyWith(
      color: context.riksa.inkMuted.withValues(alpha: 0.6),
      fontWeight: FontWeight.w500,
      height: 1,
    );
    return Row(
      children: [
        Text(isKhmer ? 'ចូលចិត្ត' : 'Like', style: actionStyle),
        const SizedBox(width: 10),
        if (onReply != null)
          Semantics(
            button: true,
            label: AppLocalizations.of(context)!.reply,
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('comment-reply-button-$commentId'),
              behavior: HitTestBehavior.opaque,
              onTap: onReply,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.reply,
                    style: actionStyle,
                  ),
                ),
              ),
            ),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: AppLocalizations.of(context)!.delete,
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('comment-delete-button-$commentId'),
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.delete,
                    style: actionStyle?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(isKhmer ? 'លាក់' : 'Hide', style: actionStyle),
      ],
    );
  }
}

String _relativeCommentAge(BuildContext context, DateTime createdAt) {
  final elapsed = DateTime.now().difference(createdAt.toLocal());
  if (elapsed.inDays >= 1) return '${elapsed.inDays}d';
  if (elapsed.inHours >= 1) return '${elapsed.inHours}h';
  if (elapsed.inMinutes >= 1) return '${elapsed.inMinutes}m';
  return Localizations.localeOf(context).languageCode == 'km' ? 'ឥឡូវ' : 'now';
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.author, this.radius = 22, this.onTap});

  final SocialAuthor author;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: context.riksa.brandSoft,
        foregroundColor: context.riksa.brand,
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  const _DetailAction({
    super.key,
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
    final color = selected ? AppColors.socialLike : context.riksa.inkMuted;
    return InkWell(
      borderRadius: AppRadii.fullBorder,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      '$count',
      style: TextStyle(color: context.riksa.ink, fontWeight: FontWeight.w600),
    ),
  );
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: context.riksa.surface,
      borderRadius: AppRadii.mediumBorder,
      border: Border.all(color: context.riksa.outline),
    ),
    child: Column(
      children: [
        Icon(
          CupertinoIcons.chat_bubble,
          color: SocialPalette.pink(context),
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.riksa.inkMuted),
        ),
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
            const Icon(
              Icons.article_outlined,
              size: 44,
              color: AppColors.editorialPink,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.postUnavailable,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.riksa.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.postUnavailableMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.riksa.inkMuted),
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
    this.replyingTo,
    this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool submitting;
  final String hint;
  final String sendLabel;
  final VoidCallback onSend;
  final SocialComment? replyingTo;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.3),
        Colors.black.withValues(alpha: 0.1),
      ],
    );
    final glassBorder = Colors.white.withValues(alpha: 0.3);
    final sendOuterFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.58);
    final sendFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.54);
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? .34 : .12),
      blurRadius: 26,
      offset: const Offset(0, 10),
    );
    final replyingName = replyingTo != null
        ? (replyingTo!.author.displayName.isEmpty
              ? replyingTo!.author.username
              : replyingTo!.author.displayName)
        : null;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: AppRadii.fullBorder,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      key: const ValueKey('reply-indicator-bar'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: ShapeDecoration(
                        gradient: glassGradient,
                        shape: StadiumBorder(
                          side: BorderSide(color: glassBorder),
                        ),
                        shadows: [shadow],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply_rounded,
                            size: 16,
                            color: context.riksa.brand,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${AppLocalizations.of(context)!.replyingTo} @$replyingName',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: context.riksa.brand,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            key: const ValueKey('cancel-reply-button'),
                            onTap: onCancelReply,
                            borderRadius: AppRadii.smallBorder,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: context.riksa.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadii.fullBorder,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: ShapeDecoration(
                          gradient: glassGradient,
                          shape: StadiumBorder(
                            side: BorderSide(color: glassBorder),
                          ),
                          shadows: [shadow],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: TextField(
                          key: const ValueKey('comment-composer'),
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 1000,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: context.riksa.ink,
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(color: context.riksa.inkMuted),
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white.withValues(
                              alpha: isDark ? .08 : .16,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onSubmitted: (_) => onSend(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: sendLabel,
                  child: SizedBox.square(
                    dimension: 56,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: sendOuterFill,
                        shape: CircleBorder(
                          side: BorderSide(color: glassBorder),
                        ),
                        shadows: [shadow],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: sendFill,
                                shape: CircleBorder(
                                  side: BorderSide(color: glassBorder),
                                ),
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                key: const ValueKey('send-comment-button'),
                                onPressed: submitting ? null : onSend,
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.sendComment,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: context.riksa.brand,
                                  disabledForegroundColor:
                                      context.riksa.inkMuted,
                                  fixedSize: const Size.square(48),
                                  shape: const CircleBorder(),
                                ),
                                icon: submitting
                                    ? SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.riksa.brand,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
