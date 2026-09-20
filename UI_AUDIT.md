# UI System Audit

**Audit date:** 2026-09-20
**Branch:** `merge/sombath-onto-mine` @ `6c6cebb`
**Scope:** 136 non-generated Dart files under `lib/` (45,842 lines), excluding `lib/l10n/gen/**`. Plus routing, design documentation, `test/visuals`, and asset declarations.
**Method:** three parallel read-only workers (two Codex, one Agy on an isolated clone) plus independent verification by the lead auditor. No application file was created, modified, or deleted. Every count below was reproduced by the auditor directly; worker claims that failed verification are listed in the Evidence Appendix and were dropped.

> **Counting caveat that applies throughout:** all figures are *static source counts*, not runtime paint counts. A token referenced once may render on every screen; a literal in dead code renders never. Where dead code inflates a number, it is called out.

---

## Executive Summary

Riksa is a **Flutter / Material 3** application (Riverpod + go_router). It is not native Android; no Compose or XML-Views code exists.

The app has a genuinely good design-system *foundation*. `lib/core/theme/app_theme.dart` (930 lines) defines a complete Material 3 light **and** dark `ThemeData`, a 30-field semantic `RiksaPalette` `ThemeExtension` reached via `context.riksa`, a 15-role `TextTheme`, spacing/radius/motion tokens, component themes for every major Material widget, and a bilingual Khmer/Latin typography helper. Dark mode is fully wired through a persisted `themeMode` provider. Localization is in excellent shape. Radii and spacing tokens are widely consumed. There is a substantial golden-test suite covering both brightnesses.

The foundation is **not yet authoritative**, and the gap is concentrated in four specific places rather than smeared evenly:

1. **Token ownership is split four ways.** Beyond `RiksaPalette`, three feature-local palette layers exist — `ProfilePalette` (146 refs), `SocialPalette` (97 refs), and `LearningTone` — and `SocialPalette`/`ProfilePalette` expose near-identical APIs, strong evidence one was copied from the other.
2. **The app's most distinctive visual layer — "glass" — is entirely untokenized.** The same blur/alpha recipe, down to identical local variable names (`glassFill`, `glassBorder`, `selectedFill`) and identical alpha constants, is copy-pasted across 8–10 files spanning core and four features. Two tab strips are line-for-line identical.
3. **A significant part of the core component library is dead.** 11 of 28 public design-system widgets have zero call sites in `lib/features`, and several are kept alive only by golden tests — which gives false confidence that the system is adopted.
4. **Design documentation actively contradicts the code and itself.** `DESIGN.md` states the primary action colour is `#2A061D`; the code resolves it to `#7657EE`. `docs/REFERENCE_UI.md` and `docs/UI_CLEANUP_PLAN.md` specify mutually exclusive bottom navigation.

The visual identity itself (violet / lavender / lime / pastel, glass chrome, pixel-art subject illustration) is coherent and worth preserving. **This codebase does not need a visual redesign; it needs token and component consolidation plus a single source of truth.** Doing screen-level redesign before settling items 1–4 would multiply the inconsistency rather than resolve it.

### Already implemented well — explicitly

- **Theme construction.** `AppTheme.light` and `AppTheme.dark` share one `_theme()` builder (`lib/core/theme/app_theme.dart:602`), so light and dark cannot structurally drift. Component themes cover app bars, cards, chips, inputs, all four button kinds, segmented buttons, tabs, switches, radios, checkboxes, list tiles, snackbars, dialogs, sheets, progress indicators and FABs (`app_theme.dart:668-873`).
- **Radii.** 270 `AppRadii.*` references against 33 raw numeric radius occurrences — by far the best-adopted token category.
- **Spacing token existence and use.** 302 `RiksaSpacing.*` references.
- **Bilingual typography.** `RiksaTypography.titleStyleFor` / `bodyStyleFor` detect Khmer text and swap family, weight, letter-spacing and line height. 111 uses across 38 files. This is careful, non-obvious work.
- **Localization.** 237 `AppLocalizations.of` references; only two hardcoded English `Text('…')` literals remain in `lib/features`, one of which is in dead code.
- **`learning_design.dart`.** Cleanly separates subject *identity* tone from lesson *status* tone, and composites pastels onto the dark surface rather than inverting them (`learning_design.dart:407-425`). The best-argued colour code in the repo.
- **Accessibility groundwork.** 80 `Semantics(`, 40 `semanticLabel`, 50 `tooltip:`, 11 `ExcludeSemantics`, a global 48×48 `IconButton` constraint (`app_theme.dart:680`), and real `MediaQuery.textScalerOf` handling in `profile_ui.dart` and `lesson_experience_screen.dart`. Better than typical for an app at this stage.
- **Motion.** `RiksaMotion.resolve()` honours `MediaQuery.disableAnimations` — reduced-motion support is built in, not bolted on.
- **Blog feature.** The best-behaved feature by token ratio (138 token refs : 18 raw colours). Its `blogSheetColor()` helper is a correct thin alias to `context.riksa.canvas`, not a rival palette.

---

## Overall Classification

**Partially structured but fragmented.**

Not "mostly hardcoded": 557 colour-token expressions against 427 raw colour expressions, 322 theme text-role accesses against 156 inline `TextStyle(` constructions, 270 `AppRadii` against 33 raw radii, 302 `RiksaSpacing` references. A majority of styling already flows through the theme.

Not "mostly coherent with local inconsistencies" either, because the divergences are *structural*, not cosmetic:

- four parallel colour-token vocabularies, two of which duplicate each other's API;
- a core component library whose most design-system-ish widgets (section header, choice pill, filter chip, filter sheet, lesson card, rounded icon button) have **zero** feature adoption;
- the primary chrome treatment (glass) has no token, no helper, and no owner;
- the documentation set cannot be used to adjudicate any of it, because it contradicts both itself and the code.

That is fragmentation at the system level while the individual screens remain, in most cases, internally coherent.

---

## UI Stack and Architecture

| Layer | Reality |
|---|---|
| Framework | Flutter, Dart SDK `^3.12.2`, `useMaterial3: true` (`app_theme.dart:638`) |
| State | `flutter_riverpod` ^3.3.2 |
| Routing | `go_router` ^17.3.0 — `StatefulShellRoute.indexedStack` with **5** branches (`app_router.dart:125`) |
| Theming | `ThemeData` × 2 + `RiksaPalette extends ThemeExtension<RiksaPalette>` (30 fields), reached via `context.riksa` (`app_theme.dart:373`) |
| Raw colour store | `AppColors` — 92 `static const` members (`app_theme.dart:6`) |
| Typography | `RiksaTypography` → 15-role `TextTheme` (`app_theme.dart:450`) |
| Spacing | `RiksaSpacing` — 4/8/12/16/24/32/48 |
| Shape | `AppRadii` — 8 distinct values + prebuilt `BorderRadius` constants |
| Elevation | `RiksaElevation.low()` — **one** shadow recipe |
| Motion | `RiksaMotion` — 5 durations, 2 curves, reduced-motion resolver |
| Shared components | `lib/core/widgets/` — 14 files, 42 classes, ~28 public |
| Feature UI | `lib/features/<feature>/presentation/` (+ `widgets/`), 68 files |

**Shell contract.** `AppShell` shows the floating bottom bar only when the branch stack depth is 1 (`app_shell.dart:47`) — a well-reasoned rule, documented in an unusually good comment. Pushed screens therefore read as full-screen.

**Navigation reachability note.** The router declares 5 shell branches, but the bottom bar exposes 4 destinations — Home, Learn, Profile, plus a centre AI action (`riksa_bottom_navigation_bar.dart:38,46,55,115`). The leaderboard branch has no bar destination; it is reached only from `HomeQuickActions` (`home_sections.dart:97`) — the same tiles `docs/UI_CLEANUP_PLAN.md:15` claims were removed.

> **Ownership note:** `lib/core/widgets/riksa_bottom_navigation_bar.dart` is being redesigned by a collaborator. Findings that touch it are recorded below as observations only; no recommendation in this audit asks for that file to be restyled.

---

## Critical Problems

These should be resolved *before* any deep screen redesign, because each one would otherwise be replicated into the new design.

1. **No page-gutter or nav-inset contract.** `RiksaBottomNavigationBar._height = 60` is **private** (`riksa_bottom_navigation_bar.dart:28`), so no screen can reference it. Four screens each guess their own clearance: `96` (`blog_feed_screen.dart:125`), `110` (`home_dashboard_screen.dart:26`), `132` (`subject_roadmap_screen.dart:94`), `160` (`lesson_catalog_screen.dart:895`). Separately, horizontal page gutters are `16`, `18`, `20` and `24` with no documented rule, and the most common value in the codebase — `20` — has no `RiksaSpacing` token at all.

2. **Four colour-token vocabularies, two of them duplicated.** See *Theme Compliance*.

3. **The glass recipe is copy-pasted, not tokenized.** See *Components*.

4. **A dead core component cluster plus a dead 1,055-line screen.** See *Components*.

