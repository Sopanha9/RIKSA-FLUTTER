# Authentication audit — 5 September 2026

## Scope and result

Reviewed Flutter authentication screens, routing, API adapters, token storage,
refresh/logout, localization, provider configuration, Android/iOS release setup,
and the sibling Riksa API's OTP contract. This is an auth-focused code and test
audit, not a penetration test or a review of every backend feature.

The existing Telegram OTP screen has been completed with destination details,
English/Khmer delivery guidance, one-time-code autofill, a 60-second resend
cooldown, clearing the previous code after resending, a change-account action,
safe back navigation for direct links, and guards against concurrent send/verify
requests. The cooldown is a UI convenience; backend rate limits remain authoritative.
The API currently limits sends to three per identifier per ten minutes.

## Verification

- `flutter analyze`: no issues.
- Full Flutter suite: 204 tests passed, including the existing golden tests.
- Release web build succeeded (using the local development API address).
- English and Khmer OTP golden previews were generated and visually checked.
- Eleven auth journey tests pass. These drive actual Flutter forms, the real
  auth notifier, AuthApi, Dio, and session storage abstraction. HTTP transport
  and platform storage are substituted; a small test router supplies a signed-in
  destination. They are not device/provider end-to-end tests.
- Covered: Telegram entry from login, registration details, code rejection and
  retry, resend success/failure, cooldown, validation, session restoration,
  logout, direct-route back navigation, Khmer at 360px/200% text, password login
  and registration, and blocked verification during resend.
- Live API smoke test at `http://localhost:8080`: registration, profile hydration,
  password login, refresh, refreshed profile, logout, revoked refresh rejection,
  and rejection of anonymous profile access passed. The missing-header response
  is HTTP 400, not 401; no profile was disclosed.
- Browser: the app launched and the Telegram account-entry screen rendered.
- Live Telegram delivery/verification and Google OAuth have **not** been completed.
  A successful mock-transport OTP test does not establish actual bot delivery.
- Native iOS/Android builds, native secure storage, and real device relaunch have
  not been verified in this audit.

Re-run local checks:

```sh
flutter analyze
flutter test
python3 tool/auth_smoke_test.py --base-url http://localhost:8080 --create-test-account
```

The live script creates a unique development user and retains it for inspection.
It uses a reserved `.invalid` email and revokes issued refresh tokens afterward;
it prints neither passwords nor tokens. It must not be aimed at production.
Two test users were created during this audit: `auth_audit_23dcf5e466` and
`auth_audit_ede093c534`. Their refresh sessions were revoked. Access tokens may
remain usable until their server-defined expiry.

## What you need to supply or do

1. **Identify the Telegram test account.** The local `riksa_db` had 13 users
   before testing, with zero non-null `telegram_id` and `telegram_chat_id`
   values. Past PostgreSQL OTP identifiers also had no match beginning `10`.
   This database therefore cannot identify the account you described. Provide
   the numeric chat ID, or identify the other environment/database containing it.
2. **Open/start your configured Riksa bot**, then use Telegram registration if
   this is a new account. For a complete live test, receive the code, enter it,
   verify landing in the signed-in app, restart the app, and log out. Test an
   incorrect code and resend as separate cases. Do not share bot tokens or JWT
   secrets in chat.
3. **Supply platform OAuth configuration.** The backend `.env` has a Google
   client ID and Telegram configuration present; presence is not proof of valid
   credentials. Flutter needs `GOOGLE_SERVER_CLIENT_ID`, plus
   `GOOGLE_IOS_CLIENT_ID` on iOS and the reversed client URL scheme. Web needs
   the configured client ID and its exact allowed origin. Follow
   `SOCIAL_AUTH_SETUP.md`; verify IDs against your provider accounts. The browser
   preview in this audit was started without Google client defines.
4. **Choose the release HTTPS API URL.** `API_BASE_URL` defaults to localhost
   (Android emulator: `10.0.2.2`). A physical phone needs a reachable host address;
   localhost on the phone points to the phone. Configure backend CORS for the
   actual web app origin when testing in a browser.
5. **Provide release signing configuration before publishing.** Android release
   currently uses the debug signing configuration. Add the actual upload/release
   key and matching Google OAuth fingerprint. Validate iOS signing and OAuth
   callbacks on a real device.

## Remaining development findings

| Priority | Finding and impact | Evidence / next work |
|---|---|---|
| High | Transient refresh failures erase the saved session. After a protected 401, a network error, 429, or 5xx during refresh becomes `false`, and the interceptor clears tokens. This conflicts with the notifier's intended recoverable-offline state. | `lib/core/network/dio_client.dart`: `_performRefresh` catch-all and refresh-failed branch. Distinguish revoked/invalid refresh from temporary failure, preserve tokens for the latter, and add transport regression cases. |
| High for release | Android permits cleartext traffic in the main manifest and signs release with debug keys. | `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`. Limit HTTP permission to development and configure production HTTPS/signing. |
| Medium | Recovery resend is an unguarded async callback: failures are not displayed and repeated taps can send overlapping requests. The final password step has no way to correct an invalid/expired code without restarting recovery. | `lib/features/auth/presentation/account_recovery_screen.dart`. Add guarded resend/error handling and navigation back to code entry. |
| Medium | Recovery/email-verification copy is hardcoded English and recovery validates only password length, unlike the registration/backend uppercase/lowercase/digit rule. | `account_recovery_screen.dart`, `auth_validators.dart`, backend `RegisterRequest.java`. Reuse validators and localized shared auth components. |
| Medium | Signed-in users are redirected away from `/auth/verify-email` before its screen can consume the token. | `lib/app/router/app_router.dart`: all signed-in `/auth` routes redirect to `/home`. Allow verification route when authenticated, with routing tests. |
| Medium | Telegram verification consumes the one-time code before checking whether a new account has names or an available username. A valid code can be spent on a failed registration. | Sibling `AuthService.telegramAuth`. Validate registration prerequisites before consuming the code, or design a short-lived verified challenge. Backend change required. |
| Medium | The app asks users for a numeric Telegram chat ID but provides no bot-opening/account-discovery flow. | `telegram_otp_screen.dart`. The sibling API has Telegram challenge endpoints; integrating that flow would eliminate manual chat-ID entry. |
| Low | Older planning documentation still claims Telegram is not a sign-in method. | `docs/AUTH_SCREEN_PLAN.md` contains historical claims contradicted by current `/auth/telegram`. Use this audit and `SOCIAL_AUTH_SETUP.md` for current behavior. |

These findings are separate from the completed OTP changes. No backend, signing,
provider secrets, or existing user records were modified to hide them.
