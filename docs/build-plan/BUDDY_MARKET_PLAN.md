# Buddy market — brainstorm plan

**Status:** turned into a Codex run sheet on 2026-09-27 →
[`next/PLAN.md`](next/PLAN.md) (Waves 0–5, prompts in `next/prompts/`).
This file stays the design reference: the reasons behind each decision, and
the audit evidence. Default decisions D1–D6 are recorded in `next/PLAN.md`.

**Contents:** buddy on the server and the market (§1–7), floating head and
quest panel plus weekly quests (§8), social post text and photo fixes (§9),
health check fixes (§10), validated code audit (§11), parking lot (§12).

**Goal:** each learner's buddy looks like theirs. Learners spend what they
earned from learning on hats, clothes and accessories. The buddy and everything
it owns live on the server, so they are the same on every device and can't be
changed on the device alone.

> Learn → earn XP → spend it in the market → buddy wears it everywhere
> (floating head, lessons, profile, leaderboard, social posts) → friends see it.

Repos and ground rules are the same as [PLAN.md](PLAN.md). This would be Wave 5
and later.

---

## 1. What already exists

The buddy is already partly on the server. This work extends it rather than
starting over.

| Piece | Where | State |
|---|---|---|
| `buddy` table: species, name, energy, bond | API `V34__buddy_care.sql` | ✅ server |
| `buddy_care_event` (deduplicated care gains) | API `V34` | ✅ server |
| `GET/PUT /buddy/me` | API `BuddyController`, app `buddy_api.dart` | ✅ used |
| App buddy state | `buddy_care_provider.dart`, `mascot_provider.dart` | ⚠️ Local copy in SharedPreferences first, then synced to the server |
| XP total | `user_gamification.total_xp` (has `@Version`) | ✅ server |
| XP ledger | `xp_transaction`: amount, sourceType, sourceId, **runningBalance** | ✅ server; already a ledger pattern to copy |
| Leaderboard | ranked by `total_xp` | ✅ server |
| Sprites | `assets/images/mascots/<species>/` ~72 body frames + 80 faces each | App-bundled PNGs |

**Gaps:**
- The server should be the only source of truth for signed-in users. The local
  copy should be a cache only.
- Nothing yet stores a balance you can spend, item ownership, or which items
  are equipped.
- Sprites are whole images, so there is nowhere to attach a hat yet.

---

## 2. Key decisions (open)

### D1. What do users spend?

Buying things **must not lower `total_xp`**. The leaderboard, tiers and rank
history all use it. If buying lowered it, people who shop would fall in rank.

| Option | How | Pros | Cons |
|---|---|---|---|
| **A. Spendable XP balance** *(leaning)* | New `xp_balance` column. Earning XP adds to both `total_xp` and `xp_balance`. Buying subtracts only from `xp_balance`. | One number users already understand; small change | Harder to reward shopping separately from ranking later |
| B. Separate coins | Earned next to XP at a set rate, plus bonuses (streaks, quests) | Full control over the economy | A second currency to explain; more UI |
| C. Hybrid | Start with A; add special "gems" later for rare items | Allows a later upgrade | Decide later |

**Backfill:** existing users start with `xp_balance = total_xp`, or with a fixed
starter amount to prevent inflation. *Undecided.*

### D2. How do items get drawn on the buddy?

This is the biggest cost. With 2 species × ~72 frames, drawing every item on
every frame won't scale.

| Option | How | Cost |
|---|---|---|
| **A. Anchor points** *(leaning)* | One JSON file per species listing each frame's head/body anchor (x, y, rotation, scale). An item is one PNG per species, placed at the anchor. | Anchors are made once per frame; each new item costs 2 PNGs |
| B. Static poses only | Items show only in the wardrobe pose, avatar and profile, not in animations | Cheapest; the buddy loses items while animated |
| C. Rive/skeletal rig | Rebuild the buddy as a Rive character with item slots | Best result; too slow before the deadline |

