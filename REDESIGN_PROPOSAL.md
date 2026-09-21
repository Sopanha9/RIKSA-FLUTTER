# Riksa — UX/UI Redesign Proposal

> Based on a full scan of `lib/` on branch `develop` (138 Dart files, ~52.6k LOC),
> read against [PRODUCT.md](PRODUCT.md) and [DESIGN.md](DESIGN.md).
> Nothing was modified to produce this document.

---

## 0. Verdict first

**Riksa does not need a visual redesign. It needs a consolidation.**

The look is already good and, in places, genuinely well-argued — the learning tab,
the roadmap, the lesson player and the motion system are the work of someone who
read PRODUCT.md and meant it. Localization, which the last handoff flagged as the
big gap, is now in excellent shape: 719 of 731 keys translated, and the only eight
English-identical values are proper nouns and number formats.

What has gone wrong is **drift**. The design system was rewritten from aubergine
to violet without the documentation, the feature palettes or the oldest screens
following it. The result is one app running three parallel color systems, a spec
document that would make a designer ship the wrong palette, and a newest-built
screen that breaks the product's single loudest rule.

So this proposal is ranked by damage, not by screen. Five problems. The first two
are worth more than the other three combined.

**Out of scope:** the bottom navigation bar (`riksa_bottom_navigation_bar.dart`)
and anything about tab count, labels or the center AI action. That is being
redesigned separately and is not touched here.

---

## 1. The five problems

### P1 — The spec and the code disagree about what the app looks like

`DESIGN.md` is the document a designer or a new engineer would read first. It is
now wrong about nearly every token it defines.

