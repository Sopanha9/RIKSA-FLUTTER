# Task
Make every user-specific piece of app state reset when the signed-in user changes, and scope device storage per user, so a second account on the same phone never sees the first account's data.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3 (Notifier / AsyncNotifier, no code-gen for these providers), go_router, Dio, SharedPreferences.

# Relevant files
- lib/features/auth/providers/auth_provider.dart — `authProvider` (`Authenticated(user)` / `Unauthenticated` / …), `logout()` at ~L336; `dioClientProvider`.
- lib/features/quests/providers/today_quests_provider.dart — `todayQuestsProvider` (L71): not autoDispose, never rebuilt on user change.
- lib/features/social/providers/social_feed_provider.dart — `socialFeedProvider` (~L377): feed, joined communities, my reactions.
- lib/features/blog/providers/blog_provider.dart — `blogFeedProvider` (~L260).
- lib/features/ai/providers/ai_chat_provider.dart — `aiChatApiProvider`, `aiChatSessionsProvider`, `aiChatSessionProvider` (family).
- lib/features/ai/data/ai_chat_cache.dart — fixed global keys `ai_chat_sessions_cache`, `ai_chat_session_<id>`.
- lib/features/ai/data/ai_chat_api.dart — `sessions()` / `session()` fall back to the cache on ANY error (L23–39).
- lib/features/resources/providers/lesson_resources_provider.dart — `lessonResourcesProvider` family (L118), holds `savedByMe`.
- lib/features/learning/providers/saved_lessons_provider.dart — device-only bookmarks under global key `riksa_saved_lesson_ids`.
- lib/features/mascot/providers/mascot_provider.dart — species/name under global keys `riksa_mascot_species` / `riksa_mascot_name`.
- lib/features/mascot/providers/buddy_care_provider.dart — already handles per-user sync (`_signedInKeyPrefix`, listens to `authProvider`); copy its pattern, keep its behavior.

# Context
Validated bugs (audit IDs X1, C1, A2, B2). After log out → log in as a different user **without restarting the app**, the new user sees the previous user's quests, social/blog feed (incl. joined communities and reactions), AI chat list, and saved-resource flags, until a manual refresh. AI chat history is also cached on disk under global keys and shown to whoever is signed in when the network fails — a privacy leak. Saved lessons are one global list for every account on the device. After logout, a guest keeps the previous user's buddy species/name (signed-in users are fine because the server buddy wins on login).

# Do
1. Add `currentUserIdProvider` (e.g. `lib/core/providers/current_user_provider.dart`): `Provider<String?>` that `ref.watch(authProvider.select(...))` and returns the signed-in user id or null. Only changes when the id changes (not on profile edits).
2. Make each user-specific provider above `ref.watch(currentUserIdProvider)` inside `build` so it rebuilds (fresh state, fresh fetch) when the user changes. For families, watch it inside the notifier's `build`. Do not add `autoDispose` where a screen relies on the cache surviving navigation unless you confirm it is safe; watching the user id is the required fix.
3. `AiChatCache`: take a user id; keys become `ai_chat_sessions_cache_<userId>` / `ai_chat_session_<userId>_<id>`. No user id (guest) → the cache is disabled (no reads, no writes). Add `clearForUser(userId)` and delete the old un-scoped keys once (migration-free: just remove them on first run). `aiChatApiProvider` builds the API with the current user's cache.
4. On logout (`AuthNotifier.logout`), clear the signed-out user's AI chat cache. Keep logout's existing behavior otherwise (local logout must always finish).
5. `SavedLessonsNotifier`: key becomes `riksa_saved_lesson_ids_<userId>`; guests use `riksa_saved_lesson_ids_guest`. On first run, move the old global list into the guest bucket (not into any account). Rebuild on user change.
6. `MascotNotifier`: on transition to signed-out, reset to the guest buddy stored under guest keys (`riksa_mascot_species_guest` / `riksa_mascot_name_guest`), falling back to the default species/name. Keep signed-in behavior: the server choice from `buddyCareProvider` still wins. Do not break first-run buddy selection (guest picks a buddy during onboarding, then signs up — that choice must still be sent to the new account once).
7. Tests (fake APIs, `ProviderContainer` or widget tests):
   - Sign in as A → load quests/feed/AI sessions/saved lessons → sign out → sign in as B → each provider shows B's data (fake returns different data per user), never A's.
   - AI cache: A's cached sessions are not returned for B when the fake API throws; guest gets no cache.
   - Saved lessons: A's bookmarks are not visible to B; old global key migrates to guest.
   - Mascot: after A signs out, the guest buddy is the guest/default, not A's.
   - Existing tests still pass.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar or its styling (a teammate owns it).
- Do not change network/refresh logic in `lib/core/network/dio_client.dart` (another worker owns it this wave).
- Do not change `lib/features/social/data/social_api.dart` or `lib/features/blog/data/blog_api.dart` (another worker).
- Do not modify files outside: lib/core/providers/**, lib/features/auth/providers/auth_provider.dart, lib/features/quests/providers/**, lib/features/social/providers/**, lib/features/blog/providers/**, lib/features/ai/{data,providers}/** (except nothing in presentation), lib/features/resources/providers/**, lib/features/learning/providers/saved_lessons_provider.dart, lib/features/mascot/providers/**, lib/l10n/** (only if you add strings; prefix `account…`), and matching test/** files.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, a table of each provider → how it now resets, and anything needing a device to verify.

# Risks
End with a "## Risks" section.
