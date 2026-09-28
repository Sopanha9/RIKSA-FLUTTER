import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  BuddyItemSlot _slot = BuddyItemSlot.hat;
  final Map<BuddyItemSlot, String> _tryOnIds = {};
  int? _balanceAfterPurchase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSignedIn = ref.watch(currentUserIdProvider) != null;
    final look = ref.watch(buddyLookProvider);
    final buddy = ref.watch(buddyCareProvider);
    final page = ref.watch(marketItemsProvider(_slot));
    final language = Localizations.localeOf(context).languageCode;
    final items = page.asData?.value.items ?? const <MarketItem>[];
    final selected = _selectedItem(items);
    final balance = _balanceAfterPurchase ?? page.asData?.value.balance;
    final decimal = NumberFormat.decimalPattern(language);

    return Scaffold(
      backgroundColor: context.riksa.canvas,
      appBar: AppBar(
        title: Text(l10n.marketTitle),
        backgroundColor: context.riksa.canvas,
        leading: const Center(
          child: RiksaBackButton(fallbackLocation: '/learn'),
        ),
        actions: [
          IconButton(
            tooltip: l10n.wardrobeTitle,
            onPressed: () => _openWardrobe(isSignedIn),
            icon: const Icon(Icons.checkroom_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketItemsProvider(_slot));
          await ref.read(marketItemsProvider(_slot).future);
        },
        child: CustomScrollView(
          key: const PageStorageKey('market-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _MarketPreview(
                  species: look.species,
                  name: look.name,
                  equipped: _previewEquipped(look.equipped, selected),
                  itemRarity: selected?.rarity,
                  raritySlot: selected?.slot,
                  balance: isSignedIn && balance != null
                      ? decimal.format(balance)
                      : null,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.marketRankNote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.riksa.inkMuted,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _MarketSlotTabs(
                  selected: _slot,
                  onSelected: (slot) => setState(() {
                    _slot = slot;
                    _balanceAfterPurchase = null;
                  }),
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
                child: _MarketStateMessage(
                  icon: Icons.cloud_off_rounded,
                  message: l10n.marketLoadFailed,
                  actionLabel: l10n.tryAgain,
                  onAction: () => ref.invalidate(marketItemsProvider(_slot)),
                ),
              ),
              data: (data) => data.items.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MarketStateMessage(
                        icon: Icons.storefront_outlined,
                        message: l10n.marketEmpty,
                      ),
                    )
                  : _MarketItemGrid(
                      items: data.items,
                      species: look.species,
                      selectedId: selected?.id,
                      balance: balance ?? data.balance,
                      isSignedIn: isSignedIn,
                      onSelect: (item) => setState(() {
                        _tryOnIds[item.slot] = item.id;
                      }),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _MarketActionBar(
          item: selected,
          isEquipped:
              selected != null &&
              (buddy.equipped[selected.slot]?.itemId == selected.id ||
                  (buddy.equipped[selected.slot] == null && selected.equipped)),
          balance: balance,
          isSignedIn: isSignedIn,
          onBuy: selected == null
              ? null
              : () {
                  if (!isSignedIn &&
                      !requireAccount(
                        context,
                        ref,
                        reason: 'market_purchase',
                      )) {
                    return;
                  }
                  _buy(selected, balance ?? 0);
                },
          onEquip: selected == null ? null : () => _equip(selected, isSignedIn),
        ),
      ),
    );
  }

  MarketItem? _selectedItem(List<MarketItem> items) {
    final selectedId = _tryOnIds[_slot];
    if (selectedId == null) return null;
    for (final item in items) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  Map<BuddyItemSlot, String> _previewEquipped(
    Map<BuddyItemSlot, String> current,
    MarketItem? selected,
  ) => {...current, if (selected != null) selected.slot: selected.assetKey};

  void _openWardrobe(bool isSignedIn) {
    if (!isSignedIn &&
        !requireAccount(context, ref, reason: 'market_wardrobe')) {
      return;
    }
    context.push('/market/wardrobe');
  }

  Future<void> _equip(MarketItem item, bool isSignedIn) async {
    if (!isSignedIn && !requireAccount(context, ref, reason: 'market_equip')) {
      return;
    }
    final buddyItem = ref.read(buddyCareProvider).equipped[item.slot];
    final alreadyEquipped =
        buddyItem?.itemId == item.id || (buddyItem == null && item.equipped);
    try {
      await ref
          .read(buddyCareProvider.notifier)
          .equip(
            item.slot,
            alreadyEquipped ? null : item.id,
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
    }
  }

  Future<void> _buy(MarketItem item, int balance) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(marketPurchaseProvider);
    final idempotencyKey = service.beginPurchaseAttempt(item);
    final receipt = await showModalBottomSheet<MarketPurchaseReceipt>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _PurchaseConfirmationSheet(
        item: item,
        balance: balance,
        idempotencyKey: idempotencyKey,
        onPurchase: (key) => service.purchase(item, idempotencyKey: key),
      ),
    );
    if (receipt == null || !mounted) return;
    setState(() => _balanceAfterPurchase = receipt.balance);
    unawaited(HapticFeedback.lightImpact().catchError((_) {}));
    final wearNow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _PurchaseCelebrationDialog(
        item: item,
        species: ref.read(buddyLookProvider).species,
      ),
    );
    if (wearNow == true && mounted) {
      try {
        await ref
            .read(buddyCareProvider.notifier)
            .equip(item.slot, item.id, assetKey: item.assetKey);
        ref.invalidate(marketItemsProvider(item.slot));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.wardrobeEquipFailed)));
        }
      }
    }
  }
}

