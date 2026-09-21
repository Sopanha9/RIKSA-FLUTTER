import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import 'widgets/riksa_report_sheet.dart';
import 'widgets/social_owner_menu.dart';
import 'widgets/social_palette.dart';

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
      final created = await ref.read(socialApiProvider).createComment(
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
      final updatedPost = _post?.copyWith(
        commentCount: math.max(0, (_post?.commentCount ?? 1) - 1),
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
            content: Text(
              isKhmer ? 'បានលុបមតិដោយជោគជ័យ' : 'Comment deleted',
            ),
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
    return Scaffold(
      backgroundColor: SocialPalette.canvas(context),
      appBar: AppBar(
        backgroundColor: SocialPalette.canvas(context),
        foregroundColor: SocialPalette.aubergine(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.postDetail,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_post != null)
            if (_post!.author.id == ref.watch(currentUserIdProvider))
              SocialOwnerMenu(
                postId: _post!.id,
                onEdit: _edit,
                onDelete: _delete,
              )
            else
              IconButton(
                key: ValueKey('post-report-${_post!.id}'),
                tooltip: Localizations.localeOf(context).languageCode == 'km'
                    ? 'រាយការណ៍'
                    : 'Report post',
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => showRiksaReportSheet(
                  context,
                  targetType: 'POST',
                  targetId: _post!.id,
                  targetTitle: _post!.title,
                ),
              ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _PostBody(
                    post: _post!,
                    onAuthorTap: _authorTap(_post!.author),
                    onReact: _react,
                    onShare: _share,
                    onCommentTap: () => _commentFocus.requestFocus(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        l10n.discussion,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: SocialPalette.aubergine(context),
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
                        const SizedBox(height: 6),
                        for (final reply in thread.replies) ...[
                          () {
                            final currentUserId =
                                ref.watch(currentUserIdProvider);
                            final canDeleteReply =
                                reply.author.id == currentUserId;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 24, bottom: 6),
                              child: _CommentCard(
                                comment: reply,
                                isReply: true,
                                onAuthorTap: _authorTap(reply.author),
                                onReply: () => _startReply(reply),
                                onDelete: canDeleteReply
                                    ? () => _deleteComment(reply)
                                    : null,
                              ),
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SocialPalette.aubergine(context),
                          side: BorderSide(
                            color: SocialPalette.outline(context),
                          ),
                        ),
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
              replyingTo: _replyingTo,
              onCancelReply: _cancelReply,
              hint: _replyingTo != null
                  ? '${l10n.reply}...'
                  : l10n.addComment,
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
    this.onCommentTap,
  });

  final SocialPost post;
  final VoidCallback? onAuthorTap;
  final VoidCallback onReact;
  final VoidCallback onShare;
  final VoidCallback? onCommentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('post-detail-body'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SocialPalette.surface(context),
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: SocialPalette.outline(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
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
              color: SocialPalette.pinkSoft(context),
              borderRadius: AppRadii.smallBorder,
            ),
            child: Text(
              post.category.name,
              style: theme.textTheme.labelMedium?.copyWith(
                color: SocialPalette.aubergine(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: RiksaTypography.bodyStyleFor(
              post.title,
              theme.textTheme.headlineSmall?.copyWith(
                color: SocialPalette.ink(context),
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
          if (post.content.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            MarkdownBody(
              key: const ValueKey('social-post-markdown'),
              data: post.markdownContent,
              selectable: true,
              softLineBreak: true,
              styleSheet: _socialMarkdownStyleSheet(
                context,
                post.markdownContent,
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
                  color: SocialPalette.surfaceRaised(context),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: SocialPalette.muted(context),
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: SocialPalette.outline(context)),
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
                key: const ValueKey('post-detail-comment-button'),
                icon: Icons.mode_comment_outlined,
                count: post.commentCount,
                onTap: onCommentTap,
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
                    color: SocialPalette.ink(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${author.username} · ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(createdAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SocialPalette.muted(context),
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
  const _CommentThread({
    required this.root,
    required this.replies,
  });

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
    return _CommentThread(
      root: root,
      replies: collectReplies(root.id),
    );
  }).toList();
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    this.onAuthorTap,
    this.onReply,
    this.onDelete,
    this.isReply = false,
  });

  final SocialComment comment;
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
    return Container(
      key: ValueKey('comment-card-${comment.id}'),
      padding: EdgeInsets.all(isReply ? 12 : 15),
      decoration: BoxDecoration(
        color: isReply
            ? SocialPalette.surfaceRaised(context)
            : SocialPalette.surface(context),
        border: Border.all(color: SocialPalette.outline(context)),
        borderRadius: AppRadii.mediumBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            author: comment.author,
            radius: isReply ? 14 : 18,
            onTap: onAuthorTap,
          ),
          SizedBox(width: isReply ? 8 : 11),
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
                          style: (isReply
                                  ? theme.textTheme.labelMedium
                                  : theme.textTheme.labelLarge)
                              ?.copyWith(
                            color: SocialPalette.ink(context),
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
                        color: SocialPalette.muted(context),
                        fontSize: isReply ? 11 : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: RiksaTypography.bodyStyleFor(
                    comment.content,
                    theme.textTheme.bodyMedium?.copyWith(
                      color: SocialPalette.ink(context),
                      height: 1.55,
                      fontSize: isReply ? 13 : null,
                    ),
                  ),
                ),
                if (onReply != null || onDelete != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (onReply != null)
                        InkWell(
                          key: ValueKey('comment-reply-button-${comment.id}'),
                          onTap: onReply,
                          borderRadius: AppRadii.smallBorder,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 14,
                                  color: SocialPalette.aubergine(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.reply,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: SocialPalette.aubergine(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 12),
                        InkWell(
                          key: ValueKey('comment-delete-button-${comment.id}'),
                          onTap: onDelete,
                          borderRadius: AppRadii.smallBorder,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isKhmer ? 'លុប' : 'Delete',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

MarkdownStyleSheet _socialMarkdownStyleSheet(
  BuildContext context,
  String content,
) {
  final theme = Theme.of(context);
  final hasKhmer = RiksaTypography.containsKhmer(content);

  TextStyle socialStyle(TextStyle? style) =>
      RiksaTypography.bodyStyleFor(content, style) ?? const TextStyle();

  final paragraph = socialStyle(
    theme.textTheme.bodyLarge?.copyWith(
      color: SocialPalette.muted(context),
      height: 1.7,
    ),
  );
  final heading = socialStyle(
    theme.textTheme.titleLarge?.copyWith(
      color: SocialPalette.ink(context),
      fontWeight: FontWeight.w800,
      height: hasKhmer ? 1.5 : 1.35,
    ),
  );

  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 5),
    h1: heading.copyWith(fontSize: 22),
    h2: heading.copyWith(fontSize: 20),
    h3: heading.copyWith(fontSize: 18),
    h1Padding: const EdgeInsets.only(top: 8, bottom: 6),
    h2Padding: const EdgeInsets.only(top: 7, bottom: 5),
    h3Padding: const EdgeInsets.only(top: 6, bottom: 4),
    strong: socialStyle(const TextStyle(fontWeight: FontWeight.w700)),
    em: socialStyle(const TextStyle(fontStyle: FontStyle.italic)),
    code: socialStyle(
      theme.textTheme.bodyMedium?.copyWith(
        color: SocialPalette.ink(context),
        backgroundColor: SocialPalette.surfaceRaised(context),
      ),
    ),
    codeblockDecoration: BoxDecoration(
      color: SocialPalette.surfaceRaised(context),
      borderRadius: AppRadii.smallBorder,
      border: Border.all(color: SocialPalette.outline(context)),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    blockquote: paragraph.copyWith(color: SocialPalette.muted(context)),
    listBullet: paragraph,
    blockSpacing: 10,
    listIndent: 22,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: SocialPalette.outline(context))),
    ),
  );
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
        backgroundColor: SocialPalette.pinkSoft(context),
        foregroundColor: SocialPalette.aubergine(context),
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
    final color = selected
        ? SocialPalette.pink(context)
        : SocialPalette.muted(context);
    return InkWell(
      borderRadius: AppRadii.fullBorder,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? SocialPalette.pinkSoft(context)
              : SocialPalette.surfaceRaised(context),
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
      color: SocialPalette.pinkSoft(context),
      borderRadius: AppRadii.smallBorder,
    ),
    child: Text(
      '$count',
      style: TextStyle(
        color: SocialPalette.aubergine(context),
        fontWeight: FontWeight.w800,
      ),
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
      color: SocialPalette.surface(context),
      borderRadius: AppRadii.mediumBorder,
      border: Border.all(color: SocialPalette.outline(context)),
    ),
    child: Column(
      children: [
        Icon(
          Icons.chat_bubble_outline_rounded,
          color: SocialPalette.pink(context),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: SocialPalette.muted(context)),
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
                color: SocialPalette.aubergine(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.postUnavailableMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: SocialPalette.muted(context)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SocialPalette.aubergine(context),
                foregroundColor: SocialPalette.onAubergine(context),
              ),
              onPressed: onRetry,
              child: Text(l10n.tryAgain),
            ),
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
    final replyingName = replyingTo != null
        ? (replyingTo!.author.displayName.isEmpty
            ? replyingTo!.author.username
            : replyingTo!.author.displayName)
        : null;

    return Material(
      color: SocialPalette.surface(context),
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null)
              Container(
                key: const ValueKey('reply-indicator-bar'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: SocialPalette.pinkSoft(context),
                  border: Border(
                    bottom: BorderSide(
                      color: SocialPalette.outline(context),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: SocialPalette.aubergine(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context)!.replyingTo} @$replyingName',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: SocialPalette.aubergine(context),
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
                          color: SocialPalette.aubergine(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
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
                        hintStyle:
                            TextStyle(color: SocialPalette.muted(context)),
                        counterText: '',
                        filled: true,
                        fillColor: SocialPalette.surfaceRaised(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.fullBorder,
                          borderSide: BorderSide(
                            color: SocialPalette.outline(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadii.fullBorder,
                          borderSide: BorderSide(
                            color: SocialPalette.outline(context),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: AppRadii.fullBorder,
                          borderSide: BorderSide(
                            color: AppColors.editorialPink,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: sendLabel,
                    child: IconButton(
                      key: const ValueKey('send-comment-button'),
                      onPressed: submitting ? null : onSend,
                      style: IconButton.styleFrom(
                        backgroundColor: SocialPalette.aubergine(context),
                        foregroundColor: SocialPalette.onAubergine(context),
                        disabledBackgroundColor: SocialPalette.outline(context),
                        shape: const CircleBorder(),
                      ),
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
          ],
        ),
      ),
    );
  }
}