5. **Design documentation cannot adjudicate disputes.** See *Design Documentation*.

6. **Live broken route (functional, found during audit).** `lib/features/leaderBoard/presentation/leaderboard_screen.dart:129` calls `context.push('/auth/province')`. No such route exists — the router defines `/province-select` (`app_router.dart:97`). The province prompt on the live leaderboard is therefore dead. This is a bug, not a style issue, and is reported here only because the audit surfaced it.

---

## Color System

### Counts

| Measure | Value |
|---|---|
| `AppColors` members | 92 |
| `RiksaPalette` semantic fields | 30 |
| Raw colour occurrences outside `lib/core/theme/` | **427** |
| — distinct normalized ARGB values | **181** |
| — `Color(0x…)` occurrences / distinct | 195 / 177 |
| — named `Colors.*` occurrences | 232 |
| `Color.fromRGBO` / `.withOpacity` | 0 / 0 |
| `context.riksa` accesses | 310 |
| `AppColors.*` references | 179 |
| `colorScheme` identifiers | 68 |
| **Token : raw expression ratio** | 557 : 427 (≈ 1.30 : 1) |

Named-colour breakdown outside the theme: `Colors.white` 149, `Colors.transparent` 59, `Colors.black` 17, `Colors.red` 6, `Colors.green` 1.

### The number that actually matters

The headline "427 raw colours" is misleading, and the audit separates two populations:

- **Illustration / preset data (legitimate):** 142 occurrences across 6 files — `learning_design.dart` (pixel-art painter), `ai_study_coach_hub.dart` (`_CoachIconPalette`), `profile_cover.dart` (gradient presets), `onboarding_art.dart`, `riksa_brand.dart`, `pixel_fire_icon.dart`. Artwork needs literal colours; this is **not** drift.
- **UI chrome (the real surface area):** 285 occurrences across 129 files — 55 distinct hex values plus the five named colours.

And within the chrome figure, `Colors.white` splits further: **110 of 140** are `Colors.white.withValues(alpha: …)` — the glass highlight layer, a deliberate technique — leaving only **30 bare opaque `Colors.white`**, of which 9 are in dead code. The genuine "hardcoded white surface" problem is therefore ~21 sites, not 149.

### Duplicate / near-duplicate values

Exact re-statements of existing tokens:

| Literal | Equals | Site |
|---|---|---|
| `#7657EE` | `AppColors.violet` | `profile_cover.dart:24` |
| `#D5F06A` | `AppColors.lime` | `profile_cover.dart:25` |
| `#237A5B` | `AppColors.brandJade` | `profile_cover.dart:29` |
| `#E69A18` | `AppColors.achievementSaffron` | `leaderboard_screen.dart:396` *(dead file)* |
| `#B87824` | `AppColors.subjectHumanities` | `leaderboard_screen.dart:411` *(dead file)* |
| `#1D1533` | `AppColors.ink` / `deepInk` | `riksa_brand.dart:141` |
| `#9D86F7` | `AppColors.editorialPink` | `riksa_brand.dart:143` |

Near-duplicate clusters (≤ 8 per-channel distance):

- **Near-white surfaces:** `#FFF7FB` (`learning_design.dart:489`), `#FFF8FC` (`profile_ui.dart:74`), `#FFF9FC` (`leaderboard_screen.dart:796`), `#FFF7F7` (`home_sections.dart:290`) — mutually within a few points, and near `appCanvas #FCFBFF`.
- **Lavender:** `#EDE9FE` (`social_post_card.dart:442`) is **one channel point** from `violetSoft #EDE8FE`.
- **Pale blue:** `#D7ECF9`, `#DBEAFE`, `#DCEBFF` cluster around `tileBlue #DDEFFB`.
- **Near-black:** `#121212` (`leaderboard_screen.dart:847`) is one point from `darkCanvas #111113`.

### Theme bypasses (verified)

- **`AppColors.socialLike` is defined (`app_theme.dart:123`) and used zero times.** The like state hardcodes `Colors.red` instead (`social_post_card.dart:501,508`; `social_post_detail_screen.dart:971`).
- **Const style defeats dark mode:** `leaderboard_states.dart:229-239` builds a `const TextStyle` with `Color(0xFF70695E)`, size 14, `w700`, letterSpacing 4 — while the rest of that same file correctly branches on brightness (`leaderboard_states.dart:17-28`).
- **Logout button:** `profile_settings_screen.dart:203-209` hardcodes foreground `#FF7B8B` and border `#593139` on a dark-aware `ProfilePalette.panel(context)` background, despite `ColorScheme.error` being used correctly elsewhere (`social_auth_section.dart:170`, `blog_detail_screen.dart:175`).

### Legacy naming layer

`AppColors` carries an `editorial*` / `brandJade*` / `gamification*` vocabulary from a previous direction, aliased onto the current violet system — e.g. `editorialAubergine = violet` (`app_theme.dart:50`), `editorialPinkSoft = violetSoft`, `brandPrimary = brandJade`. The values are correct; the **names lie about what they are**, and `editorialPink` alone is referenced 27 times. This is the single biggest source of confusion when reading feature code, and it is why `DESIGN.md` is wrong (below).

### Light / dark

Dark theme is fully defined and wired (`riksa_app.dart:24-26`, persisted `themeMode` provider). 53 explicit brightness checks across 28 files. No live routed screen suffers a whole-page dark break. Risks are element-level — see *Dark Theme Risks*.

---

## Typography

**Families.** `pubspec.yaml` declares six: Reddit Sans, Poppins, Noto Sans Khmer, Koulen, Kantumruy Pro, Khmer OS Siemreap (2.1 MB of `assets/fonts`). Only **Poppins**, **Reddit Sans** (legacy fallback) and **Khmer OS Siemreap** are referenced from `lib/`. Noto Sans Khmer, Koulen and Kantumruy Pro have zero `lib/` references — they are referenced only by golden-test font loading (`test/`: Koulen 9, Kantumruy 4, Noto 2). They ship in the app bundle but never render in it.

**Scale.** 15 Material roles defined at `app_theme.dart:497-512`, sizes 10.5 → 26. Note `displaySmall` and `headlineLarge` are *identical* (21 / w600) — two names, one role.

**Raw sizes outside the theme.** 131 occurrences across **24 distinct values**:

| 9 | 9.5 | 10 | 10.5 | 11 | 11.5 | 12 | 12.5 | 13 | 13.5 | 14 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 7 | 4 | 9 | 2 | 17 | 9 | **25** | 1 | 12 |

| 14.5 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 24 | 26 | 46 | 76 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 14 | 9 | 2 | 3 | 2 | 5 | 1 | 1 | 1 | 2 | 1 | 1 |

(`46` and `76` are wordmark sizes, not text roles.)

**Weights — the clearest single finding in this section.** The theme's type scale uses only **w400, w500, w600**. Feature code uses:

| w400 | w500 | w600 | w700 | w800 | w900 |
|---:|---:|---:|---:|---:|---:|
| 10 | 19 | 103 | **118** | **27** | **8** |

**153 uses of weights the type scale does not define**, across ~30 files. Every emphasis in the app is therefore a local override, because the scale offers no bold role. This is the root cause of most inline `TextStyle` construction.

**Theme vs inline.** 322 text-role accesses vs 156 inline `TextStyle(` constructions (67% / 33%). 265 of the theme accesses are `.copyWith(…)` — so most "theme usage" is still role *customization*, not role reuse.

**Repeated inline shapes that are really unnamed roles** (grouped by size/weight, ignoring colour):

| Shape | Count | Examples |
|---|---:|---|
| `13` alone | 11 | `riksa_profile_drawer.dart:322`, `edit_profile_screen.dart:387` |
| `13 / w600` | 7 | `profile_post_actions.dart:66`, `social_post_card.dart:557`, `lesson_experience_screen.dart:1261` |
| `12 / w700` | 6 | `social_feed_screen.dart:1171`, `streak_details_sheet.dart:211`, `lesson_catalog_screen.dart:815` |
| `14 / w700` | 4 | `profile_ui.dart:471`, `lesson_catalog_screen.dart:496` |
| `15 / w600` | 4 | `profile_post_actions.dart:464`, `learning_atoms.dart:150,336` |
| `11 / w600` | 4 | `profile_ui.dart:1000` |

**Consolidation opportunity:** add bold (w700) variants of the existing label/title roles. That single change addresses the majority of the 153 heavy-weight overrides and most of the repeated shapes above.

**Hierarchy inconsistency.** Leaderboard, interactive onboarding and some profile panels read as game UI (w800/w900, letter-spacing 4, fixed sizes) while learning and blog follow the restrained theme hierarchy. Whether that is intentional per-surface expression is a product decision — but it is currently undocumented and therefore indistinguishable from drift.

---

## Spacing and Dimensions

**Declared scale:** `RiksaSpacing` = 4, 8, 12, 16, 24, 32, 48 — a 4-point scale. 302 references.

