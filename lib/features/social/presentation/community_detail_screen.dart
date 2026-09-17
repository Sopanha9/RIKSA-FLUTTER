import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../learning/presentation/learning_design.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'widgets/community_avatar.dart';
import 'widgets/community_banner_pattern.dart';
import 'widgets/social_post_card.dart';

enum CommunityFeedSort { hot, newest, top }

/// One community's own page: banner, header, join, and its feed of posts.
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.communityId,
    this.community,
  });

  final String communityId;

  /// The community as the list already knew it, so the header draws at once.
  final SocialCategory? community;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  SocialCategory? _community;
  List<SocialPost>? _posts;
  String? _endCursor;
  bool _hasNextPage = false;
  bool _loadingMore = false;
  bool _failed = false;
  bool _joining = false;
  CommunityFeedSort _sort = CommunityFeedSort.hot;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final api = ref.read(socialApiProvider);
    try {
      final results = await Future.wait([
        if (_community == null) api.categories(),
        api.feed(categoryId: widget.communityId),
      ]);
      if (!mounted) return;
      final page = results.last as SocialFeedPage;
      setState(() {
        _community ??= (results.first as List<SocialCategory>)
            .where((item) => item.id == widget.communityId)
            .firstOrNull;
        _posts = page.posts;
        _endCursor = page.endCursor;
        _hasNextPage = page.hasNextPage;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNextPage || _posts == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(socialApiProvider)
          .feed(categoryId: widget.communityId, cursor: _endCursor);
      if (!mounted) return;
      setState(() {
        _posts = [..._posts!, ...page.posts];
        _endCursor = page.endCursor;
        _hasNextPage = page.hasNextPage;
      });
    } catch (_) {
      if (mounted) _showFailure();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleJoin() async {
    final community = _community;
    if (community == null || _joining) return;
    setState(() => _joining = true);
    try {
      final updated = await ref
          .read(socialApiProvider)
          .setCategoryJoined(community.id, joined: !community.joined);
      // Only a feed that is already loaded needs to hear about it.
      if (ref.exists(socialFeedProvider)) {
        ref.read(socialFeedProvider.notifier).syncCategory(updated);
      }
      if (mounted) setState(() => _community = updated);
    } catch (_) {
      if (mounted) _showFailure();
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _replacePost(SocialPost post) {
    final posts = _posts;
    if (posts == null) return;
    setState(() {
      _posts = [for (final item in posts) item.id == post.id ? post : item];
    });
  }

  Future<void> _react(SocialPost original) async {
    final reaction = SocialReaction.upvote;
    final removing = original.myReaction == reaction;
    _replacePost(
      original.copyWith(
        reactionCount: removing
            ? (original.reactionCount - 1).clamp(0, 1 << 31)
            : original.myReaction == null
            ? original.reactionCount + 1
            : original.reactionCount,
        myReaction: reaction,
        clearReaction: removing,
      ),
    );
    try {
      final updated = await ref
          .read(socialApiProvider)
          .react(postId: original.id, reaction: reaction);
      if (mounted) _replacePost(updated);
    } catch (_) {
      if (!mounted) return;
      _replacePost(original);
      _showFailure();
    }
  }

  Future<void> _share(SocialPost post) async {
    try {
      final updated = await ref.read(socialApiProvider).share(post.id);
      if (mounted) _replacePost(updated);
    } catch (_) {
      if (mounted) _showFailure();
      return;
    }
    if (!mounted) return;
    await _copyLink(
      'https://riksa.app/community/posts/${post.id}',
      AppLocalizations.of(context)!.copiedLink,
    );
  }

  Future<void> _copyLink(String link, String message) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showFailure() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.actionFailed)),
      );
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<CommunityFeedSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SortSheet(selected: _sort),
    );
    if (picked != null && mounted) setState(() => _sort = picked);
  }

  List<SocialPost> _sorted(List<SocialPost> posts) {
    final sorted = [...posts];
    switch (_sort) {
      case CommunityFeedSort.hot:
        break;
      case CommunityFeedSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case CommunityFeedSort.top:
        sorted.sort((a, b) => b.reactionCount.compareTo(a.reactionCount));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final community = _community;
    final subject = stemSubjectFor(community?.name ?? '');
    final posts = _posts;

    return Scaffold(
      backgroundColor: palette.canvas,
      floatingActionButton: community == null || !community.joined
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('community-create-post'),
              shape: const StadiumBorder(),
              onPressed: () async {
                await context.push(
                  '/community/create?community=${community.id}',
                );
                if (mounted) _load();
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.communityCreatePost),
            ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 400) _loadMore();
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _load,
          edgeOffset: 120,
          child: CustomScrollView(
            slivers: [
              _BannerAppBar(
                subject: subject,
                title: community?.name ?? '',
                onShare: community == null
                    ? null
                    : () => _copyLink(
                        'https://riksa.app/communities/${community.id}',
                        l10n.communityLinkCopied,
                      ),
              ),
              if (community != null)
                SliverToBoxAdapter(
                  child: _CommunityHeader(
                    community: community,
                    subject: subject,
                    busy: _joining,
                    onToggleJoin: _toggleJoin,
                  ),
                ),
              if (posts != null && posts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _SortChip(sort: _sort, onTap: _pickSort),
                    ),
                  ),
                ),
              ..._feedSlivers(context, posts),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _feedSlivers(BuildContext context, List<SocialPost>? posts) {
    final l10n = AppLocalizations.of(context)!;
    if (posts == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: _failed
                ? IllustratedEmptyState(
                    title: l10n.communitiesUnavailable,
                    body: l10n.communitiesLoadFailed,
                    actionLabel: l10n.tryAgain,
                    onAction: _load,
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      ];
    }
    if (_community == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: IllustratedEmptyState(
            title: l10n.communitiesUnavailable,
            body: l10n.communityNotFound,
          ),
        ),
      ];
    }
    if (posts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: IllustratedEmptyState(
            title: l10n.communityNoPostsTitle,
            body: l10n.communityNoPostsBody,
          ),
        ),
      ];
    }
    final currentUserId = ref.watch(currentUserIdProvider);
    final sorted = _sorted(posts);
    return [
      SliverList.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final post = sorted[index];
          return SocialPostCard(
            key: ValueKey('community-post-${post.id}'),
            post: post,
            onTap: () async {
              await context.push('/community/posts/${post.id}');
              if (mounted) _load();
            },
            onAuthorTap: publicProfilePath(post.author.id) == null
                ? null
                : () => context.push(publicProfilePath(post.author.id)!),
            onReact: () => _react(post),
            onShare: () => _share(post),
            onEdit: post.author.id == currentUserId
                ? () async {
                    final saved = await context.push<bool>(
                      '/community/posts/${post.id}/edit',
                      extra: post,
                    );
                    if (saved == true && mounted) _load();
                  }
                : null,
          );
        },
      ),
      if (_loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }
}

