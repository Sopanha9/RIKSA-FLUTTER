# Riksa Flutter Splash & Authentication Plan

**Status:** Phase 1 and core password-auth UI implemented; backend-gated work remains  
**Prepared:** 2026-08-16  
**Flutter app:** `riksa_app`  
**Backend:** sibling repository `../riksa-api`

### 2026-08-16 implementation checkpoint

- Splash/bootstrap, first-run language gate, login, and two-step registration
  are implemented with the selective-glass design treatment.
- Session storage, `/auth/me` hydration, one-time refresh retry, terminal
  session expiry, typed errors, localization, and guarded routing are wired.
- `flutter analyze`, 12 automated tests, the web release build, and the Android
  debug APK build pass.
- A live local-backend smoke test passed for register, `/auth/me`, refresh-token
  rotation, logout, and login.
- Province onboarding, recovery, Telegram, and production Google remain hidden
  until their documented backend blockers are resolved.

## 1. Goal

Build a production-ready splash and authentication experience for the Riksa
Flutter app, connect it to the implemented Spring Boot auth API, and verify the
critical flows against a real local backend.

This plan covers:

- native launch screen and animated Flutter splash;
- first-run language selection (English and Khmer);
- session bootstrap and guarded routing;
- username/password registration and login;
- one-time province selection after any authentication method;
- refresh-token rotation and logout;
- forgot/reset password through Telegram OTP;
- Google sign-in after mobile OAuth configuration;
- reusable auth models, storage, error handling, localization, and tests.

The main app shell is only an auth destination in this plan. Building its
feature tabs is outside this scope.

## 2. Contract source of truth

The implementation must follow the current Java source, especially:

- `AuthController.java` and `AuthEndpoints.java` for routes;
- the request/response DTOs under `com.riksa.auth` for JSON fields and validation;
- `AuthService.java` and `OAuth2Service.java` for behavior;
- `SecurityConfig.java`, `JwtAuthenticationFilter.java`, and
  `RateLimitFilter.java` for security behavior;
- `application.yml` for token, OTP, lockout, and rate-limit defaults.

`riksa-api/docs/AUTH_API.md` is the audited frontend/backend integration guide
for the current working tree. Java controllers, DTOs, services, security code,
and migrations remain the ultimate executable source of truth when the two
disagree.

## 3. Confirmed backend API contract

Base URL for local development: `http://localhost:8080`  
API prefix: `/api/v1`  
Auth prefix: `/api/v1/auth`

| Action | Method and path | Request JSON | Success JSON | Client treatment |
|---|---|---|---|---|
| Register | `POST /auth/register` | `username`, `displayName`, `email`, `password`; optional `phoneNumber`, `gender`, `provinceId` | `AuthResponse` | Persist tokens, load profile, and apply the province-completion gate |
| Login | `POST /auth/login` | `username`, `password` | `AuthResponse` | Persist tokens, load profile, and apply the province-completion gate |
| Refresh | `POST /auth/refresh` | `refreshToken` | New `AuthResponse` | Atomically replace the complete session |
| Logout | `POST /auth/logout` | `refreshToken` | `{message}` | Always clear the local session, even if the call fails |
| Google | `POST /auth/google` | `idToken`; optional `username`, `displayName`, `provinceId` | `AuthResponse` | Persist tokens, load profile, and apply the province-completion gate |
| Send OTP | `POST /auth/otp/send` | `identifier` only | `{message, channel: "TELEGRAM"}` | Start OTP timer; never expect the code in JSON |
| Verify OTP | `POST /auth/otp/verify` | `identifier`, `code` | `{verified, message}` | Verification only; it does not create a login session |
| Forgot password | `POST /auth/forgot-password` | `identifier` | `{message}` | Continue to OTP/reset step only on success |
| Reset password | `POST /auth/reset-password` | `identifier`, `code`, `newPassword` | `{message}` | Return to login after success |
| Verify email | `POST /auth/verify-email` | `token` | `{verified, message}` | Show success/failure; no session is returned |
| Current user | `GET /auth/me` | Bearer access token | `UserProfileResponse` | Validate and hydrate a restored session |
| Update user | `PUT /auth/me` | Bearer access token plus supplied profile fields | `UserProfileResponse` | Replace cached profile |

All paths in the table are relative to `/api/v1` because the existing
`DioClient` already includes that prefix.

### Auth response