**Actual usage:** 1,204 raw numeric literals in `EdgeInsets` (663), `SizedBox` width/height (533), and `spacing:` (8). `Gap()` is not used.

**Frequency (combined):**

```
4×113   6×65    8×124   10×79   12×151  14×86
16×121  18×62   20×113  22×11   24×42   28×18
```

**The apparent scale is 2-point, not 4-point.** The off-scale values 6, 10, 14, 18, 20 and 22 total **416 occurrences** — more than the on-scale 4/8/12/16/24 values that `RiksaSpacing` actually names. In particular:

- **`20` (113 uses) is the de-facto page gutter and has no token.** `RiksaSpacing` jumps 16 → 24.
- **`10`, `14` and `18` (227 uses combined) have no tokens** and sit between defined steps.

**Equivalent screens, inconsistent gutters:**

| Screen | Horizontal gutter | Evidence |
|---|---:|---|
| Social feed | 16 | `social_feed_screen.dart:174` |
| Learning catalog | 16 | `lesson_catalog_screen.dart:78` |
| Blog feed | 16 | `blog_feed_screen.dart:120` |
| Leaderboard | 16 | `leaderboard_screen.dart:89` |
| Profile root | 18 | `user_profile_screen.dart:110` |
| Settings / edit profile | 18 | `profile_settings_screen.dart:58`, `edit_profile_screen.dart:104` |
| Dashboard | 20 | `home_dashboard_screen.dart:26` |
| Roadmap / lesson player | 20 | `subject_roadmap_screen.dart:94` |
| Blog detail | 20 | `blog_detail_screen.dart:313` |
| Interactive onboarding | 20 | `interactive_onboarding_screen.dart:169` |
| Auth forms | 24 | `auth_scaffold.dart:32` |
| AI tutor | 24 | `ai_tutor_screen.dart:118` |

Some of this is defensible (a wider reading gutter for auth/AI). None of it is written down.

**Irregular values:** horizontal `3` (`home_sections.dart:118-120`), vertical `17` (`riksa_search_bar.dart:106`, `auth_scaffold.dart:178`), `3.5` and `1.5` (`leaderboard_podium.dart:273,319,436`), `25×29` (`leaderboard_podium.dart:411`), asymmetric `18,18,128,20` (`home_sections.dart:237`).

**Bottom nav clearance** — four different magic numbers for one 60px bar, listed under *Critical Problems*.

---

## Shapes

**Declared:** `AppRadii` = 8 (`small`), 13 (`badge`), 14 (`medium`), 16 (`row`), 16 (`large`), 20 (`panel`), 24 (`feature`), 28 (`extraLarge`), 9999 (`full`) — **9 names for 8 distinct values**: `row` and `large` are both `16`. Two names for one shape role is a small but real ambiguity for anyone choosing a token.

**Adoption is excellent:** 270 `AppRadii.*` references vs 33 raw numeric radius occurrences (17 distinct values).

**Shape constructors:** `CircleBorder` 33, `RoundedRectangleBorder` 24, `StadiumBorder` 20, `BorderRadius.circular` 12, `.only` 4, `.all` 1. No `ContinuousRectangleBorder` / `BeveledRectangleBorder`.

**Raw outliers:** 36 sheet radius (`leaderboard_screen.dart:667`), organic 56/40/44/60 hero shape (`riksa_components.dart:1565-1568`, intentional illustration), 5 (`language_select_screen.dart:241`), 11 (`riksa_components.dart:1311`), 2-radius podium caps (`leaderboard_podium.dart:431,445`).

**Inconsistent equivalent components — bottom sheets.** The theme default is a 16 top radius (`app_theme.dart:853`), yet: social search uses an explicit 28 (`social_feed_screen.dart:640`), the leaderboard rankings sheet uses 36 (`leaderboard_screen.dart:667`), and several sheets use transparent backgrounds with their own clipped surfaces (`streak_details_sheet.dart:11`, `social_create_menu.dart:21`, `user_profile_screen.dart:424`). Across 12 `showModalBottomSheet` call sites there are three different `backgroundColor` sources (`ProfilePalette.panel`, `Colors.transparent`, `context.riksa.surface`) and inconsistent drag-handle / `isScrollControlled` choices for equivalent action menus.

---

## Elevation, Borders and Shadows

**Material `elevation:` is effectively unused outside the theme** — 4 occurrences, all `0` (`blog_detail_screen.dart:232`, `social_post_detail_screen.dart:1140`, `profile_ui.dart:254`, `social_post_card.dart:68`). All depth is drawn with `BoxShadow`.

**Shadows:**

| Measure | Value |
|---|---|
| `BoxShadow` definitions outside the theme | **48** |
| Distinct textual configurations | 33 |
| `RiksaElevation.low` references | **6** |
| Distinct `blurRadius` values | 11 (18×20, 10×10, 16×5, 24×3, 20×2, 14×2, and 4/12/22/26/28) |
| Distinct Y-offsets | 10 (8×18, 4×13, 6×5, 7×3, …) |

**The one elevation token covers roughly 12% of the app's shadows.** There is no `medium`/`high` role, so every raised surface invents one. Two informal conventions have emerged organically and are worth promoting rather than replacing:

- ink @ 0.06, blur 10, offset (0,4) — 7 uses, e.g. `progress_history_screen.dart:403`
- ink @ 0.18 dark / 0.08 light, blur 18, offset (0,8) — 11 semantically equivalent uses, e.g. `user_profile_screen.dart:243`, `social_feed_screen.dart:692`

Outliers include `Colors.black` @ .28/.1 blur 22 (`riksa_search_bar.dart:51`), `Colors.black` @ .34/.12 blur 26 (`social_post_detail_screen.dart:1127`), and coloured glows (`home_sections.dart:223,246`; `interactive_onboarding_screen.dart:1448`).

**Borders:** `Border.all(…)` 72 occurrences / 44 distinct configurations; `BorderSide(…)` 51 / 20; `OutlineInputBorder` 10. Widths are mostly default 1.0 (93 combined) with 0.8, 1.2, 1.5, 1.6, 1.8, 2, 2.5 and 3 also present, plus 9 conditional-width expressions. Most common colours are `palette.outline` (25) and `context.riksa.outline` (8) — good — against `glassBorder` (12) and `Colors.white.withValues(alpha: 0.36)` (11), which are untokenized glass.

**Surface-hierarchy conclusion:** there is no shared answer to "how raised is this?". A card, a sheet, a glass bar and a podium each answer independently.

---

## Components

`lib/core/widgets/` holds 42 classes across 14 files; `riksa_components.dart` alone is 1,596 lines and 32 classes.

### Finding 1 — 11 of 28 public core widgets have zero feature adoption

Call sites **outside `lib/core/widgets/`**:

| Widget | Feature call sites | Status |
|---|---:|---|
| `RiksaSkeleton` | 32 | healthy |
| `RiksaTapFeedback` | 18 | healthy |
| `IllustratedEmptyState` | 18 | healthy |
| `RiksaAvatarImage` | 14 | healthy |
| `RiksaRankBadge` | 6 | healthy |
| `RiksaPastelCard` | 5 | healthy |
| `RiksaSearchField` | 4 | (1 of 4 is in dead code) |
| `RiksaMascot` / `RiksaEntrance` / `RiksaCountUp` | 4 each | healthy |
| `RiksaStateView` | 3 | thin |
| `RiksaSearchBar` / `RiksaPageHeader` / `RiksaSuccessMark` | 2 each | thin |
| **`RiksaSectionHeader`** | **0** | **dead — no test either** |
| **`RiksaRoundedIconButton`** | **0** | **dead — no test either** |
| **`FilterBottomSheet`** | **0** | **dead — no test either** |
| **`DailyMissionCard`** | **0** | golden test only |
| **`LessonCard`** | **0** | golden test only |
| **`RiksaChoicePill`** | **0** | golden test only |
| **`ActiveFilterChip`** | **0** | golden test only |
| `SubjectTile` | 0 | used only by dead `FilterBottomSheet` + golden test |
| `SubjectArtwork` | 0 | used only by dead `SubjectTile` / `LessonCard` |
| `AnimatedRiksaProgress`, `RiksaPressableScale` | 0 | used only by dead `LessonCard` |
| `RiksaEmptyArtwork` | 0 | used by live `IllustratedEmptyState` — **alive** |

This forms a **dead cluster**: `FilterBottomSheet` → `SubjectTile` → `SubjectArtwork`, and `LessonCard` → `AnimatedRiksaProgress` / `RiksaPressableScale` / `SubjectArtwork`. Roughly a whole lesson-catalog component set sits in core, fully golden-tested, and is rendered by nothing. **The golden tests actively disguise this**, because a passing visual suite implies the design system is in use.

> **Important non-finding.** Core `SubjectTile` and learning's `_SubjectTile` (`lesson_catalog_screen.dart:643`) are **not** duplicates. Core's is a 108px-wide selectable *filter tile* with vector `SubjectArtwork`; learning's is a full-width *list row* with description, progress, and pixel artwork, navigating to the roadmap. Different jobs. Core's is dead because the filter UI it served is dead — not because it was reimplemented.

