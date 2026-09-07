/// The feedback moments that make a sound.
///
/// Each value names one file in `assets/audio/`. Swapping the audio is a file
/// copy — nothing outside this enum knows what a cue sounds like.
enum LearningSound {
  /// An exercise answered correctly.
  correct('correct.wav'),

  /// An exercise answered incorrectly. Deliberately gentle: a learner hears
  /// this most often, and a harsh cue punishes the moment they need to retry.
  wrong('wrong.wav'),

  /// Every exercise in a section answered.
  sectionComplete('section_complete.wav'),

  /// A whole lesson finished.
  lessonComplete('lesson_complete.wav'),

  /// An achievement, rank or streak milestone.
  achievement('achievement.wav');

  const LearningSound(this.asset);

  /// Path relative to the `assets/audio/` directory.
  final String asset;

  /// How strongly the device should buzz alongside the sound.
  ///
  /// Haptics carry the feedback when the phone is muted, which on a school
  /// device is most of the time.
  LearningHaptic get haptic => switch (this) {
    LearningSound.correct => LearningHaptic.light,
    LearningSound.wrong => LearningHaptic.heavy,
    LearningSound.sectionComplete => LearningHaptic.medium,
    LearningSound.lessonComplete => LearningHaptic.medium,
    LearningSound.achievement => LearningHaptic.medium,
  };
}

enum LearningHaptic { light, medium, heavy }
