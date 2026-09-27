# RIKSA next build: Codex orchestration (Waves 0–5)

**Goal:** make the app safe and polished for the competition demo, then make
the buddy the heart of the app (quest panel, weekly chest, a market to spend XP
on items).

> Stable + private (W1) → posts look good (W2) → buddy panel + weekly quests
> (W3) → buddy wears items (W4) → market to buy them (W5).

Design notes, the reasons behind each decision, and the validated audit:
[`../BUDDY_MARKET_PLAN.md`](../BUDDY_MARKET_PLAN.md). This file is the **run
sheet**; the prompts in `prompts/` are what you paste into Codex.

## Repos

| Repo | Path | Stack | Branch |
|---|---|---|---|
| App | `RIKSA-FLUTTER` | Flutter, Riverpod 3, go_router, Dio | `staging` |
| API | `../RIKSA` | Spring Boot, Postgres, Flyway, GraphQL (social) | `feature/telegram-auth-options` |

## Ground rules for every worker

1. Codex runs with `-s workspace-write --worktree`. **Never** the bypass flag.
2. A worktree starts from the **last commit**. Wave 0 must be committed first.
3. **One writer per file.** Each prompt owns an explicit path list; anything
   outside it is rejected at review.
4. **Do not touch the bottom navigation bar.** A teammate is redesigning it.
   No new nav tab for the market; entry points are the buddy panel and the
   profile.
5. Every user-facing string goes in `lib/l10n/app_en.arb` **and**
   `app_km.arb` (Khmer is the first-run default). Run `flutter gen-l10n`.
   Khmer written by a worker is a **draft**; a Khmer speaker reviews it
   before shipping.
6. Respect reduced motion (`MediaQuery.disableAnimationsOf` / `RiksaMotion`).
7. Workers do not commit. The orchestrator reviews the diff, runs the checks,
   then integrates.
8. API migrations use the fixed numbers in the wave table. Never renumber
   someone else's.

Checks after every task:

```bash
flutter analyze && flutter test
```
```bash
./mvnw test
```

## Decisions (defaults chosen; change them here before the wave that uses them)

| # | Decision | Default | Used in |
|---|---|---|---|
| D1 | What users spend | **Spendable `xp_balance`** next to `total_xp`. Earning XP adds to both (inside `XpLedgerService.awardXp`); buying subtracts only `xp_balance`. Rank, tiers and the leaderboard stay on `total_xp`. Purchases are recorded in `buddy_inventory` (price paid + idempotency key), **not** as negative `xp_transaction` rows, so the XP history screen stays correct. | W4 |
| D1b | Starting balance for existing users | `xp_balance = total_xp` (prices are set with this in mind) | W4 |
| D2 | How items appear on the buddy | **Head items only in v1:** slots `HAT` and `EYEWEAR`, placed with per-species anchor JSON on the face and head images. Body clothing comes later. | W4, W5 |
| D3 | Where item art lives | **Bundled in the app:** `assets/images/market/<assetKey>/<species>.png`. The server only sends `assetKey`. A CDN comes later. | W4, W5 |
| D4 | Weekly chest reward | 50 XP in W3; W4 adds a random unowned COMMON item as a bonus | W3, W4 |
| D5 | Post titles | Optional (0–200). The body is required unless the post has ≥1 photo. | W3 API, W4 app |
| D6 | Daily quest rotation from a larger pool | **Not in this batch** (parking lot) | — |

## Wave 0: baseline (you, not Codex)

- [ ] **H2:** two goldens fail by 0.03% (`social_post_detail_editorial_en_light/dark`).
      Open the failure images under `test/visuals/failures/`, confirm the change
      is intended, then run
      `flutter test --update-goldens test/visuals/social_feed_screen_golden_test.dart`.
- [ ] **H3:** commit the Flutter working tree (33 modified files +
      `subject_map.dart` + `assets/images/maps/` + the province-overwrite fix in
      `auth_provider.dart` `_hydrateProfile` + `docs/build-plan/`).
- [ ] Confirm the API tree is clean (`git -C ../RIKSA status`), then note both
      commit hashes here.
