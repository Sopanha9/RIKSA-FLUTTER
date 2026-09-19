# Capybara idle animation

First animation asset trial for Riksa's study companion. The assets are
registered in `pubspec.yaml` and displayed on the Home feed (`/home`).

## Files

- `../../assets/images/capybara/idle.webp`: looping animated WebP.
- `../../assets/images/capybara/idle.png`: matching static fallback.
- `idle-preview.mp4`: silent video preview of one loop.
- `size-check.png`: static checks at 96 × 120, 128 × 160, and 160 × 200.

## Preparation

Source: user-provided `Animate_this_exact_illustrated.mp4`, a 1280 × 720,
24 fps video approximately 10 seconds long. The source remains unchanged.

- Selected source interval: 0.25–8.50 seconds (8.25 seconds).
- Compared early and late source frames to select similar endpoint poses.
- Fixed crop: x=426, y=158, width=400, height=500. This retains the character
  and scarf movement with margin throughout the selected interval.
- Output: 320 × 400, 16 fps. WebP frame durations alternate 62 and 63 ms.
- WebP quality: 82, infinite loop. Video preview uses H.264 with no audio.
- The original near-white background is retained; these are opaque assets.
- No interpolation, reverse playback, or crossfade has been added.

## Home integration

`RiksaStudyBuddy` handles animated/static playback; `RiksaStudyBuddyCard` provides
localized English/Khmer copy, an Open lessons action, and a session pause/play
control. The action opens `/learn` so the existing roadmap can choose the next
lesson without making a separate network request for the card.

The Home feed shows the card below the “What are your doubts?” composer. It is omitted while
searching, in the Blog section, and on the separate `/community` route. The
opaque artwork sits in a light card in both light and dark themes.

The widget selects the PNG when reduced motion is enabled, playback is paused
by the student, the artwork leaves its scroll viewport, the app is inactive,
the route is covered, or the navigation branch has disabled tickers. The PNG
also handles animated-asset load failures. Large text switches the artwork and
copy to a vertical layout. No new packages or AI calls are involved.

Widget tests cover asset decoding, pause/play, navigation, scrolling, app
lifecycle, inactive tickers, covered routes, semantics, and Khmer at 200% text
scale on a 360dp screen. Home snapshots live in
`test/visuals/goldens/home_study_buddy_en_light.png` and
`test/visuals/goldens/home_study_buddy_km_dark.png`.

## Visual limits and device follow-up

Gemini changed the original standing reference into a seated character. The
clip contains a prolonged eyes-closed smile and a scarf sway. It suits a calm
resting moment, but should not be described as an exact reproduction of the
original pose sheet. The loop endpoints are similar, not identical.

No phone was connected during integration. Measure playback on a target
Android device before a wider rollout;
compressed file size alone does not establish runtime memory or battery cost.

Transparent background processing and other reactions are separate follow-up
work.
