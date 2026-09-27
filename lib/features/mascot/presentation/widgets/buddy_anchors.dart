import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/buddy_api.dart';
import '../../domain/mascot.dart';

class BuddyAnchor {
  const BuddyAnchor({
    required this.x,
    required this.y,
    required this.width,
    required this.rotation,
  });

  final double x;
  final double y;
  final double width;
  final double rotation;

  BuddyAnchor apply(Map<String, dynamic> override) => BuddyAnchor(
    x: (override['x'] as num?)?.toDouble() ?? x,
    y: (override['y'] as num?)?.toDouble() ?? y,
    width: (override['w'] as num?)?.toDouble() ?? width,
    rotation: (override['rot'] as num?)?.toDouble() ?? rotation,
  );
}

class BuddyAnchorSet {
  const BuddyAnchorSet({required this.defaults, required this.frames});

  final Map<BuddyItemSlot, BuddyAnchor> defaults;
  final Map<String, Map<BuddyItemSlot, Map<String, dynamic>>> frames;

  BuddyAnchor forFrame(BuddyItemSlot slot, String? frameKey) {
    final base = defaults[slot]!;
    final override = frameKey == null ? null : frames[frameKey]?[slot];
    return override == null ? base : base.apply(override);
  }

  factory BuddyAnchorSet.fromJson(
    Map<String, dynamic> json, {
    required MascotSpecies species,
  }) {
    final face = json['face'] is Map
        ? Map<String, dynamic>.from(json['face'] as Map)
        : const <String, dynamic>{};
    final rawDefaults = face['default'] is Map
        ? Map<String, dynamic>.from(face['default'] as Map)
        : const <String, dynamic>{};
    final defaults = Map<BuddyItemSlot, BuddyAnchor>.of(
      _fallback[species]!.defaults,
    );
    for (final entry in rawDefaults.entries) {
      final slot = BuddyItemSlot.fromApiName(entry.key);
      if (slot == null || entry.value is! Map) continue;
      defaults[slot] = defaults[slot]!.apply(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    final frames = <String, Map<BuddyItemSlot, Map<String, dynamic>>>{};
    final rawFrames = face['frames'];
    if (rawFrames is Map) {
      for (final frameEntry in rawFrames.entries) {
        if (frameEntry.value is! Map) continue;
        final overrides = <BuddyItemSlot, Map<String, dynamic>>{};
        for (final entry in (frameEntry.value as Map).entries) {
          final slot = BuddyItemSlot.fromApiName(entry.key);
          if (slot != null && entry.value is Map) {
            overrides[slot] = Map<String, dynamic>.from(entry.value as Map);
          }
        }
        frames[frameEntry.key.toString()] = Map.unmodifiable(overrides);
      }
    }
    return BuddyAnchorSet(
      defaults: Map.unmodifiable(defaults),
      frames: Map.unmodifiable(frames),
    );
  }
}

abstract final class BuddyAnchorLoader {
  static final Map<MascotSpecies, Future<BuddyAnchorSet>> _cache = {};

  static Future<BuddyAnchorSet> load(MascotSpecies species) =>
      _cache.putIfAbsent(species, () => _load(species));

  static BuddyAnchorSet fallbackFor(MascotSpecies species) =>
      _fallback[species]!;

  static Future<BuddyAnchorSet> _load(MascotSpecies species) async {
    final fallback = _fallback[species]!;
    try {
      final source = await rootBundle.loadString(
        'assets/images/market/anchors/${species.name}.json',
      );
      return BuddyAnchorSet.fromJson(
        jsonDecode(source) as Map<String, dynamic>,
        species: species,
      );
    } catch (_) {
      return fallback;
    }
  }

  static void clearCacheForTesting() => _cache.clear();
}

/// Neutral face dimensions and alpha bounds were measured once from
/// `neutral_1.png`: crocodile 134x99, visible (22,4)-(132,94); capybara
/// 114x90, visible (14,4)-(112,85). Anchor centers were then placed by eye
/// over the visible crown and eye line in those images.
const Map<MascotSpecies, BuddyAnchorSet> _fallback = {
  MascotSpecies.crocodile: BuddyAnchorSet(
    defaults: {
      BuddyItemSlot.hat: BuddyAnchor(x: .52, y: .09, width: .60, rotation: -8),
      BuddyItemSlot.eyewear: BuddyAnchor(
        x: .64,
        y: .49,
        width: .57,
        rotation: 0,
      ),
    },
    frames: {},
  ),
  MascotSpecies.capybara: BuddyAnchorSet(
    defaults: {
      BuddyItemSlot.hat: BuddyAnchor(x: .55, y: .10, width: .68, rotation: -4),
      BuddyItemSlot.eyewear: BuddyAnchor(
        x: .50,
        y: .44,
        width: .65,
        rotation: 0,
      ),
    },
    frames: {},
  ),
};