### Finding 2 — the glass recipe: the largest copy-paste pattern in the app

`LeaderboardScopeTabs` (`leaderboard_scope_tabs.dart:9`) and `_FeedSectionTabs` (`social_feed_screen.dart:795`) are **line-for-line identical** — same alpha constants (0.46 / 0.58 / 0.12 / 0.72 / 0.08 / 0.54), same local variable names, same inner `tab()` builder, same `Semantics`, same `RiksaTypography.bodyStyleFor` + `labelLarge` styling, same `RiksaMotion.standard`. Only the enum type and labels differ.

The same recipe recurs across **8 files** (matching both the 0.58 and 0.72 constants):

`riksa_bottom_navigation_bar.dart`, `riksa_search_bar.dart`, `ai_chat_screen.dart`, `leaderboard_scope_tabs.dart`, `learning_atoms.dart`, `social_feed_screen.dart`, `progress_history_screen.dart`, `profile_post_actions.dart`

Five of them even share the identical variable names `glassFill` / `glassBorder` / `selectedFill`. 23 `BackdropFilter` uses span 13 files. Named glass widgets exist in four separate places (`_HeaderGlassIconButton`, `_GlassBlogCard`, `_GlassStreakCard`, `_ProfileGlassActionCircle`).

**There is no glass token, helper, or widget anywhere.** Verdict: **accidental duplication of what should be a first-class global surface treatment.** This is the highest-value consolidation in the report — the glass layer is the app's signature chrome and is currently unowned.

### Finding 3 — dead 1,055-line leaderboard screen

`lib/features/leaderBoard/leaderboard_screen.dart` (1,055 lines, 13 classes) is **imported by nothing** — not `lib/`, not `test/`, not `tool/`. The router and both test suites use `lib/features/leaderBoard/presentation/leaderboard_screen.dart` (258 lines), which correctly decomposes into `presentation/widgets/`.

The dead file materially inflates several counts in this report: 25 raw colours, 16 raw font sizes, 9 bare `Colors.white`, 12 brightness checks, and the `#E69A18` / `#B87824` / `#121212` / `#70695E` bypasses. It is a leftover from a completed refactor.

### Finding 4 — search fields: three implementations, two visual languages

| Implementation | Treatment | Call sites |
|---|---|---|
| `RiksaSearchField` (`riksa_components.dart:113`) | Flat outlined stadium field, `context.riksa.surface`, focus `context.riksa.brand` | `ai_tutor_screen.dart:158`, `interactive_onboarding_screen.dart:735`, `province_select_screen.dart:129` (+1 dead) |
| `RiksaSearchBar` (`riksa_search_bar.dart:11`) | Glass stadium pill, `BackdropFilter` blur 18, gradient, shadow, optional filter control, 56 high | `communities_screen.dart:169`, `social_feed_screen.dart:655` |
| `_LeaderboardSearchField` (`presentation/leaderboard_screen.dart:217`) | Near-verbatim copy of `RiksaSearchField` | 1 (local) |

`_LeaderboardSearchField` is the clearest case of **a global component reimplemented locally**. Differences from the original, all of which are regressions:

- hint is a hardcoded English literal `'Search learners'` — **unlocalized in a bilingual app** (independently corroborated by `screenshots/README.md:326`);
- manual `isDark ? … : AppColors.editorialNeutralSurface` branching instead of the palette;
- focus colour `AppColors.editorialPink` instead of `context.riksa.brand`;
- adds `vertical: 10` content padding.

`RiksaSearchField` vs `RiksaSearchBar` is a **justified variant** (flat vs glass) — but the split runs along feature lines (social gets glass, everything else gets flat) rather than along any documented rule, which is how two visual languages become permanent.

### Finding 5 — tab strips: five bespoke implementations, zero `TabBar`

`TabBar`, `SegmentedButton` and `ToggleButtons` are used **zero** times, although the theme configures `segmentedButtonTheme` and `tabBarTheme` (`app_theme.dart:776`). Live bespoke strips:

`_CategoryTabs` + `BlogTab` (`blog_feed_screen.dart:154`, `blog_ui.dart:343`), `LeaderboardScopeTabs`, `_FeedSectionTabs`, `_ProgressSectionTabs` (`progress_history_screen.dart:284`), `ProfileTabs` + `_ProfileTabButton` (`profile_ui.dart:767,882`).

Two are byte-identical (Finding 2). Verdict: **accidental duplication**; the theme's tab configuration is dead.

### Finding 6 — chips and pills: core dead, six feature versions live

Core `RiksaChoicePill` and `ActiveFilterChip` have zero feature adoption. Live feature chips: `AiContextChip`, `_StreakChip`, `_SubjectChip`, `LearningPill`, `_SortChip`, `_CommunityChip`, `_StreakPill`. Material's own chips are barely used (`FilterChip` 1, `ChoiceChip` 3, `ActionChip` 3, `InputChip` 1). Verdict: **feature-specific patterns that should probably be global**, given a variant-capable pill.

### Finding 7 — avatars: justified layering

`RiksaAvatarImage` (core, 14 call sites) is the shared image primitive, and feature avatars wrap it for domain concerns: `RiksaProfileAvatar`, `BlogAvatar`, `SocialAuthorAvatar`, `CommunityAvatar`, `AiCoachAvatar`, `_PublicAvatar`, `_Avatar`. Spot-checks show these add fallback initials, badges and tap targets rather than restyling. Verdict: **justified variants.** Worth a later audit for ring/size consistency, but not duplication.

### Finding 8 — profile adapters are correct layering, not duplication

`_RankCard` / `_AchievementTile` / `_EmptyPanel` in `user_profile_screen.dart:1036,983,1097` look like duplicates of `ProfileRankCard` / `ProfileAchievementTile` / `ProfileEmptyPanel` in `profile_ui.dart:1028,970,1211`. Reading them shows each is a **thin screen-local adapter that delegates** to the shared widget, injecting localized strings and trailing content. Verdict: **justified — this is good layering** and should be left alone.

### Finding 9 — headers: no shared screen header

16 `AppBar(`, 2 `SliverAppBar`, 3 `RiksaPageHeader` uses, and ~12 bespoke `_*Header` classes (`_HomeHeader`, `_OnboardingHeader`, `_CoverHeader`, `_AuthorHeader`, `_CommunityHeader`, `_RoadmapHeader`, `_TopHeader`, `AuthHeader`, `LeaderboardHeader`, `HomeSectionHeader`, `ProfileIdentityHeader`, …). Core's `RiksaSectionHeader` is dead. Verdict: **global component being reimplemented locally**, repeatedly.

### Finding 10 — loading states: two competing languages

`CircularProgressIndicator` 44 uses vs `RiksaSkeleton` 40 uses. The skeleton is the better-built option (palette-derived, reduced-motion aware) and is already cross-feature (learning, blog, AI). Full-page spinners dominate pushed detail screens (`lesson_experience_screen.dart:137`, `saved_lessons_screen.dart:105`, `social_post_detail_screen.dart:320`, `edit_profile_screen.dart:96`). Two weaker local re-inventions exist: social feed's static raised rectangles (`social_feed_screen.dart:1270`) and `_PodiumLoadingShimmer`, which is named "shimmer" but does not animate (`leaderboard_states.dart:12`). A third loader, `loading_animation_widget`, appears exactly once (`auth_switcher_screen.dart:329`).

### Finding 11 — empty states: three vocabularies

Shared `IllustratedEmptyState` (18 uses) covers learning, AI, blog, communities and progress. Feature-local variants: `_FeedMessage` (`social_feed_screen.dart:1202`), `_EmptyComments` (`social_post_detail_screen.dart:1013`), `ProfilePostsEmpty`, `_EmptyPanel`, `_EmptyPodium`, `_ProvinceError`. Genuine gaps: **the dashboard silently swallows provider errors via `SizedBox.shrink()`** (`home_dashboard_screen.dart:30`), and profile achievements collapse *error* into the same panel used for *absence* (`user_profile_screen.dart:958`).

### Finding 12 — buttons: theme configured, then overridden

`ElevatedButton` 0, `FilledButton` 69, `TextButton` 61, `IconButton` 66, `OutlinedButton` 28, `FAB` 2, plus 70 raw `InkWell` and 13 `GestureDetector`. Against these, **77 `styleFrom(` overrides** (IconButton 28, FilledButton 23, TextButton 16, OutlinedButton 8) — roughly a third of `FilledButton` uses restyle the theme default. Primary-action placement also varies by feature: auth/AI use a full-width 54px CTA, blog composer puts save at the top, social uses a FAB, `edit_profile_screen.dart:274` overrides the violet primary with a feature-local green/black button.

### Finding 13 — icon sources are unstandardized