Possible middle ground: use A for the head slot (floating head, faces, avatars)
and B for body items at first.

### D3. Where do item images live?

- **Bundled in the app:** fast and works offline, but new items need a new app
  release.
- **Server/CDN:** the catalog returns `assetUrl`s and the app caches them. New
  items can go live without a release. *(leaning, and the bundled images can
  seed the cache)*

### D4. Guests

Guests can browse the market and try items on, but can't buy. "Sign in to keep
your buddy's style" goes through `require_account.dart`, the same pattern as
quests.

---

## 3. Data model (API draft)

Next migration numbers come after the current highest (V38 when this was
written). Check again before assigning.

```sql
-- Spendable balance (if D1 = A)
ALTER TABLE user_gamification ADD COLUMN xp_balance BIGINT NOT NULL DEFAULT 0
  CHECK (xp_balance >= 0);

-- Catalog
CREATE TABLE market_item (
  id UUID PRIMARY KEY,
  slot VARCHAR(20) NOT NULL,          -- HAT | TOP | ACCESSORY | BACKGROUND | ...
  name VARCHAR(60) NOT NULL,
  name_km VARCHAR(60) NOT NULL,
  price BIGINT NOT NULL CHECK (price >= 0),
  rarity VARCHAR(20) NOT NULL,        -- COMMON | RARE | EPIC
  species_mask VARCHAR(40),           -- null = all species
  min_tier VARCHAR(20),               -- optional level gate
  available_from TIMESTAMPTZ,         -- limited / seasonal drops
  available_until TIMESTAMPTZ,
  asset_key VARCHAR(80) NOT NULL,     -- maps to per-species PNGs
  sort_order INT NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT true
);

-- Ownership
CREATE TABLE buddy_inventory (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES market_item(id),
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  source VARCHAR(20) NOT NULL,        -- PURCHASE | QUEST | ACHIEVEMENT | GIFT | ADMIN
  PRIMARY KEY (user_id, item_id)
);

-- What's worn (one item per slot)
CREATE TABLE buddy_equipped (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  slot VARCHAR(20) NOT NULL,
  item_id UUID NOT NULL REFERENCES market_item(id),
  PRIMARY KEY (user_id, slot)
);
```

Spending is recorded as a negative `xp_transaction` row with
`sourceType = "MARKET_PURCHASE"` and `sourceId = item_id`. The ledger already
has `runningBalance`, so this needs no new table. (Check whether
`runningBalance` should track `total_xp` or `xp_balance`; a separate
`balance_after` column may be needed.)

---

## 4. API contract draft

All under `/api/v1`, Bearer JWT.

`GET /market/items?slot=&cursor=`
```json
{ "items": [ { "id", "slot", "name", "nameKm", "price", "rarity",
  "assetKey", "assetUrls": { "crocodile": "…", "capybara": "…" },
  "owned": false, "equipped": false, "locked": false, "lockReason": null,
  "availableUntil": null } ],
  "balance": 1240 }
```

`POST /market/items/{id}/purchase`
- Header `Idempotency-Key: <uuid>`. A second tap returns the same result.
- One DB transaction: lock the gamification row (`@Version` or
  `SELECT … FOR UPDATE`), check the balance, subtract it, insert inventory, and
  insert the ledger row.
- `200` → `{ "item", "balance" }` · `402/409 INSUFFICIENT_BALANCE` ·
  `409 ALREADY_OWNED` · `410 NOT_AVAILABLE` · `403 LOCKED`

`GET /buddy/me` → the existing response **plus**
`"equipped": { "HAT": { "id", "assetKey" }, … }` and `"balance"`.

`PUT /buddy/me/equipped` body `{ "slot": "HAT", "itemId": "uuid" | null }`.
The server checks that the user owns the item.

