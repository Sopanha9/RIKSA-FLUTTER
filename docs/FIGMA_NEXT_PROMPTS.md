# Figma — next prompts for Codex (after the 38 screens)

Paste these into Codex **one at a time, in order**. Wait for each to finish and
check Figma before sending the next. Save a Figma version before 42a and 45.

Figma file: https://www.figma.com/design/Jp9KvJM3PSz0bEcaduViHN/Main

---

## Prompt A — Context (send first in a new Codex session)
```
We are continuing work on the RIKSA Figma file
https://www.figma.com/design/Jp9KvJM3PSz0bEcaduViHN/Main using the Figma MCP
tools. It already has 38 screen frames (01–38) on pages "1 Launch & Onboarding",
"2 Auth", "3 Home · Social · Blog", "4 Learn", "5 AI", "6 Leaderboard",
"7 Profile", built from the Flutter code in this repo.
Rules for everything that follows:
- The Dart code is the source of truth. Theme: lib/core/theme/app_theme.dart.
  Shared widgets: lib/core/widgets/. Router: lib/app/router/app_router.dart.
- Never invent a color, spacing or copy. Do not modify any Dart code.
- After each step, report what you changed and anything you could not match.
I will send the steps one at a time. Reply "ready" now.
```

## Prompt B — Open questions from Phase 1 (read-only)
```
Before continuing, answer these. Do not change Figma yet.
1. Frame 04: list every internal step of interactive_onboarding_screen.dart.
2. Frame 28: list every exercise type lesson_experience_screen.dart can render.
3. Frame 05: how many pages does onboarding_splash_screen.dart have?
4. Frame 18: what changes visually in question mode (?type=question)?
5. Frame 26: is the floating buddy shown on /learn? Is it in the frame?
6. Section 4: does the lesson player (28) or completion (29) hide the bottom nav?
   Does the frame match?
7. For frames 12, 20, 26 and 28, list anything that is NOT an exact match to the
   code (spacing, icons, colors, copy), even if small.
8. Did you create color/text styles or components during Phase 1? List them.
```

# Phase 2 — Reusable components + Light/Dark mode

Run this **after all 38 screens are done**, one prompt at a time, in order.
The order matters: colors become variables first, components are built on
those variables, then the screens use the components, and only then does dark
mode work everywhere with one switch.

The app already has a real dark theme: `RiksaPalette.light` and
`RiksaPalette.dark` in `lib/core/theme/app_theme.dart` (plus
`RiksaFeatureColors` and `RiksaSemanticColors`, each with `light`/`dark`).
Figma must use those exact values, not invented dark colors.

## Prompt 39 — Audit (read-only)
```
Phase 2, step 39. Do NOT change anything in Figma yet.
Go through all 38 frames and give me:
1. Every hard-coded color used, grouped by which RiksaPalette / RiksaFeatureColors
   / RiksaSemanticColors token it matches in lib/core/theme/app_theme.dart.
   List any color that matches NO token.
2. Every element that repeats across 2+ frames (buttons, inputs, cards, chips,
   tabs, app bars, list rows, avatars, badges, bottom nav, sheets, empty states…)
   with the frames it appears in and the Dart widget it comes from
   (check lib/core/widgets/ first, then feature widgets/ folders).
3. Every text style used, matched to the theme's text styles.
Output this as a table. This list is the plan for the next steps.
```

## Prompt 40 — Variables with Light and Dark modes
```
Phase 2, step 40. Create the design tokens as Figma variables.
Source: lib/core/theme/app_theme.dart.

- Collection "Color" with TWO modes: "Light" and "Dark".
  - One variable per RiksaPalette field (canvas, surface, surfaceRaised, ink,
    inkMuted, inkFaint, outline, jade, jadeStrong, jadeSoft, onJade, saffron,
    saffronSoft, blushSoft, creamSoft, math, science, language, technology,
    humanities, general, brand, brandStrong, brandSoft, onBrand, anchor,
    onAnchor). Light value from RiksaPalette.light, Dark from RiksaPalette.dark.
  - Groups "feature/…" and "semantic/…" for every field of RiksaFeatureColors
    and RiksaSemanticColors, again light/dark from the code.
  - Name them with slashes so they group: "surface/canvas", "text/ink",
    "brand/brand", "semantic/success", etc. Keep the Dart field name visible
    in the variable description.
- Collection "Size" (one mode): spacing and radius values the code uses
  (read the theme and lib/core/widgets for the constants).
- Text styles for every theme text style, with the real fonts.
- Keep the old color styles until step 44, then delete them.
Report every token you created with its light and dark values.
```

## Prompt 41 — Component library page
```
Phase 2, step 41. Create a Figma page "0 Components" and build the reusable
components from the step-39 list. Rules:
- Every fill, stroke and text color is BOUND to a "Color" variable. No raw hex.
  Spacing and radius bound to "Size" variables where possible.
- Match the Dart widget exactly: read its file before building it.
  Start with lib/core/widgets/: riksa_components.dart (RiksaSearchField,
  RiksaPastelCard, RiksaStateView, RiksaPageHeader, RiksaSkeleton,
  LessonCardSkeleton, IllustratedEmptyState), riksa_search_bar.dart,
  riksa_segmented_tabs.dart, riksa_glass.dart, riksa_avatar_image.dart,
  riksa_rank_badge.dart, riksa_bottom_navigation_bar.dart, language_toggle.dart,
  riksa_logo.dart / riksa_brand.dart. Then the repeated feature widgets
  (post card, lesson card, community card, comment row, chat bubble, etc.).
- Use variants for real states the code has: e.g. Button → type
  (primary/secondary/text), state (default/pressed/disabled/loading);
  Input → state (empty/filled/focused/error); Tab → selected true/false;
  Bottom nav → active tab (home/learn/ai/leaderboard/profile).
- Use component properties for text, icon swap and boolean show/hide, so
  instances are edited without detaching.
- Use auto layout everywhere so components resize with their content.
- Lay the page out in labeled sections (Buttons, Inputs, Cards, Navigation,
  Feedback, Avatars & Badges, …). Add each component's Dart file path to its
  description.
Tell me the full list of components and variants you created.
```

