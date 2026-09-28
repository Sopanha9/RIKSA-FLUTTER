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
  const BuddyAnchorSet({
    required this.defaults,
    required this.frames,
    this.hatClip = const [],
  });

  final Map<BuddyItemSlot, BuddyAnchor> defaults;
  final Map<String, Map<BuddyItemSlot, Map<String, dynamic>>> frames;

  /// The lower edge of headwear drawn into the face art itself, as points in
  /// face fractions from left to right. The crocodile's art wears a safari
  /// helmet whose brim reaches almost to its eyes, so no hat can cover it
  /// without covering the eyes too. While a hat is equipped, the face is
  /// clipped along this line and the hat's brim sits on it: the hat replaces
  /// the helmet. Empty when the art has no headwear.
  final List<Offset> hatClip;

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
    final rawClip = face['hatClip'];
    final hatClip = rawClip is List
        ? [
            for (final point in rawClip)
              if (point is List &&
                  point.length == 2 &&
                  point[0] is num &&
                  point[1] is num)
                Offset(
                  (point[0] as num).toDouble(),
                  (point[1] as num).toDouble(),
                ),
          ]
        : _fallback[species]!.hatClip;
    return BuddyAnchorSet(
      defaults: Map.unmodifiable(defaults),
      frames: Map.unmodifiable(frames),
      hatClip: List.unmodifiable(hatClip),
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
      // The anchor is the hat center; this places its lower brim on
      // [_crocodileHelmetLine], tilted with the helmet's brim.
      BuddyItemSlot.hat: BuddyAnchor(
        x: .52,
        y: .18,
        width: .74,
        rotation: -16,
      ),
      BuddyItemSlot.eyewear: BuddyAnchor(
        x: .64,
        y: .49,
        width: .57,
        rotation: 0,
      ),
    },
    frames: {},
    hatClip: _crocodileHelmetLine,
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

/// The crocodile helmet's lower edge, measured from every face frame: the
/// lowest helmet pixel per column plus the outline, with a small margin.
/// It stays above both eyes in every frame.
const _crocodileHelmetLine = [
  Offset(0, .60),
  Offset(.20, .56),
  Offset(.29, .535),
  Offset(.35, .495),
  Offset(.41, .445),
  Offset(.47, .405),
  Offset(.53, .375),
  Offset(.62, .345),
  Offset(.71, .325),
  Offset(.80, .34),
  Offset(1, .34),
];
