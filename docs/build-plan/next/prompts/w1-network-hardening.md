# Task
Stop the app from logging users out when the network drops during a token refresh, and make API clients fail with a friendly error (not a raw TypeError) when the server returns a non-JSON body.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3, Dio.

# Relevant files
- lib/core/network/dio_client.dart — interceptor `onError` (~L72–97): on 401 it calls `_refreshSingleFlight()`; if that returns false it runs `_clearSession()` and emits on `_sessionExpiredController`. `_performRefresh()` (~L131–160) wraps everything in `catch (_) { return false; }`.
- lib/features/social/data/social_api.dart, lib/features/blog/data/blog_api.dart — cast `response.data as Map` / `as Map<String, dynamic>` directly.
- Other API clients under lib/features/*/data/*_api.dart — same pattern (check them; fix the shared cause, not each call).
- test/ — look for existing dio_client / auth recovery tests (e.g. test/features/auth/providers/auth_recovery_test.dart) and follow their fake-adapter style.

# Context
Validated bug A4: a timeout or lost signal at the moment the access token expires makes `_performRefresh` return false, which the interceptor treats exactly like a revoked refresh token → the session is wiped and the user is signed out. Only a real rejection of the refresh token should end the session.
Validated (low) C3: if a gateway returns an HTML 502 page or an empty body, `response.data as Map` throws a `TypeError` instead of a `DioException`. Callers catch it, but users see a raw/odd error message.

# Do
1. Change the refresh result from `bool` to a small result type (e.g. `enum RefreshOutcome { refreshed, rejected, unavailable }`):
   - `refreshed` — new valid token pair persisted.
   - `rejected` — no refresh token, `/auth/refresh` answered 400/401/403, or the response is not a valid token pair.
   - `unavailable` — network errors, timeouts, 5xx, 429, anything else.
2. In `onError`: `refreshed` → retry as today; `rejected` → clear session + emit session-expired (today's behavior); `unavailable` → **keep the session**, pass the original error through (`handler.next(e)`) so the screen shows its normal offline/error state. The next request will try refreshing again.
3. Keep single-flight behavior (concurrent 401s share one refresh) and the `riksaAuthRetried` guard.
4. Add one shared helper for response bodies (e.g. `Map<String, dynamic> jsonMap(Response r)` in lib/core/network/) that throws a `DioException(type: DioExceptionType.badResponse, …)` with a friendly message when the body is not a JSON object. Use it in the API clients instead of raw `as Map` casts. Do not change any API client's public method signatures or behavior on valid responses.
5. Tests:
   - 401 → refresh times out → session NOT cleared, no session-expired event, original error surfaces.
   - 401 → refresh returns 401 → session cleared, session-expired emitted (existing behavior).
   - 401 → refresh returns 503 → session kept.
   - Two concurrent 401s → one refresh call.
   - An API client given an HTML string body throws the friendly DioException, not TypeError.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside: lib/core/network/**, lib/features/*/data/*_api.dart **except** lib/features/ai/data/ai_chat_api.dart (another worker owns it this wave), test/core/network/**, test files for the API clients you touch.
- Do not change `auth_provider.dart` or any provider (another worker owns them this wave).
- Do not log tokens, request bodies, or headers.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, and a short table: failure type → old behavior → new behavior.

# Risks
End with a "## Risks" section.
