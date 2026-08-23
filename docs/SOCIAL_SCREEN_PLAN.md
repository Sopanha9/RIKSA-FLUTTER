# Riksa Social Feed Screen Plan

**Status:** Social shell and first post-detail/comment phase implemented
**Prepared:** 2026-08-22
**Flutter app:** `riksa_app`
**Backend:** sibling repository `../riksa-api`

> **Contract source of truth:** the backend Java code and
> `riksa-api/src/main/resources/graphql/social.graphqls`. Note that
> `riksa-api/docs/SOCIAL_MODULE_PLAN.md` is **deprecated** (its NEW/HOT sort,
> base64 composite cursors, `searchPosts`, pinning, and `POST /api/graphql`
> designs were never implemented). `riksa-api/docs/PROJECT_GUIDE.md` is the
> designated guide; where it disagrees with code, code wins. The contract
> below was audited against the working tree on 2026-08-22.

## 1. Goal

Use `/home` as a unified, glass-style social destination for every login path:

- persistent top navigation with drawer on the left and streak/create actions
  on the right;
- glass segmented navigation for **My Feed** and **Blog** directly below the
  top bar;
- drawer navigation for profile, communities, language, and logout;
- live streak visibility on the feed;
- cursor-paginated post feed with category filters;
- blog stories inside the same shell;
- post/question creation from the global plus action;
- post detail with paged top-level comments and a comment composer;
- reactions (4 types) and share.

Navigation chrome is **drawer only** (no bottom navigation bar in this phase).
Reactions expose **all 4 backend types**: UPVOTE/DOWNVOTE inline, HAHA/LOVE via
a long-press picker.

Out of scope (no backend support exists): following/followers, notifications,
bookmarks, post view counts, NEW/HOT sorting, search.

## 2. Confirmed backend contract

Social module: single GraphQL endpoint `POST /graphql` (base URL, no `/api/v1`
prefix). Gamification: REST under `/api/v1/gamification`. All requests require
`Authorization: Bearer <accessToken>` — the existing `DioClient` interceptor
already attaches it and handles refresh.

### 2.1 GraphQL queries

| Operation | Args | Returns | Notes |
|---|---|---|---|
| `feed` | `categoryId: UUID`, `authorId: UUID`, `cursor: UUID`, `limit: Int = 20` | `FeedPage!` | Both filters optional. No sort arg — always `createdAt DESC, id DESC`, `VISIBLE` posts only. `limit` clamped 1–50. `authorId` powers profile "Posts" tab. |
| `post` | `id: UUID!` | `Post` | Errors if missing or HIDDEN — detail screen must handle gracefully. |
| `categories` | — | `[Category!]!` | Includes `memberCount` + `joined` for the current user. |
| `comments` | `postId: UUID!`, `cursor: UUID`, `limit: Int = 20` | `CommentPage!` | Top-level only (`parentId IS NULL`), oldest first. |

### 2.2 GraphQL mutations

| Operation | Args | Returns | Behavior |
|---|---|---|---|
| `createPost` | `input: CreatePostInput!` | `Post!` | **Fails unless the user joined the category first.** STEM keyword filter on title+content. |
| `updatePost` | `input: UpdatePostInput!` | `Post!` | Owner only. |
| `deletePost` | `id: UUID!` | `Boolean!` | Owner only. |
| `createComment` | `input: CreateCommentInput!` | `Comment!` | STEM filter; replies via `parentId`; increments `commentCount`. |
| `updateComment` / `deleteComment` | — | `Comment!` / `Boolean!` | Owner only. |
| `react` | `input: ReactInput!` | `Post!` | **Toggle semantics:** same type again → removes; different type → swaps; new → adds. Always build optimistic UI from the returned full `Post` (counts + `myReaction`). |
| `removeReaction` | `postId` / `commentId` | `Post!` | **Avoid** — decrements counter even when no reaction existed. Use `react` toggle only. |
| `sharePost` | `input: SharePostInput!` | `Post!` | Platform defaults to `COPY_LINK`. |
| `joinCategory` / `leaveCategory` | `categoryId: UUID!` | `Category!` | Errors if already/not member. |

### 2.3 GraphQL types (from `social.graphqls`)