/// The subject-coloured banner that collapses into a plain app bar.
class _BannerAppBar extends StatelessWidget {
  const _BannerAppBar({
    required this.subject,
    required this.title,
    required this.onShare,
  });

  final StemSubject subject;
  final String title;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final tone = subjectTone(context, subject);
    final theme = Theme.of(context);

    Widget roundButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) => Padding(
      padding: const EdgeInsets.all(6),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: palette.surface.withValues(alpha: .85),
          foregroundColor: palette.ink,
        ),
        icon: Icon(icon),
      ),
    );

    return SliverAppBar(
      pinned: true,
      expandedHeight: 132,
      backgroundColor: palette.canvas,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: roundButton(
        icon: Icons.arrow_back_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.pop(),
      ),
      actions: [
        if (onShare != null)
          roundButton(
            icon: Icons.ios_share_rounded,
            tooltip: AppLocalizations.of(context)!.communityShare,
            onPressed: onShare,
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = MediaQuery.paddingOf(context).top;
          final collapsed = constraints.maxHeight <= kToolbarHeight + top + 8;
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: tone.surface),
              CommunityBannerPattern(subject: subject, color: tone.accent),
              if (collapsed)
                ColoredBox(
                  color: palette.canvas,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 64),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RiksaTypography.titleStyleFor(
                            title,
                            theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CommunityHeader extends StatefulWidget {
  const _CommunityHeader({
    required this.community,
    required this.subject,
    required this.busy,
    required this.onToggleJoin,
  });

  final SocialCategory community;
  final StemSubject subject;
  final bool busy;
  final VoidCallback onToggleJoin;

  @override
  State<_CommunityHeader> createState() => _CommunityHeaderState();
}

class _CommunityHeaderState extends State<_CommunityHeader> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final community = widget.community;
    final locale = Localizations.localeOf(context).languageCode;
    final members = l10n.communityMemberCount(
      community.memberCount,
      NumberFormat.compact(locale: locale).format(community.memberCount),
    );
    final handle = 'c/${community.slug}';
    final description = community.description?.trim() ?? '';

    final joinButton = community.joined
        ? OutlinedButton(
            key: const ValueKey('community-detail-toggle'),
            onPressed: widget.busy ? null : widget.onToggleJoin,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              foregroundColor: palette.brand,
              side: BorderSide(color: palette.brand.withValues(alpha: .4)),
            ),
            child: Text(l10n.communityJoined),
          )
        : FilledButton(
            key: const ValueKey('community-detail-toggle'),
            onPressed: widget.busy ? null : widget.onToggleJoin,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(l10n.communityJoin),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommunityAvatar(community: community, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.titleStyleFor(
                        community.name,
                        theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      members,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        members,
                        theme.textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              joinButton,
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            AnimatedSize(
              duration: RiksaMotion.resolve(context, RiksaMotion.standard),
              alignment: Alignment.topCenter,
              child: Text(
                description,
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  description,
                  theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 2),
            InkWell(
              key: const ValueKey('community-see-more'),
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadii.fullBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _expanded ? l10n.communitySeeLess : l10n.communitySeeMore,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: palette.outline),
        ],
      ),
    );
  }
}

String _sortLabel(AppLocalizations l10n, CommunityFeedSort sort) =>
    switch (sort) {
      CommunityFeedSort.hot => l10n.communitySortHot,
      CommunityFeedSort.newest => l10n.communitySortNew,
      CommunityFeedSort.top => l10n.communitySortTop,
    };

IconData _sortIcon(CommunityFeedSort sort) => switch (sort) {
  CommunityFeedSort.hot => Icons.local_fire_department_rounded,
  CommunityFeedSort.newest => Icons.schedule_rounded,
  CommunityFeedSort.top => Icons.trending_up_rounded,
};

class _SortChip extends StatelessWidget {
  const _SortChip({required this.sort, required this.onTap});

  final CommunityFeedSort sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    return OutlinedButton.icon(
      key: const ValueKey('community-sort'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.outline),
      ),
      icon: Icon(_sortIcon(sort), size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_sortLabel(l10n, sort)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.selected});

  final CommunityFeedSort selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.communitySortBy,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final sort in CommunityFeedSort.values)
            ListTile(
              key: ValueKey('community-sort-${sort.name}'),
              leading: Icon(_sortIcon(sort)),
              title: Text(_sortLabel(l10n, sort)),
              trailing: sort == selected
                  ? Icon(Icons.check_rounded, color: palette.brand)
                  : null,
              onTap: () => Navigator.of(context).pop(sort),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
