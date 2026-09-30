import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/mascot_view.dart';
import '../../mascot/providers/mascot_provider.dart';
import 'learning_design.dart';
import 'roadmap_stones.dart';

/// One screen-tall section of a subject's map, and the road through it.
///
/// [path] runs down the middle of the drawn road in fractions of the image's
/// width and height. It was traced from the art, so a lesson placed on it
/// always lands on the road rather than in a rice field.
class MapPiece {
  const MapPiece({required this.asset, required this.path});

  final String asset;
  final List<Offset> path;
}

/// The illustrated map a subject's lessons are laid out on.
///
/// The art holds only scenery and an empty road. The lessons are drawn on top,
/// so a subject can have any number of them: the middle section repeats until
/// the road is long enough, and the map always ends at the goal.
class SubjectMapArt {
  const SubjectMapArt({
    required this.start,
    required this.middle,
    required this.goal,
    required this.aspectRatio,
  });

  final MapPiece start;
  final MapPiece middle;
  final MapPiece goal;

  /// Height over width, shared by every piece.
  final double aspectRatio;

  /// The share of a piece's height that overlaps the piece above it. That band
  /// fades in, so the seam between two generated images is not visible.
  static const double blend = 0.08;
}

/// The map for [subject]. Every subject walks the same countryside road
/// until one gets art of its own; the return stays nullable so a subject can
/// still opt back into the list.
SubjectMapArt? subjectMapArtFor(StemSubject subject) => _countrysideMap;

/// Where every piece and lesson sits, for a map drawn [width] wide.
class SubjectMapLayout {
  const SubjectMapLayout._({
    required this.pieces,
    required this.pieceHeight,
    required this.pieceStep,
    required this.height,
    required this.nodes,
  });

  /// Lays [lessons] out evenly along the road, from the start gate to the goal.
  ///
  /// The scenery starts at the top, but no lesson sits above [topInset]: that
  /// band is under the floating header.
  factory SubjectMapLayout.of(
    SubjectMapArt art, {
    required double width,
    required int lessons,
    double topInset = 0,
  }) {
    // The start holds about three lessons and the goal one or two; every
    // middle section adds room for four more.
    final middles = math.max(0, ((lessons - 7) / 4).ceil());
    final pieces = [
      art.start,
      for (var i = 0; i < middles; i++) art.middle,
      art.goal,
    ];
    final pieceHeight = width * art.aspectRatio;
    final pieceStep = pieceHeight * (1 - SubjectMapArt.blend);

    // One road through the whole map. Where two pieces overlap, the lower
    // piece's road takes over once it is past the end of the upper one's.
    final road = <Offset>[];
    for (final (index, piece) in pieces.indexed) {
      final top = index * pieceStep;
      for (final point in piece.path) {
        final mapped = Offset(point.dx * width, top + point.dy * pieceHeight);
        if (road.isEmpty || mapped.dy > road.last.dy) road.add(mapped);
      }
    }

    // Keep at least the last stretch, so a very tall header on a short map
    // still leaves a road to walk.
    final clear = road.where((point) => point.dy >= topInset).toList();
    final walkable = clear.length >= 2
        ? clear
        : road.sublist(math.max(0, road.length - 2));

    return SubjectMapLayout._(
      pieces: pieces,
      pieceHeight: pieceHeight,
      pieceStep: pieceStep,
      height: (pieces.length - 1) * pieceStep + pieceHeight,
      nodes: _spread(walkable, lessons),
    );
  }

  final List<MapPiece> pieces;
  final double pieceHeight;

  /// Distance from one piece's top to the next one's.
  final double pieceStep;
  final double height;

  /// Centre of each lesson's marker, in order.
  final List<Offset> nodes;