```graphql
type Post {
  id: UUID!  title: String!  content: String!  mediaUrl: String
  reactionCount: Int!  commentCount: Int!  shareCount: Int!
  author: User!  category: Category!  myReaction: ReactionType
  createdAt: DateTime!  updatedAt: DateTime!
  comments(cursor: UUID, limit: Int = 10): CommentPage!
}
type Comment {
  id: UUID!  content: String!  author: User!  postId: UUID!  parentId: UUID
  myReaction: ReactionType  createdAt: DateTime!  updatedAt: DateTime!
  replies(cursor: UUID, limit: Int = 5): CommentPage!
}
type Category { id: UUID!  name: String!  slug: String!  description: String
                iconUrl: String  memberCount: Int!  joined: Boolean! }
type User { id: UUID!  username: String!  displayName: String!  avatarUrl: String! }
type FeedPage    { edges: [Post!]!    pageInfo: PageInfo! }
type CommentPage { edges: [Comment!]! pageInfo: PageInfo! }
type PageInfo    { hasNextPage: Boolean!  endCursor: UUID }

enum ReactionType  { UPVOTE DOWNVOTE HAHA LOVE }
enum SharePlatform { TELEGRAM FACEBOOK COPY_LINK }

input CreatePostInput    { title: String!  content: String!  mediaUrl: String  categoryId: UUID! }
input CreateCommentInput { postId: UUID!  content: String!  parentId: UUID }
input ReactInput         { postId: UUID  commentId: UUID  type: ReactionType! }
input SharePostInput     { postId: UUID!  platform: SharePlatform }
```

Pagination: `endCursor` is the **last item's UUID** (opaque to the client —
never parse it). Feed fetches `limit+1` rows server-side to compute
`hasNextPage`.

### 2.4 Gamification REST (`/api/v1/gamification`)

| Method & path | Response fields |
|---|---|
| `GET /me` | `userId, totalXp, currentStreak, highestStreak, currentTier, currentTierIcon, nextTier, xpToNext` |
| `GET /streak` | `currentStreak, highestStreak, currentMilestoneName, currentMilestoneIcon, nextMilestoneName, nextMilestoneMinStreak, daysToNext` |
| `GET /achievements` | `[{id, name, description, iconUrl, earned, unlockedAt, progress, progressMax, progressPercent, rarity, xpReward}]` |
| `GET /leaderboard?cursor=&limit=` | `CursorPage<{rank, userId, displayName, avatarUrl, totalXp, tierName, tierIcon}>` |
| `GET /xp?cursor=&limit=` | `CursorPage<{id, amount, sourceType, sourceId, runningBalance, createdAt}>` |

Streak rules (context for UI copy): streaks are **lesson-driven only** —
posting/reacting does not affect them; timezone Asia/Phnom_Penh; a midnight
job resets lapsed streaks. Milestones: 1/3/7/14/30/60/90/365 days.

## 3. Screen design

### 3.1 Feed screen (`/home`)

```
┌─────────────────────────────────┐
│ [☰]  RIKSA Community   [🔥 7][+]│  ← pinned glass app bar
│ ┌─────────────┬───────────────┐ │
│ │   My Feed   │     Blog      │ │  ← glass segmented switch
│ └─────────────┴───────────────┘ │
│ For You│Tech│STEM│History│...   │
│ ┌─────────────────────────────┐ │
│ │ Author · community          │ │
│ │ Post title                  │ │
│ │ excerpt...           [img]  │ │
│ │ ↑ 12       💬 5       📤 2  │ │
│ └─────────────────────────────┘ │
│            ...infinite scroll   │
└─────────────────────────────────┘
```

- **Top navigation**: a pinned frosted `SliverAppBar`. The left menu opens the
  navigation drawer. The right side keeps the live streak visible and provides
  one global plus action.
- **Section switch**: a frosted segmented control sits directly under the top
  row. `My Feed` keeps the GraphQL social feed; `Blog` renders the REST blog
  feed without leaving the social shell.
- **Create action**: the plus button opens a glass bottom sheet with **Create a
  post** and **Ask the community**. Both use the community composer and the
  `createPost` mutation; if necessary the selected category is joined first.
