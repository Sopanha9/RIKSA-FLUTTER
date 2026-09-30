<!-- Generated 2026-09-29 by Agy (Gemini 3.1 Pro) from commit f905c38; routes + navigation sections rewritten and verified against app_router.dart by Claude. Feature/API sections are partial, see Risks. Regenerate when routes or features change. -->

# RIKSA Codebase Map

## Overview
RIKSA is a Flutter-based learning platform application with gamification, AI assistance, and community features. The stack utilizes Riverpod 3 (hand-written providers, no codegen) for state management, `go_router` for navigation, Dio for REST and GraphQL, and plain Dart models with hand-written `fromJson`. The entry point is `lib/main.dart`, which bootstraps the Riverpod `ProviderContainer` and schedules streak reminders before running `RiksaApp`. Environment configuration and base URLs are managed in `lib/core/network/api_config.dart`, which uses `-Ddart-define=API_BASE_URL` (defaulting to `10.0.2.2` for Android or `localhost` for others).

## Folder layout
```
lib/
├── app/               # App root configuration, real-time sync, and router setup
├── core/              # Shared infrastructure: network, storage, theme, and common widgets
├── features/          # Feature modules
│   ├── ai/            # AI tutor and chat interface
│   ├── auth/          # Authentication, onboarding, and Telegram login
│   ├── blog/          # Community articles and reading experience
│   ├── dashboard/     # Home screen widgets (study banner)
│   ├── leaderBoard/   # Global and provincial ranking screens
│   ├── learning/      # Core study loop, roadmaps, and lesson experience
│   ├── market/        # XP store and wardrobe for buddy cosmetics
│   ├── mascot/        # Virtual buddy rendering, state, and interaction
│   ├── notifications/ # Activity alerts and inbox
│   ├── quests/        # Daily and weekly challenges
│   ├── resources/     # External lesson links and supplementary materials
│   ├── social/        # Community feed, posts, and GraphQL integration
│   └── userProfile/   # Personal profiles, XP history, and settings
├── l10n/              # Localization files (.arb) and generated strings
└── main.dart          # App entry point
```

## Routes table
Source of truth: `lib/app/router/app_router.dart` (`goRouterProvider`). Paths below are relative to `lib/features/`. Landing = `kLandingLocation` = `/learn`.

**Outside the shell (full screen, no tabs)**
| Path | Screen | File |
| --- | --- | --- |
| `/` | redirect → `/learn` | |
| `/splash` | `SplashAnimationScreen` (initial route; welcome on first run) | `auth/presentation/splash_animation_screen.dart` |
| `/onboarding` | `OnboardingSplashScreen` | `auth/presentation/onboarding_splash_screen.dart` |
| `/onboarding/setup` | `InteractiveOnboardingScreen` | `auth/presentation/interactive_onboarding_screen.dart` |
| `/mascot-select` | `MascotSelectScreen` | `mascot/presentation/mascot_select_screen.dart` |
| `/language-select` | `LanguageSelectScreen` | `auth/presentation/language_select_screen.dart` |
| `/province-select` | `ProvinceSelectScreen` | `auth/presentation/province_select_screen.dart` |
| `/market` | `MarketScreen` (guest OK) | `market/presentation/market_screen.dart` |
| `/market/wardrobe` | `WardrobeScreen` | `market/presentation/wardrobe_screen.dart` |
| `/auth/login` | `AuthSwitcherScreen` (login mode) | `auth/presentation/auth_switcher_screen.dart` |
| `/auth/register` | `AuthSwitcherScreen` (register mode) | `auth/presentation/auth_switcher_screen.dart` |
| `/auth/recover` | `AccountRecoveryScreen` | `auth/presentation/account_recovery_screen.dart` |
| `/auth/verify-email` | `EmailVerificationScreen` | `auth/presentation/account_recovery_screen.dart` |
| `/auth/telegram` | `TelegramAuthScreen` | `auth/presentation/telegram_auth_screen.dart` |
| `/profile/:userId` | `PublicProfileScreen` (own id → `/profile`) | `userProfile/presentation/public_profile_screen.dart` |