```json
{
  "userId": "uuid",
  "accessToken": "jwt",
  "refreshToken": "jwt",
  "tokenType": "Bearer",
  "username": "name",
  "role": "USER"
}
```

### Profile response

```json
{
  "id": "uuid",
  "username": "name",
  "displayName": "Display Name",
  "email": "user@example.com",
  "emailVerified": false,
  "avatarUrl": "/avatars/avatar-1.png",
  "bio": null,
  "gender": null,
  "phoneNumber": null,
  "phoneVerified": false,
  "role": "USER",
  "countryId": "KH",
  "createdAt": "2026-08-16T10:00:00+07:00"
}
```

### Error response

Most backend errors use:

```json
{
  "timestamp": "ISO-8601 timestamp",
  "status": 400,
  "error": "Bad Request",
  "message": "Human-readable message"
}
```

The auth rate limiter returns the same core fields without `timestamp`.
The client must safely support both shapes.

### Validation and security behavior

- Username registration: required, 3–50 characters, unique.
- Display name: required, maximum 100 characters.
- Email: required, valid, unique.
- Password: at least 8 characters with uppercase, lowercase, and a digit.
- Login accepts username, not email.
- Access token default lifetime: 15 minutes.
- Refresh token default lifetime: 30 days.
- Refresh rotates tokens and revokes the used refresh token.
- Login is intended to lock an account for 15 minutes after 5 failed password
  attempts, but the current transaction rolls those updates back. Do not rely
  on lockout until the backend P0 fix is implemented.
- Suspended accounts receive HTTP `403` on login or refresh.
- All `/api/v1/auth/**` traffic is limited by default to 5 requests per IP per
  60 seconds, including refresh and profile requests.
- Telegram OTP is 6 digits, expires after 5 minutes, allows 3 incorrect
  attempts, and only the most recent pending code is used.
- A wrong OTP returns HTTP `200` with `verified: false`; expired, missing, or
  over-attempt OTPs return HTTP `400`.
- Email verification is not required before login.
- Although Spring Security permits the `/auth/**` namespace, `GET /auth/me` and
  `PUT /auth/me` manually require and parse a bearer token in the controller.

## 4. Current Flutter baseline and required changes

The app already has useful auth scaffolding. It should be refined rather than
rewritten blindly.

| Area | Current state | Required action |
|---|---|---|
| Animated splash | Logo animation exists; current Khmer tagline and `#F9F9FB` change are uncommitted user work | Preserve the user change, align native splash styling, and move navigation decisions into bootstrap/router state |
| Initial route | Temporarily starts at `/blog`, and blog bypasses auth | Restore a real startup route and remove the development bypass |
| Language selection | Screen and preference persistence exist | Show only on first run; make async preference loading deterministic |
| Login | Form and loading UI exist | Use localized strings, typed API errors, accessibility, and working recovery/Google actions |
| Register | Core fields exist | Enforce backend max lengths, add confirmation/UX rules, then continue to the one-time province-completion gate |
| Province completion | No Flutter screen or usable backend read/list contract exists | Add a post-auth province selector after the backend exposes province options and returns the user's selected province |
| Telegram OTP | UI exists and sends extra `channel` fields | Remove `channel`; do not present verification as Telegram sign-in |
| Auth API | Covers login, register, Google, OTP, logout, and profile read | Add refresh abstraction, forgot/reset, email verify, profile model/update, and typed failures |
| Auth state | Restores any locally stored access token as authenticated | Bootstrap through `/auth/me`, allow one refresh, then clear an invalid session |
| Network client | Has an initial single-flight refresh implementation, but currently skips the bearer token for every `/auth/*` request—including protected `/auth/me` | Allowlist only public auth calls, attach the bearer token to `/auth/me`, prevent refresh recursion, test concurrent `401`s, atomically rotate tokens, notify auth state on terminal failure, and sanitize logging |
| Secure storage | Tokens and basic user fields are stored | Wrap it in a session store and delete only Riksa auth keys on logout |
| Localization | EN/KM keys exist but screens are mostly hard-coded English | Route every user-visible auth string through generated localizations |
| Google sign-in | Package exists; button is a placeholder | Configure Android/iOS OAuth and send the returned ID token to the API |
| Forgot password route | Login links to an unregistered route | Add the complete forgot-password and reset-password route flow |
| Tests | Only a placeholder smoke test exists | Add unit, widget, router, network, and live-backend integration coverage |