- **Category chips**: "For You" (`feed` with no `categoryId`) plus each
  `Category` from the `categories` query; selection reloads the feed with that
  `categoryId`. Chips show join state (dot/badge when `joined`).
- **PostCard**: Reddit-style left vote column (▲ score ▼, vertical), title,
  content excerpt (max ~3 lines), optional `mediaUrl` image, footer with
  comment count, share count, category name, author, relative time. Tap →
  post detail. Long-press vote area → reaction picker (all 4 types). Card
  overflow menu: report (`POST /api/v1/reports`), copy link, edit/delete if
  own post.
- **Infinite scroll**: same pattern as `blog_feed_screen.dart` —
  `ScrollController` threshold near `maxScrollExtent`, guarded by `hasNextPage`
  + `isLoadingMore`.

### 3.2 Drawer (`Scaffold.drawer`)

Sections, top to bottom:

1. **Profile header** — avatar, `displayName`, and `@username`; profile setup is
   one tap away.
2. **Primary links** — My Feed, Blog, and Profile.
3. **Communities** — categories with clear joined/not-joined controls.
4. **Footer** — language toggle and logout.

The drawer uses the same translucent surface, soft border, and rounded geometry
as the top navigation. XP/tier, achievements, leaderboard, and the richer
milestone timeline remain follow-up work after their destination screens exist.

### 3.3 Post detail screen (`/community/posts/:id`)

- Post header (full content, media, author, category, time).
- Reaction bar: all 4 types; active = `myReaction`; counts update from the
  returned `Post`.
- Share button → bottom sheet (Telegram / Facebook / Copy link) →
  `sharePost` mutation with the chosen `SharePlatform`.
- Comments: top-level oldest-first via `comments(postId)` with cursor paging;
  the fixed compose bar creates comments and syncs the count back to the feed.
  Nested replies and reply-to context (`parentId`) remain a later enhancement.
- Handle moderated posts: GraphQL error on missing/HIDDEN → friendly
  "Post unavailable" state.

### 3.4 Compose screen (`/post/create`)

- Category picker (joined categories only — backend rejects posts to
  unjoined categories; if the selected category is not joined, show a join
  prompt that calls `joinCategory` first).
- Title (≤200) + content fields, optional `mediaUrl`.
- STEM keyword pre-check hint ("Posts must relate to STEM, Tech, or History")
  and surface the backend filter error verbatim on failure.
- Return `true` on success so the feed can prepend the new post (same
  convention as `blog/create`).

## 4. Architecture

Follow existing app conventions (see `lib/features/blog` as the reference
implementation): hand-written Riverpod 3 providers with sealed state classes,
defensive hand-written models, snake_case files, one screen per file.

### 4.1 Files

```
lib/features/social/
├── data/
│   ├── social_api.dart        # GraphQL + gamification REST wrapper over DioClient
│   └── social_models.dart     # SocialPost, SocialComment, SocialCategory,
│                              # PageInfo wrappers, Streak, GamificationProfile
├── providers/
│   ├── social_providers.dart  # socialApiProvider, streakProvider,
│   │                          # gamificationProfileProvider, categoriesProvider
│   ├── feed_provider.dart     # SocialFeedNotifier + sealed SocialFeedState
│   └── post_detail_provider.dart
├── presentation/
│   ├── social_feed_screen.dart
│   ├── post_detail_screen.dart
│   └── compose_post_screen.dart
└── widgets/
    ├── post_card.dart
    ├── reaction_bar.dart      # inline + long-press picker (4 types)
    ├── category_chips.dart
    ├── feed_drawer.dart
    ├── streak_chip.dart / streak_card.dart
    ├── comment_thread.dart
    └── share_sheet.dart

lib/shared/                    # currently empty dirs — populate as reused
├── avatar/  app_avatar.dart
├── navigation/ collapsing_app_bar helpers if reused elsewhere
└── gamification/  tier_badge.dart, xp_progress_bar.dart
```

### 4.2 GraphQL client

No new dependency — raw `dio.post('${ApiConfig.baseUrl}/graphql', ...)` with
hand-built operation documents, the same pattern blog already uses for
`categories` (`blog_api.dart`). All queries in one place in `social_api.dart`;
parse `data` and surface `errors[0].message` from the GraphQL envelope.