**Inside the shell** (`StatefulShellRoute.indexedStack` → `AppShell` in `lib/app/router/app_shell.dart`)
| Branch | Path | Screen | File |
| --- | --- | --- | --- |
| 0 | `/home` | `SocialFeedScreen` | `social/presentation/social_feed_screen.dart` |
| 0 | `/dashboard` | redirect → `/learn` | |
| 0 | `/community` | `SocialFeedScreen(startInCommunities: true)` | `social/presentation/social_feed_screen.dart` |
| 0 | `/communities` | `CommunitiesScreen` | `social/presentation/communities_screen.dart` |
| 0 | `/communities/create` | `CreateCommunityScreen` | `social/presentation/create_community_screen.dart` |
| 0 | `/communities/:id` | `CommunityDetailScreen` | `social/presentation/community_detail_screen.dart` |
| 0 | `/communities/:id/manage` | `ManageCommunityScreen` (owner: settings, rules, members, bans; moderators: members, bans) | `social/presentation/manage_community_screen.dart` |
| 0 | `/progress` | `ProgressHistoryScreen` | `userProfile/presentation/progress_history_screen.dart` |
| 0 | `/community/create` | `ComposeCommunityPostScreen` | `social/presentation/compose_community_post_screen.dart` |
| 0 | `/community/posts/:id/edit` | `SocialPostEditScreen` | `social/presentation/compose_community_post_screen.dart` |
| 0 | `/community/posts/:id` | `SocialPostDetailScreen` | `social/presentation/social_post_detail_screen.dart` |
| 0 | `/blog` | `BlogFeedScreen` | `blog/presentation/blog_feed_screen.dart` |
| 0 | `/blog/create` | `BlogComposerScreen` | `blog/presentation/blog_composer_screen.dart` |
| 0 | `/blog/my-posts` | `MyPostsScreen` | `blog/presentation/my_posts_screen.dart` |
| 0 | `/blog/:id/edit` | `BlogPostEditScreen` | `blog/presentation/blog_composer_screen.dart` |
| 0 | `/blog/:id` | `BlogDetailScreen` | `blog/presentation/blog_detail_screen.dart` |
| 1 | `/learn` | `LessonCatalogScreen` (landing, guest OK) | `learning/presentation/lesson_catalog_screen.dart` |
| 1 | `/learn/resume` | redirect → `/learn` | |
| 1 | `/learn/saved` | `SavedLessonsScreen` (login required) | `learning/presentation/saved_lessons_screen.dart` |
| 1 | `/learn/completion` | `LessonCompletionScreen` (`extra`: int xp or Map; login required) | `learning/presentation/learning_result_screens.dart` |
| 1 | `/learn/subject/:subjectId` | `SubjectStartScreen` (guest OK) | `learning/presentation/subject_start_screen.dart` |
| 1 | `/learn/roadmap/:categoryId` | `LearningRoadmapScreen` (guest OK) | `learning/presentation/subject_roadmap_screen.dart` |
| 1 | `/learn/:id` | `LessonExperienceScreen` (guest OK) | `learning/presentation/lesson_experience_screen.dart` |
| 2 | `/ai` | `AiTutorScreen` | `ai/presentation/ai_tutor_screen.dart` |
| 2 | `/ai/chat/:id` | `AiChatScreen` (`id=new` → new chat; query `lesson`, `context`, `prompt`) | `ai/presentation/ai_chat_screen.dart` |
| 3 | `/leaderboard` | `LeaderboardScreen` | `leaderBoard/presentation/leaderboard_screen.dart` |
| 4 | `/profile` | `UserProfileScreen` (no tab; opened from drawer and home avatar) | `userProfile/presentation/user_profile_screen.dart` |
| 4 | `/profile/settings` | `ProfileSettingsScreen` | `userProfile/presentation/profile_settings_screen.dart` |
| 4 | `/profile/edit` | `EditProfileScreen` | `userProfile/presentation/edit_profile_screen.dart` |
| 4 | `/profile/setup` | `ProfileSetupOverviewScreen` | `userProfile/presentation/profile_setup_overview_screen.dart` |
| 5 | `/notifications` | `NotificationsScreen` (inbox; tap opens `/community/posts/:id` or `/blog/:id`) | `notifications/presentation/notifications_screen.dart` |

**Redirect rules** (top-level `redirect` in `goRouterProvider`):
- While auth is `AuthInitial` or `AuthUnavailable`, every route goes to `/splash`.
- Public without login: `/splash`, `/mascot-select`, `/language-select`, `/onboarding*`, `/province-select`, `/auth/*`.
- Guests can also view (`_guestCanView`): `/learn`, `/market`, `/learn/roadmap/*`, and `/learn/*` except `/learn/saved` and `/learn/completion`.
- Any other route while logged out goes to `/auth/login?from=<encoded uri>`.
- Logged in on `/auth/*` or `/language-select` goes to `?from=`, if it is safe, otherwise `/learn`. `onboardingReturning=true` marks onboarding complete.
- Logged in with a server buddy that was never chosen (`buddyChoicePromptProvider`, set by the buddy sync in `buddy_care_provider.dart`) goes to `/mascot-select?prompt=1`. This doesn't apply on `/splash`, `/onboarding*` or `/province-select`. `prompt=1` opens `MascotSelectScreen(serverPrompt: true)`, which saves the choice and goes to `/learn`.
- Bottom nav visibility: `app_shell.dart` counts screens in the match list. Tabs show only on the root paths `/home`, `/learn`, `/ai`, `/leaderboard`, `/profile`, `/notifications`.

