# Riksa — Design System

**Source of truth: [app_theme.dart](lib/core/theme/app_theme.dart).** Where this
document and the code disagree, the code wins and this document is the bug. Every
value below was checked against the theme on 2026-09-20; sections marked
*known deviation* describe where the shipped app knowingly differs from the
stated rule.

Tokens are reached through `context.riksa` (a `RiksaPalette` theme extension).
Prefer it in feature code. Direct `AppColors` imports still exist in roughly 180
places — they are not yet an error, but new code should not add more, because
`AppColors` bypasses the dark-aware layer.

## Direction

**Playful and minimal, on rounded pastel blocks.** Soft pastel surfaces carry
the warmth, generous radii carry the friendliness, and a single saturated violet
(`AppColors.violet` `#7657EE`, never pure black) carries every primary action
as a full pill. Air between blocks does the separating; hairline borders are
rare. Line-art illustration, pastel discs and small four-point sparkles are the
decorative vocabulary. One loud moment per flow, quiet everywhere else.

> **Naming warning.** `AppColors` still carries an `editorial*` / `brandJade*`
> vocabulary from an abandoned direction, aliased onto the current violet
> system — `editorialAubergine`, `editorialPink` and friends resolve to violet
> values, not to the near-black or pink their names suggest. The values are
> correct; the names lie. Read them as aliases, not as descriptions.

This is not an editorial or spec-sheet system. Mono labels, hairline rules and
tabular column layouts are out of register. `docs/EDITORIAL_DESIGN_SYSTEM.md`
describes a superseded direction and does not govern.

## Color

### Strategy

**Pastel surfaces, one meaning each.** Colour must carry state, not decoration.
Within the learning tab:

| Hue | Meaning |
|---|---|
| Pink `#FBDCEE` | Current. The one thing you can resume right now. |
| Mint `#DDF0DC` | Done. |
| White `#FFFFFF` | Available, not started. |
| Cream `#FBEBCD` | The goal, and set-apart content such as formulas. |
| Violet `#7657EE` | Actions, and the fixed destination bar. |

At most one pastel-filled focal surface per screen, plus one drenched screen per
flow for the earned moment. The failure mode to avoid is the current lesson
catalog: every card flooded in `editorialPinkSoft`, so hue carries no
information and the screen reads as one pink mass.

### Roles

Dark mode runs on X's "Lights out" palette: a true-black ground with near-black
raised surfaces. Light mode is unchanged.

| Role | Light | Dark | Use |
|---|---|---|---|
| `canvas` | `#F9F9FB` | `#000000` | Page ground |
| `surface` | `#FFFFFF` | `#16181C` | Raised content |
| `surfaceRaised` | `#EFEFF2` | `#1D2024` | Quiet fields, inactive states |
| `ink` | `#191619` | `#E7E9EA` | Primary text |
| `inkMuted` | `#706C73` | `#71767B` | Metadata, supporting copy |
| `inkFaint` | `#A6A2AA` | `#4B4E51` | Locked / not-yet states |
| `outline` | `#E6E6EA` | `#2F3336` | Hairlines, dividers |
| `jade` | `#237A5B` | `#69B893` | Completion, understood |
| `saffron` | `#E69A18` | `#F4B84D` | Streak, XP, current position |

Interaction anchor: `AppColors.violet` `#7657EE`, which is what
`editorialAubergine` resolves to. The dark-mode accent is `editorialPink`
`#9D86F7` — a lavender, despite the name. `editorialBlack` is `#1D1533`, the
same value as `ink`. None of these three is a default surface.

### Subject hues

One per STEM subject, used at full strength on marks and numerals, and as a
6–12% tint on the single focal surface of that subject's screen.

| Subject | Light | Dark |
|---|---|---|
| Mathematics | `#76528F` | `#B49ACA` |
| Physics / Technology | `#3974A8` | `#83B5DF` |
| Chemistry | `#B87824` | `#E5AE62` |
| Biology / Science | `#198A82` | `#69C4BC` |
| General | `#68715A` | `#ADB69C` |

### Rules

- Never `#000` or `#fff` as **text**. Use `ink` / `surface`.
- The dark ground is the one exception: `canvas` is true black in dark mode,
  matching X's "Lights out". On the OLED phones the product targets it draws no
  backlight and the panel edge disappears entirely. Everything drawn on it,
  including `onJade`, still uses a near-black or near-white, never `#000`
  or `#fff`.
- Locked and completed states differ by weight and hue, never by opacity alone.
- Full-bleed pastel card backgrounds are reserved for at most one element per
  screen: the current, resumable thing.

## Typography

Latin: **Poppins**. Khmer display: **Koulen**. Khmer body:
**Khmer OS Siemreap**, falling back to Kantumruy Pro and Noto Sans Khmer.

> **Known gap.** Only Poppins, Reddit Sans (legacy fallback) and Khmer OS
> Siemreap are actually referenced from `lib/`. Koulen, Kantumruy Pro and Noto
> Sans Khmer ship in the bundle (~2.1 MB) and are loaded by golden tests, but no
> runtime code selects them — so the Khmer display face specified above does not
> currently render. Wire them up or drop them deliberately; do not delete them
> as "unused" while this section still specifies them.
Mixed-script strings must pass through
`RiksaTypography.titleStyleFor` / `bodyStyleFor`, which swap family, weight and
line height per script.

