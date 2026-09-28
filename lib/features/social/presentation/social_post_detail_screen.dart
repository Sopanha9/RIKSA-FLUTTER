import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/moderation_message.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import '../../../app/realtime_sync.dart';
import '../../../core/realtime/realtime_client.dart';
import '../../auth/data/external_link_opener.dart';
import '../../quests/providers/today_quests_provider.dart';
import 'widgets/social_owner_menu.dart';
import 'widgets/social_palette.dart';
import 'widgets/social_markdown_style.dart';
import 'widgets/social_post_media_grid.dart';
import '../../../core/widgets/markdown_math.dart';

class _CommentReplyPageInfo {
  const _CommentReplyPageInfo({required this.hasNextPage, this.endCursor});

  final bool hasNextPage;
  final String? endCursor;
}

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
  String? _replyingToId;
  Map<String, _CommentReplyPageInfo> _replyPages = const {};
  final Set<String> _loadingReplyIds = {};
  String? _endCursor;
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _submitting = false;
  final Set<String> _reactingCommentIds = {};

  bool get _hasMore => _endCursor != null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // Someone else reacted or commented: refresh in place, without the
    // loading state a full reload shows.
    ref.listenManual(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event == null) return;
      if (event.type == RealtimeEvent.resync ||
          (event.type == RealtimeTypes.postChanged &&
              event.postId == widget.postId)) {
        unawaited(_refreshQuietly());
      }
    });
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
        api.commentThreads(postId: widget.postId, limit: _pageSize),
      ]);
      if (!mounted) return;
      final page = results[1] as SocialCommentThreadPage;
      setState(() {
        _post = results[0] as SocialPost;
        _comments = _flattenThreads(page.threads);
        _replyPages = _replyPageInfoFor(page.threads);
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

  /// Refetches the post and the comments connection when it has no next page.
  Future<void> _refreshQuietly() async {
    if (_loading || _post == null) return;
    try {
      final api = ref.read(socialApiProvider);
      final allLoaded = !_hasMore;
      final results = await Future.wait<Object>([
        api.post(widget.postId),
        if (allLoaded)
          api.commentThreads(
            postId: widget.postId,
            limit: math.max(
              _pageSize,
              _comments.where((comment) => comment.parentId == null).length +
                  5,
            ),
          ),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as SocialPost;
        if (allLoaded) {
          final page = results[1] as SocialCommentThreadPage;
          _comments = _flattenThreads(page.threads);
          _replyPages = _replyPageInfoFor(page.threads);
          _endCursor = page.hasNextPage ? page.endCursor : null;
        }
      });
    } catch (_) {
      // Keep what is showing; the next change or a pull-to-refresh retries.
    }
  }

  Future<void> _loadMore() async {
    final cursor = _endCursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(socialApiProvider)
          .commentThreads(
            postId: widget.postId,
            cursor: cursor,
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, ..._flattenThreads(page.threads)];
        _replyPages = {..._replyPages, ..._replyPageInfoFor(page.threads)};
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

  Future<void> _reactToComment(SocialComment comment) async {
    if (_reactingCommentIds.contains(comment.id)) return;
    final clearReaction = comment.myReaction == SocialReaction.love;
    final optimistic = comment.copyWith(
      myReaction: clearReaction ? null : SocialReaction.love,
      clearReaction: clearReaction,
    );
    setState(() {
      _reactingCommentIds.add(comment.id);
      _comments = [
        for (final current in _comments)
          if (current.id == comment.id) optimistic else current,
      ];
    });

    var failed = false;
    try {
      await ref
          .read(socialApiProvider)
          .reactToComment(
            commentId: comment.id,
            reaction: clearReaction ? null : SocialReaction.love,
          );
    } catch (_) {
      failed = true;
      if (mounted) _showFailure();
    } finally {
      if (mounted) {
        setState(() {
          _reactingCommentIds.remove(comment.id);
          if (failed) {
            _comments = [
              for (final current in _comments)
                if (current.id == comment.id) comment else current,
            ];
          }
        });
      }
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
    setState(() {
      _replyingTo = comment;
      _replyingToId = comment.id;
    });
    _commentFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyingToId = null;
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _submitting) return;
    final parentId = _replyingToId ?? _replyingTo?.id;
    setState(() => _submitting = true);
    try {
      final created = await ref
          .read(socialApiProvider)
          .createComment(
            postId: widget.postId,
            content: content,
            parentId: parentId,
          );
      ref.read(questProgressSyncProvider).nudge();
      if (!mounted) return;
      final updatedPost = _post?.copyWith(
        commentCount: (_post?.commentCount ?? 0) + 1,
      );
      setState(() {
        _comments = [..._comments, created];
        _post = updatedPost;
        _replyingTo = null;
        _replyingToId = null;
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
    } on SocialApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final rejection = error.moderationRejection;
      final message = rejection == null
          ? AppLocalizations.of(context)!.commentFailed
          : moderationMessage(context, rejection);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _loadMoreReplies(String commentId) async {
    final pageInfo = _replyPages[commentId];
    final cursor = pageInfo?.endCursor;
    if (pageInfo?.hasNextPage != true || cursor == null || cursor.isEmpty) {
      return;
    }
    if (_loadingReplyIds.contains(commentId)) return;
    setState(() => _loadingReplyIds.add(commentId));
    try {
      final page = await ref
          .read(socialApiProvider)
          .commentReplies(
            postId: widget.postId,
            commentId: commentId,
            cursor: cursor,
            limit: 10,
          );
      if (!mounted) return;
      setState(() {
        final knownIds = _comments.map((comment) => comment.id).toSet();
        _comments = [
          ..._comments,
          for (final reply in page.replies)
            if (!knownIds.contains(reply.id)) reply,
        ];
        _replyPages = {
          ..._replyPages,
          commentId: _CommentReplyPageInfo(
            hasNextPage: page.hasNextPage,
            endCursor: page.endCursor,
          ),
        };
        _loadingReplyIds.remove(commentId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReplyIds.remove(commentId));
      _showFailure();
    }
  }

  List<SocialComment> _flattenThreads(List<SocialCommentThread> threads) => [
    for (final thread in threads) thread.root,
    for (final thread in threads) ...thread.replies,
  ];

  Map<String, _CommentReplyPageInfo> _replyPageInfoFor(
    List<SocialCommentThread> threads,
  ) => {
    for (final thread in threads)
      thread.root.id: _CommentReplyPageInfo(
        hasNextPage: thread.repliesHaveNextPage,
        endCursor: thread.repliesEndCursor,
      ),
  };

  Future<void> _deleteComment(SocialComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.commentDeleteTitle),
          content: Text(l10n.commentDeleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.delete),
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.commentDeleted),
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
    if (failure == null) {
      await RiksaBackButton.navigateBack(context, fallbackLocation: '/home');
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
                        onLike: _reactingCommentIds.contains(thread.root.id)
                            ? null
                            : () => _reactToComment(thread.root),
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
                            onLike: _reactingCommentIds.contains(reply.id)
                                ? null
                                : () => _reactToComment(reply),
                            onDelete: canDeleteReply
                                ? () => _deleteComment(reply)
                                : null,
                          );
                        }(),
                      ],
                    ],
                    if (_replyPages[thread.root.id]?.hasNextPage == true)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 2),
                        child: TextButton(
                          key: ValueKey(
                            'comment-view-more-replies-${thread.root.id}',
                          ),
                          onPressed: _loadingReplyIds.contains(thread.root.id)
                              ? null
                              : () => _loadMoreReplies(thread.root.id),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _loadingReplyIds.contains(thread.root.id)
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.commentViewMoreReplies),
                        ),
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
        leading: Center(
          child: RiksaBackButton(
            key: const ValueKey('social-post-detail-back'),
            fallbackLocation: '/home',
            icon: Icons.arrow_back_ios_new,
            iconSize: 22,
          ),
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
              inlineSyntaxes: markdownMathSyntaxes,
              builders: markdownMathBuilders,
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
    this.onLike,
    this.onDelete,
    this.isReply = false,
  });

  final SocialComment comment;
  final String? replyingToUsername;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.riksa.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isReply ? 6 : 8),
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
              SizedBox(height: isReply ? 2 : 4),
              _CommentActionRow(
                commentId: comment.id,
                isLiked: comment.myReaction == SocialReaction.love,
                onLike: onLike,
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
      margin: isReply
          ? const EdgeInsets.only(left: 22, top: 2, bottom: 2)
          : null,
      padding: isReply
          ? const EdgeInsets.fromLTRB(10, 6, 0, 6)
          : const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: isReply
          ? null
          : BoxDecoration(
              color: context.riksa.surface,
              borderRadius: AppRadii.mediumBorder,
              border: Border.all(color: context.riksa.outline),
            ),
      child: isReply
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: context.riksa.outline,
                      borderRadius: AppRadii.fullBorder,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: content),
                ],
              ),
            )
          : content,
    );
  }
}

