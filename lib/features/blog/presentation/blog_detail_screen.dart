import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';

class BlogDetailScreen extends ConsumerStatefulWidget {
  const BlogDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  BlogPost? _post;
  bool _loading = true;
  bool _liking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await ref.read(blogApiProvider).getPost(widget.id);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this post';
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null || _liking) return;
    setState(() => _liking = true);
    try {
      final updated = await ref.read(blogApiProvider).toggleLike(widget.id);
      if (mounted) setState(() => _post = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update like')),
        );
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.muted),
                    ),
                  ),
                )
              : _buildContent(_post!),
    );
  }

  Widget _buildContent(BlogPost post) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (post.hasCover)
            Image.network(
              post.coverUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.viewCount} views',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.muted),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      post.liked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color:
                          post.liked ? AppTheme.secondary : AppTheme.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: post.liked
                                ? AppTheme.secondary
                                : AppTheme.muted,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMd().format(post.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SelectableText(
                  post.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: AppTheme.onBackground,
                      ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _liking ? null : _toggleLike,
                  icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: post.liked ? AppTheme.secondary : null,
                  ),
                  label: Text(post.liked ? 'Liked' : 'Like'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
