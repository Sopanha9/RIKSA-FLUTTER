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

/// Violet is reserved for "this is the thing you can do right now".
const _currentPastel = AppColors.violetSoft;
const _currentAccent = AppColors.violet;
const _donePastel = Color(0xFFDDF0DC);
const _doneAccent = Color(0xFF2F7A44);
const _goalPastel = Color(0xFFFBEBCD);
const _goalAccent = Color(0xFFB57E14);

/// Dark mode keeps the same hues but composites them onto the raised surface
/// instead of inverting, so a pastel stays recognisably itself.
Color _darkSurface(BuildContext context, Color pastel) => Color.alphaBlend(
  // Enough of the hue to separate a done card from a not-started one at a
  // glance, without lifting the surface to the brightness of a light theme.
  pastel.withValues(alpha: .12),
  context.riksa.surfaceRaised,
);

Color _darkAccent(Color accent) => Color.lerp(accent, Colors.white, .38)!;

/// Identity tone. Use on a subject's own tile and on its roadmap header.
LearningTone subjectTone(BuildContext context, StemSubject subject) {
  final (pastel, accent) = _subjectSpec[subject]!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return LearningTone(
    surface: isDark ? _darkSurface(context, pastel) : pastel,
    ink: context.riksa.ink,
    accent: isDark ? _darkAccent(accent) : accent,
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
    LearningStatus.current => (_currentPastel, _currentAccent),
    LearningStatus.done => (_donePastel, _doneAccent),
    LearningStatus.goal => (_goalPastel, _goalAccent),
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
    accent: isDark ? _darkAccent(spec.$2) : spec.$2,
  );
}

/// The one near-black used for every primary action. Warm, never `#000000`.
Color learningAnchor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.editorialPink
    : AppColors.editorialAubergine;

/// Foreground for content sitting on [learningAnchor].
Color onLearningAnchor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.deepInk
    : const Color(0xFFFFF7FB);