### 4.3 Feed provider behavior

```dart
sealed class SocialFeedState {}
class SocialFeedLoading  extends SocialFeedState {}
class SocialFeedLoaded   extends SocialFeedState {
  final List<SocialPost> posts;
  final String? endCursor;   // UUID, opaque
  final bool hasNextPage;
  final bool isLoadingMore;
  final String? categoryId;  // null = For You
}
class SocialFeedError extends SocialFeedState { final String message; }
```

- `load({String? categoryId})` — resets and fetches page 1.
- `loadMore()` — guarded by `hasNextPage && !isLoadingMore`, appends.
- `toggleReaction(postId, ReactionType)` — optimistic local update, then
  `react` mutation; reconcile/rollback using the returned `Post`.
- `share(postId, platform)` / `report(...)` helpers.

### 4.4 Routes (`lib/app/router/app_router.dart`)

| Route | Screen | Notes |
|---|---|---|
| `/home` | `SocialFeedScreen` | Replaces `HomeShell`; auth redirect logic unchanged |
| `/community/create` | `ComposeCommunityPostScreen` | Returns `bool` |
| `/community/posts/:id` | `SocialPostDetailScreen` | Full post + comments |
| `/profile/:id` | `SocialFeedScreen` variant | Feed with `authorId`; phase 2 |

## 5. Backend gotchas (must handle)

1. `react` is a toggle — design optimistic UI around the returned full `Post`.
2. Do not use `removeReaction` (always decrements, even when nothing existed).
3. `createPost` fails without prior `joinCategory` — gate the composer.
4. STEM content filter rejects non-STEM posts/comments — pre-warn + surface
   the backend message ("Content must be related to STEM, Tech, or History").
5. GraphQL endpoint is `/graphql`, **not** `/api/graphql` (old wireframe
   footer is wrong).
6. Feed has no sort — newest first only; do not render NEW/HOT tabs.
7. Hidden (moderated) posts vanish from feeds and error on direct access.
8. No follows/notifications/view counts — do not render them anywhere.
9. GraphQL cursor = plain UUID; REST gamification cursors = opaque base64url.
   Never parse either client-side.
10. Comments are oldest-first; replies nest via `parentId`.

## 6. UI, theme, localization

- Use `AppTheme` color constants + `Theme.of(context).textTheme` idioms;
  white cards, `AppTheme.outline` borders, 12–20 radius, 20dp horizontal
  padding (match `blog_feed_screen.dart`).
- Skeleton loading, error-with-retry, and empty states for the feed.
- All user-facing strings in ARB files (`en` + `km`); do not hard-code
  English as the blog feature did.
- Design tokens will later move to the system in
  `docs/DESIGN_SYSTEM_PLAN.md`; keep this screen structure-compatible.

## 7. Testing & verification

- Unit tests under `test/features/social/`: model parsing (defensive JSON),
  feed notifier (load / loadMore / toggleReaction rollback), API operation
  builders — `mocktail`, style of `test/core/network/dio_client_test.dart`.
- `flutter analyze` clean.
- Manual smoke test vs local `riksa-api`: feed paging, category filter,
  join→post→comment→react→share round trip, streak chip after lesson
  completion.

## 8. Implementation phases

| # | Phase | Deliverable |
|---|---|---|
| 1 | Data layer | `social_api.dart` + models + provider scaffolding, unit tests |
| 2 | Feed screen | Collapsing SliverAppBar, chips, cursor pagination, PostCard |
| 3 | Drawer | Profile header, streak card, communities join/leave, quick links |
| 4 | Post detail | Paged comments and composer implemented; nested replies deferred |
| 5 | Reactions & share | 4-type picker, share sheet, report menu |
| 6 | Compose | Join gate, STEM hint, create flow |
| 7 | Polish | Skeletons, empty/error states, full l10n, tests green |

## 9. Open decisions (deferred)

- Media upload for `mediaUrl` (no upload endpoint exists yet — field stays
  optional/unused or accepts an external URL).
- Leaderboard/achievements full screens vs simple sheets.
- Whether `/profile/:id` gets its own tabbed screen later (posts/comments/
  achievements) — backend supports posts via `feed(authorId:)`; comments have
  no per-user query yet.
