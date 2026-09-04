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

| Role | Light | Dark | Use |
|---|---|---|---|
| `canvas` | `#F9F9FB` | `#181713` | Page ground |
| `surface` | `#FFFFFF` | `#211F1A` | Raised content |
| `surfaceRaised` | `#EFEFF2` | `#2C2922` | Quiet fields, inactive states |
| `ink` | `#191619` | `#F8F0E3` | Primary text |
| `inkMuted` | `#706C73` | `#C7BDAE` | Metadata, supporting copy |
| `inkFaint` | `#A6A2AA` | `#958C7E` | Locked / not-yet states |
| `outline` | `#E6E6EA` | `#494238` | Hairlines, dividers |
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

- Never `#000` or `#fff` as text or ground. Use `ink` / `surface`.
- Locked and completed states differ by weight and hue, never by opacity alone.
- Full-bleed pastel card backgrounds are reserved for at most one element per
  screen: the current, resumable thing.

## Typography

Latin: **Poppins**. Khmer display: **Koulen**. Khmer body: **Kantumruy Pro**,
falling back to Noto Sans Khmer. Mixed-script strings must pass through
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
- Bottom navigation floats; every scroll view reserves ~112dp of bottom padding.

## Motion

`RiksaMotion`: 100ms fast, 200ms standard, 550/650ms emphasis. Standard curve
`easeOutCubic`. Reserve `easeOutBack` for a single earned moment (lesson
completion), never for routine state changes. Always respect
`MediaQuery.disableAnimations` via `RiksaMotion.resolve`.

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
- Pure black `#000000` anywhere. The anchor is aubergine `#2A061D`.
- Square corners and small radii on anything interactive.
- Long scrolling runs of same-size cards where colour carries no state.
- Rows of big-number metric tiles. One big number, on the earned screen, is the
  budget for the whole flow.
- Confetti and mascot celebration.
- Em dashes in UI copy.
