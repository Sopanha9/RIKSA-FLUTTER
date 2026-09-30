import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/mascot/domain/mascot.dart';
import '../../../features/mascot/presentation/widgets/buddy_look.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/market_models.dart';

class BuddyItemArtwork extends StatelessWidget {
  const BuddyItemArtwork({
    super.key,
    required this.item,
    required this.species,
    required this.size,
  });

  final MarketItem item;
  final MascotSpecies species;
  final double size;

  @override
  Widget build(BuildContext context) => BuddyLook(
    species: species,
    loops: 1,
    face: MascotFace.neutral,
    equipped: {item.slot: item.assetKey},
    rarity: {item.slot: item.rarity},
    size: size,
    semanticLabel: item.name,
  );
}

Color marketRarityColor(BuildContext context, String rarity) =>
    switch (rarity.toUpperCase()) {
      'RARE' => const Color(0xFF4F8CC9),
      'EPIC' => const Color(0xFF8B65C9),
      _ => context.riksa.saffron,
    };

String marketItemName(BuildContext context, MarketItem item) {
  final language = Localizations.localeOf(context).languageCode;
  if (language == 'km' && item.nameKm.trim().isNotEmpty) return item.nameKm;
  return item.name;
}

String marketAvailabilityLabel(DateTime? until) {
  if (until == null) return '';
  final remaining = until.difference(DateTime.now());
  if (remaining.isNegative) return '';
  final days = remaining.inDays;
  final hours = remaining.inHours.remainder(24);
  final minutes = remaining.inMinutes.remainder(60);
  final time = days > 0
      ? '${days}d ${hours}h'
      : hours > 0
      ? '${hours}h ${minutes}m'
      : '${minutes}m';
  return time;
}

class MarketAvailabilityCountdown extends StatefulWidget {
  const MarketAvailabilityCountdown({
    super.key,
    required this.until,
    this.style,
  });

  final DateTime until;
  final TextStyle? style;

  @override
  State<MarketAvailabilityCountdown> createState() =>
      _MarketAvailabilityCountdownState();
}

class _MarketAvailabilityCountdownState
    extends State<MarketAvailabilityCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant MarketAvailabilityCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.until != widget.until) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = marketAvailabilityLabel(widget.until);
    if (remaining.isEmpty) return const SizedBox.shrink();
    return Text(
      AppLocalizations.of(context)!.marketAvailableFor(remaining),
      style: widget.style,
    );
  }
}
