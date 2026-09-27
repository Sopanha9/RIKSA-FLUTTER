# Task
Add a buddy item market to the API: a spendable XP balance, an item catalog, buying (safe against double taps and races), owning, equipping, and showing each user's buddy look publicly.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA, branch `feature/telegram-auth-options`. Spring Boot, JPA, Postgres, Flyway (next migration: **V41**), JUnit.

# Relevant files
- src/main/java/com/riksa/gamification/service/XpLedgerService.java — `awardXp(userId, amount, sourceType, sourceId)`: the single XP entry point; `findByIdForUpdate` pessimistic lock on `user_gamification`; idempotent per source; writes `xp_transaction` with `runningBalance = total_xp`; publishes `XpGainedEvent`.
- src/main/java/com/riksa/gamification/entity/UserGamification.java (`total_xp`, `@Version`), GamificationService.java (`getProfile` → `GamificationProfileResponse`), dto/GamificationProfileResponse.java, dto/LeaderboardEntryResponse.java.
- src/main/java/com/riksa/buddy/** — `Buddy` entity (table `buddy`: user_id PK, species, name, energy, bond), `BuddyService`, `BuddyController` (`GET/PUT /buddy/me`), dto/BuddyResponse.java, BuddyUpdateRequest.java.
- src/main/java/com/riksa/auth/dto/PublicProfileResponse.java (+ where it is built).
- src/main/java/com/riksa/quest/service/QuestService.java — the weekly chest (`POST /quests/chest/open`, `rewardItem` currently always null) from the previous wave.
- Migrations: V34__buddy_care.sql (buddy), V39 (weekly quests), V40 (post media).

# Decisions (fixed)
- **Spendable balance:** new `user_gamification.xp_balance`. `awardXp` adds `amount` to **both** `total_xp` and `xp_balance` in the same locked update. Purchases subtract **only** `xp_balance`. Rank/tiers/leaderboard/history stay on `total_xp`. Do **not** write negative `xp_transaction` rows (the XP history UI reads that table).
- Backfill: `xp_balance = total_xp` for existing rows.
- Slots in v1: `HAT`, `EYEWEAR`. Rarity: `COMMON|RARE|EPIC`. Art is bundled in the app; the API only returns `assetKey`.

# Contract (source of truth — implement exactly)
`GET /gamification/me` → existing shape **plus** `"xpBalance"`.

`GET /market/items?slot=HAT|EYEWEAR` (optional) →
`{ "balance": 1240, "items": [ { "id", "slot", "name", "nameKm", "price", "rarity", "assetKey", "owned", "equipped", "locked", "lockReason", "availableUntil" } ] }` — active items within their availability window, ordered by `sort_order`, then price.

`POST /market/items/{id}/purchase` with header `Idempotency-Key: <uuid>` (required → 400 if missing/invalid) → `200 { "item": <item>, "balance": 940 }`. Same key again → the same 200 (no second charge). Errors, body `{ "code", "message" }`: `409 INSUFFICIENT_BALANCE`, `409 ALREADY_OWNED`, `410 NOT_AVAILABLE`, `403 LOCKED`.

`GET /buddy/me` → existing shape **plus** `"equipped": { "HAT": { "itemId", "assetKey" } }` (only equipped slots) and `"balance"`.
`PUT /buddy/me/equipped` body `{ "slot": "HAT", "itemId": "uuid" | null }` → the updated buddy; 403 not owned; 400 slot mismatch/unknown slot.

Public look: `PublicProfileResponse.buddy` and `LeaderboardEntryResponse.buddy` = `{ "species", "name", "equipped": { "HAT": "hat_straw" } }` or `null` if no buddy row. Load it for a whole leaderboard page in one query (no N+1).

Buddy "chosen" flag (new): the server auto-creates a default crocodile ("Croco") the first time anything touches a user's buddy (`ensureAndLock` → `insertIfMissing`), so today it cannot tell "picked crocodile" from "never picked". Add `buddy.chosen_at TIMESTAMPTZ NULL`. Set it when: `mergeGuestState` runs with a non-null guest species (a first-run pick) **and** the row was just created or not yet chosen; `PUT /buddy/me` sets `species` explicitly. Default auto-creation leaves it null. Backfill: `chosen_at = created_at` for **all existing rows** (current users are never re-asked). `GET /buddy/me` and `PUT /buddy/me` responses add `"chosen": true|false`. `mergeGuestState` must still **never** change species/name of a buddy that is already chosen.

Chest (extends the previous wave): when a chest is opened, if the user does not own every active COMMON item, grant one random unowned COMMON item (`source = CHEST`, price_paid 0) and return it as `rewardItem { id, slot, assetKey, name, nameKm }`; otherwise `rewardItem = null`. XP reward unchanged. Opening stays idempotent.

Seed items (V41), Khmer names are drafts:

| assetKey | slot | name / nameKm | price | rarity |
|---|---|---|---|---|
| hat_straw | HAT | Straw hat / មួកចំបើង | 300 | COMMON |
| hat_cap_red | HAT | Red cap / មួកក្រហម | 250 | COMMON |
| hat_graduation | HAT | Graduation cap / មួកបញ្ចប់ការសិក្សា | 800 | RARE |
| hat_krama | HAT | Krama headwrap / ក្រមាពាក់ក្បាល | 500 | RARE |
| hat_crown | HAT | Little crown / មកុដតូច | 1500 | EPIC |
| eye_round | EYEWEAR | Round glasses / វ៉ែនតាមូល | 200 | COMMON |
| eye_sun | EYEWEAR | Sunglasses / វ៉ែនតាការពារពន្លឺ | 350 | COMMON |
| eye_star | EYEWEAR | Star glasses / វ៉ែនតាផ្កាយ | 700 | RARE |

# Do
1. `V41__buddy_market.sql`: `xp_balance BIGINT NOT NULL DEFAULT 0 CHECK (xp_balance >= 0)` + backfill; `market_item` (id, slot CHECK, name, name_km, price BIGINT ≥0, rarity CHECK, asset_key UNIQUE, species_mask NULL, min_tier NULL, available_from/until NULL, sort_order, active); `buddy_inventory` (user_id, item_id, acquired_at, source CHECK in PURCHASE|CHEST|ADMIN, price_paid BIGINT, idempotency_key UUID NULL, PK(user_id,item_id), UNIQUE(user_id, idempotency_key)); `buddy_equipped` (user_id, slot, item_id, PK(user_id, slot)); seed rows.
2. `XpLedgerService.awardXp`: also increment `xp_balance` (same lock, same save). Keep idempotency and events unchanged.
3. New package `com.riksa.market` (entity, repo, service, controller, DTOs, error codes). Purchase in ONE transaction: validate header → if a row with (user, idempotency_key) exists return it → lock `user_gamification` (`findByIdForUpdate`) → check availability/lock/ownership/balance → subtract `xp_balance` → insert inventory. Concurrent purchases of different items must never drive the balance negative.
4. Buddy: equipped map + balance + `chosen` on `GET /buddy/me`; `PUT /buddy/me/equipped`; unequip on null; `chosen_at` column (in V41) + backfill + the set-rules above. Tests: auto-created → `chosen:false`; guest merge on a new row → `true` with the guest species; guest merge on an already-chosen row → species/name unchanged; explicit species PUT → `true`; existing rows after migration → `true`.
5. `GamificationProfileResponse.xpBalance`; public look on public profile + leaderboard DTOs (batched).
6. Chest item drop in QuestService (only the reward part; don't change chest points/XP).
7. Tests: award adds to both totals; buy success; insufficient; already owned; not available (window); locked; missing Idempotency-Key; same key twice → one charge; two parallel purchases (different keys) that together exceed the balance → exactly one succeeds (use a real transactional test or a concurrency test with a latch); equip owned / not owned / wrong slot / unequip; leaderboard page loads looks in one query; chest grants an unowned COMMON once and null when all owned; `total_xp` unchanged by purchases; existing gamification/buddy/quest tests still pass.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not write negative rows into `xp_transaction` or change how rank/tier/leaderboard compute from `total_xp`.
- Do not modify files outside: src/main/java/com/riksa/market/** (new), src/main/java/com/riksa/gamification/** (XpLedgerService, UserGamification, GamificationService/profile DTO, LeaderboardEntryResponse + its builder), src/main/java/com/riksa/buddy/**, src/main/java/com/riksa/auth/dto/PublicProfileResponse.java + the service that builds it, src/main/java/com/riksa/quest/service/QuestService.java (chest reward only) + quest DTOs for `rewardItem`, src/main/java/com/riksa/common/constants/** (new endpoint constants), src/main/resources/db/migration/V41__buddy_market.sql, src/test/java/com/riksa/{market,gamification,buddy,quest,auth}/**.
- Do not use migration numbers other than V41.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `./mvnw test` (Docker skips noted separately), sample JSON for market list, purchase, buddy/me, and a leaderboard entry; and anything needing live Postgres to verify (especially the concurrency test).

# Risks
End with a "## Risks" section.