  /// [count] points at equal distances along [road], first and last included.
  static List<Offset> _spread(List<Offset> road, int count) {
    if (count <= 0 || road.isEmpty) return const [];
    if (count == 1 || road.length == 1) return [road.first];

    final lengths = <double>[0];
    for (var i = 1; i < road.length; i++) {
      lengths.add(lengths.last + (road[i] - road[i - 1]).distance);
    }
    final total = lengths.last;

    final nodes = <Offset>[];
    var segment = 1;
    for (var i = 0; i < count; i++) {
      final target = total * i / (count - 1);
      while (segment < road.length - 1 && lengths[segment] < target) {
        segment++;
      }
      final from = lengths[segment - 1];
      final span = lengths[segment] - from;
      final t = span == 0 ? 0.0 : ((target - from) / span).clamp(0.0, 1.0);
      nodes.add(Offset.lerp(road[segment - 1], road[segment], t)!);
    }
    return nodes;
  }
}

/// A subject's lessons as stops along an illustrated road.
///
/// The learner's buddy waits at the current lesson, and the map opens scrolled
/// to it, so the next step is the first thing on screen.
class SubjectMap extends ConsumerStatefulWidget {
  const SubjectMap({
    super.key,
    required this.art,
    required this.lessons,
    this.topInset = 0,
    this.bottomExtension = 0,
  });

  final SubjectMapArt art;

  /// Height at the top covered by the floating header; no lesson goes there.
  final double topInset;

  /// Scenery drawn past the goal, under the floating navigation bar, so the
  /// map runs to the bottom of the screen instead of ending on a blank strip.
  final double bottomExtension;

  /// Lesson stones in syllabus order.
  final List<RoadmapStone> lessons;

  @override
  ConsumerState<SubjectMap> createState() => _SubjectMapState();
}

