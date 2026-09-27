# Task
Three small, independent fixes: block double-submitting a lesson answer, stop onboarding from asking returning users for a province that will be ignored, and let iOS show notifications while the app is open.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3, go_router, flutter_local_notifications.

# Relevant files
- lib/features/learning/presentation/lesson_experience_screen.dart — `_submitAnswer` (~L799): does `setState(() => _submitting.add(exercise.id))` but never checks `_submitting.contains(exercise.id)` first; the button only shows busy after the next frame (~L654–659). `_complete` already guards with `_completing` — mirror that.
- lib/features/auth/presentation/interactive_onboarding_screen.dart — province is page `_provincePage = 2`; on finish (~L133–139) it calls `authProvider.notifier.saveProvinceSelection(provinceId)`.
- lib/features/auth/presentation/onboarding_splash_screen.dart — the first-run "Get started" screen.
- lib/features/auth/providers/auth_provider.dart — `_hydrateProfile()` (~L276): after login, a pending onboarding province is sent to the server **only if the account has no province yet**, then onboarding is marked complete. `saveProvinceSelection()` (~L287): when already signed in, it **overwrites** the server province.
- lib/core/providers/locale_provider.dart — `hasCompletedOnboarding`, `pendingProvinceId`, `completeOnboarding()`.
- lib/app/router/app_router.dart — redirect logic; onboarding routes are public.
- ios/Runner/AppDelegate.swift — does not set `UNUserNotificationCenter.current().delegate`.

# Context
B1 (validated): two quick taps on "Check answer" send two requests. The server's XP ledger is idempotent per source id, but duplicate attempts still cost requests and can confuse the UI.
H6: on a new device, a user who already has an account goes through first-run onboarding as a guest and is asked for their province; since a recent fix, login keeps the account's saved province, so that answer is silently ignored. Separately, if a **signed-in** user who already has a province reaches the onboarding finish, `saveProvinceSelection` would overwrite their province.
H7: without the notification-center delegate, flutter_local_notifications cannot present banners while the app is in the foreground and tap callbacks may not arrive.

# Do
1. **B1:** at the top of `_submitAnswer`, return early if `_submitting.contains(exercise.id)`. Make sure every exit path (including the guest-limit `return` and errors) removes the id in `finally`. Test: two taps in the same frame → the fake API is called once.
2. **H6:**
   a. On the onboarding splash (and on the first interactive onboarding page), add a clear secondary action "I already have an account" → the login screen. After a successful login from there, mark onboarding complete and land on the normal signed-in landing page — do not show the province step.
   b. In the interactive onboarding, if the user is already signed in **and** their profile has a province, skip the province page entirely and do not call `saveProvinceSelection` on finish.
   c. Do not change `_hydrateProfile` semantics (fill only when empty).
   d. Tests: returning-user path never shows the province page; a signed-in user with a province finishing onboarding does not trigger `updateProvince`; the first-time guest flow is unchanged.
   New strings use prefix `onboardingReturning…`.
3. **H7:** in `AppDelegate.swift`, set `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate` inside `didFinishLaunchingWithOptions` before `GeneratedPluginRegistrant`, as the flutter_local_notifications README describes for its current version. No other iOS changes.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar.
- Do not modify files outside: lib/features/learning/presentation/lesson_experience_screen.dart (only `_submitAnswer` + its button wiring), lib/features/auth/presentation/interactive_onboarding_screen.dart, lib/features/auth/presentation/onboarding_splash_screen.dart, lib/features/auth/presentation/login_screen.dart (only if needed to return to landing after 2a), lib/features/auth/providers/auth_provider.dart (only if strictly needed for 2a/2b), lib/core/providers/locale_provider.dart, lib/app/router/app_router.dart (only if needed for 2a), ios/Runner/AppDelegate.swift, lib/l10n/**, and matching tests under test/features/learning/**, test/features/auth/**, test/app/**.
- Do not add dependencies.

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, a short flow description for 2a/2b, and a note that H7 needs an iOS device/simulator to verify.

# Risks
End with a "## Risks" section.