## Prompts 42a–42g — Swap screens to use the components (one section each)

### 42a
```
Phase 2, step 42a. On page "1 Launch & Onboarding" (frames 01–06):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```

### 42b
```
Phase 2, step 42b. On page "2 Auth" (frames 07–11):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```

### 42c
```
Phase 2, step 42c. On page "3 Home · Social · Blog" (frames 12–25):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```

### 42d
```
Phase 2, step 42d. On page "4 Learn" (frames 26–30):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```

### 42e
```
Phase 2, step 42e. On page "5 AI" (frames 31–32):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```

### 42f
```
Phase 2, step 42f. On page "6 Leaderboard" (frames 33):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```

### 42g
```
Phase 2, step 42g. On page "7 Profile" (frames 34–38):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```

## Prompt 43 — Dark mode frames
```
Phase 2, step 43. On every page 1–7, duplicate each frame and place the copy
directly BELOW the original (same x, 120px gap). Rename it with " · Dark" at
the end. On each copy set the "Color" variable mode to "Dark" at the frame
level. Do not recolor anything by hand; if something looks wrong in dark,
the cause is a raw color or a missing binding, so fix the binding
(in the component, not the instance) and tell me.
Check images and illustrations: if the Dart code swaps an asset or changes
opacity in dark mode (search for Brightness.dark / isDark in the screen and
widget files), do the same. Report anything that still looks wrong.
```

## Prompt 44 — Final QA
```
Phase 2, step 44. Check the whole file and report:
1. Any fill/stroke/text color not bound to a variable (list frame + layer).
2. Any detached instance, or hand-drawn element that should be an instance.
3. Any component not used anywhere, and any variant nobody uses.
4. Light vs dark: for each of the 38 pairs, anything with low contrast in dark
   (text under 4.5:1 against its background).
Fix 1 and 2. Only list 3 and 4 for me. Then delete the old color styles that
step 40 replaced, if nothing uses them.
```

**Tip:** to show dark/light as a switch in prototypes too, you only need the
variable modes: select any frame and change the "Color" mode in the right
panel.

---

# Phase 3 — One page + clickable prototype

Run **after Phase 2** (so every color is already a variable and dark mode
works). Save a Figma version first.

## Prompt 45 — All screens on one page
```
Phase 3, step 45. Create a page "App" and MOVE (not copy) every screen frame
from pages 1–7 onto it, light and dark. Keep "0 Components" as its own page.
Layout:
- One horizontal row per section, in route order (01 → 38), 80px apart:
  Row 1 Launch & Onboarding, Row 2 Auth, Row 3 Home · Social · Blog,
  Row 4 Learn, Row 5 AI, Row 6 Leaderboard, Row 7 Profile.
- Each section's Dark frames sit directly under its Light frames.
- Put a large text label at the left of each row with the section name, and
  wrap each section in a Figma Section named after it.
- 400px vertical gap between sections.
Then delete the now-empty pages 1–7. Confirm the count: 38 light + 38 dark
frames (plus any 04a/28a extras), and that no instance lost its component link.
```

## Prompt 46 — Clickable prototype (follow the real app navigation)
```
Phase 3, step 46. Wire the LIGHT frames on page "App" into a prototype that
behaves like the app. The navigation must come from the code, not guesses:
- Read lib/app/router/app_router.dart and search lib/ for context.go(,
  context.push(, context.pop(, router.go( and GoRouter calls. For each screen,
  list which element leads to which route.
- Add a prototype interaction on that element in Figma:
  context.go → "Navigate to" (instant or dissolve),
  context.push → "Navigate to" with Slide in from right,
  pop / back button → "Back".
- Bottom nav bar: in the bottom-nav COMPONENT, link each tab to its tab root
  (Home → 12, Learn → 26, AI → 31, Leaderboard → 33, Profile → 34), so every
  screen's nav works at once.
- Sheets and dialogs are not frames, so skip those taps.
- Starting point: frame 01 Splash, flow name "First run".
  Add a second flow "Signed in" starting at 26 Lesson Catalog.
- Theme switch: in 37 Settings, if the code has a theme/dark-mode control, give
  it the action "Set variable mode → Color: Dark" (and Light for the other
  option), so the whole prototype switches theme live.
Then copy the same interactions onto the Dark frames, or set the Dark frames'
flow to start at 01 · Dark.
Report a table: frame → element → destination, plus any route you could not
connect and why.
```

## Prompt 47 — Prototype check
```
Phase 3, step 47. Walk both flows in presentation order and report:
1. Frames that cannot be reached from any flow start.
2. Frames with no way back or forward (dead ends) that the real app doesn't have.
3. Any interaction pointing to the wrong frame compared with the code.
Fix what you can and list the rest.
```
