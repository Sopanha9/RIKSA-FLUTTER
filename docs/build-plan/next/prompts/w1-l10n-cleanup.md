# Task
Remove every user-visible "TODO(km)" placeholder and hard-coded English string found by the audit, and delete one unused file.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, gen-l10n (`lib/l10n/app_en.arb`, `app_km.arb`, generated `lib/l10n/gen/`).

# Relevant files
- lib/l10n/app_km.arb ~L787–805 — 12 values literally start with `TODO(km): `: `buddyCareTitle`, `buddyCareLesson`, `buddyCareRead`, `buddyCareShare`, `buddyChooseAction`, `buddyCareProgress`, `buddyEnergyLively`, `buddyEnergySteady`, `buddyEnergySleepy`, `buddyEnergyNapping`, `buddyLessonEnergyLine`, `buddyReadEnjoyed`. The English originals are in app_en.arb.
- lib/features/ai/presentation/widgets/ai_study_coach_hub.dart ~L28–72 — coach titles/subtitles hard-coded in English ("Mathematics Coach", "Science Explainer", "Khmer Language Coach", "English Practice", "Grade 12 BakII Prep" + subtitles).
- lib/features/social/presentation/widgets/streak_details_sheet.dart ~L603, ~L622 — `Text('Less')`, `Text('More')` heatmap legend.
- lib/features/blog/presentation/blog_detail_screen.dart ~L292 — `actionLabel: 'Try again'`.
- lib/features/auth/presentation/onboarding_splash_screen.dart ~L685 — semantics label `'Page ${currentPage + 1} of $count'`.
- lib/features/learning/presentation/lesson_experience_screen.dart ~L259 — `message: 'Completed earlier - your progress was restored.'` (the result is built outside `build`; pass the localized string in, or localize where it is displayed).
- lib/features/learning/presentation/widgets/learning_insights.dart — not imported anywhere; English-only.

# Context
Khmer is the first-run default language and the app is a competition entry, so these strings are visible in the demo. Some screens use a local `_t('English', 'ខ្មែរ')` helper for inline bilingual text; that pattern is acceptable where it already exists, but new work goes in the ARB files.

# Do
1. Replace the 12 `TODO(km): …` values with natural, short Khmer translations of the English originals. Keep placeholders (`{name}`, `{count}`) exactly. Mark each of these 12 in your final message as "needs native review".
2. Move the coach-hub titles/subtitles to l10n keys prefixed `aiCoach…` with English + Khmer values.
3. Heatmap legend → keys `heatmapLess` / `heatmapMore` (or reuse existing keys if equivalent ones exist — search the ARB first).
4. "Try again" → reuse an existing retry key if one exists (search for `retry`/`tryAgain`), otherwise add one.
5. Onboarding page semantics → a plural/placeholder key.
6. Restored-progress message → key `lessonRestoredProgress`.
7. Delete `learning_insights.dart` after confirming (by reading imports across lib/ and test/) that nothing references it. If something does, stop and report instead of deleting.
8. Run `flutter gen-l10n`. Add or update a test that fails if any app_km.arb value starts with `TODO` (a simple ARB-parsing unit test under test/l10n/).
9. Update any golden/widget tests whose expected text changes; if a golden changes, regenerate only that golden and list it.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not change layout, colors, or behavior — strings only.
- Do not modify files outside: lib/l10n/**, the five widget files listed above, lib/features/learning/presentation/lesson_experience_screen.dart (only the restored-message string), lib/features/learning/presentation/widgets/learning_insights.dart (delete), test/l10n/**, and tests/goldens that assert the changed strings.
- Do not add dependencies.

# Deliverable
Changed files, each new/changed key with its en + km value (as a table), the real output of `flutter analyze` and `flutter test`, and the list of Khmer strings needing native review.

# Risks
End with a "## Risks" section.
