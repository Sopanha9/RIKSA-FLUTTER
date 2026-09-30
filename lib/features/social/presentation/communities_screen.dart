import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_search_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../learning/presentation/learning_design.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'widgets/community_avatar.dart';
import 'widgets/community_banner_pattern.dart';

/// The chips that narrow the directory. [joined] is the reader's own list;
/// the rest are topics read from community names until the API carries one.
enum CommunityFilter { all, joined, science, languages, history, tech, general }

CommunityFilter communityTopicFor(SocialCategory community) {
  final value = community.name.toLowerCase();
  bool has(List<String> words) => words.any(value.contains);
  if (has(['comput', 'code', 'program', 'tech', 'កុំព្យូទ័រ', 'បច្ចេក'])) {
    return CommunityFilter.tech;
  }
  if (stemSubjectFor(community.name) != StemSubject.other) {
    return CommunityFilter.science;
  }
  if (has(['english', 'language', 'literature', 'grammar', 'ភាសា', 'អក្សរ'])) {
    return CommunityFilter.languages;
  }
  if (has(['history', 'heritage', 'culture', 'ប្រវត្តិ', 'វប្បធម៌'])) {
    return CommunityFilter.history;
  }
  return CommunityFilter.general;
}

String _filterLabel(AppLocalizations l10n, CommunityFilter filter) =>
    switch (filter) {
      CommunityFilter.all => l10n.communitiesFilterAll,
      CommunityFilter.joined => l10n.communityJoined,
      CommunityFilter.science => l10n.communitiesFilterScience,
      CommunityFilter.languages => l10n.communitiesFilterLanguages,
      CommunityFilter.history => l10n.communitiesFilterHistory,
      CommunityFilter.tech => l10n.communitiesFilterTech,
      CommunityFilter.general => l10n.communitiesFilterGeneral,
    };

