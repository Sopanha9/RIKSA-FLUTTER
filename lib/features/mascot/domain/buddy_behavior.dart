import 'mascot.dart';

enum BuddyEvent {
  appHomeArrival,
  resumeLessonAvailable,
  lessonStarted,
  answerCorrect,
  answerIncorrect,
  reflectionSubmitted,
  lessonCompleted,
  streakMilestone,
  rankImproved,
  communityJoined,
  postPublished,
  commentPublished,
  aiHelpOpened,
  emptyLearningPath,
  recoverableError,
  returnedAfterBreak,
}

enum BuddyPresentation { hidden, inline, earnedMoment }

enum BuddySpeechPolicy { never, proactiveOncePerSession, earned }

/// A UI-independent decision describing how the learner's buddy responds.
class BuddyReaction {
  const BuddyReaction({
    required this.presentation,
    required this.face,
    required this.priority,
    required this.speechPolicy,
    this.mood,
    this.speechKey,
  });

  final BuddyPresentation presentation;
  final MascotFace face;
  final MascotMood? mood;
  final String? speechKey;
  final int priority;
  final BuddySpeechPolicy speechPolicy;

  bool get speechAllowed => speechPolicy != BuddySpeechPolicy.never;

  BuddyReaction withoutAutonomousReaction() => const BuddyReaction(
    presentation: BuddyPresentation.inline,
    face: MascotFace.neutral,
    priority: 0,
    speechPolicy: BuddySpeechPolicy.never,
  );
}

/// Pure policy shared by every screen; widgets only render its result.
abstract final class BuddyBehavior {
  static BuddyReaction resolve(
    BuddyEvent event, {
    bool reactionsEnabled = true,
  }) {
    final reaction = switch (event) {
      BuddyEvent.appHomeArrival => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.happy,
        priority: 10,
        speechKey: 'buddyHomeGreeting',
        speechPolicy: BuddySpeechPolicy.proactiveOncePerSession,
      ),
      BuddyEvent.returnedAfterBreak => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.determined,
        priority: 12,
        speechKey: 'buddyWelcomeBack',
        speechPolicy: BuddySpeechPolicy.proactiveOncePerSession,
      ),
      BuddyEvent.resumeLessonAvailable => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.determined,
        priority: 8,
        speechPolicy: BuddySpeechPolicy.never,
      ),
      BuddyEvent.lessonCompleted => const BuddyReaction(
        presentation: BuddyPresentation.earnedMoment,
        face: MascotFace.proud,
        mood: MascotMood.trophy,
        priority: 100,
        speechKey: 'buddyLessonCompleted',
        speechPolicy: BuddySpeechPolicy.earned,
      ),
      BuddyEvent.rankImproved => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.proud,
        mood: MascotMood.trophy,
        priority: 80,
        speechKey: 'buddyRankImproved',
        speechPolicy: BuddySpeechPolicy.earned,
      ),
      BuddyEvent.communityJoined => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.happy,
        priority: 50,
        speechKey: 'buddyCommunityJoined',
        speechPolicy: BuddySpeechPolicy.earned,
      ),
      BuddyEvent.answerCorrect ||
      BuddyEvent.reflectionSubmitted => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.proud,
        priority: 30,
        speechPolicy: BuddySpeechPolicy.never,
      ),
      BuddyEvent.answerIncorrect => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.thinking,
        priority: 30,
        speechPolicy: BuddySpeechPolicy.never,
      ),
      BuddyEvent.aiHelpOpened ||
      BuddyEvent.emptyLearningPath => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.thinking,
        priority: 20,
        speechPolicy: BuddySpeechPolicy.never,
      ),
      BuddyEvent.recoverableError => const BuddyReaction(
        presentation: BuddyPresentation.hidden,
        face: MascotFace.oops,
        priority: 5,
        speechPolicy: BuddySpeechPolicy.never,
      ),
      BuddyEvent.lessonStarted => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.determined,
        priority: 20,
        speechPolicy: BuddySpeechPolicy.never,
      ),
      BuddyEvent.streakMilestone => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.happy,
        priority: 60,
        speechPolicy: BuddySpeechPolicy.never,
      ),
      BuddyEvent.postPublished ||
      BuddyEvent.commentPublished => const BuddyReaction(
        presentation: BuddyPresentation.inline,
        face: MascotFace.wink,
        priority: 25,
        speechPolicy: BuddySpeechPolicy.never,
      ),
    };
    return reactionsEnabled ? reaction : reaction.withoutAutonomousReaction();
  }
}