class _MarketPreview extends StatelessWidget {
  const _MarketPreview({
    required this.species,
    required this.name,
    required this.equipped,
    required this.itemRarity,
    required this.raritySlot,
    required this.balance,
  });

  final MascotSpecies species;
  final String name;
  final Map<BuddyItemSlot, String> equipped;
  final String? itemRarity;
  final BuddyItemSlot? raritySlot;
  final String? balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: context.riksa.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.riksa.outline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (balance != null)
                // Flexible so the chip wraps instead of overflowing at large
                // Khmer text scales.
                Flexible(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.riksa.saffronSoft,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: context.riksa.saffron,
                          ),
                          const SizedBox(width: 4),
                          Flexible(child: Text(l10n.marketBalance(balance!))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 172,
            child: BuddyLook(
              species: species,
              loops: 1,
              face: MascotFace.neutral,
              equipped: equipped,
              rarity: {
                if (raritySlot != null && itemRarity != null)
                  raritySlot!: itemRarity!,
              },
              size: 164,
              semanticLabel: name,
            ),
          ),
          Text(name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(
            l10n.marketPreviewHint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.riksa.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _MarketSlotTabs extends StatelessWidget {
  const _MarketSlotTabs({required this.selected, required this.onSelected});

  final BuddyItemSlot selected;
  final ValueChanged<BuddyItemSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<BuddyItemSlot>(
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
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.first),
      showSelectedIcon: false,
    );
  }
}

class _MarketItemGrid extends StatelessWidget {
  const _MarketItemGrid({
    required this.items,
    required this.species,
    required this.selectedId,
    required this.balance,
    required this.isSignedIn,
    required this.onSelect,
  });