Material icons dominate, but the app also uses `CupertinoIcons` in two social files (`social_post_detail_screen.dart`, `social_post_card.dart`), SVG/asset avatars, raster achievement art, a custom-painted flame (`pixel_fire_icon.dart`), pixel-art subject illustration, and literal emoji (`interactive_onboarding_screen.dart:1465`, `leaderboard_states.dart:178`). Two subject-artwork systems exist: vector `SubjectArtwork` (core, **dead**) and `SubjectPixelArtwork` (learning, **live**, 5 uses). The live system is the pixel one.

---

## Theme Compliance

Token references vs raw values, by area:

| Area | Token refs¹ | Raw colours | Raw font sizes | Files | Ratio |
|---|---:|---:|---:|---:|---:|
| `lib/features/blog` | 138 | 18 | 8 | 9 | **7.7** |
| `lib/features/auth` | 127 | 41 | 20 | 24 | 3.1 |
| `lib/features/learning` | 206 | 70² | 21 | 17 | 2.9 |
| `lib/features/ai` | 132 | 47² | 5 | 9 | 2.8 |
| `lib/core/widgets` | 138 | 49² | 1 | 14 | 2.8 |
| `lib/features/leaderBoard` | 122 | 43³ | 27³ | 9 | 2.8 |
| `lib/features/social` | 160 | 76 | 16 | 17 | 2.1 |
| `lib/features/userProfile` | 106 | 74² | 32 | 19 | **1.4** |
| `lib/features/dashboard` | 12 | 9 | 1 | 2 | 1.3 |

¹ `context.riksa` + `Theme.of(context)` + `AppRadii.` + `RiksaSpacing.`
² inflated by legitimate illustration palettes (`learning_design.dart` 52, `ai_study_coach_hub.dart` 37, `profile_cover.dart` 29, `riksa_brand.dart` 14)
³ inflated by the dead `leaderboard_screen.dart` (25 colours, 16 font sizes)

**Overall: ~57% of colour expressions are tokens, ~67% of text styling goes through theme roles.** This is an interleaved system, not a hardcoded one.

### The real compliance problem: four palette vocabularies

| Vocabulary | Location | Refs | Assessment |
|---|---|---:|---|
| `RiksaPalette` via `context.riksa` | `app_theme.dart:127` | 310 | **The intended system** |
| `AppColors` direct | `app_theme.dart:6` | 179 | Bypasses the dark-aware layer; `DESIGN.md:5` explicitly forbids this |
| `ProfilePalette` + `ProfilePaletteScope` | `profile_ui.dart:12,79` | 146 | Parallel `InheritedWidget` theming layer |
| `SocialPalette` | `social_palette.dart:5` | 97 | Parallel static facade |
| `LearningTone` | `learning_design.dart:371` | 8 | **Justified** — subject/status identity, not general theming |

**`SocialPalette` and `ProfilePalette` are near-identical APIs.** Both expose `canvas`, `surface`/`panel`, `surfaceRaised`/`panelSoft`, `ink`/`text`, `muted`, `outline`/`border`, `aubergine`, `pink`, `pinkSoft`, `onAubergine`, `green`, `editorialSurface`; both branch on brightness; both fall back to the legacy `editorial*` values in light mode. `SocialPalette` even carries alias methods (`green` → `pink`, `panel` → `surface`, `border` → `outline`, `text` → `ink`) whose names exactly mirror `ProfilePalette`'s members (`social_palette.dart:44-47`). That is strong evidence one was copied from the other.

**Six answers to "what colour is this page":**

| Screen | Background source |
|---|---|
| `home_dashboard_screen.dart:16` | theme default (none set) |
| `ai_tutor_screen.dart:105` | theme default (none set) |
| `lesson_catalog_screen.dart:38` | `context.riksa.canvas` |
| `blog_feed_screen.dart:65` | `blogSheetColor(context)` → `context.riksa.canvas` ✅ |
| `social_feed_screen.dart:80` | `SocialPalette.canvas(context)` |
| `user_profile_screen.dart:61` | `ProfilePalette.canvas(context)` |
| `leaderboard_screen.dart:70` | inline `isDark ? context.riksa.canvas : AppColors.editorialNeutralCanvas` |

The leaderboard's inline expression is **exactly** what `SocialPalette.canvas` encapsulates — the same rule, written out by hand. `blogSheetColor` is the well-behaved case: a thin, correct alias, not a rival palette.

---

## Screen Inconsistencies

Areas that read as a different visual system from the rest:

1. **Social shell (`social_feed_screen.dart`, `communities_screen.dart`).** The only feature using the glass search bar, glass header icon buttons, `_GlassBlogCard` and its own `SocialPalette`. 14-radius feed blocks rather than the theme's 16 card radius (`social_feed_screen.dart:1270`). Internally coherent; externally distinct.

2. **Profile / edit / settings.** Runs on `ProfilePaletteScope` — a route-level `InheritedWidget` palette — with its own panels, tab bar and gamification typography (w800/w900). Highest raw-token debt of any feature (ratio 1.4, 32 raw font sizes). `edit_profile_screen.dart:274` overrides the app's violet primary with a green/black button.

3. **Leaderboard.** Podium, medals, rank badges, letter-spacing-4 labels. Hardcoded `const` colours that ignore dark mode (`leaderboard_states.dart:229`). Reached through no bottom-nav destination and containing a broken `/auth/province` push.

4. **Interactive onboarding (`interactive_onboarding_screen.dart`, 1,746 lines).** 26 heavy-weight overrides (the most of any file), 15 raw font sizes, 17 raw colours, 8 `Border.all`, its own header, progress and fire artwork, emoji, and a gradient. Also contradicts `PRODUCT.md` (below).

5. **Dashboard (`home_dashboard_screen.dart` + `home_sections.dart`).** A fixed red/pink gradient card with white content that does not respond to theme (`home_sections.dart:218-290`) — and gradient card fills are explicitly banned by `DESIGN.md:216`. Silently swallows errors. Only 2 files, weakest token ratio.

**Consistent and well-built, for contrast:** the **learning** family (catalog, roadmap, player, saved, completion) shares subject/status semantics, feature atoms, the shared skeleton and empty state, and uses the Khmer typography helpers throughout. **Auth** is consistent behind `auth_scaffold.dart` (one gutter, one scroll architecture, one panel, one CTA height, width-capped at 480). **Blog** is the cleanest token citizen in the app.

---

## Accessibility Risks

Only obvious, verifiable issues.

1. **Tap targets below 48 px.** `_HeaderGlassIconButton` is explicitly 42×42 and built from a raw `InkWell` with no `Semantics` and no tooltip (`social_feed_screen.dart:667,700`) — both undersized and unnamed.
2. **Unlabelled comment actions.** Reply and delete are raw `GestureDetector`s with 4 px vertical padding, no button semantics, no size constraint (`social_post_detail_screen.dart:828,842`).
3. **Missing tooltips on icon-only buttons.** `social_feed_screen.dart` has 3 `IconButton`s and 0 tooltips; `social_post_detail_screen.dart` has 2 and 0.
4. **Interactive identities lack roles.** Author avatar/name navigation uses `GestureDetector` without button/link semantics (`social_post_card.dart:206,226`).
5. **Unlocalized accessibility string.** The collapsed navigation item is labelled with the hardcoded English `'Current Tab'` and exposes an empty `onTap` (`riksa_bottom_navigation_bar.dart:131,161`) — announcing a non-action as a button. *(Observation only — file under separate ownership.)*
6. **Unlocalized visible string.** `'Search learners'` (`presentation/leaderboard_screen.dart:229`) in a Khmer/English app.
7. **Meaningful images without labels.** Blog cover uses `Image.network` with neither `semanticLabel` nor `excludeFromSemantics` (`blog_ui.dart:520`). Avatars handle this more deliberately.
8. **Text scaling suppressed in two places.** Nav labels are capped at 1.3 and wrapped in `FittedBox` (`riksa_bottom_navigation_bar.dart:78,359`); the rank badge disables scaling to fit a 26×26 asset (`ranking_list_row.dart:52`).

**Not flagged:** fixed numeric `fontSize` values still scale with `textScaler` unless explicitly disabled, so the 131 raw sizes are a consistency problem, not an accessibility one. No definitively failing contrast pair could be proven by static inspection; no contrast measurement was performed.

---

## Dark Theme Risks

**A dark theme exists and is fully wired.** `AppTheme.dark` (`app_theme.dart:547`), `RiksaPalette.dark` (30 fields, `app_theme.dart:233`), `darkTheme:` + persisted `themeMode:` (`riksa_app.dart:24-26`). 53 explicit brightness checks across 28 files. Golden tests cover both brightnesses.

**No live routed screen suffers a whole-page dark break.** Risks are element-level:

| Risk | Evidence |
|---|---|
| `const TextStyle` with fixed `#70695E` — cannot adapt | `leaderboard_states.dart:229-239` |
| Logout foreground `#FF7B8B` + border `#593139` fixed on a dark-aware panel | `profile_settings_screen.dart:203-209` |
| Hardcoded white cover-picker selection treatment | `edit_profile_screen.dart:569` |
| Avatar control black/white foregrounds bypass `onBrand` (dark `onBrand` is near-black, not white) | `edit_profile_screen.dart:144-150,458-467` |
| Fixed red/pink gradient card with white content, theme-invariant | `home_sections.dart:218-290` |
| ~21 live bare opaque `Colors.white` fills | see *Color System* |