## Navigation flow
- **First run**: `/splash` (welcome, Get Started) → `/onboarding` (intro, skipped once viewed) → `/mascot-select` → `/language-select` → `/onboarding/setup` → `/province-select` → `/learn` if signed in, otherwise `/auth/login`. The onboarding intro also offers "I have an account" → `/auth/login?onboardingReturning=true`.
- **Returning user**: `/splash` restores the session, then goes to `/onboarding` if the intro was never viewed, otherwise `/learn`.
- **Returning after sign-out/guest**: a protected route → `/auth/login?from=…` → back to `from` after login.
- Note: step order after `/mascot-select` comes from code comments and `context.go` calls. `test/features/auth/presentation/first_run_to_learn_test.dart` is the executable version of this flow.

## Features
- **AI**: `AiTutorScreen`, `AiChatScreen` | `ai_chat_provider` | `AiChatApi` (Chats and tutor endpoints).
- **Auth**: `AuthSwitcherScreen`, `TelegramAuthScreen` | `authProvider` (handles session state) | `AuthApi` (`/auth/login`, Telegram flows, `/auth/me`), `GoogleAuthClient`.
- **Blog**: `BlogFeedScreen`, `BlogDetailScreen` | `blog_provider` | `BlogApi` (CRUD for articles, categories via GraphQL).
- **Leaderboard**: `LeaderboardScreen` | `leaderboard_provider` (unverified) | `ProfileApi` (Leaderboard scopes & ranks).
- **Learning**: `LessonCatalogScreen`, `LessonExperienceScreen` | `learning_home_provider`, `lesson_catalog_provider` | `LearningApi` (Fetching catalogs, checking answers).
- **Market**: `MarketScreen`, `WardrobeScreen` | `market_provider` | `MarketApi` (Item purchases via `/market/items`).
- **Mascot**: `FloatingBuddy`, `BuddyLook` | `mascot_provider` (Buddy state), `buddy_care_provider` | `BuddyApi` (`/buddy/me` updates and equips).
- **Social**: `SocialFeedScreen`, `SocialPostDetailScreen` | `social_feed_provider` | `SocialApi` (GraphQL queries/mutations for posts, comments; community management: `community`, `communityMembers`, `communityBans`, `updateCommunity`, `setCommunityMemberRole`, `removeCommunityMember`, `unbanCommunityMember`, `pinCommunityPost`). Roles are OWNER/MODERATOR/MEMBER on `SocialCategory.myRole`; the backend side is `CommunityModerationService` in RIKSA.
- **UserProfile**: `UserProfileScreen`, `PublicProfileScreen` | `profile_provider` | `ProfileApi` (Gamification, XP activity).

## Core
- **Widgets**: `RiksaBottomNavigationBar` (floating bottom tabs), `FloatingBuddy` (global mascot overlay), `MarkdownBody` configured with `markdownMathSyntaxes` for math support.
- **Theme**: `AppTheme`, heavily leaning on `RiksaPalette` and `RiksaSemanticColors` configured in `lib/core/theme/app_theme.dart`.
- **Network Client**: `DioClient` (`lib/core/network/dio_client.dart`) with a single-flight JWT refresh interceptor. Unauthenticated paths (`/auth/register`, `/auth/refresh`, etc.) bypass the interceptor.
- **Storage**: `SessionStore` inside `lib/core/storage/session_store.dart` uses `flutter_secure_storage` to persist JWT access/refresh tokens.
- **Localization**: Uses `.arb` files (`lib/l10n/app_en.arb`, `app_km.arb`) and generates `AppLocalizations`.

## Backend API index
Generated by grepping `lib/features/*/data` and `lib/core/network`. REST paths are relative to `ApiConfig.baseUrl` + `/api/v1`. The method column is blank when the path is not passed straight to `dio.<verb>('...')`. `lib/core/network/dio_client.dart` also lists the `/auth/*` paths that skip the token-refresh interceptor.

