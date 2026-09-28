# Task
Make the RIKSA lesson flow (Read → Respond → Reflect, plus feedback and completion) feel calm, focused and clean. Keep all behaviour and keep RIKSA's own identity. This is a visual and layout refactor, not a feature change.

# Repo
This directory (`RIKSA-FLUTTER`), branch `staging`. Flutter, Riverpod 3, go_router. Bilingual en/km (Khmer is the first-run default; Khmer script needs more line height than Latin). A competition entry judged on Best UX/UI. **The rules forbid copying designs from other apps**: apply the principles below with RIKSA's own palette, buddy and type. Do not reproduce another product's layout.

# Relevant files
- `lib/features/learning/presentation/lesson_experience_screen.dart` (2370 lines):
  - `_LessonBarDelegate`: top bar with ←, "1 / 2", AI and ⋯ buttons, and a separate progress bar;
  - `_LessonIdentity`, `_LessonBuddyScene` (mascot banner), `_JourneyStages` (1 Read · 2 Respond · 3 Reflect);
  - `_ExerciseCard`, `_ChoiceAnswers`, `_Feedback`, `_AskTutorButton`, `_LessonResourcesCallout`;
  - `_StepCounter` and phase/flow classes.
- `lib/features/learning/presentation/learning_result_screens.dart`: `LessonCompletionScreen`.
- `lib/features/learning/presentation/learning_design.dart`, `widgets/learning_atoms.dart`, `widgets/learning_status_bar.dart`: shared learning styles.
- `lib/core/theme/app_theme.dart`: `context.riksa` palette, `AppRadii`, `RiksaSpacing`, `RiksaTypography`, `RiksaMotion` (use `RiksaMotion.resolve` for every animation, so reduced motion is respected).
- `lib/core/widgets/riksa_back_button.dart`: the shared back control (keep using it; keep the lesson's existing exit/unsaved-progress behaviour).
- Tests:
  - `test/features/learning/presentation/lesson_experience_screen_test.dart` and `lesson_journey_test.dart`: keep them green; keep the `ValueKey`s they use, or update the tests with the same intent;
  - goldens in `test/visuals/lesson_experience_golden_test.dart` (`lesson_reading/working/practice/feedback/reflection/completion_en_light.png`, `lesson_reading_en_dark.png`).

# What is noisy today (from the current goldens)
- The top bar has ←, "1 / 2", a round AI button and a round ⋯ button, then a second progress bar under them.
- There's text nobody needs: "0 of 1 responses checked", "Your working:" with a pencil, and "Compare your working and choose an answer."
- Cards sit inside cards: a white card on a grey canvas holding lavender answer tiles. The selected answer turns **solid black**, the heaviest element on the screen.
- The mascot banner repeats on the practice step, cropped at the top.
- The feedback panel repeats itself: "That's it…", then "Correct.", then "Explanation" label and body, inline in a green block that pushes content down.
- The bottom primary button has a doubled shadow.

# Target
1. **Top bar:** an exit control on the start side, **one** thin progress bar filling the middle (it replaces "1 / 2"), and one quiet trailing control. Put the AI tutor, hint, scratch work, resources, report and sound in a single ⋯ sheet, or one quiet row.
2. **Flat surfaces:** the page canvas plus content. No card-in-card. Answers are rows with a 1 px outline on the canvas/surface colour. Shadows only on the bottom action, and a single one (fix the doubled shadow).
3. **The question is the hero:** larger question type, generous spacing, content width capped (~640) on wide screens. The illustration/banner shows **only on the Read step** (and smaller); practice steps don't show it.
4. **Answers:**
   - idle: outline;
   - selected: brand-coloured outline + light brand tint + brand letter badge, **not** solid black;
   - after Check: correct = success colour, wrong = error colour on the chosen row, and the correct one marked.
   - Keep 48 px minimum hit areas.
5. **Primary action:** fixed at the bottom. "Check" stays **disabled until an answer is chosen**, then becomes "Continue" after feedback.
6. **Feedback:** a bottom panel that slides up over the action area (success or error tint). One line such as "Correct! 6 N" or "Not quite", a small buddy, and a "Why?" expander for the explanation. The page content underneath doesn't jump. Remove the duplicated "Correct." and "Explanation" labels.
7. **Remove** "N of M responses checked" (the progress bar says it) and the extra instruction lines. Keep the scratch-work feature reachable from the ⋯ sheet or a small icon, not as a labelled row.
8. **Journey stages** (Read · Respond · Reflect): keep them, but lighter. Either merge them into the progress bar as segments, or show them as a small caption. Pick one and apply it consistently.
9. **Completion screen:** same calm style. One hero result (XP / streak), one primary action, one secondary.
10. **Khmer:** body line height ≥ 1.5 for Khmer text (use `RiksaTypography.bodyStyleFor` / the existing Khmer-aware helpers) and never clip stacked glyphs. Remove any user-facing text you delete from **both** ARB files. New text goes in both ARBs with the `lesson…` prefix (natural Khmer; it will be reviewed).
11. **Dark mode** must look intentional. Check every colour through `context.riksa` tokens; no raw `Colors.white` surfaces.

# Do
1. Implement the target in the listed files. Prefer extracting small private widgets or new files under `lib/features/learning/presentation/widgets/lesson/` over growing the 2370-line screen; moving code out of it is welcome.
2. Keep every behaviour: answer checking, hints, AI tutor entry, resources, exit guard, XP award, completion routing, deep-link back behaviour, reduced motion, and screen-reader semantics (announce correct/incorrect).
3. Tests:
   - Check is disabled before a selection;
   - the selected answer uses the brand outline, not a black fill;
   - the feedback panel shows one result line and expands "Why?";
   - the banner is absent on the practice step;
   - the Khmer locale renders the practice step without overflow.
   Update existing tests only where the UI intentionally changed.
4. You cannot run Flutter in this sandbox (the SDK cache is outside the workspace). Write carefully; the orchestrator runs `flutter analyze`, `flutter test`, and reviews every golden diff visually. Do **not** run `--update-goldens`. List the goldens you expect to change.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside `lib/features/learning/presentation/**`, `lib/l10n/**` (only `lesson…` keys, plus removing keys you made unused), and `test/features/learning/**` / `test/visuals/lesson_experience_golden_test.dart`.
- Do not change `lib/core/theme/**`, the router, the bottom navigation bar, providers/data layers, or the lesson catalog/roadmap screens.
- Do not add dependencies, fonts or images.
- Do not copy another product's layout or styling.

# Deliverable
Changed/new files, a before → after note per target item, l10n keys added/removed, tests added/changed, expected golden changes, and anything unverified because Flutter couldn't run.

# Risks
End with a "## Risks" section.
