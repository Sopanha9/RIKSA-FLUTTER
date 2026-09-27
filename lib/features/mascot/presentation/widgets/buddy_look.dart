import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/buddy_api.dart';
import '../../domain/mascot.dart';
import 'buddy_anchors.dart';
import 'mascot_face_view.dart';

/// A face with its head slots layered over the source image. The layout stays
/// square at [size]; art and placeholders can paint beyond those bounds.
class BuddyLook extends StatefulWidget {
  const BuddyLook({
    super.key,
    required this.species,
    required this.face,
    required this.equipped,
    required this.size,
    this.loops,
    this.frameKey,
    this.semanticLabel,
    this.rarity = const {},
  });

  final MascotSpecies species;
  final MascotFace face;
  final Map<BuddyItemSlot, String> equipped;
  final double size;
  final int? loops;
  final String? frameKey;
  final String? semanticLabel;
  final Map<BuddyItemSlot, String> rarity;

  @override
  State<BuddyLook> createState() => _BuddyLookState();
}

class _BuddyLookState extends State<BuddyLook> {
  late final ValueNotifier<String> _activeFrameKey = ValueNotifier(
    '${widget.face.name}_1',
  );

  @override
  void didUpdateWidget(BuddyLook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face != widget.face || oldWidget.species != widget.species) {
      _activeFrameKey.value = '${widget.face.name}_1';
    }
  }

  @override
  void dispose() {
    _activeFrameKey.dispose();
    super.dispose();
  }

  static const faceHeightFractions = {
    MascotSpecies.crocodile: 99 / 134,
    MascotSpecies.capybara: 90 / 114,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final species = widget.species;
    final face = widget.face;
    final equipped = widget.equipped;
    final size = widget.size;
    final items = [
      for (final slot in const [BuddyItemSlot.eyewear, BuddyItemSlot.hat])
        if (equipped[slot]?.isNotEmpty == true) slot,
    ];
    final spokenLabel = [
      widget.semanticLabel ?? _speciesName(strings, species),
      for (final slot in items) '${_slotName(strings, slot)} ${equipped[slot]}',
    ].join(', ');

    return Semantics(
      label: spokenLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: FutureBuilder<BuddyAnchorSet>(
            future: BuddyAnchorLoader.load(species),
            builder: (context, snapshot) {
              final anchors =
                  snapshot.data ?? BuddyAnchorLoader.fallbackFor(species);
              final faceHeight = size * faceHeightFractions[species]!;
              final faceTop = size - faceHeight;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: MascotFaceView(
                      species: species,
                      face: face,
                      size: size,
                      loops: widget.loops,
                      activeFrameKey: _activeFrameKey,
                    ),
                  ),
                  Positioned.fill(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _activeFrameKey,
                      builder: (context, activeFrame, _) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final slot in const [
                            BuddyItemSlot.eyewear,
                            BuddyItemSlot.hat,
                          ])
                            if (equipped[slot]?.isNotEmpty == true)
                              _PlacedItem(
                                slot: slot,
                                species: species,
                                assetKey: equipped[slot]!,
                                rarity: widget.rarity[slot],
                                size: size,
                                faceTop: faceTop,
                                faceHeight: faceHeight,
                                anchor: anchors.forFrame(
                                  slot,
                                  widget.frameKey ?? activeFrame,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _speciesName(
    AppLocalizations? strings,
    MascotSpecies species,
  ) => switch (species) {
    MascotSpecies.crocodile => strings?.buddyLookCrocodile ?? 'Crocodile',
    MascotSpecies.capybara => strings?.buddyLookCapybara ?? 'Capybara',
  };

  static String _slotName(AppLocalizations? strings, BuddyItemSlot slot) =>
      switch (slot) {
        BuddyItemSlot.hat => strings?.buddyLookHat ?? 'hat',
        BuddyItemSlot.eyewear => strings?.buddyLookEyewear ?? 'glasses',
      };
}

class _PlacedItem extends StatelessWidget {
  const _PlacedItem({
    required this.slot,
    required this.species,
    required this.assetKey,
    required this.rarity,
    required this.size,
    required this.faceTop,
    required this.faceHeight,
    required this.anchor,
  });

  final BuddyItemSlot slot;
  final MascotSpecies species;
  final String assetKey;
  final String? rarity;
  final double size;
  final double faceTop;
  final double faceHeight;
  final BuddyAnchor anchor;

  @override
  Widget build(BuildContext context) {
    final width = size * anchor.width;
    final height = width * (slot == BuddyItemSlot.hat ? .5 : .375);
    final left = size * anchor.x - width / 2;
    final top = faceTop + faceHeight * anchor.y - height / 2;
    final path = 'assets/images/market/$assetKey/${species.name}.png';
    final placeholder = CustomPaint(
      painter: BuddyItemPlaceholderPainter(slot: slot, rarity: rarity),
      size: Size(width, height),
    );
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: anchor.rotation * math.pi / 180,
        // Only load art that ships in the bundle. Asking for a missing PNG
        // fails every time, logs an error, and leaves the load's timers
        // behind; the vector placeholder covers every item until then.
        child: bundledItemArt.contains(path)
            ? Image.asset(
                path,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}

/// Item art files that are bundled (and listed in pubspec.yaml), as
/// `assets/images/market/<assetKey>/<species>.png`. Add each PNG here when
/// the artist delivers it; anything missing draws the vector placeholder.
const Set<String> bundledItemArt = {};

/// Placeholder vector art used until the artist PNG for a slot is bundled.
class BuddyItemPlaceholderPainter extends CustomPainter {
  const BuddyItemPlaceholderPainter({required this.slot, this.rarity});

  final BuddyItemSlot slot;
  final String? rarity;

  @override
  void paint(Canvas canvas, Size size) {
    final color = switch (rarity?.toLowerCase()) {
      'rare' => const Color(0xFF4F8CC9),
      'epic' => const Color(0xFF8B65C9),
      'legendary' => const Color(0xFFD49A30),
      _ =>
        slot == BuddyItemSlot.hat
            ? const Color(0xFFD99A42)
            : const Color(0xFF4D9BB2),
    };
    final outline = Paint()
      ..color = const Color(0xFF493A35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, size.width * .035).toDouble()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    if (slot == BuddyItemSlot.hat) {
      final crown = Path()
        ..moveTo(size.width * .30, size.height * .72)
        ..quadraticBezierTo(
          size.width * .32,
          size.height * .18,
          size.width * .52,
          size.height * .16,
        )
        ..quadraticBezierTo(
          size.width * .76,
          size.height * .20,
          size.width * .76,
          size.height * .72,
        )
        ..close();
      canvas.drawPath(crown, fill);
      canvas.drawPath(crown, outline);
      final brim = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .08,
          size.height * .68,
          size.width * .84,
          size.height * .22,
        ),
        Radius.circular(size.height * .12),
      );
      canvas.drawRRect(brim, fill);
      canvas.drawRRect(brim, outline);
      final band = Paint()
        ..color = const Color(0xFF9F6030)
        ..strokeWidth = math.max(1.2, size.width * .035).toDouble();
      canvas.drawLine(
        Offset(size.width * .32, size.height * .55),
        Offset(size.width * .75, size.height * .55),
        band,
      );
    } else {
      final lensW = size.width * .39;
      final lensH = size.height * .62;
      final leftLens = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .05, size.height * .18, lensW, lensH),
        Radius.circular(size.height * .13),
      );
      final rightLens = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .56, size.height * .18, lensW, lensH),
        Radius.circular(size.height * .13),
      );
      final lensFill = Paint()..color = color.withValues(alpha: .24);
      canvas.drawRRect(leftLens, lensFill);
      canvas.drawRRect(rightLens, lensFill);
      canvas.drawRRect(leftLens, outline);
      canvas.drawRRect(rightLens, outline);
      canvas.drawLine(
        Offset(size.width * .44, size.height * .46),
        Offset(size.width * .56, size.height * .46),
        outline,
      );
      canvas.drawLine(
        Offset(size.width * .05, size.height * .34),
        Offset(0, size.height * .28),
        outline,
      );
      canvas.drawLine(
        Offset(size.width * .95, size.height * .34),
        Offset(size.width, size.height * .28),
        outline,
      );
    }
  }

  @override
  bool shouldRepaint(BuddyItemPlaceholderPainter oldDelegate) =>
      oldDelegate.slot != slot || oldDelegate.rarity != rarity;
}