### Immediate security fixes

- Disable body logging for auth calls. The current debug `LogInterceptor` can
  print passwords, OTPs, access tokens, and refresh tokens.
- Replace the broad “never attach a token to `/auth/*`” rule with an explicit
  public-endpoint allowlist; `/auth/me` needs the access token.
- Never expose tokens through widget state, error strings, analytics, or logs.
- Store tokens only through the session storage layer.
- On refresh failure, clear the local session once and redirect to login.
- Do not trust token presence in storage as proof of authentication.

## 5. Target navigation and session flow

```text
Native launch screen
        |
Animated Flutter splash + app bootstrap
        |
        +-- no saved language --> Language selection --> Auth entry
        |
        +-- no saved session --------------------------> Auth entry
        |
        +-- saved session ---------------------+
                                                 |
Login / Register / Google success ---------------+--> GET /auth/me
                                                        |
                                                        +-- 401 --> refresh once
                                                        |              |
                                                        |              +-- retry fails
                                                        |                    --> clear session --> Login
                                                        |
                                                        +-- valid profile
                                                               |
                                                               +-- province missing
                                                               |      --> Select province
                                                               |      --> PUT /auth/me
                                                               |      --> Home
                                                               |
                                                               +-- province present --> Home
```

Rules:

1. The Flutter splash has a minimum display duration for visual consistency,
   but it must not add a fixed delay after bootstrap has finished.
2. Language restoration and auth restoration begin concurrently.
3. Router guards wait for bootstrap completion to avoid login/home flashes.
4. A requested protected deep link is retained and opened after login.
5. Province completion is required once after authentication, not on every
   login. Returning users with a province go directly to Home.
6. Authenticated users visiting `/auth/*` are redirected to the app shell,
   except explicit verification/recovery callbacks when needed.

## 6. Screen plan

### 6.1 Native and animated splash

- Match Android/iOS native backgrounds to the Flutter splash to avoid a flash.
- Preserve the current Riksa logo animation and Khmer tagline.
- Respect reduced-motion accessibility settings with a simple fade or static
  fallback.
- Run locale/session bootstrap behind the animation.
- Show a retryable offline state only when a saved session needs validation;
  first-time unauthenticated users can continue to login without network.

### 6.2 First-run language selection

- Keep English and Khmer cards, large tap areas, and clear selected state.
- Persist completion separately from the locale value so English does not look
  like an uninitialized default.
- After selection, continue to the pending route or login.
- Keep language switching accessible later from auth screens/settings.

### 6.3 Login

- Username and password fields with autofill hints and keyboard actions.
- Password visibility toggle.
- Inline required-field validation; do not impose registration-only username
  length validation during login.
- Loading state disables duplicate submission.
- Render backend/network/rate-limit/suspension errors in a stable inline error
  area; a snackbar may supplement but must not be the only error UI.
- Link to registration and forgot password.
- Enable Google only after platform configuration is present.
- Hide or relabel “Continue with Telegram” until the backend supports an actual
  Telegram authentication/session endpoint.

### 6.4 Registration

- Fields: username, display name, email, password, confirm password.
- Optional phone number and gender may be collected only when the product wants
  them; omit blank optional values from JSON.
- Match all backend validation rules and max lengths.
- Add password requirement indicators and terms/privacy acknowledgement when
  product links are available.
- On HTTP `200`, persist the returned session, load `/auth/me`, and route through
  the province-completion gate before entering Home.
- Explain that email can be verified later; the backend does not gate login on
  verification.
- Keep province out of the core registration form; collecting it as a focused
  post-auth step reduces form friction and works identically for Google users.

### 6.5 Province completion

- Show immediately after login, registration, or Google authentication only
  when the authenticated profile has no province.
- Load a backend-owned list containing stable UUID, Khmer name, and Latin name.
- Provide search plus a scrollable list/grid; display the name for the active
  locale and the second language as supporting text.
- Submit `{provinceId}` through `PUT /auth/me` and continue to Home only after
  the updated profile confirms the selection.
- Allow the province to be changed later from Edit Profile.
- Do not hard-code database UUIDs or trust the older six-province design list.
- If loading fails, keep the authenticated session and show retry/offline UI;
  do not send the user back through login.

This target flow requires the backend changes listed in Phase 0. The current
`UserProfileResponse` has no province field, no controller lists provinces, and
the Flyway migrations create the table but do not seed province rows.