Scale (from `RiksaTypography.textTheme`), contrast ratio ≥1.25 between adjacent
display steps:

| Step | Size / weight | Use |
|---|---|---|
| `displayLarge` | 26 / 600 | Screen title |
| `displayMedium` | 24 / 600 | Screen title, tighter |
| `displaySmall` | 21 / 600 | Alias of `headlineLarge` |
| `headlineLarge` | 21 / 600 | Focal card title — prefer this over `displaySmall` |
| `headlineMedium` | 18 / 600 | Section heading |
| `headlineSmall` | 16 / 600 | Sub-heading |
| `titleLarge` | 17 / 500 | Lesson row title |
| `titleMedium` | 15 / 500 | Row title |
| `titleSmall` | 14 / 500 | Dense row title |
| `bodyLarge` | 15 / 400 | Lesson reading copy |
| `bodyMedium` | 13.5 / 400 | Body copy |
| `bodySmall` | 11.5 / 400 | Supporting copy (muted) |
| `labelLarge` | 13 / 500 | Button and tab labels |
| `labelMedium` | 11.5 / 500 | Metadata |
| `labelSmall` | 10.5 / 400 | Unit labels (muted) |

**Bold roles.** The scale above stops at w600. For emphasis use the w700
variants rather than an inline `TextStyle`: `labelLargeBold`, `labelMediumBold`,
`labelSmallBold`, `titleLargeBold`, `titleMediumBold`, `titleSmallBold`,
`bodyLargeBold`, `bodyMediumBold`, `bodySmallBold`. They are a `TextTheme`
extension, so `Theme.of(context).textTheme.titleMediumBold` resolves them. Each
differs from its base role only in weight.

- Lesson reading copy sits at 16–17px with 1.6 line height and a measure capped
  near 68 characters. Reading is the one place that gets generous leading.
- Metadata stays 400–600. When everything is 800 the hierarchy is gone.
- Khmer titles run taller: allow `height: 1.15–1.3` and never fix a title row
  to a single line height computed from Latin.

## Surfaces and shape

| Radius | Token | Use |
|---|---|---|
| 8 | `AppRadii.small` | Small inner shapes |
| 13 | `AppRadii.badge` | Icon badges (squircle, never a square) |
| 14 | `AppRadii.medium` | Rows nested inside a panel |
| 16 | `AppRadii.row` / `AppRadii.large` | Cards and rows — two names, one value |
| 20 | `AppRadii.panel` | Panels, inline blocks |
| 24 | `AppRadii.feature` | Feature cards |
| 28 | `AppRadii.extraLarge` | Drenched headers, tall sheets |
| full | `AppRadii.fullBorder` | Buttons, chips, avatars |

`row` and `large` are both 16. The duplication is intentional and kept for
compatibility; prefer `large` unless the shape really is a list row.

Nothing is square and nothing is hard-edged. Buttons are always full pills at
54dp, never rectangles with a small radius.

- Space is the default separator. Borders are the exception, and are hairlines
  at `outline`.
- One level of nesting is allowed and expected: white pill rows inside a pastel
  unit panel. Two levels is not.
- Elevation has three roles and nothing else. Do not hand-write a `BoxShadow`.
  - `RiksaElevation.low` — resting cards. The current item may carry one soft
    shadow to lift it off its pastel ground.
  - `RiksaElevation.raised` — ink @ 6%, blur 10, offset (0,4). Selected chips
    and small lifted surfaces.
  - `RiksaElevation.overlay` — ink @ 18% dark / 8% light, blur 18, offset (0,8).
    Glass chrome, sheets and floating bars.

## Glass

Glass is the app's signature chrome, not decoration: a blur, a translucent
fill and a hairline light border, used for floating controls that sit over
content. It is a token, never hand-rolled.

- `context.riksaGlass` gives `fill`, `border`, `selectedFill`, `selectedBorder`
  and `blurSigma` (14 by default), all brightness-aware.
- `RiksaGlassSurface` draws the full recipe — shadow, clip, backdrop blur, fill
  and border. `RiksaGlassSelection` draws the selected chip inside a strip.
- `RiksaSegmentedTabs` is the shared glass tab strip. Do not build another.

Use glass for chrome that floats over scrolling content. Do not use it for
resting content surfaces — those are flat pastel or `surface`.

## Layout

- Base grid 4dp. Screen gutter is `RiksaSpacing.gutter` (20dp) — use the token,
  not a literal. Auth and AI reading surfaces may widen to 24dp. Section rhythm
  varies deliberately: 24dp inside a group, 32–40dp between groups.
- `RiksaSpacing` is 4 / 8 / 12 / 16 / **20 (`gutter`)** / 24 / 32 / 48. Values
  off that scale (6, 10, 14, 18, 22) are legacy and should not be added to.