| Method | Path | File |
| --- | --- | --- |
| POST | `/auth/refresh` | `lib/core/network/dio_client.dart` |
| GET | `/ai/chats` | `lib/features/ai/data/ai_chat_api.dart` |
| DELETE/GET | `/ai/chats/$id` | `lib/features/ai/data/ai_chat_api.dart` |
| POST | `/ai/chats/messages` | `lib/features/ai/data/ai_chat_api.dart` |
| POST | `/auth/forgot-password` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/google` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/login` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/logout` | `lib/features/auth/data/auth_api.dart` |
| GET/PUT | `/auth/me` | `lib/features/auth/data/auth_api.dart` |
| GET | `/auth/provinces` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/register` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/reset-password` | `lib/features/auth/data/auth_api.dart` |
| GET | `/auth/telegram/bot` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/telegram/code` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/telegram/complete` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/telegram/start` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/telegram/status` | `lib/features/auth/data/auth_api.dart` |
| POST | `/auth/verify-email` | `lib/features/auth/data/auth_api.dart` |
| GET/POST | `/blog` | `lib/features/blog/data/blog_api.dart` |
| DELETE/GET/PUT | `/blog/$id` | `lib/features/blog/data/blog_api.dart` |
| POST | `/blog/$id/like` | `lib/features/blog/data/blog_api.dart` |
| GET | `/blog/my-posts` | `lib/features/blog/data/blog_api.dart` |
| POST (GraphQL) | `/graphql` | `lib/features/blog/data/blog_api.dart` |
| POST (GraphQL) | `/graphql` | `lib/features/learning/data/learning_api.dart` |
| POST | `/learning/lessons/$lessonId/exercises/$exerciseId/check` | `lib/features/learning/data/learning_api.dart` |
| GET | `/learning/me/continue` | `lib/features/learning/data/learning_api.dart` |
| GET | `/lessons` | `lib/features/learning/data/learning_api.dart` |
| GET | `/lessons/$lessonId` | `lib/features/learning/data/learning_api.dart` |
| POST | `/lessons/$lessonId/complete` | `lib/features/learning/data/learning_api.dart` |
| POST | `/lessons/$lessonId/exercises/$exerciseId/attempt` | `lib/features/learning/data/learning_api.dart` |
| GET | `/lessons/roadmap` | `lib/features/learning/data/learning_api.dart` |
| GET | `/market/items` | `lib/features/market/data/market_api.dart` |
| POST | `/market/items/$itemId/purchase` | `lib/features/market/data/market_api.dart` |
| POST | `/blog/$blogId/read-complete` | `lib/features/mascot/data/buddy_api.dart` |
| GET/PUT | `/buddy/me` | `lib/features/mascot/data/buddy_api.dart` |
| GET | `/notifications` (cursor, limit), `/notifications/unread-count` | `lib/features/notifications/data/notifications_api.dart` |
| POST | `/notifications/{id}/read`, `/notifications/read-all` | `lib/features/notifications/data/notifications_api.dart` |
| (browser) | `{baseUrl}/legal/{faq,terms,privacy,agreement}.html` | `lib/core/network/support_documents.dart` |
| PUT | `/buddy/me/equipped` | `lib/features/mascot/data/buddy_api.dart` |
| POST | `/quests/$id/claim` | `lib/features/quests/data/quests_api.dart` |
| POST | `/quests/chest/open` | `lib/features/quests/data/quests_api.dart` |
| GET | `/quests/today` | `lib/features/quests/data/quests_api.dart` |
| GET | `/quests/week` | `lib/features/quests/data/quests_api.dart` |
| GET/POST | `/learning/lessons/$lessonId/resources` | `lib/features/resources/data/resources_api.dart` |
| POST | `/reports` | `lib/features/resources/data/resources_api.dart` |
| DELETE | `/resources/$id` | `lib/features/resources/data/resources_api.dart` |
| DELETE/POST | `/resources/$id/save` | `lib/features/resources/data/resources_api.dart` |
| GET | `/gamification/streak` | `lib/features/social/data/social_api.dart` |
| POST (GraphQL) | `/graphql` | `lib/features/social/data/social_api.dart` |
| GET | `/gamification/achievements` | `lib/features/userProfile/data/profile_api.dart` |
| GET | `/gamification/me` | `lib/features/userProfile/data/profile_api.dart` |
| GET | `/gamification/rank-history` | `lib/features/userProfile/data/profile_api.dart` |
| GET | `/gamification/xp` | `lib/features/userProfile/data/profile_api.dart` |
| GET | `/leaderboard` | `lib/features/userProfile/data/profile_api.dart` |
| GET | `/leaderboard/me` | `lib/features/userProfile/data/profile_api.dart` |
| GET | `/profiles/${Uri.encodeComponent(userId)}` | `lib/features/userProfile/data/public_profile_api.dart` |

## Tests
- **Folder layout**: Matches `lib/` structure (e.g., `test/features/learning/`). Includes `test/visuals/` for golden tests and `test/fixtures/` for mock JSON responses.
- **Backend Fakes**: E2E-style tests (like `lesson_journey_test.dart`) construct custom API fake classes (e.g., `JourneyApi` extending `LearningApi`) overriding endpoints to mimic state transitions locally instead of relying heavily on generic mocks.
- **Golden Images**: PNGs sit in a `goldens/` folder next to each golden test (e.g. `test/features/market/presentation/goldens/`), plus `test/visuals/`. Refresh them with `flutter test --update-goldens`.
- **Notable Tests**: `lesson_journey_test.dart` acts as an integration-level UI test verifying full interaction loops (answering questions, reading reflections, saving progress as a guest).

## Conventions & gotchas
- **No codegen in use**: `riverpod_generator`, `freezed`, `json_serializable` and `build_runner` are in `pubspec.yaml`, but `lib/` has no annotations and no `.g.dart` or `.freezed.dart` files. Models parse JSON by hand.
- **GraphQL via Dio**: `graphql_flutter` is in `pubspec.yaml`, but nothing in `lib/` imports it. Social, blog categories and learning send GraphQL as a Dio `POST` to `${ApiConfig.baseUrl}/graphql`.
- **Offline Sync & Guests**: The lesson screen caches guest progress locally (using `_guestCorrectAnswers`) and attempts to sync it via `_syncGuestCorrectAnswers()` when the user finally logs in.
- **Single-Flight Refresh**: Auth token refresh is strictly single-flight in `DioClient` using a shared `Future` so concurrent network failures don't blast the server with `/auth/refresh` requests.
- **Mascot Art**: Buddy cosmetics are loaded dynamically using `bundledItemArt.contains()` checks before falling back to programmatic Canvas drawing (vector placeholders) in `BuddyItemPlaceholderPainter`.

- **Notifications**: `lib/features/notifications/` (models, API, `notificationInboxProvider`, `unreadNotificationCountProvider`). The bell badge is fed by `app_shell.dart` into `RiksaBottomNavigationBar.notificationCount`. Live updates: `notification.created` in `lib/app/realtime_sync.dart`.
- **Tap-everything crawler**: `test/crawler/`. `tap_everything_test.dart` runs the real app signed in against `FakeRiksaServer` (`crawler_fixtures.dart` answers every endpoint), taps every button on 21 screens, and writes `build/crawler_report.md`. When a screen calls a new endpoint, add it to `crawlerRoutes()`. `probe_test.dart` lists which endpoints each screen calls.

## Where to change X
- **Help & legal page links** → `lib/core/network/support_documents.dart` (pages live in the backend at `src/main/resources/static/legal/`)
- **Notification wording** → `notification*` keys in `lib/l10n/app_en.arb` / `app_km.arb`
- **Bottom nav tabs / shell**: `lib/app/router/app_shell.dart` and `lib/core/widgets/riksa_bottom_navigation_bar.dart`
- **Add a route**: `lib/app/router/app_router.dart`
- **API base URL**: `lib/core/network/api_config.dart`
- **Auth state & behavior**: `lib/features/auth/providers/auth_provider.dart`
- **Buddy/mascot cosmetics**: `lib/features/mascot/presentation/widgets/buddy_look.dart`
- **Lesson reading/practice UI**: `lib/features/learning/presentation/lesson_experience_screen.dart`
- **Social feed queries**: `lib/features/social/data/social_api.dart`
- **Color tokens / App Theme**: `lib/core/theme/app_theme.dart`
- **Auth storage keys**: `lib/core/storage/session_store.dart`
- **App Strings (English)**: `lib/l10n/app_en.arb`

## Risks
- Most files outside of `auth`, `learning`, `mascot`, and `social` data/presentation roots were skimmed or inferred. Internal implementations for features like `quests`, `resources`, and `blog` UI were not exhaustively read.
- Some provider implementations (`leaderboard_provider`, `social_feed_provider`) were not read in detail.
- The `graphql_flutter` library exists in the codebase but seems bypassed by `SocialApi`; other features might use it directly, but this was unverified.
