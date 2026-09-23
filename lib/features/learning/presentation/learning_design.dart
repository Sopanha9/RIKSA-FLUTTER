/// Colour vocabulary for the learning feature.
///
/// Two independent axes decide what a surface looks like, and mixing them on
/// one surface is what made the old catalog unreadable:
///
/// * [StemSubject] is *identity*. It colours a subject's own tile and the
///   header of that subject's roadmap, so a learner recognises the subject
///   before reading its name.
/// * [LearningStatus] is *state*. It colours everything inside a roadmap, so
///   progress can be read at a glance without parsing any text.
///
/// The core [RiksaSubjectKind] deliberately collapses physics, chemistry and
/// biology into one "science" bucket because community and blog only need that
/// much resolution. Learning needs each Grade 12 STEM subject to be distinct,
/// so it keeps its own classification here rather than widening the shared one.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum StemSubject { mathematics, physics, chemistry, biology, technology, other }

/// Classifies a category name coming from the learning API.
///
/// Matches Khmer as well as English because category names are authored in
/// either script by admins in `riksa_admin`.
StemSubject stemSubjectFor(String categoryName) {
  final value = categoryName.toLowerCase();
  if (value.contains('math') || value.contains('គណិត')) {
    return StemSubject.mathematics;
  }
  if (value.contains('phys') || value.contains('រូបវិទ្យា')) {
    return StemSubject.physics;
  }
  if (value.contains('chem') || value.contains('គីមី')) {
    return StemSubject.chemistry;
  }
  if (value.contains('bio') || value.contains('ជីវ')) {
    return StemSubject.biology;
  }
  if (value.contains('computer') ||
      value.contains('tech') ||
      value.contains('engineer') ||
      value.contains('កុំព្យូទ័រ') ||
      value.contains('បច្ចេក')) {
    return StemSubject.technology;
  }
  return StemSubject.other;
}

IconData stemSubjectIcon(StemSubject subject) => switch (subject) {
  StemSubject.mathematics => Icons.functions_rounded,
  StemSubject.physics => Icons.bolt_rounded,
  StemSubject.chemistry => Icons.science_rounded,
  StemSubject.biology => Icons.eco_rounded,
  StemSubject.technology => Icons.code_rounded,
  StemSubject.other => Icons.school_rounded,
};

/// The pixel-art picture for a subject, or null where there is none.
String? stemSubjectAsset(StemSubject subject) => switch (subject) {
  StemSubject.mathematics => 'assets/images/subjects/math.png',
  StemSubject.physics => 'assets/images/subjects/physics.png',
  StemSubject.chemistry => 'assets/images/subjects/chemistry.png',
  StemSubject.biology => 'assets/images/subjects/biology.png',
  StemSubject.technology => 'assets/images/subjects/computer.png',
  StemSubject.other => null,
};

/// A subject's square tile: its pixel-art picture on its own pastel, or the
/// plain icon on the subject tone for subjects without a picture.
class StemSubjectTile extends StatelessWidget {
  const StemSubjectTile({super.key, required this.subject, required this.size});

  final StemSubject subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = subjectTone(context, subject);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(size * .26),
      ),
      child: Icon(
        stemSubjectIcon(subject),
        size: size * .5,
        color: tone.accent,
      ),
    );
    final asset = stemSubjectAsset(subject);
    if (asset == null) return fallback;
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// A subject's pixel artwork, painted rather than loaded from an asset.
class SubjectPixelArtwork extends StatelessWidget {
  const SubjectPixelArtwork({super.key, required this.subject, this.size = 60});

  final StemSubject subject;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    key: ValueKey('subject-artwork-${subject.name}'),
    dimension: size,
    child: CustomPaint(
      painter: _SubjectPixelArtworkPainter(subject, context.riksa),
    ),
  );
}

class _SubjectPixelArtworkPainter extends CustomPainter {
  const _SubjectPixelArtworkPainter(this.subject, this.palette);

