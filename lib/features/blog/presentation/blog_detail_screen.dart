import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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

/// Long-form reading view for a single post.
///
/// The cover runs full bleed under a floating back control, the headline
/// carries the page, and the metrics sit in a bar that floats above the text
/// so the reading column stays uninterrupted.
class BlogDetailScreen extends ConsumerStatefulWidget {
  const BlogDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  static const double _coverHeight = 268;

  final _scrollController = ScrollController();
  BlogPost? _post;
  bool _loading = true;
  bool _liking = false;
  bool _collapsed = false;
  double _readingProgress = 0.0;
  double _textScale = 1.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold = (_post?.hasCover ?? false)
        ? _coverHeight - kToolbarHeight - 24
        : 8.0;
    final collapsed = _scrollController.offset > threshold;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);

    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      final progress =
          (_scrollController.offset /
                  _scrollController.position.maxScrollExtent)
              .clamp(0.0, 1.0);
      if ((progress - _readingProgress).abs() > 0.005) {
        setState(() => _readingProgress = progress);
      }
    }
  }

  void _cycleFontSize() {
    HapticFeedback.selectionClick();
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    setState(() {
      if (_textScale <= 1.0) {
        _textScale = 1.18;
      } else if (_textScale <= 1.2) {
        _textScale = 1.35;
      } else {
        _textScale = 1.0;
      }
    });
    final label = _textScale > 1.2
        ? (isKhmer
              ? 'ទំហំអក្សរ៖ ធំខ្លាំង (1.35x)'
              : 'Text size: Extra Large (1.35x)')
        : (_textScale > 1.0
              ? (isKhmer ? 'ទំហំអក្សរ៖ ធំ (1.18x)' : 'Text size: Large (1.18x)')
              : (isKhmer
                    ? 'ទំហំអក្សរ៖ ធម្មតា (1.0x)'
                    : 'Text size: Default (1.0x)'));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(label), duration: const Duration(seconds: 1)),
      );
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
    if (_post == null || _liking) return;
    setState(() => _liking = true);
    try {
      final updated = await ref.read(blogApiProvider).toggleLike(widget.id);
      if (!mounted) return;
      setState(() => _post = updated);
      // Keep the timeline row in step with what the reader just did.
      ref.read(blogFeedProvider.notifier).applyUpdate(updated);
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

  Future<void> _edit(BlogPost post) async {
    final saved = await context.push<bool>(
      '/blog/${post.id}/edit',
      extra: post,
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(BlogPost post) async {
    if (!await confirmBlogPostDeletion(context)) return;
    try {
      await ref.read(blogApiProvider).deletePost(post.id);
      if (!mounted) return;
      ref.read(blogFeedProvider.notifier).removePost(post.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      context.pop();
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

  void _openProfile(PublicProfile? profile) {
    final path = publicProfilePath(profile?.id ?? _post?.authorId);
    if (path != null) context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    return Scaffold(
      backgroundColor: blogSheetColor(context),
      body: _loading
          ? _ChromeScaffold(child: const _ArticleSkeleton())
          : _error != null
          ? _ChromeScaffold(
              child: BlogNotice(
                title: 'This post would not open',
                body: _error!,
                icon: Icons.cloud_off_outlined,
                actionLabel: 'Try again',
                onAction: _load,
              ),
            )
          : Stack(
              children: [
                _buildArticle(post!),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom:
                      MediaQuery.paddingOf(context).bottom + RiksaSpacing.md,
                  child: Center(
                    child: _MetricsBar(post: post, onLike: _toggleLike),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildArticle(BlogPost post) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final profile = ref.watch(blogAuthorProvider(post.authorId)).value;
    final isOwner = ref.watch(currentUserIdProvider) == post.authorId;

    return SelectionArea(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: palette.surface,
            surfaceTintColor: Colors.transparent,
            expandedHeight: post.hasCover ? _coverHeight : null,
            leadingWidth: 60,
            leading: Center(
              child: _ChromeButton(
                icon: Icons.arrow_back_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
                onImage: post.hasCover && !_collapsed,
              ),
            ),
            title: AnimatedOpacity(
              duration: RiksaMotion.resolve(context, RiksaMotion.fast),
              opacity: _collapsed ? 1 : 0,
              child: Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  post.title,
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2.5),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AnimatedOpacity(
                    duration: RiksaMotion.resolve(context, RiksaMotion.fast),
                    opacity: _collapsed ? 1 : 0,
                    child: const BlogDivider(),
                  ),
                  LinearProgressIndicator(
                    key: const ValueKey('blog-reading-progress'),
                    value: _readingProgress,
                    minHeight: 2.5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.brand),
                  ),
                ],
              ),
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: RiksaSpacing.xs),
                  child: _ChromeButton(
                    key: const ValueKey('blog-font-size-toggle'),
                    icon: Icons.format_size_rounded,
                    tooltip:
                        Localizations.localeOf(context).languageCode == 'km'
                        ? 'ប្តូរទំហំអក្សរ'
                        : 'Adjust text size',
                    onPressed: _cycleFontSize,
                    onImage: post.hasCover && !_collapsed,
                  ),
                ),
              ),
              if (isOwner)
                Padding(
                  padding: const EdgeInsets.only(right: RiksaSpacing.xs),
                  child: BlogOwnerMenu(
                    onEdit: () => _edit(post),
                    onDelete: () => _delete(post),
                    onImage: post.hasCover && !_collapsed,
                  ),
                ),
            ],
            flexibleSpace: post.hasCover
                ? FlexibleSpaceBar(
                    background: _CoverHeader(url: post.coverUrl!),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: BlogMetrics.readingWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    RiksaSpacing.md + 4,
                    RiksaSpacing.md,
                    RiksaSpacing.md + 4,
                    112 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlogCategoryTag(categoryId: post.categoryId),
                      const SizedBox(height: RiksaSpacing.sm),
                      Text(
                        post.title,
                        style: RiksaTypography.titleStyleFor(
                          post.title,
                          theme.textTheme.displaySmall?.copyWith(
                            fontSize: 26 * _textScale,
                            fontWeight: FontWeight.w600,
                            height: 1.18,
                            letterSpacing: 0,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: RiksaSpacing.md),
                      _AuthorHeader(
                        profile: profile,
                        post: post,
                        // Your own byline needs no shortcut to your profile.
                        showProfileAction: !isOwner,
                        onOpenProfile: () => _openProfile(profile),
                      ),
                      const SizedBox(height: RiksaSpacing.md),
                      const BlogDivider(),
                      const SizedBox(height: RiksaSpacing.md),
                      MarkdownBody(
                        key: const ValueKey('blog-post-markdown'),
                        data: post.markdownContent,
                        softLineBreak: true,
                        styleSheet: blogMarkdownStyleSheet(
                          context,
                          post.markdownContent,
                          textScale: _textScale,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back chrome for the states that render before a post is available.
class _ChromeScaffold extends StatelessWidget {
  const _ChromeScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: RiksaSpacing.md),
              _ChromeButton(
                icon: Icons.arrow_back_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
                onImage: false,
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

/// Circular control that stays legible whether it sits on the sheet or on
/// top of a cover photo.
class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.onImage,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return AnimatedContainer(
      duration: RiksaMotion.resolve(context, RiksaMotion.fast),
      decoration: ShapeDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: .48)
            : Colors.transparent,
        shape: const CircleBorder(),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: onImage ? Colors.white : palette.ink,
          minimumSize: const Size.square(44),
        ),
        icon: Icon(icon, size: 22),
      ),
    );
  }
}

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(
            color: palette.surfaceRaised,
            child: Icon(
              Icons.auto_stories_outlined,
              size: 52,
              color: palette.inkMuted,
            ),
          ),
        ),
        // Keeps the floating back control readable on light photography.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x66000000), Color(0x00000000)],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({
    required this.profile,
    required this.post,
    required this.showProfileAction,
    required this.onOpenProfile,
  });

  final PublicProfile? profile;
  final BlogPost post;
  final bool showProfileAction;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final name = blogAuthorName(profile);
    final handle = profile?.username.trim() ?? '';
    final date = blogFullDate(context, post.createdAt);

    return Row(
      children: [
        BlogAvatar(
          profile: profile,
          size: BlogMetrics.detailAvatar,
          onTap: onOpenProfile,
        ),
        const SizedBox(width: RiksaSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onOpenProfile,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RiksaTypography.bodyStyleFor(
                          name,
                          theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (profile?.isVerified ?? false) ...[
                    const SizedBox(width: 4),
                    const BlogVerifiedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                handle.isEmpty ? date : '@$handle · $date',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (profile != null && showProfileAction) ...[
          const SizedBox(width: RiksaSpacing.sm),
          FilledButton(
            onPressed: onOpenProfile,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Profile'),
          ),
        ],
      ],
    );
  }
}

/// Floating pill with the post metrics and the like control.
class _MetricsBar extends StatelessWidget {
  const _MetricsBar({required this.post, required this.onLike});

  final BlogPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.outline)),
        shadows: RiksaElevation.low(theme.brightness),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              onTap: onLike,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.sm),
              child: SizedBox(
                height: 18,
                child: VerticalDivider(width: 1, color: palette.outline),
              ),
            ),
            BlogAction(
              icon: Icons.bar_chart_rounded,
              label: blogCountLabel(post.viewCount),
              semanticLabel: '${post.viewCount} views',
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleSkeleton extends StatelessWidget {
  const _ArticleSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: RiksaSpacing.md + 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RiksaSkeleton(height: 180, radius: AppRadii.large),
        SizedBox(height: RiksaSpacing.lg),
        RiksaSkeleton(height: 26, radius: AppRadii.small),
        SizedBox(height: RiksaSpacing.xs),
        RiksaSkeleton(height: 26, width: 220, radius: AppRadii.small),
        SizedBox(height: RiksaSpacing.lg),
        RiksaSkeleton(height: 14, radius: AppRadii.full),
        SizedBox(height: RiksaSpacing.sm),
        RiksaSkeleton(height: 14, radius: AppRadii.full),
        SizedBox(height: RiksaSpacing.sm),
        RiksaSkeleton(height: 14, width: 260, radius: AppRadii.full),
      ],
    ),
  );
}
