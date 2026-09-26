# Task
Stop hitting guests with a sign-up wall on their first answer, and make finishing a lesson one tap.

# Repos
- API: C:\Users\dvdphobia\Desktop\workspaces\RIKSA (Spring Boot). Read AGENTS.md first.
- App: C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER (Flutter + Riverpod).
You run in ONE repo (the -C one). Do only that half.

# Relevant files
API:
- src/main/java/com/riksa/learning/controller/LessonController.java, LearningProgressController.java
- src/main/java/com/riksa/learning/service/ — answer checking and LessonCompletionService
- src/main/java/com/riksa/auth/security/SecurityConfig.java
App:
- lib/features/learning/presentation/lesson_experience_screen.dart — `_submitAnswer` (~line 762) and `_complete` (~line 800) both call `requireAccount` first; `_LessonPhase.reflecting` and "Tap how it went to finish" block completion
- lib/features/learning/data/learning_api.dart
- lib/features/auth/presentation/require_account.dart

# Context
User testing: guests may read lessons, but the first "Check answer" demands an account after they typed an answer. That is the moment people quit. Also finishing requires a confidence choice plus a reflection screen; learners want one tap.

Contract: `POST /api/v1/learning/lessons/{lessonId}/exercises/{exerciseId}/check` body `{ "answer" }` → the same result shape as the signed-in submit, public, stores nothing, awards nothing, rate limited per IP (30/min → 429).

# Do — API half
1. Add the public check endpoint reusing the existing checking logic (no duplication), plus the rate limit.
2. Tests: correct/incorrect, nothing persisted, no XP, 429.

# Do — App half
1. Guests use the public check for their first 3 checked answers (count stored locally, try/catch). On the 3rd correct answer or on completing the lesson, show a friendly "Save your progress" sheet (buddy line) with sign-in — then continue where they were.
2. Signed-in flow unchanged.
3. Completion: a single "Finish lesson" button. Confidence becomes an optional one-tap row on the completion screen ("I can explain it" / "I want to revisit it"); reflection text becomes optional and collapsed. If skipped, send `needsReview: false` / empty notes (check what the API accepts and say so).
4. Update tests in test/features/learning/presentation/ (lesson_experience_screen_test, lesson_journey_test) and regenerate affected goldens under test/visuals only if the change is intended; list them.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- API: only src/main/java/com/riksa/learning/**, SecurityConfig.java (permit rule), src/test/java/com/riksa/learning/**.
- App: only lib/features/learning/**, lib/l10n/**, test/features/learning/**, test/visuals/** (lesson goldens).
- Do not touch the bottom navigation bar.

# Deliverable
Changed files, real test output, list of regenerated goldens.

# Risks
End with a "## Risks" section.