  final List<MarketItem> items;
  final MascotSpecies species;
  final String? selectedId;
  final int balance;
  final bool isSignedIn;
  final ValueChanged<MarketItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (var index = 0; index < items.length; index += 2)
        items.skip(index).take(2).toList(growable: false),
    ];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: rows.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final row = rows[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < 2; column++) ...[
                if (column > 0) const SizedBox(width: 12),
                Expanded(
                  child: column < row.length
                      ? _MarketItemCard(
                          item: row[column],
                          species: species,
                          selected: row[column].id == selectedId,
                          balance: balance,
                          isSignedIn: isSignedIn,
                          onTap: () => onSelect(row[column]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MarketItemCard extends StatelessWidget {
  const _MarketItemCard({
    required this.item,
    required this.species,
    required this.selected,
    required this.balance,
    required this.isSignedIn,
    required this.onTap,
  });

  final MarketItem item;
  final MascotSpecies species;
  final bool selected;
  final int balance;
  final bool isSignedIn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final rarityColor = marketRarityColor(context, item.rarity);
    final until = marketAvailabilityLabel(item.availableUntil);
    final rarityLabel = switch (item.rarity.toUpperCase()) {
      'RARE' => l10n.marketRarityRare,
      'EPIC' => l10n.marketRarityEpic,
      _ => l10n.marketRarityCommon,
    };
    final need = math.max(0, item.price - balance).toInt();
    return Semantics(
      button: true,
      selected: selected,
      label: '${marketItemName(context, item)}, $rarityLabel, ${item.price} XP',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.riksa.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? rarityColor : context.riksa.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  height: 98,
                  child: BuddyItemArtwork(
                    item: item,
                    species: species,
                    size: 96,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                marketItemName(context, item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  _ItemBadge(label: rarityLabel, color: rarityColor),
                  if (item.owned)
                    _ItemBadge(
                      label: l10n.marketOwned,
                      color: context.riksa.brand,
                    ),
                  if (item.equipped)
                    _ItemBadge(
                      label: l10n.marketEquipped,
                      color: context.riksa.brandStrong,
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 17,
                    color: context.riksa.saffron,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      NumberFormat.decimalPattern(locale).format(item.price),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (until.isNotEmpty && item.availableUntil != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: MarketAvailabilityCountdown(
                    until: item.availableUntil!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.riksa.inkMuted,
                    ),
                  ),
                ),
              if (item.locked && item.lockReason?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.lockReason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.riksa.semantic.error,
                    ),
                  ),
                )
              else if (isSignedIn && !item.owned && !item.locked && need > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.marketNeedMore(need),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.riksa.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemBadge extends StatelessWidget {
  const _ItemBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MarketActionBar extends StatelessWidget {
  const _MarketActionBar({
    required this.item,
    required this.isEquipped,
    required this.balance,
    required this.isSignedIn,
    required this.onBuy,
    required this.onEquip,
  });

  final MarketItem? item;
  final bool isEquipped;
  final int? balance;
  final bool isSignedIn;
  final VoidCallback? onBuy;
  final VoidCallback? onEquip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = item;
    final xp = balance ?? 0;
    final notEnough = current != null && xp < current.price;
    final need = current == null ? 0 : math.max(0, current.price - xp).toInt();
    final String label;
    final VoidCallback? action;
    if (current == null) {
      label = l10n.marketSelectItem;
      action = null;
    } else if (isEquipped) {
      label = l10n.marketEquipped;
      action = null;
    } else if (current.owned) {
      label = l10n.marketEquip;
      action = onEquip;
    } else if (current.locked) {
      label = current.lockReason?.trim().isNotEmpty == true
          ? current.lockReason!
          : l10n.marketLocked;
      action = null;
    } else if (!isSignedIn) {
      label = l10n.marketBuyFor(current.price);
      action = onBuy;
    } else if (notEnough) {
      label = l10n.marketNotEnoughXp(need);
      action = null;
    } else {
      label = l10n.marketBuyFor(current.price);
      action = onBuy;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: context.riksa.surface,
        border: Border(top: BorderSide(color: context.riksa.outline)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _PurchaseConfirmationSheet extends StatefulWidget {
  const _PurchaseConfirmationSheet({
    required this.item,
    required this.balance,
    required this.idempotencyKey,
    required this.onPurchase,
  });

  final MarketItem item;
  final int balance;
  final String idempotencyKey;
  final Future<MarketPurchaseReceipt> Function(String key) onPurchase;

  @override
  State<_PurchaseConfirmationSheet> createState() =>
      _PurchaseConfirmationSheetState();
}

class _PurchaseConfirmationSheetState
    extends State<_PurchaseConfirmationSheet> {
  bool _working = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final decimal = NumberFormat.decimalPattern(locale);
    final balanceAfter = math.max(0, widget.balance - widget.item.price);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.marketConfirmTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.marketConfirmBody(
              marketItemName(context, widget.item),
              decimal.format(widget.item.price),
              decimal.format(widget.balance),
              decimal.format(balanceAfter),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: context.riksa.saffron),
              const SizedBox(width: 5),
              Text(l10n.marketBalance(decimal.format(balanceAfter))),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              marketErrorMessage(_error!, l10n),
              style: TextStyle(color: context.riksa.semantic.error),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            key: const ValueKey('market-confirm-purchase'),
            onPressed: _working ? null : _purchase,
            child: _working
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_error == null ? l10n.marketConfirm : l10n.marketRetry),
          ),
          TextButton(
            onPressed: _working ? null : () => Navigator.pop(context),
            child: Text(l10n.marketCancel),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final receipt = await widget.onPurchase(widget.idempotencyKey);
      if (mounted) Navigator.pop(context, receipt);
    } catch (error) {
      if (mounted) {
        setState(() {
          _working = false;
          _error = error;
        });
      }
    }
  }
}

class _PurchaseCelebrationDialog extends StatelessWidget {
  const _PurchaseCelebrationDialog({required this.item, required this.species});

  final MarketItem item;
  final MascotSpecies species;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            painter: const _ConfettiPainter(),
            child: SizedBox(
              width: 208,
              height: 100,
              child: BuddyLook(
                species: species,
                loops: 1,
                face: MascotFace.happy,
                equipped: {item.slot: item.assetKey},
                rarity: {item.slot: item.rarity},
                size: 92,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.marketPurchaseSuccess(marketItemName(context, item)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.marketContinue),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.marketWearNow),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  static const colors = [
    Color(0xFFE6AA43),
    Color(0xFF62A892),
    Color(0xFF8B65C9),
    Color(0xFFE77971),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 22; index++) {
      final x = ((index * 37) % 207).toDouble();
      final y = (index.isEven ? 2 : 21) + (index % 3) * 3.0;
      final paint = Paint()..color = colors[index % colors.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(index * .42);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 5, height: 9),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}

class _MarketStateMessage extends StatelessWidget {
  const _MarketStateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: context.riksa.inkMuted),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

String marketErrorMessage(Object error, AppLocalizations l10n) {
  final responseData = error is DioException ? error.response?.data : null;
  final code = responseData is Map
      ? responseData['code']?.toString().toUpperCase()
      : null;
  return switch (code) {
    'INSUFFICIENT_BALANCE' => l10n.marketErrorInsufficientBalance,
    'ALREADY_OWNED' => l10n.marketErrorAlreadyOwned,
    'NOT_AVAILABLE' => l10n.marketErrorNotAvailable,
    'LOCKED' => l10n.marketErrorLocked,
    _ => l10n.marketErrorNetwork,
  };
}