  final StemSubject subject;
  final RiksaPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 128, size.height / 128);
    final background = switch (subject) {
      StemSubject.biology => palette.jadeSoft,
      StemSubject.chemistry => palette.brandSoft,
      StemSubject.technology => palette.jadeSoft,
      StemSubject.mathematics => palette.blushSoft,
      StemSubject.physics => palette.surfaceRaised,
      StemSubject.other => palette.saffronSoft,
    };

    canvas.drawRRect(_rr(9, 8, 110, 110, 15), _fill(background));
    canvas.drawRect(
      const Rect.fromLTWH(16, 16, 7, 7),
      _fill(palette.surface.withValues(alpha: .92)),
    );
    canvas.drawRect(
      const Rect.fromLTWH(25, 10, 8, 8),
      _fill(palette.surface.withValues(alpha: .84)),
    );

    switch (subject) {
      case StemSubject.biology:
        _paintBiology(canvas);
      case StemSubject.chemistry:
        _paintChemistry(canvas);
      case StemSubject.technology:
        _paintComputer(canvas);
      case StemSubject.mathematics:
        _paintMath(canvas);
      case StemSubject.physics:
        _paintPhysics(canvas);
      case StemSubject.other:
        _paintOther(canvas);
    }
  }

  void _paintBiology(Canvas c) {
    final edge = palette.jadeStrong;
    c.drawRRect(_rr(34, 33, 59, 62, 9), _fill(palette.surface));
    c.drawRRect(_rr(34, 33, 59, 62, 9), _stroke(edge, 4));
    c.drawRect(
      const Rect.fromLTWH(42, 88, 43, 11),
      _fill(palette.saffron),
    );
    c.drawRect(const Rect.fromLTWH(42, 88, 43, 11), _stroke(edge, 3));
    c.drawRect(
      const Rect.fromLTWH(45, 82, 37, 8),
      _fill(palette.saffron),
    );
    c.drawLine(const Offset(64, 82), const Offset(64, 51), _stroke(edge, 4));
    c.drawOval(
      const Rect.fromLTWH(42, 51, 23, 21),
      _fill(palette.jade),
    );
    c.drawOval(const Rect.fromLTWH(42, 51, 23, 21), _stroke(edge, 3));
    c.drawOval(
      const Rect.fromLTWH(63, 43, 27, 23),
      _fill(palette.jade),
    );
    c.drawOval(const Rect.fromLTWH(63, 43, 27, 23), _stroke(edge, 3));
    c.drawLine(
      const Offset(47, 66),
      const Offset(60, 57),
      _stroke(palette.reward, 3),
    );
    c.drawLine(
      const Offset(69, 59),
      const Offset(83, 49),
      _stroke(palette.reward, 3),
    );
  }

  void _paintChemistry(Canvas c) {
    final edge = palette.brandStrong;
    c.drawRect(
      const Rect.fromLTWH(55, 29, 18, 10),
      _fill(palette.brand),
    );
    c.drawRect(const Rect.fromLTWH(55, 29, 18, 10), _stroke(edge, 4));
    c.drawRect(
      const Rect.fromLTWH(59, 39, 10, 23),
      _fill(palette.brandSoft),
    );
    c.drawRect(const Rect.fromLTWH(59, 39, 10, 23), _stroke(edge, 3));
    final flask = Path()
      ..moveTo(47, 61)
      ..lineTo(81, 61)
      ..lineTo(97, 96)
      ..lineTo(31, 96)
      ..close();
    c.drawPath(flask, _fill(palette.brand));
    c.drawPath(flask, _stroke(edge, 4));
    c.drawRect(
      const Rect.fromLTWH(42, 79, 44, 9),
      _fill(palette.brandSoft),
    );
    c.drawRect(
      const Rect.fromLTWH(36, 88, 56, 8),
      _fill(palette.brandStrong),
    );
    for (final bubble in const [
      Rect.fromLTWH(36, 43, 8, 8),
      Rect.fromLTWH(86, 34, 7, 7),
      Rect.fromLTWH(78, 23, 5, 5),
    ]) {
      c.drawOval(bubble, _fill(palette.brandSoft));
      c.drawOval(bubble, _stroke(edge, 2));
    }
  }

  void _paintComputer(Canvas c) {
    final edge = palette.jadeStrong;
    c.drawRRect(_rr(26, 34, 76, 47, 6), _fill(palette.surface));
    c.drawRRect(_rr(26, 34, 76, 47, 6), _stroke(edge, 4));
    c.drawRect(
      const Rect.fromLTWH(32, 40, 64, 35),
      _fill(palette.surfaceRaised),
    );
    final base = Path()
      ..moveTo(20, 84)
      ..lineTo(108, 84)
      ..lineTo(99, 98)
      ..lineTo(29, 98)
      ..close();
    c.drawPath(base, _fill(palette.jade));
    c.drawPath(base, _stroke(edge, 3));
    c.drawLine(
      const Offset(50, 51),
      const Offset(39, 60),
      _stroke(palette.jade, 5),
    );
    c.drawLine(
      const Offset(39, 60),
      const Offset(50, 69),
      _stroke(palette.jade, 5),
    );
    c.drawLine(
      const Offset(78, 51),
      const Offset(89, 60),
      _stroke(palette.jade, 5),
    );
    c.drawLine(
      const Offset(89, 60),
      const Offset(78, 69),
      _stroke(palette.jade, 5),
    );
    c.drawLine(const Offset(68, 49), const Offset(59, 72), _stroke(edge, 4));
  }

  void _paintMath(Canvas c) {
    final edge = palette.math;
    c.drawRRect(_rr(33, 30, 56, 64, 4), _fill(palette.surface));
    c.drawRRect(_rr(33, 30, 56, 64, 4), _stroke(edge, 4));
    c.drawRect(
      const Rect.fromLTWH(33, 30, 10, 64),
      _fill(palette.blushSoft),
    );
    for (final y in const [45.0, 56.0, 68.0, 80.0]) {
      c.drawLine(
        Offset(49, y),
        Offset(82, y),
        _stroke(palette.outline, 2),
      );
    }
    final sigma = Path()
      ..moveTo(59, 42)
      ..lineTo(88, 42)
      ..lineTo(73, 60)
      ..lineTo(89, 81)
      ..lineTo(60, 81)
      ..lineTo(73, 62)
      ..close();
    c.drawPath(sigma, _fill(palette.math));
    c.drawPath(sigma, _stroke(edge, 3));
    final ruler = Path()
      ..moveTo(83, 31)
      ..lineTo(93, 36)
      ..lineTo(59, 104)
      ..lineTo(49, 100)
      ..close();
    c.drawPath(ruler, _fill(palette.saffron));
    c.drawPath(ruler, _stroke(edge, 3));
  }

  void _paintPhysics(Canvas c) {
    final edge = palette.science;
    c.drawOval(const Rect.fromLTWH(29, 51, 71, 31), _stroke(edge, 3));
    c.drawOval(const Rect.fromLTWH(37, 35, 55, 65), _stroke(edge, 3));
    c.drawOval(const Rect.fromLTWH(41, 35, 47, 65), _stroke(edge, 3));
    c.drawOval(
      const Rect.fromLTWH(57, 57, 14, 14),
      _fill(palette.science),
    );
    c.drawOval(const Rect.fromLTWH(57, 57, 14, 14), _stroke(edge, 3));
    final bolt = Path()
      ..moveTo(66, 25)
      ..lineTo(47, 66)
      ..lineTo(62, 65)
      ..lineTo(55, 100)
      ..lineTo(86, 53)
      ..lineTo(70, 55)
      ..close();
    c.drawPath(bolt, _fill(palette.science));
    c.drawPath(bolt, _stroke(edge, 3));
  }

  void _paintOther(Canvas c) {
    final edge = palette.saffron;
    c.drawRect(
      const Rect.fromLTWH(35, 43, 58, 45),
      _fill(palette.saffron),
    );
    c.drawRect(const Rect.fromLTWH(35, 43, 58, 45), _stroke(edge, 4));
    c.drawLine(const Offset(64, 43), const Offset(64, 88), _stroke(edge, 3));
  }

  static Paint _fill(Color color) => Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.fill
    ..color = color;

  static Paint _stroke(Color color, double width) => Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = color;

  static RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  @override
  bool shouldRepaint(covariant _SubjectPixelArtworkPainter oldDelegate) =>
      oldDelegate.subject != subject || oldDelegate.palette != palette;
}