class _SubjectMapState extends ConsumerState<SubjectMap> {
  final _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _currentKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(target, alignment: .45);
    });
  }

  void _open(RoadmapStone stone) {
    final lesson = stone.lesson;
    if (lesson == null) return;
    if (!stone.isOpenable) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.lessonLocked)),
        );
      return;
    }
    context.push('/learn/${lesson.id}', extra: lesson);
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.lessons;
    final currentIndex = lessons.indexWhere(
      (stone) => stone.status == LearningStatus.current,
    );
    final started = lessons.any((stone) => stone.status == LearningStatus.done);
    final species =
        ref.watch(mascotProvider).profile?.species ?? MascotSpecies.crocodile;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layout = SubjectMapLayout.of(
          widget.art,
          width: width,
          lessons: lessons.length,
          topInset: widget.topInset,
        );
        final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context))
            .round();

        final goal = layout.pieces.last;
        return SizedBox(
          width: width,
          height: layout.height + widget.bottomExtension,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.bottomExtension > 0)
                // The goal's bottom edge mirrored, so the seam is invisible.
                Positioned(
                  top: layout.height - 1,
                  left: 0,
                  width: width,
                  height: widget.bottomExtension + 1,
                  child: ExcludeSemantics(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: layout.pieceHeight,
                        maxHeight: layout.pieceHeight,
                        child: Transform.flip(
                          flipY: true,
                          child: _PieceImage(
                            asset: goal.asset,
                            cacheWidth: cacheWidth,
                            fadeIn: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              for (final (index, piece) in layout.pieces.indexed)
                Positioned(
                  top: index * layout.pieceStep,
                  left: 0,
                  width: width,
                  height: layout.pieceHeight,
                  child: ExcludeSemantics(
                    child: _PieceImage(
                      asset: piece.asset,
                      cacheWidth: cacheWidth,
                      fadeIn: index > 0,
                    ),
                  ),
                ),
              for (final (index, stone) in lessons.indexed)
                if (index != currentIndex)
                  _placed(
                    layout.nodes[index],
                    _MapNode.size,
                    _MapNode(stone: stone, onTap: () => _open(stone)),
                  ),
              if (currentIndex >= 0)
                ..._current(
                  layout.nodes[currentIndex],
                  lessons[currentIndex],
                  width: width,
                  started: started,
                  species: species,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _placed(Offset centre, double size, Widget child) => Positioned(
    left: centre.dx - size / 2,
    top: centre.dy - size / 2,
    width: size,
    height: size,
    child: child,
  );

  /// The current lesson: a larger marker, what to do there, and the buddy.
  List<Widget> _current(
    Offset centre,
    RoadmapStone stone, {
    required double width,
    required bool started,
    required MascotSpecies species,
  }) {
    const buddySize = 76.0;
    const gap = 8.0;
    const edge = 8.0;
    final half = _MapNode.currentSize / 2;

    // The label sits beside the marker, so it never covers the road ahead. It
    // reads best to the right, and moves left only when the marker is well
    // over to the right. The buddy stands on the other side, or above the
    // marker when that side is too narrow for it.
    final tagOnRight = centre.dx <= width * .6;
    final tagRoom = tagOnRight
        ? width - (centre.dx + half + gap) - edge
        : centre.dx - half - gap - edge;
    final tagWidth = math.min(_CurrentTag.maxWidth, tagRoom);
    final buddyRoom = tagOnRight
        ? centre.dx - half - gap - edge
        : width - (centre.dx + half + gap) - edge;
    final buddyBeside = buddyRoom >= buddySize;
    final buddyLeft = !buddyBeside
        ? centre.dx - buddySize / 2
        : tagOnRight
        ? centre.dx - half - gap - buddySize
        : centre.dx + half + gap;
    final buddyTop = buddyBeside
        ? centre.dy - buddySize * MascotView.heightFactor + 18
        : centre.dy - half - buddySize * MascotView.heightFactor + 10;

    return [
      Positioned(
        left: buddyLeft,
        top: buddyTop,
        width: buddySize,
        child: IgnorePointer(
          child: MascotView(
            species: species,
            size: buddySize,
            mood: MascotMood.greeting,
          ),
        ),
      ),
      _placed(
        centre,
        _MapNode.currentSize,
        _MapNode(
          key: _currentKey,
          stone: stone,
          current: true,
          onTap: () => _open(stone),
        ),
      ),
      Positioned(
        left: tagOnRight ? centre.dx + half + gap : null,
        right: tagOnRight ? null : width - (centre.dx - half - gap),
        top: centre.dy,
        width: tagWidth,
        child: FractionalTranslation(
          // Centred on the marker's middle, whatever height the text takes.
          translation: const Offset(0, -.5),
          child: _CurrentTag(
            label: started
                ? AppLocalizations.of(context)!.continueLabel
                : AppLocalizations.of(context)!.startHere,
            title: stone.title,
            pointsLeft: tagOnRight,
            onTap: () => _open(stone),
          ),
        ),
      ),
    ];
  }
}

/// One piece of the map. Every piece after the first fades in over the one
/// above it, so the join between two images reads as one landscape.
class _PieceImage extends StatelessWidget {
  const _PieceImage({
    required this.asset,
    required this.cacheWidth,
    required this.fadeIn,
  });

  final String asset;
  final int cacheWidth;
  final bool fadeIn;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      fit: BoxFit.fill,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => ColoredBox(color: context.riksa.canvas),
    );
    if (!fadeIn) return image;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0, SubjectMapArt.blend],
      ).createShader(bounds),
      child: image,
    );
  }
}

/// A lesson's stop on the road.
class _MapNode extends StatelessWidget {
  const _MapNode({
    super.key,
    required this.stone,
    required this.onTap,
    this.current = false,
  });

  static const size = 50.0;
  static const currentSize = 64.0;

  final RoadmapStone stone;
  final VoidCallback onTap;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final l10n = AppLocalizations.of(context)!;
    final done = stone.status == LearningStatus.done;
    final locked = stone.status == LearningStatus.locked;

    final background = current
        ? palette.brand
        : done
        ? palette.semantic.success
        : locked
        ? const Color(0xFFD9D4C7)
        : Colors.white;
    final foreground = current
        ? palette.onBrand
        : done
        ? palette.semantic.onSuccess
        : locked
        ? const Color(0xFF8A8475)
        : const Color(0xFF2B2A26);