| DESIGN.md says | `app_theme.dart` actually does |
|---|---|
| Action anchor is aubergine `#2A061D` | `editorialAubergine = violet #7657EE` ([app_theme.dart:51](lib/core/theme/app_theme.dart#L51)) |
| Dark-mode accent is pink `#EE8FD0` | `editorialPink = #9D86F7`, a violet |
| Dark ground is true black `#000000`, X "Lights out" | `darkCanvas = #111113`, with a comment explicitly rejecting purple-black |
| Radii 13 / 15 / 20 / 24 / 32 | 8 / 13 / 14 / 16 / 16 / 20 / 24 / 28 |
| "Buttons are always full pills at 54dp" | 54dp appears once, in `IllustratedEmptyState` |
| Pastel `Mint #DDF0DC` = done, `Cream #FBEBCD` = goal | Those exact values live in `learning_design.dart`, not in the palette |

The `editorial*` names are now pure misdirection: eleven constants named after a
color scheme the app no longer uses, aliased to a different one. `editorialMint`
resolves to `limeSoft`. `editorialAubergineRaised` resolves to `darkSurfaceRaised`.

This is not cosmetic. Any redesign work that starts from DESIGN.md starts from a
palette that was replaced.

### P2 — Three color systems, and one of them has stopped meaning anything

DESIGN.md's rule is unambiguous: tokens are reached "through `context.riksa` …
never by importing raw `AppColors` into feature code."

**23 feature files import and use `AppColors` directly**, some heavily:
`interactive_onboarding_screen.dart` (25 uses), `profile_ui.dart` (24),
`leaderboard_podium.dart` (18), `streak_details_sheet.dart` (16).

On top of that sit three feature-local shadow palettes that each re-derive what
`RiksaPalette` already provides:

- `SocialPalette` — [social_palette.dart](lib/features/social/presentation/widgets/social_palette.dart)
- `ProfilePalette` + `ProfilePaletteScope` — [profile_ui.dart:10](lib/features/userProfile/presentation/widgets/profile_ui.dart#L10)
- `LearningTone` — [learning_design.dart:112](lib/features/learning/presentation/learning_design.dart#L112)

`SocialPalette` is the clearest casualty of the violet migration. Its names no
longer describe its values:

```dart
static Color green(BuildContext context) => pink(context);   // returns violet
static Color aubergine(BuildContext context) => ... AppColors.editorialAubergine; // violet
static Color panel(...) => surface(...);   // dead alias
static Color border(...) => outline(...);  // dead alias
static Color text(...) => ink(...);        // dead alias
```

`SocialPalette.green()` is what paints the Home feed's refresh indicator. It is
violet. A developer reading that call site learns nothing true.

**There are also two competing subject-hue systems.** `RiksaPalette` carries
`math/science/language/technology/humanities/general` with DESIGN.md's values
(Math `#76528F` purple, Biology `#198A82` teal). `learning_design.dart`'s
`_subjectSpec` ignores them and assigns its own (Math `#C8467F` pink, Chemistry
violet, Biology `#3D8238` green). Learning uses the second. The first is
near-dead weight — and `language` and `humanities` describe subjects the product
explicitly does not ship ("Scope today: STEM only").

### P3 — The onboarding is the one thing PRODUCT.md forbids

`interactive_onboarding_screen.dart` is 1,746 lines, the second-largest file in
the app, and the most recently built major screen. Its flow is:

> Goal → Subject → Province → Pace → **Quiz 1** → **Quiz 2** → **Payoff**

with button copy that reads, verbatim:

> `'Start Challenge'` → `'Next Challenge'` → `'Claim Reward'`

Against PRODUCT.md:

- *"Explicit anti-pattern: QCM / multiple choice as the core loop… Any future checking mechanic must require the learner to **produce** something, not select something."* — `_QuizStep` is four lettered options, A–D, with a correct index.
- *"Anti-reference: **Duolingo.** Mascots, streak guilt, cartoon celebration."* — a two-question multiple-choice challenge with a reward claim in the first sixty seconds is that pattern precisely.
- *"Never cute, never congratulatory beyond what was actually earned."* — nothing has been earned yet. The user has not read a lesson.
- *"Sessions are 5–20 minutes… stolen time."* — seven full-screen steps stand between install and the login screen, before any content.

It is also **the app's only unlocalized screen**. Zero `AppLocalizations`
references; 36 inline `lang == 'km' ? … : …` ternaries, plus 10 more in
`onboarding_models.dart`. Every other feature migrated to ARB. This one shipped
after, and shipped around it.

### P4 — Roughly 2,500 lines of screens nobody can reach

Verified unreferenced by any navigation or import:

| File / route | LOC | Note |
|---|---|---|
| `leaderBoard/leaderboard_screen.dart` | 1,055 | Superseded by `presentation/leaderboard_screen.dart`; imported by nothing |
| `dashboard/home_dashboard_screen.dart` + `widgets/home_sections.dart` | 599 | `/dashboard` — the **only** route that links `/community` and `/learn/resume` |
| `blog/blog_feed_screen.dart` | 358 | `/blog` — blog ships as a tab inside the Home feed |
| `auth/language_select_screen.dart` | 302 | **Now fully orphaned.** Splash handles language inline via its `_welcoming` state; nothing routes to `/language-select` |
| `userProfile/profile_setup_overview_screen.dart` | ~150 | `/profile/setup` — unreachable |
| `learning/widgets/learning_insights.dart` | — | Never imported |
| `auth/login_screen.dart`, `register_screen.dart`, `core/widgets/riksa_logo.dart` | 41 | Empty wrappers |

Plus seven unused components inside `riksa_components.dart` (`DailyMissionCard`,
`LessonCard`, `LessonCardSkeleton`, `FilterBottomSheet`, `RiksaChoicePill`,
`RiksaSectionHeader`, `ActiveFilterChip`).

`ResumeLearningScreen` is reachable only from the orphaned dashboard, so
"resume an in-progress lesson" is a built, working, invisible feature.

**Province is asked twice**, in two different UIs: `_ProvinceStep` inside the
interactive onboarding, and the standalone `/province-select` screen the splash
still routes to on a legacy branch.

### P5 — Two live bugs and a Khmer-sized hole in the test net

1. **Broken link, still present.** [leaderboard_screen.dart:129](lib/features/leaderBoard/presentation/leaderboard_screen.dart#L129) pushes `/auth/province`, which is not a registered route. The real one is `/province-select`. The empty-leaderboard CTA is dead.
2. **Content scrolls under the floating nav bar.** The bar is 60dp plus safe area, drawn with `extendBody: true`. DESIGN.md requires every tab root to reserve ~112dp. Exactly one file does — `blog_detail_screen.dart:324`. The Learn tab is worse than the rest: it wraps in `SafeArea(bottom: false)` and then pads the list to 24dp ([lesson_catalog_screen.dart:78](lib/features/learning/presentation/lesson_catalog_screen.dart#L78)), while its own skeleton state pads to 160.
3. **Khmer is barely golden-tested.** 70 goldens; 11 are Khmer, and 8 of those are the Telegram auth flow and the nav bar. `learning_home`, `social_feed`, `user_profile`, `leaderboard`, `subject_roadmap`, `lesson_reading` and every blog screen have **no Khmer golden at all** — against a stated principle that layouts must survive text 40% longer and taller. Text-scale goldens (`2.0`) exist only for the nav bar, and only four files in the whole app consult `MediaQuery.textScalerOf`.

---

## 2. The proposal

### Phase 1 — Make one palette true (highest value, lowest risk)

The goal is that `context.riksa` is the only way any feature file gets a color.

1. **Rewrite `DESIGN.md` to describe violet/lime.** Do this first. Until it is
   true, every other decision gets re-litigated. Include the real radius ladder,
   the real dark ground, and the real subject hues.
2. **Delete the `editorial*` alias block** ([app_theme.dart:49–63](lib/core/theme/app_theme.dart#L49)) and the compatibility aliases below it. They are a rename away from gone; `sed` across 23 files, then let the analyzer find the rest.
3. **Fold the three feature palettes into `RiksaPalette`.**
   - `SocialPalette` → delete outright. Every method either forwards to `context.riksa` already or returns a mis-named constant.
   - `ProfilePalette` → keep only `ProfilePaletteScope`, and only if a per-profile theme override is a real requirement. Every fallback in it is already a `context.riksa` or `colorScheme` lookup.
   - `LearningTone` → **keep**. It is the one that earns its place: it encodes state (current / done / goal / locked) as a hue pair, which is exactly the "difference means difference" principle. But move `_subjectSpec` into `RiksaPalette` so there is a single subject-hue source, and drop `language`/`humanities` from the palette since the product is STEM-only.
4. **Collapse the radius ladder** from nine values to DESIGN.md's six. `large` and `row` are both 16 today, which makes the choice between them meaningless.

*Why first:* it touches no layout, so goldens either pass or reveal a genuine
color change. It is the prerequisite for anyone else designing against this app.

### Phase 2 — Rebuild first run around the product's own thesis

PRODUCT.md: *"'What should I study next?' is the question the product must answer
before anything else."* First run should answer it, not test the learner.

**Proposed flow — four steps, no quiz:**

> Language (keep on splash) → **Goal** → **Subjects** → **Province + Pace** → Auth

Then land on a Learn tab that already has a Continue card pointing at lesson one
of the subject they picked. That is the payoff: not a claimed reward, but a path
that already has their name on it.

Specifically:

- **Delete `_QuizStep` and `_PayoffStep`.** Two multiple-choice questions cannot place a learner, so they are not diagnostic; they are engagement theater, and they are the anti-pattern by name.
- **Merge Province and Pace** onto one step. Province is a single picker; pace is four options. Neither needs a full screen.
- **Delete `/province-select` and `language_select_screen.dart`.** Province lives in onboarding; language lives on the splash. Keeping the standalone copies means two UIs for one answer drifting apart.
- **Localize the whole screen to ARB.** 46 hardcoded ternaries across the screen and its models. This is not optional — it is the flagship screen for a Khmer-first product.
- **Replace the "Claim Reward" moment** with a plain statement of the plan: subject, unit count, and the first lesson's title. Serious, warm, unpatronizing.

*Expected outcome:* seven steps to four, ~1,746 lines to something closer to 900,
and the newest screen stops contradicting the product brief.

### Phase 3 — Delete, then fix the two bugs

1. Remove everything in P4. Before deleting `home_dashboard_screen.dart`, make one call: **`ResumeLearningScreen` is a good feature stranded behind a dead route.** Either surface "in-progress lessons" from the Learn tab's Continue card area, or delete it too. Do not leave it reachable-by-nobody.
2. Fix `/auth/province` → `/province-select` (or, after Phase 2, point it at the onboarding province step).
3. **Introduce one bottom-inset helper** and use it on all five tab roots. The nav bar owns its height; content should ask for it rather than five screens each guessing. Something like a `RiksaTabScrollPadding` constant read from the same source the nav bar uses, so the two cannot drift.

### Phase 4 — Close the Khmer and text-scale gap

Add goldens for the six core screens in `km` at 1.0, and at 2.0 text scale in
`en`, for: Learn home, subject roadmap, lesson reading, social feed, leaderboard,
user profile. This is the guard rail that makes principle 6 ("Khmer-first
typography") enforceable instead of aspirational. Twelve new goldens will find
more real layout breakage than any amount of visual review.

---

## 3. What I deliberately propose leaving alone

- **The bottom navigation bar.** Owned elsewhere, being redesigned.
- **The learning tab, subject roadmap and lesson player.** They are the strongest work in the app and they already implement the product thesis. Phase 1 will change their color *sources*, not their design.
- **The motion system.** `RiksaMotion`, `RiksaEntrance`, `RiksaCountUp` and the reduced-motion handling are well-built and consistently applied.
- **Localization, outside onboarding.** 719/731 is a good number. Do not reopen it.
- **The Home tab being the community feed.** It sits oddly against "the path is the product," but changing the landing tab is a product decision with retention consequences, not a UI cleanup. Flagging it, not proposing it.

---

## 4. Suggested order

| Phase | Work | Risk | Unblocks |
|---|---|---|---|
| 1 | One palette; rewrite DESIGN.md | Low | Everything else, and any outside designer |
| 3 | Delete dead code; fix nav inset + broken link | Low | A smaller surface to reason about |
| 4 | Khmer + text-scale goldens | Low | Safe layout changes afterwards |
| 2 | Rebuild first run | Medium | The product's own brief |

Phase 2 is listed last to *do* and second in *importance* — it is the only one
that changes user-facing behavior, so it should land on a codebase that already
has one palette and a Khmer safety net under it.
