import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';

class BlogFeedScreen extends ConsumerStatefulWidget {
  const BlogFeedScreen({super.key});

  @override
  ConsumerState<BlogFeedScreen> createState() => _BlogFeedScreenState();
}

class _BlogFeedScreenState extends ConsumerState<BlogFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(blogFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _createPost() async {
    final created = await context.push<bool>('/blog/create');
    if (created == true) ref.read(blogFeedProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(blogFeedProvider);
    final categories = ref.watch(blogCategoriesProvider);
    final selectedCategoryId = feedState is BlogFeedLoaded
        ? feedState.categoryId
        : null;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Write'),
      ),
      body: Column(
        children: [
          RiksaPageHeader(
            title: 'Stories',
            subtitle: 'Ideas and lessons from the Riksa community',
            leading: RiksaRoundedIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.pop(),
            ),
            trailing: RiksaRoundedIconButton(
              icon: Icons.article_outlined,
              tooltip: 'My posts',
              onPressed: () => context.push('/blog/my-posts'),
            ),
          ),
          _CategoryChips(
            categories: categories,
            selectedCategoryId: selectedCategoryId,
          ),
          const SizedBox(height: RiksaSpacing.sm),
          Expanded(child: _buildBody(feedState)),
        ],
      ),
    );
  }

  Widget _buildBody(BlogFeedState state) => switch (state) {
    BlogFeedLoading() => const RiksaStateView(
      title: 'Finding fresh stories',
      body: 'Gathering the latest posts for you.',
      loading: true,
    ),
    BlogFeedError(:final message) => RiksaStateView(
      title: 'Stories are taking a break',
      body: message,
      icon: Icons.cloud_off_outlined,
      actionLabel: 'Try again',
      onAction: () => ref.read(blogFeedProvider.notifier).load(),
    ),
    BlogFeedLoaded(:final posts, :final hasMore, :final isLoadingMore) =>
      posts.isEmpty
          ? RiksaStateView(
              title: 'A blank first page',
              body: 'Be the first learner to share something useful.',
              icon: Icons.menu_book_outlined,
              actionLabel: 'Write a story',
              onAction: _createPost,
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(blogFeedProvider.notifier).load(),
              child: ListView.builder(
                key: const PageStorageKey('blog-feed-scroll'),
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  RiksaSpacing.md,
                  0,
                  RiksaSpacing.md,
                  112,
                ),
                itemCount: posts.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == posts.length) {
                    return Padding(
                      padding: const EdgeInsets.all(RiksaSpacing.lg),
                      child: Center(
                        child: isLoadingMore
                            ? const CircularProgressIndicator()
                            : const SizedBox.shrink(),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: RiksaSpacing.md),
                    child: _PostCard(post: posts[index], index: index),
                  );
                },
              ),
            ),
  };
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategoryId,
  });

  final AsyncValue<List<BlogCategory>> categories;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: categories.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
          child: RiksaSkeleton(height: 44, radius: AppRadii.full),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: RiksaSpacing.xs),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final category = isAll ? null : items[index - 1];
            final id = category?.id;
            return RiksaChoicePill(
              label: category?.name ?? 'All',
              icon: isAll ? Icons.grid_view_rounded : Icons.bookmark_outline,
              selected: selectedCategoryId == id,
              onSelected: (_) =>
                  ref.read(blogFeedProvider.notifier).load(categoryId: id),
            );
          },
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.index});

  final BlogPost post;
  final int index;

  RiksaPastelTone get _tone => switch (index % 3) {
    0 => RiksaPastelTone.cream,
    1 => RiksaPastelTone.jade,
    _ => RiksaPastelTone.blush,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.riksa;
    return RiksaPastelCard(
      tone: _tone,
      padding: EdgeInsets.zero,
      semanticLabel: post.title,
      onTap: () => context.push('/blog/${post.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.hasCover)
            AspectRatio(
              aspectRatio: 2,
              child: Image.network(
                post.coverUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: palette.surfaceRaised,
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 52,
                    color: palette.jadeStrong,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(RiksaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: ShapeDecoration(
                        color: palette.surface.withValues(alpha: .72),
                        shape: const StadiumBorder(),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RiksaSpacing.sm,
                          vertical: RiksaSpacing.xxs,
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(post.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: palette.inkMuted,
                    ),
                    const SizedBox(width: RiksaSpacing.xxs),
                    Text(
                      '${post.viewCount}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: RiksaSpacing.sm),
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: RiksaSpacing.xs),
                Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: RiksaSpacing.sm),
                Row(
                  children: [
                    Text(
                      'Read story',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.jadeStrong,
                      ),
                    ),
                    const SizedBox(width: RiksaSpacing.xxs),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: palette.jadeStrong,
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: post.liked ? 'Unlike' : 'Like',
                      child: InkResponse(
                        onTap: () => ref
                            .read(blogFeedProvider.notifier)
                            .toggleLike(post.id),
                        radius: 24,
                        child: SizedBox.square(
                          dimension: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                post.liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                                color: post.liked
                                    ? Theme.of(context).colorScheme.error
                                    : palette.inkMuted,
                              ),
                              const SizedBox(width: RiksaSpacing.xxs),
                              Text(
                                '${post.likeCount}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
