import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/blog_api.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';
import 'widgets/blog_ui.dart';

/// The author's own posts, including the ones still waiting on moderation.
class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  static const int _pageSize = 20;
  static const List<(String, BlogStatus?)> _filters = [
    ('All', null),
    ('In review', BlogStatus.pending),
    ('Published', BlogStatus.approved),
    ('Rejected', BlogStatus.rejected),
  ];

  final _scrollCtrl = ScrollController();
  final List<BlogPost> _posts = [];
  BlogStatus? _status;
  int _page = 0;
  int _totalPages = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load(page: 0);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _hasMore => _page + 1 < _totalPages;

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loadingMore) {
      _load(page: _page + 1);
    }
  }

  void _selectStatus(BlogStatus? status) {
    if (status == _status) return;
    setState(() => _status = status);
    _load(page: 0);
  }

  Future<void> _load({required int page}) async {
    if (page == 0) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    final requestedStatus = _status;
    try {
      final result = await ref
          .read(blogApiProvider)
          .myPosts(status: requestedStatus, page: page, size: _pageSize);
      if (!mounted || requestedStatus != _status) return;
      setState(() {
        if (page == 0) {
          _posts
            ..clear()
            ..addAll(result.content);
        } else {
          _posts.addAll(result.content);
        }
        _page = result.page;
        _totalPages = result.totalPages;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestedStatus != _status) return;
      setState(() {
        if (page == 0) _error = 'Could not load your posts';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _edit(BlogPost post) async {
    final saved = await context.push<bool>(
      '/blog/${post.id}/edit',
      extra: post,
    );
    if (saved == true && mounted) await _load(page: 0);
  }

  Future<void> _delete(BlogPost post) async {
    if (!await confirmBlogPostDeletion(context)) return;
    try {
      await ref.read(blogApiProvider).deletePost(post.id);
      if (!mounted) return;
      ref.read(blogFeedProvider.notifier).removePost(post.id);
      setState(() => _posts.removeWhere((item) => item.id == post.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted')));
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blogOwnerActionError(e, BlogOwnerAction.delete)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blogSheetColor(context),
      body: Column(
        children: [
          BlogTopBar(title: 'Your posts', onBack: () => context.pop()),
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final (label, status) = _filters[index];
                return BlogTab(
                  label: label,
                  selected: _status == status,
                  onTap: () => _selectStatus(status),
                );
              },
            ),
          ),
          const BlogDivider(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 4,
        separatorBuilder: (_, _) => const BlogDivider(),
        itemBuilder: (_, _) => const BlogRowSkeleton(),
      );
    }
    if (_error != null) {
      return BlogNotice(
        title: 'Could not load your posts',
        body: _error!,
        icon: Icons.cloud_off_outlined,
        actionLabel: 'Try again',
        onAction: () => _load(page: 0),
      );
    }
    if (_posts.isEmpty) {
      return BlogNotice(
        title: _status == null ? 'No posts yet' : 'Nothing here',
        body: _status == null
            ? 'Everything you write shows up here, with its review status.'
            : 'You have no posts with this status right now.',
        icon: Icons.edit_note_rounded,
        actionLabel: _status == null ? 'Write a post' : null,
        onAction: _status == null
            ? () async {
                final created = await context.push<bool>('/blog/create');
                if (created == true) _load(page: 0);
              }
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(page: 0),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(bottom: RiksaSpacing.lg),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const BlogDivider(),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return Padding(
              padding: const EdgeInsets.all(RiksaSpacing.lg),
              child: Center(
                child: _loadingMore
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          final post = _posts[index];
          return _MyPostRow(
            post: post,
            onEdit: () => _edit(post),
            onDelete: () => _delete(post),
          );
        },
      ),
    );
  }
}

class _MyPostRow extends StatelessWidget {
  const _MyPostRow({
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });

  final BlogPost post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final preview = post.plainTextPreview;
    final rejected =
        post.status == BlogStatus.rejected &&
        (post.rejectionReason?.isNotEmpty ?? false);

    return InkWell(
      // Only approved posts resolve on the public detail endpoint.
      onTap: post.status == BlogStatus.approved
          ? () => context.push('/blog/${post.id}')
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BlogMetrics.gutter,
          14,
          BlogMetrics.gutter,
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.bodyStyleFor(
                      post.title,
                      theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: RiksaSpacing.sm),
                _StatusBadge(status: post.status),
                BlogOwnerMenu(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  preview,
                  theme.textTheme.bodyMedium?.copyWith(
                    color: palette.inkMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: RiksaSpacing.xs),
            Row(
              children: [
                Text(
                  blogFullDate(context, post.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
                if (post.status == BlogStatus.approved) ...[
                  const SizedBox(width: RiksaSpacing.md),
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 16,
                    color: palette.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    blogCountLabel(post.viewCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                  const SizedBox(width: RiksaSpacing.md),
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 16,
                    color: palette.inkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    blogCountLabel(post.likeCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
            if (rejected) ...[
              const SizedBox(height: RiksaSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(RiksaSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: .08),
                  borderRadius: AppRadii.mediumBorder,
                ),
                child: Text(
                  post.rejectionReason!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BlogStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final (label, foreground, background) = switch (status) {
      // Ink on the soft amber keeps the label legible; the tint carries the
      // status signal on its own.
      BlogStatus.pending => ('In review', palette.ink, palette.saffronSoft),
      BlogStatus.approved => (
        'Published',
        palette.jadeStrong,
        palette.jadeSoft,
      ),
      BlogStatus.rejected => (
        'Rejected',
        Theme.of(context).colorScheme.error,
        Theme.of(context).colorScheme.error.withValues(alpha: .1),
      ),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