- Must hold at 360dp width and at 200% text scale.
- Bottom navigation floats on the screen a tab lands on, and every scroll view
  there reserves ~112dp of bottom padding for it.
- A screen pushed on top of a tab does not get the tab bar. It already draws a
  back control — an explicit one, or the leading arrow an `AppBar` implies — so
  the tabs would be a second way out, and on a lesson, a chat, a composer or a
  settings form they stack on top of that screen's own bottom bar and shrink the
  content area one step further at every level.
- The rule lives in `showsBottomNavigation` in
  [app_shell.dart](lib/app/router/app_shell.dart) and reads the route stack, not
  a list of paths, so a new screen is covered by how it is navigated to rather
  than by remembering to register it. Reach a screen with `push` and it is a
  step; reach it with `go` and it is a destination. A pushed screen must not
  reserve the 112dp, or it will leave a dead strip.

## Motion

`RiksaMotion`: 100ms fast, 200ms standard, 550/650ms emphasis, 30ms stagger.
Standard curve `easeOutCubic`. Reserve `easeOutBack` for a single earned moment
(lesson completion), never for routine state changes. Always respect
`MediaQuery.disableAnimations` via `RiksaMotion.resolve`.

**Values arrive, they do not appear.** Anything the learner earned (progress
tracks and rings, their own rank and XP) animates from zero on first paint. A
bar painted straight at its value reads as a fact about the database; a bar that
fills reads as ground the learner covered. Use `RiksaCountUp` for numerals and
seed every progress tween with an explicit `begin: 0`, because
`TweenAnimationBuilder` without a `begin` starts at the end value and only moves
on later changes.

**Lists assemble.** Rows enter through `RiksaEntrance`, offset by index, capped
at 8 rows so a long list still finishes promptly. It drops its own `Opacity` and
`Transform` once the row lands, so a long feed does not carry a `saveLayer` per
row for the rest of the session.

Restraint still applies. Animate the learner's own numbers, not everyone's: six
XP counters ticking at once is the gamified noise the product sets itself
against.

## Interaction and personality

**Respond on contact.** Primary learning buttons, icon controls and tappable
cards use `RiksaTapFeedback`: a 100ms press to 97% scale, released on lift,
cancel or scroll. The native button retains keyboard activation, ripple and
semantics. Disabled and busy actions do not react or submit again.

**Show the handoff.** Desktop navigation uses a 240ms fade and small lift; mobile keeps native
iOS swipe-back and Android predictive back. Lesson steps use `RiksaContentReveal` for a 200ms
arrival. Animate only a new step, never each keystroke; preserve field focus,
selection and scroll state. Do not keep an outgoing interactive copy of a form.

**Make the outcome clear.** An in-flight primary action keeps its accent color
and shows a short localized status beside its spinner. Feedback includes an
icon and words, not color alone. A confirmed completion draws one checkmark
and counts the earned XP once. Never delay a result to make an animation last.
Reduced motion removes movement and uses a static loading indicator.

**Give empty states a useful personality.** The illustration is a small open
book with a tucked-in pink bookmark and two ink sparkles. It arrives once;
it does not bounce while someone reads. A warm title names the opportunity,
body copy explains the next step, and one button helps the student take it.
Failures describe what happened and offer recovery without blaming the learner.
Keep Khmer and English equally natural.

**Hierarchy comes before decoration.** Use a bold lesson or section title,
medium-weight action labels and regular reading copy with generous leading.
Aubergine in light mode and pink in dark mode mark the primary action; jade
marks confirmed progress. Give these elements room instead of filling every
gap with another card. Riksa's pastel blocks, book artwork and STEM content
are the concrete visual references. When borrowing an external reference,
record the specific typography, spacing or motion behavior being adopted.

## Component conventions

- Shared widgets live in [riksa_components.dart](lib/core/widgets/riksa_components.dart).
- Every interactive element carries a stable `ValueKey` for widget and golden
  tests (`test/visuals/goldens/`). Renaming a key breaks tests; update both.
- All user-facing strings come from `AppLocalizations` with entries in both
  `lib/l10n/app_en.arb` and `lib/l10n/app_km.arb`.

## Banned

- Side-stripe borders as accents.
- Gradient text. *Known deviation:* gradient card fills were banned here, but
  about ten ship today, including the dashboard learning card. Treat them as
  legacy — do not add more, and prefer a flat pastel for anything new.
- Glass used as decoration, or hand-rolled. Glass itself is sanctioned chrome —
  see **Glass** above — but only through `RiksaGlassSurface` /
  `RiksaSegmentedTabs`, and only for controls floating over content.
- Pure black `#000000` as text, or as any light-mode surface. The action
  anchor is violet `#7657EE` in light and lavender `#9D86F7` in dark; the
  dark-mode page ground is the single sanctioned use of true black.
- Square corners and small radii on anything interactive.
- Long scrolling runs of same-size cards where colour carries no state.
- Rows of big-number metric tiles. One big number, on the earned screen, is the
  budget for the whole flow.
- Confetti and mascot celebration.
- Em dashes in UI copy.
