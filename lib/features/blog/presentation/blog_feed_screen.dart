import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';

class BlogFeedScreen extends ConsumerStatefulWidget {
  const BlogFeedScreen({super.key});

  @override
  ConsumerState<BlogFeedScreen> createState() => _BlogFeedScreenState();
}

class _BlogFeedScreenState extends ConsumerState<BlogFeedScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(blogFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(blogFeedProvider);
    final categoriesAsync = ref.watch(blogCategoriesProvider);
    final selectedCategoryId = feedState is BlogFeedLoaded
        ? feedState.categoryId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
        actions: [
          IconButton(
            onPressed: () => context.push('/blog/my-posts'),
            icon: const Icon(Icons.article_outlined),
            tooltip: 'My posts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/blog/create');
          if (created == true) {
            ref.read(blogFeedProvider.notifier).load();
          }
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.edit_outlined, color: AppTheme.onPrimary),
      ),
      body: Column(
        children: [
          _CategoryChips(
            categoriesAsync: categoriesAsync,
            selectedCategoryId: selectedCategoryId,
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(feedState)),
        ],
      ),
    );
  }

  Widget _buildBody(BlogFeedState feedState) {
    return switch (feedState) {
      BlogFeedLoading() => const Center(child: CircularProgressIndicator()),
      BlogFeedError(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(blogFeedProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      BlogFeedLoaded(:final posts, :final hasMore, :final isLoadingMore) =>
        posts.isEmpty
            ? Center(
                child: Text(
                  'No posts yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
              )
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                itemCount: posts.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == posts.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isLoadingMore
                                ? AppTheme.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  }
                  return _PostCard(post: posts[index]);
                },
              ),
    };
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({
    required this.categoriesAsync,
    required this.selectedCategoryId,
  });

  final AsyncValue<List<BlogCategory>> categoriesAsync;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: categoriesAsync.when(
        loading: () => const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (categories) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _Chip(
                label: 'All',
                selected: selectedCategoryId == null,
                onTap: () => ref.read(blogFeedProvider.notifier).load(),
              );
            }
            final category = categories[index - 1];
            return _Chip(
              label: category.name,
              selected: selectedCategoryId == category.id,
              onTap: () => ref
                  .read(blogFeedProvider.notifier)
                  .load(categoryId: category.id),
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: AppRadii.mediumBorder,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppTheme.onPrimary : AppTheme.onBackground,
          ),
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/blog/${post.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppRadii.smallBorder,
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.hasCover)
              Image.network(
                post.coverUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        DateFormat.yMMMd().format(post.createdAt),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.viewCount}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref
                            .read(blogFeedProvider.notifier)
                            .toggleLike(post.id),
                        child: Row(
                          children: [
                            Icon(
                              post.liked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: post.liked
                                  ? AppTheme.secondary
                                  : AppTheme.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likeCount}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: post.liked
                                        ? AppTheme.secondary
                                        : AppTheme.muted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