Public buddy look (for other people's profiles, leaderboard rows and social
posts): add `buddy: { species, name, equipped }` to the public profile and
leaderboard entry DTOs. **Don't** make a separate call for each row.

---

## 5. App work draft

- **Server-first buddy:** for signed-in users, `/buddy/me` is the truth and
  SharedPreferences is only a cache. When a guest signs up, their local buddy is
  sent to the server once (the same idea as the pending-province fix: fill only
  when the server copy is empty; **never** overwrite an existing account).
- **`lib/features/market/`:** models, api, providers (`marketItemsProvider`,
  `buddyLookProvider`, a purchase action that refreshes the balance and the
  buddy).
- **`BuddyLook` widget:** draws the base sprite plus the equipped layers using
  the anchor JSON. Every buddy render goes through it: floating head, lesson
  companion, profile, avatar, leaderboard, and milestone posts.
- **Market screen:** tabs by slot, a big live preview of the user's buddy at
  the top, try-on without buying, price and balance, and a buy confirmation
  sheet. Celebrate a purchase with a mascot `celebrate` animation (respect
  reduced motion).
- **Wardrobe:** owned items, and tap to equip or unequip.
- **Entry points:** the floating buddy sheet, the profile, and a small "new
  items" dot. **Not the bottom nav bar**, because a teammate owns it.
- l10n prefix: `market…`, `wardrobe…`.

---

## 6. Suggested waves (for later)

| Wave | Task | Repo | Depends on |
|---|---|---|---|
| 5a | Balance column + ledger + backfill; catalog/inventory/equipped tables; seed 6–10 items | API | D1 |
| 5a | Anchor JSON for both species + first item PNGs (hat slot) | Assets | D2 |
| 5b | Market + purchase + equip endpoints; public look on DTOs | API | 5a |
| 5b | Server-first buddy refactor + `BuddyLook` widget (fake API) | App | 5a assets |
| 5c | Market screen + wardrobe (fake API) | App | 5b contract |
| 5d | Read-only review, both repos | Both | all |

Minimum for the competition demo: **1–2 slots (hat and top), 6–10 items,
buy/equip, and the look shown on the floating head and profile.**

---

## 7. Risks and abuse

- **Double spend or race:** idempotency key plus a row lock. Test two purchases
  running at once.
- **XP farming:** now that XP buys things, check that current XP sources have
  caps (quests, resource saves, care).
- **Inflation:** if everyone already has thousands of XP, the market is sold
  out on day one. Backfill carefully (D1).
- **Art cost:** each item × each species. Keep the first set small.
- **Offline:** show the cached look; turn off buying while offline.
- **Refunds/admin:** admin grant/revoke endpoint using `source = ADMIN`, and a
  negative ledger row for refunds.

---

## 8. Floating buddy and quest sheet refresh

These can ship **before** the market. The market will later reuse the look.

### Floating head: no circle
- Draw the face PNG straight onto the page, with no circle, border or clip. The
  faces already have transparent backgrounds (crocodile 138×101, capybara
  118×92), so they show at their real shape.
- A shadow that follows the head's shape (a blurred, darker copy of the image),
  not a box shadow. In dark mode, a thin light outline so it reads over dark
  content.
- The tap area stays ≥56px. Replace the circle ripple with a squash/bounce
  (skip it when reduced motion is on). Put the badge next to the face, on the
  side facing the middle of the screen.
