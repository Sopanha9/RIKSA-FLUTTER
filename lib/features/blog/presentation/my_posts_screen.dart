import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  final _scrollCtrl = ScrollController();
  final List<BlogPost> _posts = [];
  int _page = 0;
  int _totalPages = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  static const int _pageSize = 20;

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

  Future<void> _load({required int page}) async {
    if (page == 0) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final result = await ref
          .read(blogApiProvider)
          .myPosts(page: page, size: _pageSize);
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        if (page == 0) _error = 'Could not load your posts';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Posts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _load(page: 0),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _posts.isEmpty
          ? Center(
              child: Text(
                'You have not written any posts yet',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
            )
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: _posts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _posts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return _MyPostTile(post: _posts[index]);
              },
            ),
    );
  }
}

class _MyPostTile extends StatelessWidget {
  const _MyPostTile({required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onBackground,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: post.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMd().format(post.createdAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
          if (post.status == BlogStatus.rejected &&
              (post.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: AppRadii.smallBorder,
              ),
              child: Text(
                post.rejectionReason!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BlogStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BlogStatus.pending => ('Pending', const Color(0xFFB45309)),
      BlogStatus.approved => ('Approved', AppTheme.primary),
      BlogStatus.rejected => ('Rejected', AppTheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadii.smallBorder,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