### 6.6 Forgot and reset password

Use a three-step UI while retaining the same `identifier` throughout:

1. Enter username, email, or Telegram ID and call `/forgot-password`.
2. Explain Telegram delivery, enter the 6-digit OTP, and show a resend timer.
3. Enter/confirm the new password and call `/reset-password` with identifier,
   OTP, and new password.

On success, clear sensitive field controllers, return to login, and prefill the
username only when the entered identifier was a username.

### 6.7 Google sign-in

- Configure Android SHA/package and iOS URL scheme/client configuration.
- Request an ID token with the backend's Google client ID as the server client
  ID/audience.
- Send only the ID token to `/auth/google` for the standard path.
- Treat user cancellation as neutral, not an error.
- Persist the backend `AuthResponse`, not Google provider tokens, as the Riksa
  session.
- Load `/auth/me` and apply the same one-time province gate used by password
  login and registration.

### 6.8 Telegram OTP verification

The current backend OTP endpoints verify a chat ID/code but return no
`AuthResponse`. They cannot log a user in. Keep the screen only for an explicit
verification or recovery context once the backend can associate a Telegram ID
with the user. The form must send only `identifier` and `code`.

### 6.9 Email verification

Add an app/deep-link result screen only after the backend has real email
delivery and a confirmed link format. The current server creates verification
tokens but the email provider is still a stub.

## 7. Target code organization

```text
lib/
  app/router/app_router.dart
  core/
    error/api_failure.dart
    network/dio_client.dart
    storage/session_store.dart
  features/auth/
    data/
      auth_api.dart
      auth_models.dart
      auth_repository.dart
    providers/
      auth_provider.dart
      auth_state.dart
    presentation/
      splash_animation_screen.dart
      language_select_screen.dart
      login_screen.dart
      register_screen.dart
      province_select_screen.dart
      forgot_password_screen.dart
      reset_password_screen.dart
      google_profile_completion_screen.dart   # only if later required
      email_verification_screen.dart           # backend-gated
    widgets/
      auth_form_scaffold.dart
      auth_error_banner.dart
      password_field.dart
      password_requirements.dart
```

Architecture rules:

- Widgets call an auth controller, not `Dio` directly.
- The repository owns API-to-domain mapping and typed failures.
- The session store is the only layer that reads/writes token keys.
- Auth state distinguishes `bootstrapping`, `unauthenticated`,
  `authenticating`, `profileIncomplete(profile)`, and
  `authenticated(profile)`; recoverable form errors do not destroy the previous
  navigation state.
- The network interceptor refreshes through a bare client, allows only one
  refresh in flight, retries each request at most once, and emits a terminal
  session-expired event when refresh fails.
- API logging uses metadata only (method, sanitized path, status, duration, and
  correlation ID), never bodies or authorization headers.

## 8. Implementation phases

### Phase 0 — Backend alignment

- [x] Treat Java DTOs/controllers as the frozen v1 client contract.
- [ ] Decide whether Telegram is verification-only or must become real sign-in.
- [ ] Add a way to link `telegramId` before shipping Telegram password recovery.
- [ ] Add public `GET /api/v1/provinces`, returning stable `id`, `nameKhmer`, and
  `nameLatin` fields in a typed response.
- [ ] Seed the approved Cambodian province list through a Flyway migration; the
  current migrations create the table but insert no provinces.
- [ ] Add province ID/names (or a nested province object) to
  `UserProfileResponse` so the client can detect incomplete onboarding.
- [ ] Reject unknown `provinceId` values with HTTP `400`; registration and
  profile update currently ignore an unknown UUID and still succeed.
- [ ] Configure real Google client IDs and mobile application identifiers.
- [ ] Decide the email verification deep-link format and email provider timeline.
- [ ] For practical mobile use, narrow the global auth rate limiter to sensitive
  endpoints or set a documented development limit.
- [ ] Protect `/auth/me` through Spring Security instead of relying only on
  controller-level bearer parsing, and enforce suspension consistently for
  Google sign-in.

### Phase 1 — Secure foundation and startup

- [x] Add typed API failure parsing, including `400`, `401`, `403`, `409`, `429`,
  timeouts, offline, and malformed responses.