    final Widget face = done
        ? Icon(Icons.check_rounded, size: 26, color: foreground)
        : locked
        ? Icon(Icons.lock_rounded, size: 20, color: foreground)
        : Text(
            '${stone.index}',
            style: TextStyle(
              color: foreground,
              fontSize: current ? 22 : 17,
              fontWeight: FontWeight.w800,
            ),
          );

    final status = done
        ? l10n.completedLabel
        : locked
        ? l10n.lessonLockedShort
        : null;

    return Semantics(
      button: true,
      label: ['${stone.index}. ${stone.title}', ?status].join(', '),
      excludeSemantics: true,
      child: Tooltip(
        message: stone.title,
        child: GestureDetector(
          key: ValueKey('map-lesson-${stone.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: current ? 4 : 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .28),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
                if (current)
                  BoxShadow(
                    color: palette.brand.withValues(alpha: .4),
                    spreadRadius: 8,
                  ),
              ],
            ),
            child: Center(child: face),
          ),
        ),
      ),
    );
  }
}

/// What the current stop is: "Start here" or "Continue", and its title. It
/// sits beside the marker with a small pointer towards it.
class _CurrentTag extends StatelessWidget {
  const _CurrentTag({
    required this.label,
    required this.title,
    required this.pointsLeft,
    required this.onTap,
  });

  static const maxWidth = 170.0;
  static const _pointer = 7.0;

  final String label;
  final String title;

  /// True when the marker is to the tag's left.
  final bool pointsLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.mediumBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: RiksaTypography.bodyStyleFor(
              label,
              theme.textTheme.labelMedium?.copyWith(
                color: palette.brand,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: RiksaTypography.bodyStyleFor(
              title,
              theme.textTheme.bodySmall?.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
    final pointer = CustomPaint(
      size: const Size(_pointer, _pointer * 2),
      painter: _PointerPainter(color: palette.surface, left: pointsLeft),
    );

    return ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: pointsLeft
              ? [pointer, Flexible(child: card)]
              : [Flexible(child: card), pointer],
        ),
      ),
    );
  }
}

