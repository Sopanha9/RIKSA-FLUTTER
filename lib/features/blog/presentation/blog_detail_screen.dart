import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
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
        _error = 'Could not load this story';
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null || _liking) return;
    setState(() => _liking = true);
    try {
      final updated = await ref.read(blogApiProvider).toggleLike(widget.id);
      if (mounted) setState(() => _post = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not update like')));
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: _loading
          ? const RiksaStateView(
              title: 'Opening story',
              body: 'Preparing a comfortable reading view.',
              loading: true,
            )
          : _error != null
          ? RiksaStateView(
              title: 'This story would not open',
              body: _error!,
              icon: Icons.cloud_off_outlined,
              actionLabel: 'Try again',
              onAction: _load,
            )
          : _buildContent(_post!),
    );
  }

  Widget _buildContent(BlogPost post) {
    final palette = context.riksa;
    return SelectionArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          RiksaSpacing.md,
          RiksaSpacing.xs,
          RiksaSpacing.md,
          RiksaSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RiksaPastelCard(
                  tone: RiksaPastelTone.blush,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (post.hasCover)
                        AspectRatio(
                          aspectRatio: 16 / 8,
                          child: Image.network(
                            post.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: palette.surfaceRaised,
                              child: Icon(
                                Icons.auto_stories_outlined,
                                size: 56,
                                color: palette.jadeStrong,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(RiksaSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RIKSA STORY',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: palette.jadeStrong,
                                    letterSpacing: 1,
                                  ),
                            ),
                            const SizedBox(height: RiksaSpacing.xs),
                            Text(
                              post.title,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: RiksaSpacing.md),
                            Wrap(
                              spacing: RiksaSpacing.md,
                              runSpacing: RiksaSpacing.xs,
                              children: [
                                _StoryMeta(
                                  icon: Icons.calendar_today_outlined,
                                  label: DateFormat.yMMMd().format(
                                    post.createdAt,
                                  ),
                                ),
                                _StoryMeta(
                                  icon: Icons.visibility_outlined,
                                  label: '${post.viewCount} views',
                                ),
                                _StoryMeta(
                                  icon: Icons.favorite_border_rounded,
                                  label: '${post.likeCount} likes',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RiksaSpacing.md),
                RiksaPastelCard(
                  padding: const EdgeInsets.all(RiksaSpacing.lg),
                  child: Text(
                    post.content,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.75),
                  ),
                ),
                const SizedBox(height: RiksaSpacing.md),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _liking ? null : _toggleLike,
                    icon: Icon(
                      post.liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: post.liked
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    label: Text(post.liked ? 'Liked' : 'Like this story'),
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

class _StoryMeta extends StatelessWidget {
  const _StoryMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.riksa.inkMuted),
      const SizedBox(width: RiksaSpacing.xxs),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
