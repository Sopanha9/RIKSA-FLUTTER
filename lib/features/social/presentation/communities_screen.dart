import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_components.dart';
import '../../../core/widgets/riksa_search_bar.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../learning/presentation/learning_design.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';

/// Learning groups to discover and join, and the ones already joined.
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});
  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  List<SocialCategory>? _items;
  bool _failed = false;
  bool _mineOnly = false;
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
      if (!mounted) return;
      setState(() {
        final index = _items!.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) _items![index] = updated;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.actionFailed)),
          );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final items = (_items ?? const <SocialCategory>[])
        .where((item) => !_mineOnly || item.joined)
        .where(
          (item) =>
              _query.isEmpty ||
              item.name.toLowerCase().contains(_query) ||
              (item.description ?? '').toLowerCase().contains(_query),
        )
        .toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        leading: IconButton(
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.menuCommunities,
          style: RiksaTypography.titleStyleFor(
            l10n.menuCommunities,
            theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _CommunityTabs(
              mineOnly: _mineOnly,
              onChanged: (value) => setState(() => _mineOnly = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: RiksaSearchBar(
              key: const ValueKey('communities-search'),
              hintText: l10n.communitiesSearchHint,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: _items == null
                ? Center(
                    child: _failed
                        ? IllustratedEmptyState(
                            title: l10n.communitiesUnavailable,
                            body: l10n.communitiesLoadFailed,
                            actionLabel: l10n.tryAgain,
                            onAction: _load,
                          )
                        : const CircularProgressIndicator(),
                  )
                : items.isEmpty
                ? IllustratedEmptyState(
                    title: _mineOnly
                        ? l10n.communitiesMine
                        : l10n.noSearchResults,
                    body: _mineOnly
                        ? l10n.communitiesNoneJoined
                        : l10n.communitiesSearchHint,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CommunityRow(
                        item: items[index],
                        busy: _pending.contains(items[index].id),
                        onToggle: () => _toggle(items[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTabs extends StatelessWidget {
  const _CommunityTabs({required this.mineOnly, required this.onChanged});

  final bool mineOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    Widget tab(String label, bool selected, VoidCallback onTap, String key) =>
        Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            child: InkWell(
              key: ValueKey(key),
              onTap: onTap,
              borderRadius: AppRadii.fullBorder,
              child: AnimatedContainer(
                duration: RiksaMotion.resolve(context, RiksaMotion.standard),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? palette.brandSoft : Colors.transparent,
                  borderRadius: AppRadii.fullBorder,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiksaTypography.bodyStyleFor(
                    label,
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? palette.brand : palette.inkMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.fullBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          tab(
            l10n.communitiesDiscover,
            !mineOnly,
            () => onChanged(false),
            'communities-discover-tab',
          ),
          tab(
            l10n.communitiesMine,
            mineOnly,
            () => onChanged(true),
            'communities-mine-tab',
          ),
        ],
      ),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({
    required this.item,
    required this.busy,
    required this.onToggle,
  });

  final SocialCategory item;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final locale = Localizations.localeOf(context).languageCode;
    final stem = stemSubjectFor(item.name);
    final members = l10n.communityMembers(
      NumberFormat.compact(locale: locale).format(item.memberCount),
    );

    return Container(
      key: ValueKey('community-${item.id}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.largeBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          StemSubjectTile(subject: stem, size: 48),
          const SizedBox(width: 12),
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
                    theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
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
          const SizedBox(width: 8),
          item.joined
              ? OutlinedButton(
                  key: ValueKey('community-toggle-${item.id}'),
                  onPressed: busy ? null : onToggle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    foregroundColor: palette.brand,
                    side: BorderSide(
                      color: palette.brand.withValues(alpha: .4),
                    ),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: Text(l10n.communityJoined),
                )
              : FilledButton(
                  key: ValueKey('community-toggle-${item.id}'),
                  onPressed: busy ? null : onToggle,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: Text(l10n.communityJoin),
                ),
        ],
      ),
    );
  }
}