/// A flat pastel surface plus the ink that stays legible on it.
@immutable
class LearningTone {
  const LearningTone({
    required this.surface,
    required this.ink,
    required this.accent,
  });

  /// The flat pastel fill. Never a gradient.
  final Color surface;

  /// Body and title colour on top of [surface].
  final Color ink;

  /// The saturated form of the same hue, for icons, numerals and progress.
  final Color accent;
}

/// Light-mode pastel and its saturated partner, per subject.
/// The pastel squares from the reference subject grid.
const _subjectSpec = <StemSubject, (Color, Color)>{
  StemSubject.mathematics: (AppColors.tilePink, Color(0xFFC8467F)),
  StemSubject.physics: (AppColors.tileBlue, Color(0xFF2F74B0)),
  StemSubject.chemistry: (AppColors.tileLavender, AppColors.violet),
  StemSubject.biology: (AppColors.tileGreen, Color(0xFF3D8238)),
  StemSubject.technology: (AppColors.tileMint, Color(0xFF1F7D6B)),
  StemSubject.other: (AppColors.tileYellow, Color(0xFFA9760F)),
};

/// Dark mode keeps the same hues but composites them onto the raised surface
/// instead of inverting, so a pastel stays recognisably itself.
Color _darkSurface(BuildContext context, Color pastel) => Color.alphaBlend(
  // Enough of the hue to separate a done card from a not-started one at a
  // glance, without lifting the surface to the brightness of a light theme.
  pastel.withValues(alpha: .12),
  context.riksa.surfaceRaised,
);