- [ ] Baseline: `flutter analyze` clean, `flutter test` all green;
      `./mvnw test` = 417 tests, 0 failures, 5 Docker skips (last recorded).
- [ ] **Art (a person, can run in parallel with W1–W3):** item PNGs for the
      seeded items (§W4 table) for both species, and anchor points for the
      head (see `prompts/w4-buddy-look.md`). W4 ships with vector
      placeholders if the art isn't ready.

Baseline commits: Flutter `________` · API `________`

## Waves (max 3 concurrent workers)

| Wave | Task | Repo (`-C`) | Prompt | Migration |
|---|---|---|---|---|
| 1 | Account switch + per-user storage (X1, C1, A2, B2) | App | `prompts/w1-account-switch.md` | — |
| 1 | Network hardening (A4, C3) | App | `prompts/w1-network-hardening.md` | — |
| 1 | Khmer + l10n cleanup (H1, H4, H5, B6, H8) | App | `prompts/w1-l10n-cleanup.md` | — |
| 1.5 | *(optional)* Agy audit of files W1 audit skipped | App | orchestrator; see below | — |
| 2 | Social posts: text + photos (T1–T5, P1–P4, C6) | App | `prompts/w2-social-posts-ui.md` | — |
| 2 | Feed state fixes (C2, C4) | App | `prompts/w2-feed-state-fixes.md` | — |
| 2 | Small fixes (B1, H6, H7) | App | `prompts/w2-small-fixes.md` | — |
| 3 | Weekly quests + chest API | API | `prompts/w3-weekly-quests-api.md` | V39 |
| 3 | Floating head + quest panel + weekly tab | App | `prompts/w3-buddy-head-panel.md` | — |
| 3 | Post media + optional title API | API | `prompts/w3-social-media-api.md` | V40 |
| 4 | Market API (balance, catalog, buy, equip) | API | `prompts/w4-market-api.md` | V41 |
| 4 | Server-first buddy + `BuddyLook` | App | `prompts/w4-buddy-look.md` | — |
| 4 | Multi-photo posts (app) | App | `prompts/w4-social-multiphoto-ui.md` | — |
| 5 | Market + wardrobe screens | App | `prompts/w5-market-ui.md` | — |
| 5 | Read-only review | App | `prompts/w5-review.md` (`-s read-only`, no worktree) | — |
| 5 | Read-only review | API | `prompts/w5-review.md` (`-s read-only`, no worktree) | — |

App tasks build against the contracts below with a **fake API in tests**, so
they run in the same wave as their API half. Integrate a whole wave, run the
checks, commit, then start the next wave from that commit.

**Shared files, merged by hand:** `lib/l10n/app_en.arb` and `app_km.arb` are
the only files two workers in one wave may both touch. Each task uses its own
key prefix:

| Task | l10n prefix |
|---|---|
| w1-account-switch | `account…` |
| w1-network-hardening | `network…` |
| w1-l10n-cleanup | fixes existing keys; new keys `aiCoach…`, `heatmap…`, `lessonRestored…` |
| w2-social-posts-ui | `post…`, `composer…`, `photoViewer…` |
| w2-feed-state-fixes | `feed…` |
| w2-small-fixes | `onboardingReturning…` |
| w3-buddy-head-panel | `buddyPanel…`, `weekly…`, `chest…` |
| w4-buddy-look | `buddyLook…` |
| w4-social-multiphoto-ui | `postPhotos…` |
| w5-market-ui | `market…`, `wardrobe…` |

Merge the keys, then run `flutter gen-l10n` once.

**Files touched in more than one wave (never twice in one wave):**
`auth_provider.dart` (W1 account-switch, W2 small-fixes),
`social_feed_provider.dart` / `blog_provider.dart` (W1 account-switch, W2 feed-state),
`social_post_card.dart` / `social_post_detail_screen.dart` /
`compose_community_post_screen.dart` / `social_models.dart` (W2 posts-ui, W4 multiphoto),
`floating_buddy.dart` (W3 panel, W4 buddy-look, W5 market entry),
`quest_models.dart` / `today_quests_provider.dart` (W1 account-switch, W3 panel),
`lesson_experience_screen.dart` (W1 l10n B6, W2 small-fixes B1),
API `quest/**` (W3 weekly, W4 chest item drop).