**Latent risk:** the dead `leaderboard_screen.dart` hardcodes white row surfaces and `#121212` text throughout (`leaderboard_screen.dart:795-905`). Harmless while unrouted; a full dark-mode break if revived.

**Handled well:** `learning_design.dart` composites pastels onto the dark surface and lightens accents rather than inverting (`:407-425`); `SocialPalette`, `ProfilePalette` and `leaderboard_states.dart:17-28` all branch correctly; artwork palettes are intentionally theme-invariant.

---

## Design Documentation

**There is no reliable source of truth.** Thirteen documents make overlapping claims; several are stale and at least three pairs directly contradict each other.

| Document | Claimed role | Status |
|---|---|---|
| `DESIGN.md` | "Riksa — Design System" | **Contradicts the code** |
| `docs/REFERENCE_UI.md` | 2026-09-15 board "governs composition" | **Contradicts `UI_CLEANUP_PLAN.md`** |
| `docs/UI_CLEANUP_PLAN.md` | Marked implemented/verified 2026-09-15; "supersedes older directions" | **Contradicts `REFERENCE_UI.md`** and its own claims |
| `docs/EDITORIAL_DESIGN_SYSTEM.md` | Editorial direction | **Contradicts `DESIGN.md` and `PRODUCT.md`** |
| `docs/DESIGN_SYSTEM_PLAN.md` | "Direction proposed — approve before production UI coding", 2026-08-16 | Proposes green, `Today/Rank/Me` nav, no AI tab, no pill buttons — none adopted |
| `UI_HANDOFF.md` | Handoff pinned to `develop`@`9fc0133` | Stale (1,660 lines) |
| `ui_map.json` | Machine-readable UI map | Stale — same `develop`@`9fc0133` |
| `PRODUCT.md` | Product principles | **Contradicted by onboarding** |
| `REDESIGN_PROPOSAL.md` | 2026-09-18 proposal | Accurate diagnosis; not adopted |
| `docs/SOCIAL_SCREEN_PLAN.md`, `docs/AUTH_SCREEN_PLAN.md` | Feature plans | Historical; partly superseded |
| `docs/wireframes/social_wireframe.html` | Old wireframe | Explicitly deprecated by `SOCIAL_SCREEN_PLAN.md:10` |
| `screenshots/` (26 + reference set) | Capture library, 2026-09-14 | Evidence, not normative |

### The four contradictions that matter

1. **`DESIGN.md` is wrong about the app's primary colour.** It states the primary action anchor is "`editorialAubergine` `#2A061D`, never pure black" (`DESIGN.md:11`, repeated at `:32` and `:221`). The code defines `editorialAubergine = violet = Color(0xFF7657EE)` (`app_theme.dart:50,12`) — a violet, not a near-black. `#2A061D` appears in `lib/` exactly once, in `onboarding_art.dart:149`, as a remap *away* from that value. Anyone following `DESIGN.md` today would build the wrong app.

2. **`DESIGN.md` bans what the app does.** `DESIGN.md:5` says tokens should be reached through `context.riksa`, "never by importing raw `AppColors` into feature code" — there are 179 such imports. `DESIGN.md:216` bans "gradient card fills" — there are 10 gradients across 9 files, including the dashboard learning card (`home_sections.dart:218-290`). It also declares "This is not an editorial … system" (`DESIGN.md:16`), while `docs/EDITORIAL_DESIGN_SYSTEM.md` exists to define exactly that.

3. **Two documents specify mutually exclusive navigation.** `docs/REFERENCE_UI.md:12-13` requires a "slim white bottom navigation at tab roots; all five icon labels remain visible… Reserve navigation height; no hiding on scroll", and declares "The earlier dark floating navigation proposal is superseded" (`:6`). `docs/UI_CLEANUP_PLAN.md:10-12` requires "a floating deep-purple pill with a lime active icon… hide it on pushed screens". The shipped bar is a *floating glass pill with four destinations that collapses on scroll* — matching neither. `REFERENCE_UI.md:11` also specifies 16 dp page gutters; the codebase's dominant gutter is 20.

4. **`UI_CLEANUP_PLAN.md` claims work that is not done.** `:15` states "Home: remove the four shortcut tiles." `HomeQuickActions` is still rendered at `social_feed_screen.dart:184` — and is the only route to the leaderboard.

Additionally, `PRODUCT.md:34,67` specifies a "read, reflect, discuss" loop and explicitly rejects Duolingo-style playfulness, while `interactive_onboarding_screen.dart:233,1399` implements graded quiz steps and a streak reward.

**Current de-facto source of truth: the code itself** — specifically `lib/core/theme/app_theme.dart`. Every document that claims otherwise is wrong in at least one material respect.

---

## Prioritized Refactor Plan

**None of this has been performed. This is an audit only.**

### P0 — Design-system / architecture blockers

**P0.1 — Declare one source of truth and correct it.**
*Problem:* five documents claim authority; `DESIGN.md` misstates the primary colour, bans `AppColors` usage that is pervasive, and bans gradients that ship.
*Affected:* `DESIGN.md`, `docs/EDITORIAL_DESIGN_SYSTEM.md`, `docs/REFERENCE_UI.md`, `docs/UI_CLEANUP_PLAN.md`, `docs/DESIGN_SYSTEM_PLAN.md`, `UI_HANDOFF.md`, `ui_map.json`.
*Why:* no token, component or screen decision can be adjudicated while the documents disagree; every redesign argument will restart from scratch.
*Eventual replacement:* one `DESIGN.md` regenerated **from** `app_theme.dart`, stating actual values; every superseded document moved to `docs/archive/` with a header naming what replaced it.

