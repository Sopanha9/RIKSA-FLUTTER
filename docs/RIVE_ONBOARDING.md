# Riksa onboarding Rive contract

Export the production animation to:

```text
assets/rive/onboarding.riv
```

The file must contain these case-sensitive names:

| Scene | Artboard | State machine |
| --- | --- | --- |
| Learning | `Learning` | `Onboarding` |
| Achievement | `Achievement` | `Onboarding` |
| Community | `Community` | `Onboarding` |

Each artboard should use a transparent square canvas and preserve the visual
language of the matching PNG in `assets/images/splashScreen/`. Keep localized
copy in Flutter; do not embed text in the Rive file.

Use Rive listeners for tap reactions. The Flutter runtime pauses inactive
artboards, so the state machine must resume cleanly and should settle whenever
there is no active animation.

## Motion brief

- **Learning:** open the book, turn a page, draw with the pencil, and gently
  pulse the video tile.
- **Achievement:** land the trophy, fill the progress bar, pop the XP coin, and
  give the flame a small reaction.
- **Community:** reveal the messages, blink the characters, and wave with one
  character.
- Keep entrance motion around 600-900 ms and idle motion subtle.
- Keep important artwork inside a 12% safe area on every edge.
- Aim to keep `onboarding.riv` below 500 KB.

The app automatically uses the current PNG when motion is disabled or when the
Rive file, artboard, or state machine cannot be loaded.