/// The small triangle joining the tag to its marker.
class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.color, required this.left});

  final Color color;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = left ? 0.0 : size.width;
    final base = left ? size.width : 0.0;
    canvas.drawPath(
      Path()
        ..moveTo(base, 0)
        ..lineTo(tip, size.height / 2)
        ..lineTo(base, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.color != color || old.left != left;
}

// Road centrelines traced from the art in assets/images/maps/math/.
const _countrysideMap = SubjectMapArt(
  aspectRatio: 1672 / 941,
  start: MapPiece(
    asset: 'assets/images/maps/math/start.webp',
    path: [
      Offset(0.5151, 0.0969),
      Offset(0.5189, 0.1184),
      Offset(0.5283, 0.14),
      Offset(0.5382, 0.1615),
      Offset(0.5427, 0.183),
      Offset(0.5373, 0.2045),
      Offset(0.522, 0.2261),
      Offset(0.498, 0.2476),
      Offset(0.4669, 0.2691),
      Offset(0.4318, 0.2907),
      Offset(0.3993, 0.3122),
      Offset(0.3769, 0.3337),
      Offset(0.3671, 0.3553),
      Offset(0.368, 0.3768),
      Offset(0.3748, 0.3983),
      Offset(0.3934, 0.4199),
      Offset(0.4269, 0.4414),
      Offset(0.47, 0.4629),
      Offset(0.5174, 0.4844),
      Offset(0.5635, 0.506),
      Offset(0.6024, 0.5275),
      Offset(0.6294, 0.549),
      Offset(0.6424, 0.5706),
      Offset(0.6422, 0.5921),
      Offset(0.6312, 0.6136),
      Offset(0.6088, 0.6352),
      Offset(0.5806, 0.6567),
      Offset(0.5479, 0.6782),
      Offset(0.5175, 0.6998),
      Offset(0.4963, 0.7213),
      Offset(0.4823, 0.7428),
      Offset(0.4744, 0.7644),
      Offset(0.4741, 0.7859),
      Offset(0.4804, 0.8074),
      Offset(0.4947, 0.8289),
      Offset(0.5162, 0.8505),
      Offset(0.5383, 0.872),
      Offset(0.5568, 0.8935),
      Offset(0.5688, 0.9151),
      Offset(0.5748, 0.9366),
      Offset(0.576, 0.9581),
      Offset(0.5757, 0.9797),
    ],
  ),
  middle: MapPiece(
    asset: 'assets/images/maps/math/middle.webp',
    path: [
      Offset(0.5298, 0.0),
      Offset(0.5337, 0.0215),
      Offset(0.5416, 0.0431),
      Offset(0.5482, 0.0646),
      Offset(0.5504, 0.0861),
      Offset(0.5458, 0.1077),
      Offset(0.5328, 0.1292),
      Offset(0.5115, 0.1507),
      Offset(0.4835, 0.1722),
      Offset(0.4527, 0.1938),
      Offset(0.4239, 0.2153),
      Offset(0.3995, 0.2368),
      Offset(0.3808, 0.2584),
      Offset(0.3716, 0.2799),
      Offset(0.3728, 0.3014),
      Offset(0.3864, 0.323),
      Offset(0.4105, 0.3445),
      Offset(0.4501, 0.366),
      Offset(0.4998, 0.3876),
      Offset(0.5449, 0.4091),
      Offset(0.5816, 0.4306),
      Offset(0.6138, 0.4522),
      Offset(0.6406, 0.4737),
      Offset(0.6599, 0.4952),
      Offset(0.6702, 0.5167),
      Offset(0.6695, 0.5383),
      Offset(0.6597, 0.5598),
      Offset(0.6409, 0.5813),
      Offset(0.6142, 0.6029),
      Offset(0.5822, 0.6244),
      Offset(0.5503, 0.6459),
      Offset(0.5215, 0.6675),
      Offset(0.4982, 0.689),
      Offset(0.4811, 0.7105),
      Offset(0.4725, 0.7321),
      Offset(0.4727, 0.7536),
      Offset(0.4816, 0.7751),
      Offset(0.498, 0.7967),
      Offset(0.5164, 0.8182),
      Offset(0.5304, 0.8397),
      Offset(0.5375, 0.8612),
      Offset(0.5383, 0.8828),
      Offset(0.5387, 0.9043),
      Offset(0.5443, 0.9258),
      Offset(0.5572, 0.9474),
      Offset(0.5731, 0.9689),
      Offset(0.582, 0.9904),
    ],
  ),
  goal: MapPiece(
    asset: 'assets/images/maps/math/goal.webp',
    path: [
      Offset(0.5125, 0.0),
      Offset(0.5198, 0.0215),
      Offset(0.5339, 0.0431),
      Offset(0.5459, 0.0646),
      Offset(0.554, 0.0861),
      Offset(0.5571, 0.1077),
      Offset(0.5539, 0.1292),
      Offset(0.5435, 0.1507),
      Offset(0.5263, 0.1722),
      Offset(0.5035, 0.1938),
      Offset(0.4794, 0.2153),
      Offset(0.4563, 0.2368),
      Offset(0.4395, 0.2584),
      Offset(0.4326, 0.2799),
      Offset(0.4378, 0.3014),
      Offset(0.4562, 0.323),
      Offset(0.4863, 0.3445),
      Offset(0.5224, 0.366),
      Offset(0.5518, 0.3876),
      Offset(0.5682, 0.4091),
      Offset(0.5714, 0.4306),
      Offset(0.5638, 0.4522),
      Offset(0.5487, 0.4737),
      Offset(0.5324, 0.4952),
      Offset(0.5226, 0.5167),
    ],
  ),
);