class _CommentActionRow extends StatelessWidget {
  const _CommentActionRow({
    required this.commentId,
    required this.isLiked,
    this.onLike,
    this.onReply,
    this.onDelete,
  });

  final String commentId;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final actionStyle = theme.textTheme.labelMedium?.copyWith(
      color: context.riksa.inkMuted,
      fontWeight: FontWeight.w500,
      height: 1,
    );
    final likeColor = isLiked ? AppColors.socialLike : context.riksa.inkMuted;

    return SizedBox(
      key: ValueKey('comment-action-row-$commentId'),
      height: 48,
      child: Row(
        children: [
          Semantics(
            button: true,
            enabled: onLike != null,
            selected: isLiked,
            label: isLiked ? l10n.commentUnlike : l10n.commentLike,
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('comment-like-button-$commentId'),
              behavior: HitTestBehavior.opaque,
              onTap: onLike,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: likeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLiked ? l10n.commentUnlike : l10n.commentLike,
                          style: actionStyle?.copyWith(color: likeColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onReply != null)
            Semantics(
              button: true,
              label: l10n.reply,
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('comment-reply-button-$commentId'),
                behavior: HitTestBehavior.opaque,
                onTap: onReply,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(child: Text(l10n.reply, style: actionStyle)),
                ),
              ),
            ),
          if (onDelete != null) ...[
            const SizedBox(width: 2),
            Semantics(
              button: true,
              label: l10n.delete,
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('comment-delete-button-$commentId'),
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(
                    child: Text(
                      l10n.delete,
                      style: actionStyle?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _relativeCommentAge(BuildContext context, DateTime createdAt) {
  final elapsed = DateTime.now().difference(createdAt.toLocal());
  final l10n = AppLocalizations.of(context)!;
  if (elapsed.inDays >= 1) return l10n.commentAgeDays(elapsed.inDays);
  if (elapsed.inHours >= 1) return l10n.commentAgeHours(elapsed.inHours);
  if (elapsed.inMinutes >= 1) return l10n.commentAgeMinutes(elapsed.inMinutes);
  return l10n.commentAgeNow;
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
    final l10n = AppLocalizations.of(context)!;
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
                child: Container(
                  key: const ValueKey('reply-indicator-bar'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.riksa.surface,
                    borderRadius: AppRadii.fullBorder,
                    border: Border.all(color: context.riksa.outline),
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
                          '${l10n.replyingTo} @$replyingName',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.riksa.brand,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('cancel-reply-button'),
                        onPressed: onCancelReply,
                        tooltip: l10n.cancel,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: context.riksa.brand,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.riksa.surface,
                      borderRadius: AppRadii.fullBorder,
                      border: Border.all(color: context.riksa.outline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? .12
                                : .04,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final enabled = value.text.trim().isNotEmpty && !submitting;
                    return Semantics(
                      button: true,
                      enabled: enabled,
                      label: sendLabel,
                      child: IconButton(
                        key: const ValueKey('send-comment-button'),
                        onPressed: enabled ? onSend : null,
                        tooltip: sendLabel,
                        style: IconButton.styleFrom(
                          backgroundColor: enabled
                              ? context.riksa.brand
                              : context.riksa.canvas,
                          foregroundColor: enabled
                              ? context.riksa.onBrand
                              : context.riksa.inkMuted,
                          disabledBackgroundColor: context.riksa.canvas,
                          disabledForegroundColor: context.riksa.inkMuted,
                          fixedSize: const Size.square(48),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: enabled
                                ? context.riksa.brand
                                : context.riksa.outline,
                          ),
                          shape: const CircleBorder(),
                        ),
                        icon: submitting
                            ? SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.riksa.inkMuted,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
