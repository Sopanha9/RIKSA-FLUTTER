# Riksa reference UI

The user-supplied screen board (15 September 2026) governs composition.
The accompanying component board governs the wordmark, mascot, illustration,
purple accents, pastel subject colors, and controls. The earlier dark floating
navigation proposal is superseded.

## Shared rules

- White/light lavender canvas, white secondary surfaces, purple primary actions.
- Compact rounded cards: 14-20dp corners, 16dp page gutters, 8-12dp internal gaps.
- Page headings 20-22dp, section headings 16dp, body 14dp. Reading stays 16dp.
- Use the same Poppins and Khmer type families through the shared typography helpers.
- Slim white bottom navigation at tab roots; all five icon labels remain visible.
  Purple marks selection. Reserve navigation height; no hiding on scroll.
- Pushed pages use back navigation and do not stack another tab bar.
- Green progress, pale lime for the learner's rank, quiet lavender selected controls.
- Keep button targets at least 48dp; allow labels and rows to grow at larger text.
- Reuse the Riksa wordmark, study-buddy mascot and subject icon family.
- User data, loading, retry, empty, and disabled states retain their real behavior.

## Screen compositions

Home: greeting, search, four pastel destinations, compact learning card, feed.
Learning: compact resume card and subject rows with small subject marks.
Leaderboard: heading, scope controls/search, personal rank, all ranked users as rows.
Profile: compact avatar/identity panel, progress, menu rows, existing content tabs.
Auth/onboarding: wordmark or learner illustration, concise copy, purple action.
AI: existing study-buddy mascot, white conversation surfaces and compact prompts.
Saved lessons, communities, blog and settings inherit the same type, shape and
surface rules without losing their existing actions.

## Verification

Inspect the rendered screen family, not just isolated components. Test navigation,
forms, loading/error states, 360dp layouts, English/Khmer, dark mode and large text.
Visual tests record accepted output; they do not establish reference fidelity.