- Later: new face art at 2–3× (it's slightly blurry at 56–64px on 3× screens).
  Hats from the market can extend past the face outline.

### Today sheet redesign
Current version (`_TodayQuestsSheet` in `floating_buddy.dart`): plain Material
cards, and the streak is a pill with no visual. Each quest row shows its
progress in three places (bar, "x of y", then "x/y" again), and the claim
button is a small TextButton.

**Presentation: a speech bubble growing out of the head, not a bottom sheet.**
- Tapping the head grows a panel out of the head (scale and fade from the
  head's position). A small tail points back to the head, so the buddy looks
  like it's talking. The head stays visible above the dim layer and plays a
  talking/happy face.
- **Same content as the bottom-sheet design, not a cut-down version:** the
  panel is nearly screen width (screen − 24px, max ~380px on tablets) and up to
  ~75% of the height. It keeps full-size stat tiles (streak dots, chest bar),
  quest rows with the "progress · +XP" subline and progress ring, the bonus
  and reset footer, and the guest sign-in. Only the origin and shape change.
- **Placement:** line the panel up with the edge the head is snapped to. If the
  head is in the top half of the screen, open downward; otherwise open upward.
  Never cover the nav bar or system insets. Max height is the space left after
  those; content scrolls inside.
- **Close:** tap outside, tap the head again, back button or gesture,
  or `Go →`. It shrinks back into the head.
- **Mechanics:** use a route (`showGeneralDialog` / `PopupRoute` with a custom
  transition) rather than a bare `OverlayEntry`. That gives the back button,
  focus trapping and screen-reader "dismiss" support for free.
- **Reduced motion:** fade only.
- **Fallback:** when the panel can't fit (short screen, landscape, or Khmer at
  large text scale), switch to the bottom sheet with the same contents.
  Build the content as one widget used by both.
- Dragging the head while the panel is open isn't allowed; close it first.

Target layout (top to bottom):
1. **The buddy speaks:** the live mood face and a chat-style speech bubble. The
   line reacts to state ("1 lesson left and your streak is safe", "Claim your
   XP!", "All done — see you tomorrow").
2. **Two stat tiles:** a streak tile with the last 7 days as dots, and a
   weekly-chest progress tile (see below).
3. **Today / This week toggle,** with a dot showing how many are claimable.
4. **Compact quest rows:** a progress ring around the icon, a title, a
   "progress · +XP" subline, and **one** action on the right:
   `Claim` (filled) when claimable, `Go →` to the matching screen when not done
   (lesson → /learn, social → /social), and faded with strike-through when
   claimed.
5. **Footer:** the all-clear bonus and a "resets in Xh Ym" countdown
   (Asia/Phnom_Penh midnight).
- Claiming: an XP count-up flies from the row into the tile, the buddy switches
  to `celebrate`, and there's a light haptic. Reduced motion shows a static
  "+15 XP".
- Guests: the same layout with a lock on the claim buttons and one sign-in
  button at the bottom.
- Market hook for later: a "Spend XP" link that shows the balance.

### Weekly quests (new — only daily quests exist today)
Today the API has `QuestType` with 3 fixed daily types (`COMPLETE_LESSON`,
`CORRECT_ANSWERS`, `SOCIAL_ACTION`), table `daily_quest` (`V35`), and
`GET /quests/today`. There are no weekly quests, and the daily set is the same
every day.

Proposal:
- `quest` gets a `period` column (`DAILY | WEEKLY`) and a `period_start` (the
  date the day or week starts; the week starts Monday, Phnom Penh time).
  *Or* a separate `weekly_quest` table. Decide when writing the prompt.
- Weekly examples: finish 7 lessons (100 XP), 5-day activity week (80 XP),
  30 correct answers (60 XP), help once (post a resource or comment, 40 XP),
  and complete a whole unit (120 XP).
- **Weekly chest:** each daily quest claimed adds 1 point (max 21/week), and
  15 points opens the chest. The chest gives bonus XP now and a **random
  market item** once the market exists. This ties the two features together.
- Daily set rotation: pick 3 from a larger pool each day, deterministic per
  user and date, so days don't all feel the same.
- API: `GET /quests/week` (same shape plus `weekStart` and `chest`:
  `{ points, target, opened }`), and `POST /quests/chest/open`. Reuse the claim
  endpoint for weekly quests.
- Anti-farm: social quests count only distinct targets, and none on your own
  posts.

## 9. Social posts: text formatting and photos

Not a buddy feature, but part of the same next batch. Found by review on
2026-09-26.

### Problems found

**Text**
- T1. The detail body is **13px in a muted grey** (`_socialMarkdownStyleSheet`
  `p:` in `social_post_detail_screen.dart` ~L907). The feed preview is 15px in
  the normal ink colour, so opening a post makes it harder to read.
- T2. `textAlign: WrapAlignment.spaceBetween` in the same style sheet spreads
  words unevenly, which is worse in Khmer.
- T3. The feed preview shows raw markdown. `socialMarkdownPreview`
  (`social_models.dart` ~L301) only removes headings, `-`/`+` bullets, `**`,
  `__` and backticks. `*italic*`, `[text](url)`, `> quote`, `1.` lists, `* `
  bullets, code fences and `![](…)` stay. Blank lines use up the 4-line preview.
- T4. Links can't be tapped (`MarkdownBody` has no `onTapLink`).
- T5. The composer body is a plain `TextFormField`: no formatting help and no
  preview. The toolbar only has "Add photo".
- T6. Every post needs a title (≥4 chars) and a body (≥10 chars)
  (`compose_community_post_screen.dart` ~L391). That feels like Reddit on an
  X-style feed; a quick question with a photo can't be posted.

**Photos**
- P1. Feed photos are always cropped to 16:9 (`social_post_card.dart` ~L153).
  Tall phone photos of homework, notes and exam questions lose their top and
  bottom.
- P2. There's no full-screen viewer or pinch-zoom, so a photographed maths
  problem can't be read.
- P3. Detail photos have no height limit, so long screenshots become huge.
- P4. There's no `loadingBuilder` or caching, so images pop in, shift the
  layout and download again. The feed decodes the full 1600px image (no
  `cacheWidth`).
- P5. Only one photo per post (`mediaUrl: String?`).

### Fix: part 1, app only (no API change)
- T1/T2: set the detail body to 15–16px in `ink` with normal alignment. Keep
  the heading scale and the Khmer line height from `RiksaTypography`.
- T3: build the preview from the parsed markdown AST (`package:markdown`, which
  `flutter_markdown_plus` already depends on) instead of regex. Output plain
  text, keep line breaks and fold blank lines together. Show `[image]` / link
  text only.
- T4: add `onTapLink` that opens `http`/`https` only, in an external browser
  (`url_launcher`; check whether it's already a dependency).
- T5: a formatting bar above the keyboard: bold, italic, bullet list, numbered
  list, quote and link. Each wraps or prefixes the selection in the controller.
  Add a **Write / Preview** toggle that uses the same markdown style sheet as
  the detail page.
- P1: feed photos use the image's real shape, clamped between **1:1 and 4:5
  (portrait)**. Wide images can go down to 16:9. Until the size is known, use a
  4:5 placeholder with the surface colour.
- P2: tap a photo to open a full-screen viewer: a Hero transition,
  `InteractiveViewer` pinch/double-tap zoom, swipe down to close, and a
  dark background.
- P3: limit detail photos to ~70% of the screen height with `BoxFit.contain`;
  tap to open the viewer.
- P4: add a `loadingBuilder` shimmer/placeholder, and feed `cacheWidth` ≈
  card width × device pixel ratio. Consider `cached_network_image` (a new
  dependency; say so before adding it).
- Tests: preview stripping (table of inputs to expected output), link tap,
  portrait photo not cropped, viewer opens and closes, composer bar wraps the
  selection, and Khmer at 200% text scale. Regenerate the social goldens.

### Fix: part 2, needs the API
- P5: `mediaUrls: string[]` (max 4) on posts. Show 1 / 2 side by side / 3 as
  one big plus two small / a 2×2 grid, and the viewer swipes between them. Keep
  reading the old `mediaUrl` until all old posts are migrated.
- Store `width` and `height` for each uploaded image and return them next to
  the URL, so the feed lays out correctly before the image loads (no jump).
- T6: title optional (or only required for "question" posts). The feed falls
  back to the first line of the body.

## 10. Health check fixes (found 2026-09-27)

Baseline on `staging` with the uncommitted working tree: `flutter analyze` is
clean, and **497/499** tests pass.

| # | Issue | Where | Priority |
|---|---|---|---|
| H1 | 12 Khmer strings are literally `"TODO(km): …"`: `buddyCareTitle`, `buddyCareLesson`, `buddyCareRead`, `buddyCareShare`, `buddyChooseAction`, `buddyCareProgress`, `buddyEnergyLively/Steady/Sleepy/Napping`, `buddyLessonEnergyLine`, `buddyReadEnjoyed`. Khmer is the first-run default. | `lib/l10n/app_km.arb` ~L787 | **High (demo)** |
| H2 | 2 golden tests fail by 0.03% (105px): `social_post_detail_editorial_en_light/dark`. The only direct change is the author tap → `openUserProfile`, so the pixel change likely comes from a shared widget in the uncommitted diff (profile/avatar). **Inspect the diff before regenerating.** | `test/visuals/social_feed_screen_golden_test.dart:309` | High |
| H3 | 33 modified and untracked files are uncommitted on `staging` (incl. `subject_map.dart`, `assets/images/maps/`). Commit before any Codex wave, because worktrees start from the last commit. | repo | **High (blocks waves)** |
| H4 | AI tutor coach cards are English only (titles and subtitles written in code). Move them to l10n (`aiCoach…` prefix). | `lib/features/ai/presentation/widgets/ai_study_coach_hub.dart` ~L28–72 | Medium |
| H5 | English-only strings: heatmap "Less"/"More", blog error "Try again", onboarding screen-reader "Page x of y". | `streak_details_sheet.dart` ~L603/622, `blog_detail_screen.dart` ~L292, `onboarding_splash_screen.dart` ~L685 | Medium |
| H6 | On a new device, onboarding asks existing accounts for a province, which is then ignored (login now keeps the saved province). Skip that step for returning accounts, or let them sign in first. | `interactive_onboarding_screen.dart`, `auth_provider.dart` `_hydrateProfile` | Medium |
| H7 | iOS `AppDelegate` doesn't set the `UNUserNotificationCenter` delegate, so there's no banner while the app is open and a notification tap may not reach the app. | `ios/Runner/AppDelegate.swift` | Low |
| H8 | `learning_insights.dart` isn't imported anywhere, and its text is English only. Delete it, or wire it up and translate it. | `lib/features/learning/presentation/widgets/learning_insights.dart` | Low |

Notes:
- H1: **a Khmer speaker must review** the translations before shipping, even if
  a worker drafts them.
- H3 is **Wave 0** for this batch. Nothing else starts until the tree is
  committed and green.
- Already fixed in this session (not yet committed): login no longer replaces
  an existing account's province with the onboarding pick
  (`auth_provider.dart` `_hydrateProfile`).

## 11. Code audit: Agy findings validated by Claude (2026-09-27)

Three read-only Agy workers (Gemini 3.1 Pro) audited `lib/` in disposable
clones that included the uncommitted work. They reported 19 findings. Each one
was then checked against the real code. **Confirmed** = the bug is real as
described. **Partial** = real, but narrower or less severe than reported.
**Rejected** = not a bug.

### Confirmed, fix these

| # | Issue | Where | Sev |
|---|---|---|---|
| **X1** | **Account switch leaks the previous user's data (one root cause).** Several user-specific providers are neither `autoDispose` nor rebuilt when the signed-in user changes, and `AuthNotifier.logout()` invalidates nothing. After logout → a different login on the same device (no app restart), the new user sees the old user's cached data until a manual refresh. Affected: `todayQuestsProvider` (A1), `socialFeedProvider` + `blogFeedProvider` incl. joined communities and my reactions (C5), `aiChatSessionsProvider` / `aiChatSessionProvider` (C1), `lessonResourcesProvider` `savedByMe` (B4). **Fix once:** a `currentUserIdProvider` (select on `authProvider`); every user-specific provider `watch`es it so it rebuilds on account change. Or invalidate them all in one place on auth change. Add a test: log in as A → load → log out → log in as B → no A data. | `today_quests_provider.dart:71`, `social_feed_provider.dart:377`, `blog_provider.dart:260`, `ai_chat_provider.dart:6-14`, `lesson_resources_provider.dart:118`, `auth_provider.dart:336` | **High** |
| **C1** | **AI chat history saved on the device is shared across accounts.** `AiChatCache` uses fixed keys (`ai_chat_sessions_cache`, `ai_chat_session_<id>`) and is never cleared on logout. `AiChatApi.sessions()/session()` fall back to it on **any** network error, so user B offline sees user A's AI conversations. Scope the keys by user id and clear them on logout. | `ai/data/ai_chat_cache.dart:6-7`, `ai_chat_api.dart:23-39` | **High (privacy)** |
| **A4** | **A network hiccup during token refresh logs the user out.** `_performRefresh` catches everything and returns `false`. The interceptor then runs `_clearSession()` and fires session-expired. A timeout or no signal at the moment the access token expires is treated like a revoked token. Only a 401/403 from `/auth/refresh` (or an invalid token pair) should clear the session; network errors should fail the original request and keep the session. | `core/network/dio_client.dart:131-160` (caller ~L81-85) | **High** |
| **C4** | **Communities tab / search can get stuck empty.** Filtering is done on the client over the pages already loaded, and more pages only load from a scroll listener. If none of the loaded posts match, the list can't scroll, so `loadMore` never fires. Short term: when the filtered list is shorter than the screen and `hasNextPage`, call `loadMore()` automatically (with a cap). Proper fix: server-side `categoryId` / `joinedOnly` / search params. | `social/presentation/social_feed_screen.dart:180-184`, `_loadMoreNearEdge` ~L70 | Medium |
| **C2** | **Creating a post can undo other feed changes made during the upload.** `createPost` captures `latest = current` **before** the `await`, then writes `latest.copyWith(...)`. A like, join or `loadMore` finishing meanwhile is lost. Re-read `state` after the await (as `toggleReaction` already does). Agy says `BlogFeedNotifier.loadMore` / `toggleLike` have the same pattern; **check those while fixing.** | `social_feed_provider.dart:228-244`, `blog_provider.dart` | Medium |
| **B2** | **Saved (bookmarked) lessons are shared by every account on the device.** They're stored only on the device under the global key `riksa_saved_lesson_ids`, with no user scope and no server sync. Scope the key by user id (and keep a guest bucket); ideally sync to the server later. | `learning/providers/saved_lessons_provider.dart:8,65` | Medium |
| **A2** | **The previous user's buddy stays for the next guest.** `mascotProvider` uses global keys. On login, `buddyCareProvider` replaces them with the server buddy (so signed-in users are fine), but after logout a guest keeps the previous user's species and name. Reset to the guest buddy on logout. Fits the "server-first buddy" work in §5. | `mascot/providers/mascot_provider.dart:41-42`, `buddy_care_provider.dart:78-86` | Low–Med |
| **B1** | **No guard against a double tap on "Check answer".** `_submitAnswer` adds to `_submitting` but never checks it first. The button only turns busy after the next frame, so two quick taps send two requests. Add `if (_submitting.contains(exercise.id)) return;`. Also confirm the API scores each exercise attempt only once (backend idempotency). | `learning/presentation/lesson_experience_screen.dart:799-806` | Medium |
| **B6** | English written in code: `'Completed earlier - your progress was restored.'` → l10n. | `lesson_experience_screen.dart:259` | Low |

### Partial / low value (optional)
- **C3:** `response.data as Map` on a non-JSON 502 page throws a `TypeError`
  instead of a `DioException`. It **does not crash the app**: callers catch it,
  or it becomes an `AsyncError`. But users would see a raw error. Low: add a
  type check in the API clients so they throw a friendly error.
- **C6:** deleting a root comment removes its replies from the list, but
  `commentCount` only goes down by 1. It depends on whether the server count
  includes replies; check the backend, then subtract what was actually
  removed. Low.
- **B5:** the leaderboard rankings are drawn in a `Column`, not built lazily.
  It's fine at the current page size; switch to `SliverList.builder` if the
  list grows past ~100. Low.
- **A6:** the buddy card decodes the full scene `.webp` for an 82px card. Add
  `cacheWidth`. Low.

### Rejected
- **A3 (open redirect via `/\evil.com`):** `from` only goes to go_router
  `context.go`. On mobile that's an unmatched route. On web, same-origin
  `pushState` can't send the user to another host. Harmless hardening at most
  (optionally also reject `\`).
- **A5 / C7 ("must use Asia/Phnom_Penh for all day boundaries"):** these are
  **device-side** things: an 8 PM reminder at the user's local time, "hide
  buddy for today", "Today/Yesterday" chat labels. The local time zone is
  correct for them. Phnom Penh time only matters for server-side quest and
  streak days, and those are already computed on the server.
- **B3 ("PopScope confirm dialog loops forever"):** `_safePop` calls
  `Navigator.pop()`, which **does not** check `PopScope.canPop` (only
  `maybePop` does). Confirming "Leave" pops normally.

### Audit coverage gaps
- **Worker B skipped ~35 files "for time"**, including all of
  `userProfile/` (profile screen, public profile, settings, providers),
  `learning_api.dart`, `learning_home/roadmap/catalog` providers,
  `subject_map.dart`, and the resources UI. **Re-run a focused audit on these
  before calling the audit complete.**
- The audit was static only. X1, A4, C4 and B1 need a device/API test to
  reproduce.

## 12. Idea parking lot

*Add new ideas here before they go into the plan.*

Deferred from the 2026-09-27 run sheet:
- Daily quest rotation from a larger pool (D6).
- Weekly social quest counting only **others'** posts and **distinct** targets
  (needs a target id on `SocialActionEvent`).
- Body clothing (tops, backgrounds) using per-frame body anchors.
- Item art served from a CDN instead of bundled (D3).
- Server push (FCM) for social events and item drops; local reminders for
  quest reset and "chest almost full".
- Server-side feed filters (`categoryId`, `joinedOnly`, search) to replace the
  client-side auto-load in C4.
- Sync saved lessons to the server.

From the Agy audit of the files the first audit skipped (2026-09-27). G1
(profile stats/catalog not reset on account change) is fixed in
`924ac90`. Still open:
- G2 `learning_home_provider.dart:152` reads roadmap futures with `ref.read`,
  so an open home screen doesn't update after lesson progress (switching to
  `watch` needs care to avoid rebuild loops).
- G3 `lesson_catalog_provider.dart:201` swallows a failed next-page load.
- G4 `user_profile_screen.dart:1008` builds all posts in a `Column`.
- G5 `profile_cover.dart:116` decodes the cover at full size (`cacheWidth`).
- G6 `profile_ui.dart:614`, `riksa_profile_drawer.dart:503` tap targets < 48px.
- G7 `public_profile_screen.dart:230` articles tab renders empty space.

- Items as quest/achievement rewards (not only purchases).
- Limited seasonal drops (Khmer New Year, Pchum Ben, exam season).
- Province-themed items (ties into the province leaderboard).
- Rarity tiers with a visual shine.
- Gifting items to friends.
- Buddy "outfit" shown on social milestone posts.
- Try-on shareable card image.