/// The community directory: the reader's own communities, a featured one to
/// discover, and every community ranked by size.
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});
  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  List<SocialCategory>? _items;
  bool _failed = false;
  CommunityFilter _filter = CommunityFilter.all;
  String _query = '';
  final _pending = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final value = await ref.read(socialApiProvider).categories();
      if (mounted) setState(() => _items = value);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle(SocialCategory item) async {
    if (_pending.contains(item.id)) return;
    setState(() => _pending.add(item.id));
    try {
      final updated = await ref
          .read(socialApiProvider)
          .setCategoryJoined(item.id, joined: !item.joined);
      // Only a feed that is already loaded needs to hear about it.
      if (ref.exists(socialFeedProvider)) {
        ref.read(socialFeedProvider.notifier).syncCategory(updated);
      }
      if (!mounted) return;
      setState(() {
        final index = _items!.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) _items![index] = updated;
      });
    } catch (_) {
      _showMessage(AppLocalizations.of(context)!.actionFailed);
    } finally {
      if (mounted) setState(() => _pending.remove(item.id));
    }
  }

  Future<void> _open(SocialCategory item) async {
    await context.push('/communities/${item.id}', extra: item);
    if (mounted) _load();
  }

  Future<void> _create() async {
    final created = await context.push<SocialCategory>('/communities/create');
    if (!mounted || created == null) return;
    _load();
    _showMessage(AppLocalizations.of(context)!.createCommunityCreated);
    await _open(created);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        leading: Center(
          child: RiksaBackButton(
            fallbackLocation: '/home',
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.menuCommunities,
          style: RiksaTypography.titleStyleFor(
            l10n.menuCommunities,
            theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filled(
              key: const ValueKey('communities-create'),
              onPressed: _create,
              tooltip: l10n.communitiesCreate,
              style: IconButton.styleFrom(
                backgroundColor: palette.brand,
                foregroundColor: palette.onBrand,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: RiksaSearchBar(
              key: const ValueKey('communities-search'),
              hintText: l10n.communitiesSearchHint,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _items;
    if (items == null) {
      return Center(
        child: _failed
            ? IllustratedEmptyState(
                title: l10n.communitiesUnavailable,
                body: l10n.communitiesLoadFailed,
                actionLabel: l10n.tryAgain,
                onAction: _load,
              )
            : const CircularProgressIndicator(),
      );
    }

    final bySize = [...items]
      ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    final joined = bySize.where((item) => item.joined).toList();

    Widget row(SocialCategory item) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: _CommunityRow(
        item: item,
        busy: _pending.contains(item.id),
        onToggle: () => _toggle(item),
        onOpen: () => _open(item),
      ),
    );

    final List<Widget> slivers;
    if (_query.isNotEmpty) {
      final results = bySize
          .where(
            (item) =>
                item.name.toLowerCase().contains(_query) ||
                (item.description ?? '').toLowerCase().contains(_query),
          )
          .toList();
      slivers = [
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (results.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: IllustratedEmptyState(
              title: l10n.noSearchResults,
              body: l10n.communitiesSearchHint,
            ),
          )
        else
          SliverList.builder(
            itemCount: results.length,
            itemBuilder: (_, index) => row(results[index]),
          ),
      ];
    } else {
      // Topics that no community belongs to would only lead to empty lists.
      final topics = {for (final item in items) communityTopicFor(item)};
      final filters = [
        CommunityFilter.all,
        if (joined.isNotEmpty) CommunityFilter.joined,
        for (final filter in CommunityFilter.values.skip(2))
          if (topics.contains(filter)) filter,
      ];
      if (!filters.contains(_filter)) _filter = CommunityFilter.all;

      final showAll = _filter == CommunityFilter.all;
      // Feature the biggest community the reader has not joined yet.
      final featured = showAll && items.isNotEmpty
          ? bySize.where((item) => !item.joined).firstOrNull ?? bySize.first
          : null;
      final listed = bySize.where((item) {
        if (item.id == featured?.id) return false;
        return switch (_filter) {
          CommunityFilter.all => true,
          CommunityFilter.joined => item.joined,
          _ => communityTopicFor(item) == _filter,
        };
      }).toList();

      slivers = [
        if (joined.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: l10n.communitiesYours,
              actionLabel: l10n.communitiesSeeAll,
              onAction: () => setState(() => _filter = CommunityFilter.joined),
            ),
          ),
          SliverToBoxAdapter(
            child: _JoinedStrip(communities: joined, onOpen: _open),
          ),
        ],
        SliverToBoxAdapter(
          child: _FilterChips(
            filters: filters,
            selected: _filter,
            onSelected: (value) => setState(() => _filter = value),
          ),
        ),
        if (featured != null) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(title: l10n.communitiesFeatured),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeaturedCard(
                community: featured,
                busy: _pending.contains(featured.id),
                onToggle: () => _toggle(featured),
                onOpen: () => _open(featured),
              ),
            ),
          ),
        ],
        if (listed.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: showAll
                  ? l10n.popularCommunities
                  : _filterLabel(l10n, _filter),
            ),
          ),
          SliverList.builder(
            itemCount: listed.length,
            itemBuilder: (_, index) => row(listed[index]),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: _CreateCommunityCard(onCreate: _create),
          ),
        ),
      ];
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        key: const ValueKey('communities-list'),
        slivers: slivers,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: RiksaTypography.titleStyleFor(
                title,
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: palette.brand,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// The reader's communities as a row of round icons.
class _JoinedStrip extends StatelessWidget {
  const _JoinedStrip({required this.communities, required this.onOpen});

  final List<SocialCategory> communities;
  final ValueChanged<SocialCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 124,
      child: ListView.separated(
        key: const ValueKey('communities-joined-strip'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: communities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final item = communities[index];
          return InkWell(
            key: ValueKey('communities-joined-${item.id}'),
            onTap: () => onOpen(item),
            borderRadius: AppRadii.largeBorder,
            child: SizedBox(
              width: 88,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  ClipOval(child: CommunityAvatar(community: item, size: 68)),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: RiksaTypography.bodyStyleFor(
                      item.name,
                      theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<CommunityFilter> filters;
  final CommunityFilter selected;
  final ValueChanged<CommunityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final active = filter == selected;
          final label = _filterLabel(l10n, filter);
          return Semantics(
            button: true,
            selected: active,
            child: InkWell(
              key: ValueKey('communities-filter-${filter.name}'),
              onTap: () => onSelected(filter),
              borderRadius: AppRadii.fullBorder,
              child: AnimatedContainer(
                duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? palette.brand : palette.surface,
                  borderRadius: AppRadii.fullBorder,
                  border: Border.all(
                    color: active ? palette.brand : palette.outline,
                  ),
                ),
                child: Text(
                  label,
                  style: RiksaTypography.bodyStyleFor(
                    label,
                    theme.textTheme.labelLarge?.copyWith(
                      color: active ? palette.onBrand : palette.inkMuted,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _memberLabel(BuildContext context, SocialCategory item) {
  final locale = Localizations.localeOf(context).languageCode;
  return AppLocalizations.of(context)!.communityMemberCount(
    item.memberCount,
    NumberFormat.compact(locale: locale).format(item.memberCount),
  );
}

class _MemberLine extends StatelessWidget {
  const _MemberLine({required this.community});

  final SocialCategory community;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final members = _memberLabel(context, community);
    return Row(
      children: [
        Icon(Icons.people_outline_rounded, size: 16, color: palette.inkMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            members,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RiksaTypography.bodyStyleFor(
              members,
              Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.inkMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.community,
    required this.busy,
    required this.onToggle,
  });

  final SocialCategory community;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final key = ValueKey('community-toggle-${community.id}');
    const size = Size(88, 40);
    return community.joined
        ? OutlinedButton(
            key: key,
            onPressed: busy ? null : onToggle,
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              foregroundColor: palette.brand,
              backgroundColor: palette.brandSoft.withValues(alpha: .4),
              side: BorderSide(color: palette.brand.withValues(alpha: .5)),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.communityJoined),
          )
        : FilledButton(
            key: key,
            onPressed: busy ? null : onToggle,
            style: FilledButton.styleFrom(
              minimumSize: size,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.communityJoin),
          );
  }
}

/// A wide card with a banner that puts one community in front of the reader.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.community,
    required this.busy,
    required this.onToggle,
    required this.onOpen,
  });

  final SocialCategory community;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final subject = stemSubjectFor(community.name);
    final tone = subjectTone(context, subject);
    final description = community.description?.trim() ?? '';
    const bannerHeight = 128.0;
    const avatarSize = 68.0;

    return Material(
      key: ValueKey('communities-featured-${community.id}'),
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.largeBorder,
        side: BorderSide(color: palette.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: bannerHeight + 40,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: bannerHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: tone.surface),
                        CommunityBannerPattern(
                          subject: subject,
                          color: tone.accent,
                        ),
                      ],
                    ),
                  ),
                  // The icon sits on the banner's lower edge.
                  Positioned(
                    left: 16,
                    top: bannerHeight - avatarSize / 2 - 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: CommunityAvatar(
                        community: community,
                        size: avatarSize,
                      ),
                    ),
                  ),
                  Positioned(
                    left: avatarSize + 32,
                    right: 16,
                    top: bannerHeight + 8,
                    child: Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.titleStyleFor(
                        community.name,
                        theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description.isNotEmpty) ...[
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: RiksaTypography.bodyStyleFor(
                              description,
                              theme.textTheme.bodyMedium?.copyWith(
                                color: palette.inkMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        _MemberLine(community: community),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _JoinButton(
                    community: community,
                    busy: busy,
                    onToggle: onToggle,
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

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({
    required this.item,
    required this.busy,
    required this.onToggle,
    required this.onOpen,
  });

  final SocialCategory item;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final description = item.description?.trim() ?? '';

    return Material(
      key: ValueKey('community-${item.id}'),
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.largeBorder,
        side: BorderSide(color: palette.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CommunityAvatar(community: item, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RiksaTypography.bodyStyleFor(
                        item.name,
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: RiksaTypography.bodyStyleFor(
                          description,
                          theme.textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    _MemberLine(community: item),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _JoinButton(community: item, busy: busy, onToggle: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCommunityCard extends StatelessWidget {
  const _CreateCommunityCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final prompt = l10n.communitiesCantFind;
    return CustomPaint(
      painter: _DashedBorderPainter(color: palette.outline, radius: 20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                prompt,
                style: RiksaTypography.titleStyleFor(
                  prompt,
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: const ValueKey('communities-create-card'),
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: Text(l10n.communitiesCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(.75),
      );
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 10) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
