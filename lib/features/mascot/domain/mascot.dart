/// The study buddy a learner picks during first run.
enum MascotSpecies { crocodile, capybara }

/// What the mascot is doing. Every species has art for every mood, so a
/// screen can ask for a mood without knowing which buddy the learner chose.
///
/// [treat] is the reward pose: the crocodile eats an ice cream, the capybara
/// studies with its books.
enum MascotMood {
  idle,
  happy,
  sad,
  thinking,
  sleep,
  celebrate,
  greeting,
  treat,
  love,
  walk,
  trophy,
}

/// Where each mood's frames live and how long one loop of them takes.
///
/// Frames are `assets/images/mascots/<species>/<mood>_<n>.png`, numbered from
/// 1. A mood can have any number of frames, and each species its own count:
/// dropping in a longer animation strip only needs the files and the count
/// below. Timing is set per loop, so more frames play smoother, not slower.
abstract final class MascotSprites {
  /// Pixel height of each species' upscaled idle pose (`idle_1.png`), used to
  /// draw every frame at the same character scale regardless of canvas size.
  static const idlePixelHeights = {
    MascotSpecies.crocodile: 375,
    MascotSpecies.capybara: 336,
  };

  static int idlePixelHeight(MascotSpecies species) =>
      idlePixelHeights[species]!;

  /// Per-species counts: each buddy's animation strips were drawn
  /// separately, so their lengths differ.
  static const _frameCounts = {
    MascotSpecies.crocodile: {
      MascotMood.idle: 3,
      MascotMood.happy: 10,
      MascotMood.sad: 6,
      MascotMood.thinking: 7,
      MascotMood.sleep: 9,
      MascotMood.celebrate: 8,
      MascotMood.greeting: 10,
      MascotMood.treat: 6,
      MascotMood.love: 8,
      MascotMood.walk: 8,
      MascotMood.trophy: 6,
    },
    MascotSpecies.capybara: {
      MascotMood.idle: 3,
      MascotMood.happy: 10,
      MascotMood.sad: 7,
      MascotMood.thinking: 7,
      MascotMood.sleep: 9,
      MascotMood.celebrate: 9,
      MascotMood.greeting: 9,
      MascotMood.treat: 7,
      MascotMood.love: 7,
      MascotMood.walk: 8,
      MascotMood.trophy: 6,
    },
  };

  /// One full cycle of each mood. Slow moods read as calm, quick ones as
  /// excited; the walk is fast enough to read as steps.
  static const _loopDurations = {
    MascotMood.idle: Duration(milliseconds: 3600),
    MascotMood.happy: Duration(milliseconds: 2000),
    MascotMood.sad: Duration(milliseconds: 3400),
    MascotMood.thinking: Duration(milliseconds: 3600),
    MascotMood.sleep: Duration(milliseconds: 4800),
    MascotMood.celebrate: Duration(milliseconds: 1800),
    MascotMood.greeting: Duration(milliseconds: 2000),
    MascotMood.treat: Duration(milliseconds: 3000),
    MascotMood.love: Duration(milliseconds: 2800),
    MascotMood.walk: Duration(milliseconds: 1200),
    MascotMood.trophy: Duration(milliseconds: 2400),
  };

  static int frameCount(MascotSpecies species, MascotMood mood) =>
      _frameCounts[species]![mood]!;

  static List<String> frames(MascotSpecies species, MascotMood mood) => [
    for (var i = 1; i <= frameCount(species, mood); i++)
      'assets/images/mascots/${species.name}/${mood.name}_$i.png',
  ];

  static Duration frameDuration(MascotSpecies species, MascotMood mood) =>
      _loopDurations[mood]! ~/ frameCount(species, mood);

  /// One full play of a mood, which is also how long a reaction lasts.
  static Duration loopDuration(MascotMood mood) => _loopDurations[mood]!;

  /// Whether a mood's drawings fade into each other. Calm moods change a
  /// little between drawings, so a short fade smooths them; big moves (a
  /// jump, a wave, steps) change too much and a fade would show two bodies
  /// at once, so they cut cleanly like hand-drawn animation.
  static bool blends(MascotMood mood) => switch (mood) {
    MascotMood.idle ||
    MascotMood.sad ||
    MascotMood.sleep ||
    MascotMood.thinking ||
    MascotMood.love ||
    MascotMood.treat => true,
    MascotMood.happy ||
    MascotMood.celebrate ||
    MascotMood.greeting ||
    MascotMood.walk ||
    MascotMood.trophy => false,
  };

  /// Every frame of one species, for precaching before the mascot appears.
  static Iterable<String> allFrames(MascotSpecies species) =>
      MascotMood.values.expand((mood) => frames(species, mood));
}

/// Head-only expressions for small places: avatars, chat, quiz feedback,
/// notifications. Both buddies have every face.
enum MascotFace {
  neutral,
  happy,
  laughing,
  wink,
  love,
  proud,
  cool,
  determined,
  surprised,
  shy,
  thinking,
  confused,
  oops,
  nervous,
  annoyed,
  sad,
  crying,
  dizzy,
  sleepy,
  silly,
}

/// Face frames live at `assets/images/mascots/<species>/faces/<face>_<n>.png`.
abstract final class MascotFaceSprites {
  static const frameCount = 4;

  static const _loopDurations = {
    MascotFace.neutral: Duration(milliseconds: 3200),
    MascotFace.laughing: Duration(milliseconds: 800),
    MascotFace.crying: Duration(milliseconds: 1000),
    MascotFace.dizzy: Duration(milliseconds: 900),
    MascotFace.nervous: Duration(milliseconds: 1000),
    MascotFace.sad: Duration(milliseconds: 2200),
    MascotFace.sleepy: Duration(milliseconds: 2600),
    MascotFace.thinking: Duration(milliseconds: 2400),
  };

  /// How long each frame holds, relative to the others. A resting face
  /// mostly holds its first frame, so the blink stays a blink.
  static const _holds = {
    MascotFace.neutral: [8, 1, 1, 4],
    MascotFace.wink: [4, 1, 3, 1],
    MascotFace.cool: [4, 2, 2, 2],
  };

  static List<String> frames(MascotSpecies species, MascotFace face) => [
    for (var i = 1; i <= frameCount; i++)
      'assets/images/mascots/${species.name}/faces/${face.name}_$i.png',
  ];

  static Duration loopDuration(MascotFace face) =>
      _loopDurations[face] ?? const Duration(milliseconds: 1400);

  static List<int> holds(MascotFace face) => _holds[face] ?? const [1, 1, 1, 1];
}