**P0.2 — Publish the navigation inset and page-gutter contract.**
*Problem:* `RiksaBottomNavigationBar._height` is private; four screens hardcode 96/110/132/160 clearance. Page gutters are 16/18/20/24 with no rule, and the most-used value (20, 113 occurrences) has no token.
*Affected:* `riksa_bottom_navigation_bar.dart:28`; `blog_feed_screen.dart:125`, `home_dashboard_screen.dart:26`, `subject_roadmap_screen.dart:94`, `lesson_catalog_screen.dart:895`; `RiksaSpacing`.
*Why:* redesigned screens will each re-guess the same number, and any change to the bar silently breaks four screens. *(Coordinate with the bar's owner: this needs a public height constant or an inherited inset, not a restyle.)*
*Eventual replacement:* a public nav-height/inset exposed by the shell, plus a documented page-gutter token per screen class.

**P0.3 — Settle token ownership.**
*Problem:* `RiksaPalette` (310), `AppColors` direct (179), `ProfilePalette` (146), `SocialPalette` (97) — and the latter two are near-duplicate APIs. Seven screens set their background seven different ways.
*Affected:* `social_palette.dart:5`, `profile_ui.dart:12,79`, `leaderboard_screen.dart:70`, plus the 179 direct `AppColors` sites.
*Why:* every new screen must choose a vocabulary, and each choice compounds the split.
*Eventual replacement:* one semantic palette; `ProfilePaletteScope` retained only if route-level re-skinning is a real product requirement, expressed as a `ThemeExtension` override rather than a parallel `InheritedWidget`.

**P0.4 — Rename the legacy `editorial*` / `brandJade*` alias layer.**
*Problem:* ~30 `AppColors` members carry names from an abandoned direction and resolve to violet-system values (`editorialAubergine = violet`); `editorialPink` alone has 27 references.
*Affected:* `app_theme.dart:48-64,95-123`, plus call sites across social, profile and leaderboard.
*Why:* it is the direct cause of `DESIGN.md` being wrong and makes feature code unreadable.
*Eventual replacement:* semantic names matching the shipped identity, with aliases removed rather than retained.

### P1 — Major visual inconsistencies

**P1.1 — Give "glass" a token and a widget.**
*Problem:* the app's signature chrome is copy-pasted across 8–10 files with identical alpha constants and variable names; two tab strips are line-for-line identical.
*Affected:* `riksa_bottom_navigation_bar.dart`, `riksa_search_bar.dart`, `ai_chat_screen.dart`, `leaderboard_scope_tabs.dart`, `learning_atoms.dart`, `social_feed_screen.dart`, `progress_history_screen.dart`, `profile_post_actions.dart`, and the four `*Glass*` widgets.
*Why:* highest-leverage single fix; it is both the largest duplication and the most identity-defining surface.
*Eventual replacement:* a `RiksaGlass` surface (or `RiksaElevation`-style recipe) exposing fill/border/selected tokens, consumed everywhere.

**P1.2 — Add bold roles to the type scale.**
*Problem:* the scale stops at w600; 153 uses of w700/w800/w900 across ~30 files are all local overrides, plus 131 raw `fontSize` values across 24 sizes and ~35 repeated inline shapes that are unnamed roles.
*Affected:* `RiksaTypography.textTheme` (`app_theme.dart:497`) and the repeated shapes listed under *Typography*.
*Why:* removes the most common reason to construct `TextStyle` by hand.
*Eventual replacement:* bold variants of the label/title/body roles; also resolve `displaySmall` == `headlineLarge`.

**P1.3 — Establish surface-elevation roles.**
*Problem:* one token (`RiksaElevation.low`, 6 uses) against 48 shadow definitions in 33 configurations.
*Affected:* the two organically-standard recipes named under *Elevation*, plus sheet/card/glass surfaces.
*Why:* without raised/overlay roles, every new surface invents a shadow.
*Eventual replacement:* promote the two existing de-facto recipes to `RiksaElevation.raised` / `.overlay`.

**P1.4 — Standardize the bottom-sheet surface.**
*Problem:* 12 call sites, three `backgroundColor` sources, radii of 16 / 28 / 36, inconsistent drag handles.
*Affected:* `streak_details_sheet.dart:11`, `social_create_menu.dart:21`, `social_feed_screen.dart:640`, `leaderboard_screen.dart:667`, `edit_profile_screen.dart:339,495`, `user_profile_screen.dart:424`, `community_detail_screen.dart:185`, `blog_composer_screen.dart:195`, `lesson_experience_screen.dart:329`.
*Why:* action menus are the most repeated modal pattern in the app.
*Eventual replacement:* one `RiksaSheet` wrapper; `isScrollControlled` remains per-call.

**P1.5 — Converge loading and empty states.**
*Problem:* 44 spinners vs 40 skeletons; a non-animating widget named `_PodiumLoadingShimmer`; a single-use third-party loader; the dashboard swallows errors in `SizedBox.shrink()`; profile collapses error into empty.
*Affected:* `leaderboard_states.dart:12`, `social_feed_screen.dart:1270`, `auth_switcher_screen.dart:329`, `home_dashboard_screen.dart:30`, `user_profile_screen.dart:958`, and the listed spinner screens.
*Why:* loading is the first thing every user sees on every screen.
*Eventual replacement:* content-shaped `RiksaSkeleton` as the default for content areas; spinners reserved for in-button/pagination; a distinct error state everywhere.

### P2 — Component duplication and cleanup

**P2.1 — Delete the dead leaderboard screen.** `lib/features/leaderBoard/leaderboard_screen.dart` — 1,055 lines, imported by nothing. Removing it also removes 25 raw colours, 16 raw font sizes, 9 bare whites and 4 token bypasses from every future measurement.

**P2.2 — Resolve the dead core cluster.** `RiksaSectionHeader`, `RiksaRoundedIconButton`, `FilterBottomSheet`, `DailyMissionCard`, `LessonCard`, `RiksaChoicePill`, `ActiveFilterChip`, `SubjectTile`, `SubjectArtwork`, `AnimatedRiksaProgress`, `RiksaPressableScale` — zero feature call sites; four survive only via golden tests. Each is either adopted or deleted *with* its golden test; leaving a tested-but-unused component is worse than either, because it makes the design system look adopted when it is not.

**P2.3 — Fold `_LeaderboardSearchField` into `RiksaSearchField`.** `presentation/leaderboard_screen.dart:217` is a near-verbatim copy whose divergences are all regressions, including the unlocalized `'Search learners'` hint.

**P2.4 — Unify the two identical tab strips, then the other three.** `LeaderboardScopeTabs` and `_FeedSectionTabs` first (line-for-line identical), then `_CategoryTabs`/`BlogTab`, `_ProgressSectionTabs`, `ProfileTabs`. Either adopt `TabBar`/`SegmentedButton` (whose themes are already configured and unused) or build one shared strip and delete `segmentedButtonTheme`.

**P2.5 — Introduce one shared screen header.** ~12 bespoke `_*Header` classes against 3 uses of the existing `RiksaPageHeader` and a dead `RiksaSectionHeader`.

**P2.6 — Give chips one variant-capable component.** Seven live feature chips; two dead core ones.

**P2.7 — Reduce the 77 `styleFrom` overrides** by encoding the recurring shapes (full-width 54px CTA, glass icon button, pill) as variants.

### P3 — Polish

- **P3.1 — Replace exact-duplicate literals with their tokens** (the 7 exact matches listed under *Color System*) and collapse the near-white cluster `#FFF7FB` / `#FFF8FC` / `#FFF9FC` / `#FFF7F7`.
- **P3.2 — Use `AppColors.socialLike`** instead of `Colors.red` (`social_post_card.dart:501,508`; `social_post_detail_screen.dart:971`), or delete the unused token.
- **P3.3 — Fix the const dark-mode bypasses:** `leaderboard_states.dart:229-239`, `profile_settings_screen.dart:203-209`, `edit_profile_screen.dart:569`.
- **P3.4 — Accessibility gaps:** size and label `_HeaderGlassIconButton`; add button semantics to comment actions and author identities; add the 5 missing `IconButton` tooltips; add `semanticLabel`/`excludeFromSemantics` to blog covers; localize `'Current Tab'` and `'Search learners'`.
- **P3.5 — Remove or adopt the three unused font families** (Noto Sans Khmer, Koulen, Kantumruy Pro) — 2.1 MB of `assets/fonts` referenced only by golden tests.
- **P3.6 — Resolve `AppRadii.row` == `AppRadii.large`** (both 16) and `displaySmall` == `headlineLarge` (both 21/w600).
- **P3.7 — Decide the icon policy** — Material vs `CupertinoIcons` (2 social files) vs emoji vs custom paint vs raster — and document when each applies.
- **P3.8 — Fix the broken `/auth/province` push** (`presentation/leaderboard_screen.dart:129` → `/province-select`). Functional bug, listed here for completeness.

---

## Consolidation Opportunities

**Current state**

- **181** distinct raw colour values outside the theme (**427** occurrences), against a **30**-field semantic palette and a **92**-member `AppColors`; **4** competing palette vocabularies; **6** ways to set a page background
- **24** distinct raw text sizes (**131** occurrences) against **15** theme roles; **6** font weights in use against **3** defined; ~**35** repeated inline styles that are unnamed roles; **6** declared font families, **3** actually rendered
- **1,204** raw spacing/dimension literals against a **7**-step scale; the most common value (20) untokenized; **4** page gutters; **4** hardcoded nav clearances
- **8** distinct radius values under **9** names; **17** distinct raw radii; **3** bottom-sheet radii
- **1** elevation token against **48** shadow definitions in **33** configurations
- **3** search fields; **5** live tab strips (2 identical); **7** live chips; ~**12** bespoke headers; **2** loading languages; **3** empty-state vocabularies; **77** button style overrides
- **11** of 28 core widgets with zero feature adoption; **1,055** lines of dead screen; **1** untokenized glass recipe copied across **8–10** files
- **13** design documents, **0** reliable sources of truth

**Plausible consolidated direction** — figures follow from the evidence above, not from a target picked in advance:

- **one** semantic palette as the only vocabulary, with the `editorial*`/`brandJade*` aliases renamed away; raw literals confined to the **6** illustration files, where they belong
- the existing **15** typography roles **plus bold variants** of the label/title/body roles — enough to absorb the 153 heavy-weight overrides without growing the scale's concepts
- the existing **7**-step spacing scale **plus a page-gutter token** and a public **nav-inset** constant; the 2-point intermediates (6/10/14/18/22) either admitted to the scale or removed
- **8** shape roles under **8** unambiguous names (resolving `row`/`large`), and **one** sheet shape
- **3** elevation roles — `low` (exists) plus `raised` and `overlay` promoted from the two recipes the code already converged on — plus **one** glass surface token
- **one** search component with flat and glass variants; **one** tab strip; **one** chip with variants; **one** page header; **one** skeleton-first loading language; **one** state view covering empty *and* error
- a shared button system with the variants the code already uses — full-width CTA, glass icon button, pill — replacing the bulk of the 77 overrides
- **one** `DESIGN.md`, generated from the theme, with everything else archived

---

## Evidence Appendix

### Verification method

Three read-only workers ran in parallel; the lead auditor independently reproduced every figure carried into this report.

| Worker | Tool | Scope | Outcome |
|---|---|---|---|
| W1 | `codex exec -s read-only` | Design-token census | **Completed** (30,606 B). Counts matched the auditor's independently on every cross-checked metric. |
| W2 | `agy` on an isolated `--no-hardlinks` clone | Component/architecture audit | **Failed twice, third run truncated.** Used only where corroborated. |
| W3 | `codex exec -s read-only` | Screen consistency + documentation | **Completed** (41,463 B). Content accurate; one filename wrong; one claim rejected. |

**Repository safety.** `git status --short` before and after is byte-identical (5 untracked markdown files + the skill directory). No file under `lib/`, `test/`, `docs/` or `assets/` was modified. The agy clone's `git status` was clean and its HEAD unchanged at `6c6cebb`, confirming no worker side effects. `UI_AUDIT.md` (an untracked artefact of a prior 2026-09-19 run, since invalidated by the `6c6cebb` merge) was regenerated.

### Worker claims rejected after verification

| Claim | Source | Verification |
|---|---|---|
| `RiksaSearchField` has 1 call site | W2 | **False** — 4 (`ai_tutor_screen.dart:158`, `interactive_onboarding_screen.dart:735`, `province_select_screen.dart:129`, + dead file) |
| `RiksaRoundedIconButton` used by `learning_status_bar.dart:45` | W2 | **False** — that file has no such reference; the widget has 0 call sites anywhere |
| "17 component families exhibit duplication" | W2 | Unsupported; no enumeration provided. Dropped |
| `StemSubjectTile` at `learning_design.dart:104` | W2 | **Wrong line** — it is at `:73`. W2's line numbers are systematically shifted and none were used |
| Social post detail has no empty-comments state | W3 | **False** — `_EmptyComments` (`social_post_detail_screen.dart:1013`) is used at `:354` with localized `l10n.noComments` |
| `lib/core/widgets/riksa_ui.dart` | W3 | **File does not exist** (cited twice); the correct path is `riksa_components.dart`. Line numbers were correct |

### Worker claims verified and retained

`DESIGN.md` aubergine contradiction · `UI_CLEANUP_PLAN.md` vs `REFERENCE_UI.md` nav contradiction · `HomeQuickActions` still rendered · broken `/auth/province` route · `Colors.red` vs unused `AppColors.socialLike` · `leaderboard_states.dart:229` const bypass · `profile_settings_screen.dart:203-209` hardcoded logout colours · three unused font families · dead `leaderboard_screen.dart` · `_HeaderGlassIconButton` 42×42 · dashboard error suppression.

### Key reproduction commands

```bash
# Raw colour occurrences outside the theme (427)
find lib -name '*.dart' ! -path 'lib/l10n/gen/*' ! -path 'lib/core/theme/*' \
  | xargs grep -hoP '(?<![A-Za-z])Colors\.[a-zA-Z]+|Color\(0x[0-9A-Fa-f]{8}\)' | wc -l

# Heavy weights the type scale does not define (153)
find lib -name '*.dart' ! -path 'lib/l10n/gen/*' ! -path 'lib/core/theme/*' \
  | xargs grep -hoP 'FontWeight\.w[789]00' | wc -l

# Core widgets with zero feature adoption
grep -rn "\bRiksaSectionHeader\b" lib test --include=*.dart | grep -v "class RiksaSectionHeader"

# The dead leaderboard screen (returns nothing)
grep -rn "leaderBoard/leaderboard_screen.dart" lib test tool

# The copied glass recipe (8 files)
grep -rl 'withValues(alpha: 0.58)' lib --include=*.dart \
  | while read f; do grep -q 'withValues(alpha: 0.72)' "$f" && echo "$f"; done
```

### Principal file references

| Concern | Path |
|---|---|
| Theme, tokens, typography | `lib/core/theme/app_theme.dart` (930 lines) |
| Shared components | `lib/core/widgets/riksa_components.dart` (1,596 lines, 32 classes) |
| Glass chrome | `lib/core/widgets/riksa_search_bar.dart`, `riksa_bottom_navigation_bar.dart` |
| Routing / shell | `lib/app/router/app_router.dart`, `app_shell.dart` |
| Parallel palettes | `lib/features/userProfile/presentation/widgets/profile_ui.dart:12,79`; `lib/features/social/presentation/widgets/social_palette.dart:5` |
| Feature design system (good) | `lib/features/learning/presentation/learning_design.dart` |
| Dead code | `lib/features/leaderBoard/leaderboard_screen.dart` |
| Identical tab strips | `lib/features/leaderBoard/presentation/widgets/leaderboard_scope_tabs.dart:9`; `lib/features/social/presentation/social_feed_screen.dart:795` |
| Contradictory docs | `DESIGN.md`, `docs/REFERENCE_UI.md`, `docs/UI_CLEANUP_PLAN.md`, `docs/EDITORIAL_DESIGN_SYSTEM.md` |

---

# Remediation Status — 2026-09-20

Implemented on `merge/sombath-onto-mine`, commits `119c4b4`..`8307cc9`.

**Verification method.** The baseline was **not green**: 319 passing / **84 failing**
before any change, almost all stale goldens from the `6c6cebb` glasses merge plus
the in-flight bottom-nav work. The golden suite therefore *cannot* detect a visual
regression from this refactor. Two things compensate:

1. Every extracted token is **numerically identical** to the literal it replaced,
   so migration is visually invisible by construction.
2. Verification is a **set-difference** against the recorded 84, not a "tests pass"
   claim.

Final state: `flutter analyze` **8 issues — identical to baseline**, tests **80 failing,
zero new failures**, 4 fixed (the deleted dead-component goldens).

## Addressed

| Item | Outcome |
|---|---|
| P0.1 | `DESIGN.md` corrected against the theme — primary colour, all 15 type roles, all 8 radii, glass/elevation/gutter tokens, the `editorial*` alias warning, the Khmer font gap |
| P0.2 *(partial)* | `RiksaSpacing.gutter = 20` added and documented. Nav-inset half **deferred** |
| P0.3 | `SocialPalette` retired (97 → 5 refs); `ProfilePalette` reduced (146 → 30 refs) |
| P1.1 | `RiksaGlass` tokens + `RiksaGlassSurface` / `RiksaGlassSelection`; 6 sites migrated |
| P1.2 *(partial)* | 9 bold `w700` roles added. Migrating the 153 existing overrides not done |
| P1.3 *(partial)* | `RiksaElevation.raised` / `.overlay` added. Migrating the 48 shadows not done |
| P2.1 | Dead 1,055-line leaderboard screen deleted |
| P2.2 | 11 dead core widgets + 3 orphaned helpers deleted with their goldens; live `RiksaPageHeader` coverage moved to a widget test |
| P2.4 *(partial)* | The two duplicated strips unified as `RiksaSegmentedTabs`. The other three not done |
| P3.1 | Five exact-duplicate literals replaced with their tokens |
| P3.2 | `AppColors.socialLike` adopted |
| P3.3 | Three const dark-mode bypasses fixed |
| P3.4 *(partial)* | Comment actions, author identities, blog cover, 48px targets. Nav string **deferred** |
| P3.6 | `AppRadii.row`/`large` and `displaySmall`/`headlineLarge` documented as intentional aliases (not changed — changing them is a visual redesign) |
| P3.8 | Broken `/auth/province` → `/province-select` fixed |

## Deferred — bottom navigation is owned by another developer

Not touched, by instruction. These remain open:

- **P0.2 (nav inset).** `RiksaBottomNavigationBar._height` is still private, and
  `blog_feed_screen` / `home_dashboard_screen` / `subject_roadmap_screen` /
  `lesson_catalog_screen` still hardcode 96 / 110 / 132 / 160 clearance.
- **P1.1 (nav glass).** `riksa_bottom_navigation_bar.dart` still carries its own
  inline copy of the glass recipe. It is the one remaining duplicate.
- **P3.4 (nav a11y).** The hardcoded English `'Current Tab'` and its empty `onTap`.
- **Doc contradiction #3.** `docs/REFERENCE_UI.md` and `docs/UI_CLEANUP_PLAN.md`
  specify mutually exclusive navigation. Both files are left entirely untouched.

## Rejected after verification — the audit was wrong

- **"3 `IconButton`s with 0 tooltips" (`social_feed_screen.dart`).** Those are the
  file's own `_HeaderGlassIconButton` class, not Flutter's widget, and both call
  sites already carry `Semantics(label:)`.
- **"The two tab strips are line-for-line identical."** They are not: 46px with
  outer padding and a selection haptic vs 48px with a container key. All
  differences preserved.
- **"The glass recipe recurs across 8 files."** Three of those are genuinely
  different surfaces — blur 18 + gradient; fill 0.58/0.72 with a blur-24 shadow;
  blur 12 over `panelSoft @ 0.6` — and were deliberately not migrated.
- **P3.5 (delete 3 unused fonts).** Refused. Koulen, Kantumruy Pro and Noto Sans
  Khmer are exactly the Khmer stack `DESIGN.md` specifies and `KHMER_TODO.md` is
  actively building toward. They are specified-but-unwired, not dead. The gap is
  now documented in `DESIGN.md` instead.

## Not attempted

P1.4 bottom-sheet surface, P1.5 loading/empty convergence, P2.3 `_LeaderboardSearchField`,
P2.5 shared screen header, P2.6 chips, P2.7 the 77 `styleFrom` overrides, P3.7 icon policy,
P0.4 the `editorial*` rename, and archiving the superseded documents.

P0.4 is deliberately sequenced last: consolidating the palettes first removed a
large share of the `editorial*` references, so the rename is now a smaller change
than the audit measured.
