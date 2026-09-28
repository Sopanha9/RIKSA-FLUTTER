import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/current_user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../features/auth/presentation/require_account.dart';
import '../../../features/mascot/data/buddy_api.dart';
import '../../../features/mascot/domain/mascot.dart';
import '../../../features/mascot/presentation/widgets/buddy_look.dart';
import '../../../features/mascot/providers/buddy_care_provider.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/market_models.dart';
import '../providers/market_provider.dart';
import 'market_widgets.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  BuddyItemSlot _slot = BuddyItemSlot.hat;
  final Map<BuddyItemSlot, String> _previewIds = {};
  String? _pendingItemId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(currentUserIdProvider);
    final isSignedIn = userId != null;
    final look = ref.watch(buddyLookProvider);
    final buddy = ref.watch(buddyCareProvider);
    final page = ref.watch(marketItemsProvider(_slot));
    final items =
        page.asData?.value.items.where((item) => item.owned).toList() ??
        const <MarketItem>[];
    final selected = items
        .where((item) => item.id == _previewIds[_slot])
        .firstOrNull;
    final equippedIds = {
      for (final entry in buddy.equipped.entries) entry.key: entry.value.itemId,
    };
    final preview = {
      ...look.equipped,
      if (selected != null) selected.slot: selected.assetKey,
    };

    return Scaffold(
      backgroundColor: context.riksa.canvas,
      appBar: AppBar(
        title: Text(l10n.wardrobeTitle),
        backgroundColor: context.riksa.canvas,
        leading: const Center(
          child: RiksaBackButton(fallbackLocation: '/market'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketItemsProvider(_slot));
          await ref.read(marketItemsProvider(_slot).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.riksa.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.riksa.outline),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 162,
                        child: BuddyLook(
                          species: look.species,
                          loops: 1,
                          face: MascotFace.neutral,
                          equipped: preview,
                          size: 154,
                          semanticLabel: look.name,
                        ),
                      ),
                      Text(
                        look.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SegmentedButton<BuddyItemSlot>(
                  segments: [
                    ButtonSegment(
                      value: BuddyItemSlot.hat,
                      icon: const Icon(Icons.checkroom_rounded),
                      label: Text(l10n.marketHats),
                    ),
                    ButtonSegment(
                      value: BuddyItemSlot.eyewear,
                      icon: const Icon(Icons.visibility_rounded),
                      label: Text(l10n.marketGlasses),
                    ),
                  ],
                  selected: {_slot},
                  onSelectionChanged: (selection) => setState(() {
                    _slot = selection.first;
                  }),
                  showSelectedIcon: false,
                ),
              ),
            ),
            page.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _WardrobeMessage(
                  icon: Icons.cloud_off_rounded,
                  message: l10n.marketLoadFailed,
                  action: l10n.tryAgain,
                  onPressed: () => ref.invalidate(marketItemsProvider(_slot)),
                ),
              ),
              data: (_) => items.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _WardrobeMessage(
                        icon: Icons.checkroom_outlined,
                        message: l10n.wardrobeEmpty,
                        action: l10n.marketBrowse,
                        onPressed: () => context.go('/market'),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isEquipped =
                              equippedIds[_slot] == item.id ||
                              (equippedIds[_slot] == null && item.equipped);
                          return _WardrobeItemCard(
                            item: item,
                            species: look.species,
                            selected: selected?.id == item.id,
                            isEquipped: isEquipped,
                            isWorking: _pendingItemId == item.id,
                            onSelect: () => setState(() {
                              _previewIds[_slot] = item.id;
                            }),
                            onToggle: () => _toggleEquip(
                              item,
                              isEquipped: isEquipped,
                              isSignedIn: isSignedIn,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleEquip(
    MarketItem item, {
    required bool isEquipped,
    required bool isSignedIn,
  }) async {
    if (!isSignedIn && !requireAccount(context, ref, reason: 'market_equip')) {
      return;
    }
    setState(() => _pendingItemId = item.id);
    try {
      await ref
          .read(buddyCareProvider.notifier)
          .equip(
            item.slot,
            isEquipped ? null : item.id,
            assetKey: item.assetKey,
          );
      ref.invalidate(marketItemsProvider(item.slot));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.wardrobeEquipFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingItemId = null);
    }
  }
}

class _WardrobeItemCard extends StatelessWidget {
  const _WardrobeItemCard({
    required this.item,
    required this.species,
    required this.selected,
    required this.isEquipped,
    required this.isWorking,
    required this.onSelect,
    required this.onToggle,
  });

  final MarketItem item;
  final MascotSpecies species;
  final bool selected;
  final bool isEquipped;
  final bool isWorking;
  final VoidCallback onSelect;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = marketItemName(context, item);
    return Material(
      color: context.riksa.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? context.riksa.brand : context.riksa.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: BuddyItemArtwork(item: item, species: species, size: 74),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.rarity == 'EPIC'
                          ? l10n.marketRarityEpic
                          : item.rarity == 'RARE'
                          ? l10n.marketRarityRare
                          : l10n.marketRarityCommon,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: marketRarityColor(context, item.rarity),
                      ),
                    ),
                    const SizedBox(height: 7),
                    OutlinedButton(
                      onPressed: isWorking ? null : onToggle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: isWorking
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEquipped
                                  ? l10n.wardrobeUnequip
                                  : l10n.marketEquip,
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ],
                ),
              ),
              if (isEquipped) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: context.riksa.brand),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WardrobeMessage extends StatelessWidget {
  const _WardrobeMessage({
    required this.icon,
    required this.message,
    this.action,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: context.riksa.inkMuted),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          if (action != null && onPressed != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onPressed, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
