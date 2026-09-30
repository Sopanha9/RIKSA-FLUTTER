import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../learning/presentation/learning_design.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'manage_community_screen.dart' show CommunityRoleBadge;
import 'widgets/community_avatar.dart';
import 'widgets/community_banner_art.dart';
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
  SocialPost? _pinned;
  String? _endCursor;
  bool _hasNextPage = false;
  bool _loadingMore = false;
  bool _failed = false;
  String? _failure;
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
        api.community(widget.communityId),
        api.feed(categoryId: widget.communityId),
      ]);
      if (!mounted) return;
      final community = results.first as SocialCategory?;
      final page = results.last as SocialFeedPage;
      final pinnedId = community?.pinnedPostId;
      SocialPost? pinned;
      if (pinnedId != null) {
        pinned = page.posts.where((post) => post.id == pinnedId).firstOrNull;
        try {
          pinned ??= await api.post(pinnedId);
        } catch (_) {
          // A pinned post that no longer loads just isn't shown.
        }
        if (!mounted) return;
      }
      setState(() {
        _community = community ?? _community;
        _pinned = pinned;
        _posts = page.posts;
        _endCursor = page.endCursor;
        _hasNextPage = page.hasNextPage;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _failure = error is SocialApiException ? error.message : null;
        });
      }
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
      // The join mutation returns the bare category; keep rules and settings.
      if (mounted) {
        setState(
          () => _community = SocialCategory(
            id: updated.id,
            name: updated.name,
            slug: updated.slug,
            description: updated.description,
            iconUrl: updated.iconUrl,
            memberCount: updated.memberCount,
            joined: updated.joined,
            myRole: updated.joined ? CommunityRole.member : null,
            postPermission: community.postPermission,
            pinnedPostId: community.pinnedPostId,
            rules: community.rules,
            bannerUrl: community.bannerUrl,
            bannerColor: community.bannerColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) _showFailure(error);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _replacePost(SocialPost post) {
    final posts = _posts;
    if (posts == null) return;
    setState(() {
      _posts = [for (final item in posts) item.id == post.id ? post : item];
      if (_pinned?.id == post.id) _pinned = post;
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

  void _showFailure([Object? error]) {
    final message = error is SocialApiException
        ? error.message
        : AppLocalizations.of(context)!.actionFailed;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openManage(SocialCategory community, String? tab) async {
    await context.push(
      '/communities/${community.id}/manage${tab == null ? '' : '?tab=$tab'}',
      extra: community,
    );
    if (mounted) _load();
  }

  Future<bool> _confirm(String title, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('community-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _postAction(SocialPost post, _PostAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final api = ref.read(socialApiProvider);
    final community = _community;
    if (community == null) return;
    try {
      switch (action) {
        case _PostAction.edit:
          final saved = await context.push<bool>(
            '/community/posts/${post.id}/edit',
            extra: post,
          );
          if (saved == true && mounted) _load();
          return;
        case _PostAction.pin || _PostAction.unpin:
          final updated = await api.pinCommunityPost(
            community.id,
            action == _PostAction.pin ? post.id : null,
          );
          if (!mounted) return;
          setState(() {
            _community = updated;
            _pinned = action == _PostAction.pin ? post : null;
          });
          return;
        case _PostAction.delete:
          if (!await _confirm(l10n.communityRemovePostConfirm, l10n.delete)) {
            return;
          }
          await api.deletePost(post.id);
        case _PostAction.removeAuthor || _PostAction.banAuthor:
          final name = post.author.displayName.trim().isEmpty
              ? post.author.username
              : post.author.displayName;
          final ban = action == _PostAction.banAuthor;
          if (!await _confirm(
            ban
                ? l10n.communityBanConfirm(name)
                : l10n.communityRemoveConfirm(name),
            ban ? l10n.communityBan : l10n.communityRemove,
          )) {
            return;
          }
          await api.removeCommunityMember(
            community.id,
            post.author.id,
            ban: ban,
          );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.communitySaved)));
      _load();
    } catch (error) {
      if (mounted) _showFailure(error);
    }
  }

  Widget? _postMenu(SocialPost post, String? currentUserId) {
    final community = _community;
    if (community == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final mine = post.author.id == currentUserId;
    final userPost = post.kind == SocialPostKind.user;
    final moderate = community.canModerate;
    if (!moderate && !(mine && userPost)) return null;
    final pinned = community.pinnedPostId == post.id;
    final error = Theme.of(context).colorScheme.error;

    PopupMenuItem<_PostAction> item(
      _PostAction value,
      IconData icon,
      String label, {
      bool danger = false,
    }) => PopupMenuItem(
      value: value,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 20, color: danger ? error : null),
        title: Text(label, style: danger ? TextStyle(color: error) : null),
      ),
    );

    return PopupMenuButton<_PostAction>(
      key: ValueKey('post-options-${post.id}'),
      tooltip: l10n.postOptions,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: context.riksa.inkMuted,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
      ),
      onSelected: (action) => _postAction(post, action),
      itemBuilder: (context) => [
        if (mine && userPost)
          item(_PostAction.edit, Icons.edit_outlined, l10n.editPost),
        if (moderate)
          pinned
              ? item(
                  _PostAction.unpin,
                  Icons.push_pin_outlined,
                  l10n.communityUnpinPost,
                )
              : item(
                  _PostAction.pin,
                  Icons.push_pin_rounded,
                  l10n.communityPinPost,
                ),
        if (userPost && (mine || moderate))
          item(
            _PostAction.delete,
            Icons.delete_outline_rounded,
            mine ? l10n.deletePost : l10n.communityRemovePost,
            danger: true,
          ),
        if (moderate && !mine) ...[
          item(
            _PostAction.removeAuthor,
            Icons.person_remove_outlined,
            l10n.communityRemoveMember,
            danger: true,
          ),
          item(
            _PostAction.banAuthor,
            Icons.block_rounded,
            l10n.communityBanMember,
            danger: true,
          ),
        ],
      ],
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
      floatingActionButton: community == null || !community.canPost
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
                community: community,
                subject: subject,
                title: community?.name ?? '',
                onShare: community == null
                    ? null
                    : () => _copyLink(
                        'https://riksa.app/communities/${community.id}',
                        l10n.communityLinkCopied,
                      ),
                onManage: community == null || !community.canModerate
                    ? null
                    : () => _openManage(community, null),
              ),
              if (community != null)
                SliverToBoxAdapter(
                  child: _CommunityHeader(
                    community: community,
                    subject: subject,
                    busy: _joining,
                    onToggleJoin: _toggleJoin,
                    hasPinned: _pinned != null,
                    onManage: (tab) => _openManage(community, tab),
                    onInvite: () => _copyLink(
                      'https://riksa.app/communities/${community.id}',
                      l10n.communityLinkCopied,
                    ),
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
                    body: _failure ?? l10n.communitiesLoadFailed,
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
      final community = _community!;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: community.canPost
              ? IllustratedEmptyState(
                  title: l10n.communityStartTitle,
                  body: community.isOwner
                      ? l10n.communityStartOwnerBody
                      : l10n.communityNoPostsBody,
                  actionLabel: l10n.communityCreatePost,
                  onAction: () async {
                    await context.push(
                      '/community/create?community=${community.id}',
                    );
                    if (mounted) _load();
                  },
                )
              : IllustratedEmptyState(
                  title: l10n.communityNoPostsTitle,
                  body: l10n.communityNoPostsBody,
                ),
        ),
      ];
    }
    final currentUserId = ref.watch(currentUserIdProvider);
    final pinned = _pinned;
    final sorted = _sorted([
      for (final post in posts)
        if (post.id != pinned?.id) post,
    ]);
    final items = [?pinned, ...sorted];
    return [
      SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final post = items[index];
          final card = SocialPostCard(
            key: ValueKey('community-post-${post.id}'),
            post: post,
            onTap: () async {
              await context.push('/community/posts/${post.id}');
              if (mounted) _load();
            },
            onAuthorTap: publicProfilePath(post.author.id) == null
                ? null
                : () => openUserProfile(context, post.author.id),
            onReact: () => _react(post),
            onShare: () => _share(post),
            menu: _postMenu(post, currentUserId),
          );
          if (post.id != pinned?.id) return card;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                key: const ValueKey('community-pinned-label'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.push_pin_rounded,
                      size: 14,
                      color: context.riksa.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.communityPinned,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.riksa.brand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              card,
            ],
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
    required this.community,
    required this.subject,
    required this.title,
    required this.onShare,
    this.onManage,
  });

  final SocialCategory? community;
  final StemSubject subject;
  final String title;
  final VoidCallback? onShare;
  final VoidCallback? onManage;

  static const _iconSize = 88.0;
  static const _iconOverhang = 44.0;

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
      expandedHeight: 150 + _iconOverhang,
      backgroundColor: palette.canvas,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: roundButton(
        icon: Icons.arrow_back_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => RiksaBackButton.navigateBack(
          context,
          fallbackLocation: '/communities',
        ),
      ),
      actions: [
        if (onManage != null)
          KeyedSubtree(
            key: const ValueKey('community-manage'),
            child: roundButton(
              icon: Icons.admin_panel_settings_outlined,
              tooltip: AppLocalizations.of(context)!.communityManage,
              onPressed: onManage,
            ),
          ),
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
          final community = this.community;
          // 1 when fully open, 0 by the time the bar has collapsed.
          final shown =
              ((constraints.maxHeight - kToolbarHeight - top) /
                      (150 + _iconOverhang - kToolbarHeight - top))
                  .clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: palette.canvas),
              Positioned.fill(
                bottom: _iconOverhang,
                child: CommunityBannerArt(
                  subject: subject,
                  bannerUrl: community?.bannerUrl,
                  bannerColor: community?.bannerColor,
                ),
              ),
              if (community != null)
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Opacity(
                    opacity: Curves.easeIn.transform(shown),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: palette.canvas,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: tone.accent.withValues(alpha: .3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CommunityAvatar(
                        community: community,
                        size: _iconSize - 8,
                      ),
                    ),
                  ),
                ),
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
    required this.hasPinned,
    required this.onManage,
    required this.onInvite,
  });

  final SocialCategory community;
  final StemSubject subject;
  final bool busy;
  final VoidCallback onToggleJoin;
  final bool hasPinned;

  /// Opens the manage screen on a tab: settings, rules, members or banned.
  final ValueChanged<String> onManage;
  final VoidCallback onInvite;

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
    final description = community.description?.trim() ?? '';

    final joinButton = community.isOwner
        ? const SizedBox.shrink()
        : community.joined
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'c/${community.slug}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (community.canModerate) ...[
                          const SizedBox(width: 8),
                          CommunityRoleBadge(role: community.myRole!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              joinButton,
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(icon: Icons.groups_rounded, label: members),
              if (community.rules.isNotEmpty)
                _StatChip(
                  icon: Icons.gavel_rounded,
                  label: l10n.communityStatRules(community.rules.length),
                ),
              if (community.postPermission ==
                  CommunityPostPermission.moderators)
                _StatChip(
                  icon: Icons.campaign_rounded,
                  label: l10n.communityPostModsOnly,
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            AnimatedSize(
              duration: RiksaMotion.resolve(context, RiksaMotion.standard),
              alignment: Alignment.topCenter,
              child: Text(
                description,
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: RiksaTypography.bodyStyleFor(
                  description,
                  theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (description.length > 120)
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
          if (community.joined && !community.canPost) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 16,
                  color: palette.inkMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.communityModsOnlyNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (community.isOwner)
            _SetupChecklist(
              community: community,
              hasPinned: widget.hasPinned,
              onManage: widget.onManage,
              onInvite: widget.onInvite,
            ),
          if (community.canModerate)
            _ModTools(community: community, onManage: widget.onManage),
          if (community.rules.isNotEmpty) ...[
            const SizedBox(height: 12),
            _RulesCard(rules: community.rules),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: palette.outline),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.fullBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: palette.brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: RiksaTypography.bodyStyleFor(
              label,
              Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big, colourful shortcuts into the manage screen for the owner and mods.
class _ModTools extends StatelessWidget {
  const _ModTools({required this.community, required this.onManage});

  final SocialCategory community;
  final ValueChanged<String> onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final tiles = [
      if (community.isOwner)
        (
          'settings',
          Icons.tune_rounded,
          l10n.communityTabSettings,
          const Color(0xFF7C5CFF),
        ),
      if (community.isOwner)
        (
          'rules',
          Icons.gavel_rounded,
          l10n.communityTabRules,
          const Color(0xFFFF8A3D),
        ),
      (
        'members',
        Icons.groups_rounded,
        l10n.communityTabMembers,
        const Color(0xFF14B8A6),
      ),
      (
        'banned',
        Icons.block_rounded,
        l10n.communityTabBanned,
        const Color(0xFFF43F5E),
      ),
    ];

    return Container(
      key: const ValueKey('community-mod-tools'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: AppRadii.mediumBorder,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.brand.withValues(alpha: .14),
            palette.brand.withValues(alpha: .04),
          ],
        ),
        border: Border.all(color: palette.brand.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 18, color: palette.brand),
              const SizedBox(width: 6),
              Text(
                l10n.communityModTools,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (index, (tab, icon, label, color))
                  in tiles.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: palette.surface,
                    borderRadius: AppRadii.mediumBorder,
                    child: InkWell(
                      key: ValueKey('community-tool-$tab'),
                      borderRadius: AppRadii.mediumBorder,
                      onTap: () => onManage(tab),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 20, color: color),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// First steps for a new owner; disappears once everything is done.
class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist({
    required this.community,
    required this.hasPinned,
    required this.onManage,
    required this.onInvite,
  });

  final SocialCategory community;
  final bool hasPinned;
  final ValueChanged<String> onManage;
  final VoidCallback onInvite;

  static const _memberGoal = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final steps = [
      (
        (community.description ?? '').trim().isNotEmpty,
        l10n.communitySetupDescription,
        () => onManage('settings'),
      ),
      (
        community.rules.isNotEmpty,
        l10n.communitySetupRules,
        () => onManage('rules'),
      ),
      (hasPinned, l10n.communitySetupPin, null),
      (
        community.memberCount >= _memberGoal,
        l10n.communitySetupMembers(_memberGoal),
        onInvite,
      ),
    ];
    final done = steps.where((step) => step.$1).length;
    if (done == steps.length) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('community-setup'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, size: 18, color: palette.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.communitySetupTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                l10n.communitySetupProgress(done, steps.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadii.fullBorder,
            child: LinearProgressIndicator(
              value: done / steps.length,
              minHeight: 6,
              backgroundColor: palette.brand.withValues(alpha: .12),
              color: palette.brand,
            ),
          ),
          const SizedBox(height: 4),
          for (final (complete, label, onTap) in steps)
            InkWell(
              onTap: complete ? null : onTap,
              borderRadius: AppRadii.mediumBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      complete
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: complete
                          ? const Color(0xFF22C55E)
                          : palette.inkMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: RiksaTypography.bodyStyleFor(
                          label,
                          theme.textTheme.bodyMedium?.copyWith(
                            color: complete ? palette.inkMuted : palette.ink,
                            decoration: complete
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
                    if (!complete && onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: palette.inkMuted,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _PostAction { edit, pin, unpin, delete, removeAuthor, banAuthor }

/// The community's rules, folded to one line until opened.
class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.rules});

  final List<CommunityRule> rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.mediumBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('community-rules'),
          shape: const RoundedRectangleBorder(),
          leading: Icon(Icons.gavel_rounded, color: palette.brand),
          title: Text(
            l10n.communityRules,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text('${rules.length}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (final (index, rule) in rules.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${index + 1}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.brand,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.title,
                            style: RiksaTypography.bodyStyleFor(
                              rule.title,
                              theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if ((rule.body ?? '').isNotEmpty)
                            Text(
                              rule.body!,
                              style: RiksaTypography.bodyStyleFor(
                                rule.body!,
                                theme.textTheme.bodySmall?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
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
