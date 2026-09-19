# Riksa — Design System

Flutter. Tokens live in [app_theme.dart](lib/core/theme/app_theme.dart) and are
reached through `context.riksa` (a `RiksaPalette` theme extension), never by
importing raw `AppColors` into feature code.

## Direction

**Playful and minimal, on rounded pastel blocks.** Soft pastel surfaces carry
the warmth, generous radii carry the friendliness, and a single warm near-black
(`editorialAubergine` `#2A061D`, never pure black) carries every primary action
as a full pill. Air between blocks does the separating; hairline borders are
rare. Line-art illustration, pastel discs and small four-point sparkles are the
decorative vocabulary. One loud moment per flow, quiet everywhere else.

This is not an editorial or spec-sheet system. Mono labels, hairline rules and
tabular column layouts are out of register.

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
| Aubergine `#2A061D` | Actions, and the fixed destination bar. |

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

Interaction anchor: `editorialBlack` `#111012` in light, `editorialPink`
`#EE8FD0` in dark. Pink is an accent and a dark-mode anchor. It is not a
default surface.

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
Mixed-script strings must pass through
`RiksaTypography.titleStyleFor` / `bodyStyleFor`, which swap family, weight and
line height per script.

Scale (from `RiksaTypography.textTheme`), contrast ratio ≥1.25 between adjacent
display steps:

| Step | Size / weight | Use |
|---|---|---|
| `displaySmall` | 28 / 700 | Screen title |
| `headlineSmall` | 21 / 700 | Focal card title |
| `titleMedium` | 17 / 600 | Lesson row title |
| `bodyMedium` | 14 / 400 | Lesson reading copy |
| `labelSmall` | 11 / 600 | Metadata, unit labels |

- Lesson reading copy sits at 16–17px with 1.6 line height and a measure capped
  near 68 characters. Reading is the one place that gets generous leading.
- Metadata stays 400–600. When everything is 800 the hierarchy is gone.
- Khmer titles run taller: allow `height: 1.15–1.3` and never fix a title row
  to a single line height computed from Latin.

## Surfaces and shape

| Radius | Token | Use |
|---|---|---|
| 13 | `AppRadii.small` | Icon badges (squircle, never a square) |
| 15 | `AppRadii.medium` | Rows nested inside a panel |
| 20 | `AppRadii.large` | Secondary cards |
| 24 | `AppRadii.large`+ | Panels, inline blocks |
| 32 | `AppRadii.extraLarge` | Feature cards, drenched headers |
| full | `AppRadii.fullBorder` | Buttons, chips, avatars |

Nothing is square and nothing is hard-edged. Buttons are always full pills at
54dp, never rectangles with a small radius.

- Space is the default separator. Borders are the exception, and are hairlines
  at `outline`.
- One level of nesting is allowed and expected: white pill rows inside a pastel
  unit panel. Two levels is not.
- Elevation is a single low shadow (`RiksaElevation.low`) or nothing. The
  current item may carry one soft shadow to lift it off its pastel ground.

## Layout

- Base grid 4dp. Screen gutter 18–20dp. Section rhythm varies deliberately:
  24dp inside a group, 32–40dp between groups.
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
- Gradient text and gradient card fills. Pastels are flat.
- Decorative glassmorphism.
- Pure black `#000000` as text, or as any light-mode surface. The action
  anchor is aubergine `#2A061D` in light and pink `#EE8FD0` in dark; the
  dark-mode page ground is the single sanctioned use of true black.
- Square corners and small radii on anything interactive.
- Long scrolling runs of same-size cards where colour carries no state.
- Rows of big-number metric tiles. One big number, on the earned screen, is the
  budget for the whole flow.
- Confetti and mascot celebration.
- Em dashes in UI copy.
