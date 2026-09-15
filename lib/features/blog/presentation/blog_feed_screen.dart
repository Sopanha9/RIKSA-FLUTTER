import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../auth/providers/auth_provider.dart';
import '../../userProfile/data/public_profile.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/blog_api.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';
import 'widgets/blog_ui.dart';

/// Timeline of approved community articles.
///
/// The layout follows a social timeline rather than a card grid: one sheet,
/// author-first rows, and a hairline between posts. Colour, type, and radii
/// all come from the Riksa palette.
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
    final selectedCategoryId = feedState is BlogFeedLoaded
        ? feedState.categoryId
        : null;

    return Scaffold(
      backgroundColor: blogSheetColor(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        tooltip: 'Write a post',
        child: const Icon(Icons.edit_outlined),
      ),
      body: Column(
        children: [
          BlogTopBar(
            title: 'Blog',
            onBack: () => context.pop(),
            trailing: IconButton(
              onPressed: () => context.push('/blog/my-posts'),
              tooltip: 'Your posts',
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: context.riksa.ink,
              ),
              icon: const Icon(Icons.article_outlined, size: 22),
            ),
          ),
          _CategoryTabs(selectedCategoryId: selectedCategoryId),
          Expanded(child: _buildBody(feedState)),
        ],
      ),
    );
  }

  Widget _buildBody(BlogFeedState state) => switch (state) {
    BlogFeedLoading() => ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 5,
      separatorBuilder: (_, _) => const BlogDivider(),
      itemBuilder: (_, _) => const BlogRowSkeleton(),
    ),
    BlogFeedError(:final message) => BlogNotice(
      title: 'Posts are taking a break',
      body: message,
      icon: Icons.cloud_off_outlined,
      actionLabel: 'Try again',
      onAction: () => ref.read(blogFeedProvider.notifier).load(),
    ),
    BlogFeedLoaded(:final posts, :final hasMore, :final isLoadingMore) =>
      posts.isEmpty
          ? BlogNotice(
              title: 'Nothing posted yet',
              body:
                  'Be the first learner to share something useful with the '
                  'Riksa community.',
              icon: Icons.menu_book_outlined,
              actionLabel: 'Write a post',
              onAction: _createPost,
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(blogFeedProvider.notifier).load(),
              child: ListView.separated(
                key: const PageStorageKey('blog-feed-scroll'),
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: posts.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == posts.length) {
                    return Padding(
                      padding: const EdgeInsets.all(RiksaSpacing.lg),
                      child: Center(
                        child: isLoadingMore
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }
                  return BlogTimelineRow(post: posts[index]);
                },
              ),
            ),
  };
}

/// Horizontal tab strip. `All` plus one tab per category, with the underline
/// indicator marking the active feed.
class _CategoryTabs extends ConsumerWidget {
  const _CategoryTabs({required this.selectedCategoryId});

  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(blogCategoriesProvider);
    return SizedBox(
      height: 48,
      child: categories.when(
        loading: () => const Padding(
          padding: EdgeInsets.fromLTRB(BlogMetrics.gutter, 12, 0, 16),
          child: Row(
            children: [
              RiksaSkeleton(height: 14, width: 54, radius: AppRadii.full),
              SizedBox(width: 26),
              RiksaSkeleton(height: 14, width: 78, radius: AppRadii.full),
              SizedBox(width: 26),
              RiksaSkeleton(height: 14, width: 62, radius: AppRadii.full),
            ],
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            final category = index == 0 ? null : items[index - 1];
            final id = category?.id;
            return BlogTab(
              label: category?.name ?? 'All',
              selected: selectedCategoryId == id,
              onTap: () =>
                  ref.read(blogFeedProvider.notifier).load(categoryId: id),
            );
          },
        ),
      ),
    );
  }
}

/// One post in the timeline: author line, headline, preview, cover, actions.
class BlogTimelineRow extends ConsumerWidget {
  const BlogTimelineRow({super.key, required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final profile = ref.watch(blogAuthorProvider(post.authorId)).value;
    final isOwner = ref.watch(currentUserIdProvider) == post.authorId;
    final preview = post.plainTextPreview;

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.largeBorder,
        side: BorderSide(color: palette.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/blog/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlogAvatar(
                profile: profile,
                size: BlogMetrics.rowAvatar,
                onTap: () => _openProfile(context, profile),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BlogAuthorMetaLine(
                            profile: profile,
                            createdAt: post.createdAt,
                          ),
                        ),
                        if (isOwner)
                          BlogOwnerMenu(
                            onEdit: () => _edit(context, ref),
                            onDelete: () => _delete(context, ref),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        post.title,
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: -.2,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 3,
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
                    if (post.hasCover) ...[
                      const SizedBox(height: 12),
                      BlogCoverImage(url: post.coverUrl!),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        BlogAction(
                          icon: Icons.favorite_border_rounded,
                          activeIcon: Icons.favorite_rounded,
                          label: blogCountLabel(post.likeCount),
                          semanticLabel: post.liked
                              ? 'Unlike, ${post.likeCount} likes'
                              : 'Like, ${post.likeCount} likes',
                          selected: post.liked,
                          selectedColor: theme.colorScheme.error,
                          onTap: () => ref
                              .read(blogFeedProvider.notifier)
                              .toggleLike(post.id),
                        ),
                        const SizedBox(width: RiksaSpacing.md),
                        BlogAction(
                          icon: Icons.bar_chart_rounded,
                          label: blogCountLabel(post.viewCount),
                          semanticLabel: '${post.viewCount} views',
                        ),
                        const Spacer(),
                        Flexible(
                          child: BlogCategoryTag(categoryId: post.categoryId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await context.push<bool>(
      '/blog/${post.id}/edit',
      extra: post,
    );
    if (saved == true && context.mounted) {
      await ref.read(blogFeedProvider.notifier).load();
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmBlogPostDeletion(context)) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(blogApiProvider).deletePost(post.id);
      ref.read(blogFeedProvider.notifier).removePost(post.id);
      messenger.showSnackBar(const SnackBar(content: Text('Post deleted')));
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(blogOwnerActionError(e, BlogOwnerAction.delete)),
        ),
      );
    }
  }

  void _openProfile(BuildContext context, PublicProfile? profile) {
    final path = publicProfilePath(profile?.id ?? post.authorId);
    if (path != null) context.push(path);
  }
}