### Wave 1.5 (optional): audit the files the first audit skipped

The first audit skipped all of `lib/features/userProfile/**`,
`learning_api.dart`, `learning_home_provider.dart`,
`learning_roadmap_provider.dart`, `lesson_catalog_provider.dart`,
`subject_map.dart`, `saved_lessons_screen.dart`, `lesson_search_delegate.dart`,
and `lib/features/resources/{data,presentation}/**`. Run a read-only
audit on them (Agy or Codex `-s read-only`) with the same brief, then add
confirmed findings to W2 or W3 before those waves start.

## Integration checklist

- [ ] Wave 0 — baseline committed; Flutter green; API baseline recorded.
- [ ] Wave 1 — account switch, network hardening, l10n. Manual check: log in
      as A → open quests, social, AI chat, saved lessons → log out → log in as
      B → none of A's data visible, even offline.
- [ ] Wave 2 — posts, feed state, small fixes. Manual check: a tall photo is
      not cropped; tap opens the zoom viewer; links open; a composer bold/list
      preview matches the published post.
- [ ] Wave 3 — weekly quests API (V39) + panel, and post media API (V40).
      Manual check: the panel grows from the head on both edges; the chest
      opens at 15.
- [ ] Wave 4 — market API (V41), `BuddyLook`, multi-photo posts. Manual check:
      buy and equip work on the API; the hat shows on the floating head;
      rank did **not** drop after buying.
- [ ] Wave 5 — market UI; both reviews resolved.

## API contracts (source of truth)

All JSON, Bearer JWT, base `/api/v1`. Day and week boundaries use
`Asia/Phnom_Penh`; the week starts **Monday 00:00**.

### Weekly quests + chest (W3, V39)

`GET /quests/today` → existing shape **plus** `"resetsAt": "2026-09-28T00:00:00+07:00"`.

`GET /quests/week`

```json
{
  "weekStart": "2026-09-28",
  "resetsAt": "2026-10-05T00:00:00+07:00",
  "quests": [
    {
      "id": "uuid",
      "type": "WEEKLY_LESSONS",
      "title": "Finish 7 lessons",
      "titleKm": "បញ្ចប់មេរៀន 7",
      "target": 7,
      "progress": 3,
      "xpReward": 100,
      "completed": false,
      "claimed": false
    }
  ],
  "chest": {
    "id": "uuid",
    "points": 9,
    "target": 15,
    "maxPoints": 21,
    "opened": false,
    "xpReward": 50,
    "rewardItem": null
  }
}
```

Weekly types (four per week, created lazily on the first request):

| Type | Target | XP | Progress source |
|---|---|---|---|
| `WEEKLY_LESSONS` | 7 | 100 | each completed lesson |
| `WEEKLY_CORRECT_ANSWERS` | 30 | 60 | each correct exercise answer |
| `WEEKLY_ACTIVE_DAYS` | 5 | 80 | distinct days with ≥1 completed lesson |
| `WEEKLY_SOCIAL` | 5 | 40 | each social action (the same event as the daily social quest; `SocialActionEvent` has no target id yet, so "others' posts, distinct targets" is in the parking lot) |

`POST /quests/{id}/claim` works for daily **and** weekly ids. Weekly claims
award XP through `XpLedgerService.awardXp` with `sourceType = "WEEKLY_QUEST"`
and `sourceId = quest id`.

Chest points = the number of **daily** quests claimed in the current week
(max 21). `POST /quests/chest/open` → the updated chest. It returns 409 if
`points < target` or it's already opened. It awards `xpReward` with
`sourceType = "QUEST_CHEST"` and `sourceId = chest id`. `rewardItem` stays
`null` until W4, then becomes `{ "id", "slot", "assetKey", "name", "nameKm" }`
or `null`.

### Post media + optional title (W3, V40)

GraphQL (`social.graphqls`):

