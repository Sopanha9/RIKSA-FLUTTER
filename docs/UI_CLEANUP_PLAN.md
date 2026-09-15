# UI cleanup plan

## Intended result

Keep the violet identity while giving each screen a clear main action. Use a
neutral light canvas, white secondary cards, green progress, and lime rewards.

## Implementation

1. Navigation: a floating deep-purple pill with a lime active icon and visible
   active label. Other destinations retain tooltips and accessible names.
   Keep the bar visible while scrolling at tab roots, hide it on pushed screens,
   and reserve its height in the shell so content and action buttons stay clear.
   Allow the bar to grow with larger text.
2. Home: remove the four shortcut tiles. Put Continue learning above the feed
   and link to Communities from the feed heading. Keep official post styling subtle.
3. Learning: move aggregate Bac II progress after the subject list. Use white
   subject cards, small subject accents, smaller portraits, and green progress.
4. Onboarding: strengthen the illustration's lavender clothing, enlarge the
   artwork, and reduce the gap before the heading.
5. Verification: cover tab switching, branch state, scroll persistence, pushed
   screens, content clearance, English/Khmer labels, and 200% text. Inspect screen
   previews before accepting updated visual baselines.

The navigation and color decisions here supersede the older aubergine/pink and
overlaid-navigation guidance in DESIGN.md for this cleanup.

## Result

Implemented and visually inspected on 2026-09-15. All 360 Flutter tests pass.
Static analysis of lib and test reports no issues. Navigation previews cover
English and Khmer, light and dark themes, and 100%/200% text on a 360dp screen.
Verification uses widget rendering and test data; no live backend or device run
was required for this UI cleanup.
