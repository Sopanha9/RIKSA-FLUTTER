# Telegram sign-in flow (app)

The server contract, bot commands, and configuration live in the API repo:
[`RIKSA/docs/FLUTTER_TELEGRAM_AUTH.md`](../../RIKSA/docs/FLUTTER_TELEGRAM_AUTH.md)
(branch `feature/telegram-auth-options`). This page covers the app side.

## Screens (`lib/features/auth/presentation/telegram_auth_screen.dart`)

```
Login / Register ── Continue with Telegram ──► /auth/telegram
  [Options]
    ├─ Open Telegram ── POST /telegram/start → open tg:// (fallback https://t.me)
    │    [Waiting] spinner · "expires in 9:59" · Open Telegram again · Copy link
    │              · Having trouble? Log in with code · Cancel
    │      poll /telegram/status every pollIntervalSeconds, and immediately on resume
    │
    └─ Log in with code ── GET /telegram/bot
         [Code] "Paste the code from @riksa_bot to sign in."
                1 Open @riksa_bot and tap Start (or /code) · 2 Copy · 3 Paste
                [Open @riksa_bot]  [ VE9BLZ8J  📋 ]  [Sign in]
           POST /telegram/code

  AUTHENTICATED ───────────────────────────► /home
  PROFILE_REQUIRED ─► [Profile] username + display name (prefilled)
                        POST /telegram/complete → /home
                        409 → inline username error · 410 → back to options
  EXPIRED / DENIED ─► back to options with explanation
```

## Details

- **Code input:** upper-cases, keeps only letters and digits (`ve9b-lz8j` →
  `VE9BLZ8J`), and limits to 8 characters.
- **Paste button:** finds the code inside a copied bot message, so users can
  copy the whole message, then submits it. When the app resumes on the code step
  with an empty field, it checks the clipboard silently.
- **Polling errors:** network and 5xx errors keep polling, 429 backs off
  (x2, max 15 s), and 4xx errors return to the options with "expired".
- **Tokens:** `requestToken` and `signupToken` stay in widget state only and are
  never persisted or logged.
- **Tests:** `test/features/auth/presentation/auth_journey_test.dart`
  (options, one-tap, code, profile, fallbacks) and
  `test/visuals/telegram_auth_golden_test.dart` (intro, waiting, code, and
  profile screens in en and km).