- [x] Add `SessionStore` and migrate all auth storage access into it.
- [x] Harden and test refresh rotation/single-flight behavior.
- [x] Remove sensitive request/response body logging.
- [x] Add deterministic bootstrap state and `/auth/me` session validation.
- [ ] Route an authenticated profile without a province to profile completion
  before any protected destination.
- [x] Restore `/splash` startup, remove the `/blog` auth bypass, and implement
  guarded redirects without route recreation glitches.
- [x] Align Android and iOS native splash backgrounds/assets.

**Exit:** cold start reliably lands on language, login, province completion, or
home; invalid sessions and incomplete profiles cannot enter the main app.

### Phase 2 — Core auth UI

- [x] Refine login and registration screens using shared auth widgets.
- [ ] Build the localized, searchable province-completion screen and profile
  update action.
- [x] Match backend field validation exactly.
- [x] Wire repository/controller states and preserve server error messages
  without exposing internals.
- [x] Localize core splash/login/register strings in English and Khmer.
- [x] Add focus, autofill, semantics, text scaling, keyboard, and small-screen
  behavior.
- [x] Make logout revoke the refresh token best-effort and always clear local
  auth state.

**Exit:** registration, login, province completion, restored session, automatic
refresh, and logout pass against the local backend on Android and iOS
simulators.

### Phase 3 — Recovery and OTP

- [ ] Add registered forgot-password and reset-password routes.
- [ ] Implement identifier, OTP, new-password, resend, expiry, and max-attempt UI.
- [x] Remove obsolete `channel` fields from Flutter OTP requests.
- [ ] Handle HTTP `200` with `verified: false` as a failure state.
- [ ] Gate standalone Telegram verification on the backend linking decision.

**Exit:** a backend user with an associated Telegram ID can reset a password
end to end with a real bot message.

### Phase 4 — Google and email verification

- [ ] Complete Android/iOS Google sign-in configuration.
- [ ] Exchange a real Google ID token for a Riksa session.
- [ ] Test existing-email account linking and new-user creation.
- [ ] Add email verification deep-link/result UI only after backend delivery and
  link format are ready.

**Exit:** Google works on physical/simulator targets intended for development;
email verification is either complete or intentionally hidden.

### Phase 5 — Polish and release readiness

- [ ] Verify native/Flutter splash continuity and reduced motion.
- [ ] Verify EN/KM layouts at large text sizes.
- [ ] Add analytics events that contain no credentials, identifiers, or tokens.
- [ ] Remove preview routes, placeholders, temporary bypasses, and debug copy.
- [ ] Run the complete automated and live-backend matrix.

## 9. Test plan

### Automated Flutter tests

**Unit**

- JSON parsing/serialization for every auth request and response.
- Validation boundaries: username 3/50, display name 100, password policy,
  email, and 6-digit OTP.
- Error parsing for normal API errors and the shorter `429` body.
- Session storage read/write/rotation/targeted deletion.
- Auth controller transitions for login, register, restore, refresh failure,
  logout, offline, and Google cancellation.

**Network**

- Bearer token is attached only where intended.
- Ten simultaneous protected `401` responses cause one refresh request.
- All waiting calls retry with the new access token.
- A retried request cannot start a second refresh loop.
- Refresh failure clears the session once and moves the router to login.
- Request/response logs contain no passwords, OTPs, or tokens.

**Widget/router**

- Splash destinations for first run, logged out, valid session, invalid session,
  and offline restoration.
- Login/register validation, loading, success, server error, and `429` states.
- Forgot/reset flow keeps its identifier and clears passwords after success.
- EN/KM rendering, text scaling, keyboard visibility, and back navigation.
- Protected deep link resumes after successful authentication.

Run on every change:

```bash
flutter analyze
flutter test
```

### Local backend integration setup

From `../riksa-api`:

```bash
docker compose up -d postgres
set -a
source .env
set +a
./mvnw spring-boot:run
curl http://localhost:8080/actuator/health
```

From `riksa_app`:

```bash
# iOS simulator / macOS / web
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Android emulator (also the app's current default)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Physical device: use the development machine's LAN IP
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:8080
```

Do not commit `.env`, Google secrets, Telegram bot tokens, JWTs, passwords, or
captured auth responses.

### Live backend matrix