```graphql
type PostMedia { url: String!  width: Int  height: Int }

type Post {
  # existing fields…
  mediaUrl: String          # kept: equals media[0].url, for old clients
  media:    [PostMedia!]!   # 0–4, in display order
}

input CreatePostInput {
  title:      String        # optional now, 0–200 chars
  content:    String!       # may be "" when media is non-empty
  mediaUrl:   String        # deprecated; still accepted
  media:      [PostMediaInput!]   # max 4
  categoryId: UUID!
}
input PostMediaInput { url: String!  width: Int  height: Int }
# UpdatePostInput gets the same optional `media` (null = unchanged, [] = clear).
```

`POST /media` (existing upload) response → `{ "id", "url", "width", "height" }`
(width/height read from the image; null if unreadable).

Validation: at least one of title / content / media must be non-empty; max 4
media; media URLs must come from this API's own media host.

### Market (W4, V41)

`GET /gamification/me` → existing shape **plus** `"xpBalance": 1240`.

`GET /market/items?slot=HAT|EYEWEAR` (slot optional)

```json
{
  "balance": 1240,
  "items": [
    {
      "id": "uuid",
      "slot": "HAT",
      "name": "Straw hat",
      "nameKm": "មួកចំបើង",
      "price": 300,
      "rarity": "COMMON",
      "assetKey": "hat_straw",
      "owned": false,
      "equipped": false,
      "locked": false,
      "lockReason": null,
      "availableUntil": null
    }
  ]
}
```

`POST /market/items/{id}/purchase`, header `Idempotency-Key: <uuid>` (required, 400 if missing)
→ `200 { "item": <item>, "balance": 940 }`. A repeat with the same key returns
the same 200. Errors (body `{ "code", "message" }`): `409 INSUFFICIENT_BALANCE`,
`409 ALREADY_OWNED`, `410 NOT_AVAILABLE`, `403 LOCKED`.

`GET /buddy/me` → existing shape **plus**
`"equipped": { "HAT": { "itemId": "uuid", "assetKey": "hat_straw" } }` and
`"balance": 940`.

`GET /buddy/me` and `PUT /buddy/me` also add `"chosen": true|false`. It's false only
for a buddy the server auto-created as the default crocodile. `buddy.chosen_at`
(V41) is set by a first-run guest pick or an explicit species change.
Existing rows are backfilled as chosen. The app shows the buddy picker once
after sign-in when `chosen` is false and there is no guest pick to send.

`PUT /buddy/me/equipped` body `{ "slot": "HAT", "itemId": "uuid" | null }` →
the updated buddy. 403 if the user doesn't own the item; 400 if the item's
slot doesn't match.

Public look on `PublicProfileResponse` and `LeaderboardEntryResponse`:
`"buddy": { "species": "capybara", "name": "Capy", "equipped": { "HAT": "hat_straw" } }`
(`null` when the user has no buddy row).

Seed items (V41):

| assetKey | slot | Name / Khmer | Price | Rarity |
|---|---|---|---|---|
| `hat_straw` | HAT | Straw hat / មួកចំបើង | 300 | COMMON |
| `hat_cap_red` | HAT | Red cap / មួកក្រហម | 250 | COMMON |
| `hat_graduation` | HAT | Graduation cap / មួកបញ្ចប់ការសិក្សា | 800 | RARE |
| `hat_krama` | HAT | Krama headwrap / ក្រមាពាក់ក្បាល | 500 | RARE |
| `hat_crown` | HAT | Little crown / មកុដតូច | 1500 | EPIC |
| `eye_round` | EYEWEAR | Round glasses / វ៉ែនតាមូល | 200 | COMMON |
| `eye_sun` | EYEWEAR | Sunglasses / វ៉ែនតាការពារពន្លឺ | 350 | COMMON |
| `eye_star` | EYEWEAR | Star glasses / វ៉ែនតាផ្កាយ | 700 | RARE |

(The Khmer names are drafts; have a Khmer speaker review them.)

## How to launch a task

From `RIKSA-FLUTTER`, per task (`$OUT` = a scratch folder per task):

```bash
codex exec -C "<repo>" -s workspace-write --worktree -o "$OUT/last.md" < docs/build-plan/next/prompts/<task>.md > "$OUT/log.txt" 2>&1
```

API tasks use `-C ../RIKSA`. Reviews use `-s read-only` and no `--worktree`.

After each worker: read `last.md`, diff the worktree against its start
commit, reject out-of-scope paths, run the checks above, then integrate.