Color _darkAccent(BuildContext context, Color accent) =>
    Color.lerp(accent, context.riksa.ink, .38)!;

/// Identity tone. Use on a subject's own tile and on its roadmap header.
LearningTone subjectTone(BuildContext context, StemSubject subject) {
  final (pastel, accent) = _subjectSpec[subject]!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return LearningTone(
    surface: isDark ? _darkSurface(context, pastel) : pastel,
    ink: context.riksa.ink,
    accent: isDark ? _darkAccent(context, accent) : accent,
  );
}

/// Where a lesson or unit sits in the learner's path.
enum LearningStatus {
  /// The single thing the learner can resume right now.
  current,

  /// Finished.
  done,

  /// Reachable but not started.
  todo,

  /// Gated behind earlier work.
  locked,

  /// The end of a roadmap. Not a lesson, a destination.
  goal,
}

/// State tone. Use for everything inside a roadmap, and for nothing outside it.
LearningTone statusTone(BuildContext context, LearningStatus status) {
  final palette = context.riksa;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  (Color, Color) spec = switch (status) {
    LearningStatus.current => (palette.brandSoft, palette.brand),
    LearningStatus.done => (palette.jadeSoft, palette.jadeStrong),
    LearningStatus.goal => (palette.saffronSoft, palette.saffron),
    LearningStatus.todo ||
    LearningStatus.locked => (palette.surface, palette.inkMuted),
  };

  if (status == LearningStatus.todo || status == LearningStatus.locked) {
    return LearningTone(
      surface: palette.surface,
      // Locked content is quieted with a muted ink, never with opacity, so it
      // keeps its contrast ratio at large text scales.
      ink: status == LearningStatus.locked ? palette.inkFaint : palette.ink,
      accent: status == LearningStatus.locked
          ? palette.inkFaint
          : palette.inkMuted,
    );
  }

  return LearningTone(
    surface: isDark ? _darkSurface(context, spec.$1) : spec.$1,
    ink: palette.ink,
    accent: isDark ? _darkAccent(context, spec.$2) : spec.$2,
  );
}

/// The inverse surface used for primary actions.
Color learningAnchor(BuildContext context) => context.riksa.anchor;

/// Foreground for content sitting on [learningAnchor].
Color onLearningAnchor(BuildContext context) => context.riksa.onAnchor;