| Scenario | Expected result |
|---|---|
| Register unique valid user | HTTP `200`, session saved, missing province routes to province completion |
| Complete province after register | Province list loads, `PUT /auth/me` succeeds, Home opens |
| Duplicate username/email | HTTP `400`, backend message shown on registration |
| Invalid password policy | Blocked locally and rejected by backend if sent |
| Login without province | HTTP `200`, failed-attempt counter resets, province completion opens |
| Login with province | HTTP `200`, failed-attempt counter resets, Home opens without asking again |
| Wrong credentials | HTTP `400`, generic invalid-credentials UI |
| Five failed logins | Account locks; lockout message is handled |
| Suspended user | HTTP `403`, suspension message is shown and no session saved |
| Suspended user via Google | Backend rejects sign-in and no session is saved |
| Access expiry | One refresh, original request retries successfully |
| Refresh reuse | Used token is rejected because rotation revoked it |
| Logout online | Refresh token revoked and local session removed |
| Logout offline | Local session still removed |
| App relaunch | `/auth/me` validates session and province before Home |
| Invalid province UUID | Backend returns HTTP `400`; selection remains open |
| Province list unavailable | Auth session remains valid; retry/offline state is shown |
| More than rate limit | HTTP `429`, cooldown UI prevents retry spam |
| OTP send | Real Telegram receives one 6-digit code |
| Wrong OTP | HTTP `200`, `verified: false` shown as invalid |
| Expired/too many OTP attempts | HTTP `400`, user is prompted to resend |
| Password reset | New password logs in; old password fails |
| New Google user | Backend account/gamification row created and session returned |
| Existing email via Google | Backend links Google ID and returns the existing account |
| No network/timeout | Retryable UI; no false authenticated state |

Use unique test accounts and either raise the development rate limit or pause
between cases; the backend default is only 5 auth requests per IP per minute.

## 10. Backend gaps that affect the Flutter design

These are contract decisions, not Flutter-only bugs:

1. **Telegram is not a sign-in method.** `/otp/verify` returns verification
   status, not tokens. The existing “Continue with Telegram” label is therefore
   misleading.
2. **Telegram recovery is not reachable for newly registered users.** Password
   reset requires `User.telegramId`, but registration accepts only
   `phoneNumber`, and there is no endpoint to link a Telegram ID.
3. **Province completion is not implementable from the current API.**
   Registration/Google/profile update accept a UUID, but no endpoint lists
   provinces, `UserProfileResponse` does not expose the user's province, invalid
   IDs are silently ignored, and the Flyway migrations seed no province rows.
4. **Email delivery is a stub.** The backend stores a verification token but
   does not send a usable email/link yet.
5. **Auth rate limiting is very broad.** The default 5 requests/minute/IP also
   covers `/auth/me`, refresh, and logout, which can interrupt a normal startup
   or test sequence.
6. **Backend auth documentation is stale.** Update it after the contract
   decisions above so mobile, backend, and QA share one description.
7. **Protected auth routes use an inconsistent security boundary.** Spring
   Security permits all `/auth/**` routes while `/auth/me` parses the bearer
   token inside the controller. This can bypass the filter's suspension check.
   Google authentication also does not currently reject suspended existing
   users. Both should be corrected server-side before release.

Until these are resolved, the Flutter UI can be designed with mock province
data, but it must not hard-code UUIDs or claim the one-time profile gate is
backend-integrated. Telegram remains limited to a supported recovery or
account-linking flow.

## 11. Definition of done

- [ ] Native splash, animated splash, first-run language selection, and auth
  bootstrap have no visible route/background flash.
- [ ] Register, login, restore, refresh rotation, profile load, and logout work
  against `riksa-api`.
- [ ] Every authenticated user without a province completes province selection
  once before Home; returning users are not asked again.
- [ ] Province options come from the API, are available in Khmer and Latin, and
  an invalid UUID is rejected by the backend.
- [ ] Forgot/reset works for a backend account with a linked Telegram ID.
- [ ] Google sign-in works with real development OAuth configuration.
- [x] No UI claims Telegram sign-in when the server only verifies OTP.
- [x] Core splash, login, and registration text is available in English and Khmer.
- [x] Passwords, OTPs, access tokens, and refresh tokens never appear in logs.
- [ ] Invalid, expired, revoked, locked, suspended, offline, and rate-limited
  states have clear user-visible behavior.
- [x] `flutter analyze` and `flutter test` pass (12 automated tests).
- [ ] The live backend matrix passes on at least one Android and one iOS target.
- [ ] Backend-dependent gaps are resolved or intentionally hidden from the UI.
