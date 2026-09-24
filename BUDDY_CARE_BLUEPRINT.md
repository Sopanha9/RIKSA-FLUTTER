# Buddy Care — Plan and Codex Build Blueprint

Status: planned, not built. Written 2026-09-24 on `feat/buddy-first-run`.
Depends on: `FIRST_RUN_BLUEPRINT.md` Steps 4b and 5 (buddy picker in Settings,
buddy scene in lessons). Those are already in the working tree.

## 0. The idea, and the verdict on it

**Ask:** make the buddy a core part of the app. The learner has one buddy.
Studying, reading a blog story and posting in a community earn points. The
goal is to keep the buddy going.

**Verdict:** worth building. It gives the buddy a reason to exist beyond
decoration, and it rewards the whole app (learn, read, share) instead of only
lessons. Three parts of the literal ask would hurt the product, so this plan
changes them:

| Literal ask | Problem | What this plan does instead |
|---|---|---|
| Buddy can die ("keep alive") | `PRODUCT.md` names *streak guilt* as an anti-reference. A Bac II student who misses 4 days during exam week comes back to a dead or sick pet. They quit, or feel worse. Finch and Tamagotchi-style death loops are the pattern the product rejects. | The buddy **never dies and is never sick or sad because you were away**. Its *energy* drains slowly. At low energy it **naps**. One lesson wakes it. The return greeting is warm (`returnedAfterBreak` → greeting). |
| Posting earns the same points as studying | This turns the community into a points farm with "hi" posts. It also changes the leaderboard if the points are XP. | Care points are a **separate meter, not XP**. XP and rank stay lesson-only, as `PRODUCT.md` says. Social actions give small, **daily-capped** care. A lesson is always worth the most. |
| Reading a blog = points | Views are recorded when the post is *fetched* (`blog_api.dart:64`, `BlogEngagementService.trackView`), so opening a post is not reading it. | A read counts only after the reader **reaches the end and spends ≥ 40 s** on the post. It is sent by an explicit `read-complete` call, capped at 2 per day. |

"Choose only one pet": this already holds. The learner has one buddy
(`MascotProfile`). Switching species in Settings **keeps the bond and energy**,
because they belong to the learner, not the animal. Nothing is lost by
switching, so nobody is punished for trying the other buddy.

**Competition note (memory: ACLEDA entry, no copied designs):** the reference
mockup was Finch ("adventure", "goals left today"). Do not reuse that wording
or layout. Riksa's version is framed around study: **"Today with {name}"**,
with a care list of study actions and an energy ring around the buddy. It
uses our existing pond/park scenes.

## 1. Mechanics (the spec Codex builds against)

### 1.1 Energy (0–100)

- Starts at 60 when the buddy is first chosen.
- **Decay:** −1 per 72 minutes, so a full buddy goes from 100 to 0 in 5 days.
  Decay is *computed*, never ticked by a job:
  `energy_now = clamp(stored_energy − floor(minutes_since(updated_at) / 72), 0, 100)`.
  Every write first settles the decay, then adds the gain, then stores the
  result with `updated_at = now`.
- **Floor behaviour:** 0 means asleep. There is no negative state, no
  sickness, no death and no loss of bond.

| Energy | Pose on Learn / Home (`MascotMood`) | Face (`MascotFace`) | Line |
|---|---|---|---|
| 70–100 | `happy` (one play), then `idle` | `happy` | "{name} is full of energy." |
| 35–69 | `idle` | `neutral` | "One lesson keeps {name} going." |
| 1–34 | `idle` with `sleepy` face chips | `sleepy` | "{name} is getting sleepy." |
| 0 | `sleep` | `sleepy` | "{name} is napping. A lesson wakes them up." |

`sad` and `crying` are **never** driven by energy.

### 1.2 Care actions (gains)

| Action | Source key | Energy | Bond | Daily cap | Where it is detected |
|---|---|---|---|---|---|
| Complete a lesson | `LESSON` | +35 | +10 | none (bond cap 5 lessons/day) | `LessonCompletedEvent` (backend) |
| Finish reading a blog story | `BLOG_READ` | +10 | +3 | 2 per day | new `POST /blog/{id}/read-complete` |
| Publish a community post | `POST` | +10 | +3 | 1 per day | `PostCreatedEvent` (backend) |
| Publish an approved blog story | `BLOG_PUBLISHED` | +20 | +8 | 1 per day | `BlogPostApprovedEvent` (backend) |

- Every gain is **idempotent** per `(user, source_key, source_id)`. This is
  the same rule `XpLedgerService.awardXp` uses, so a retried event or a
  re-read post never pays twice.
- Comments are left out of v1. There is no `CommentCreatedEvent` yet, and
  comments are the easiest thing to spam. Add them in v2 if needed.

### 1.3 Bond (the "score")

Bond is the long-term, never-decreasing score: the learner's history with
their buddy.

- `bond` is an integer. Its level is `bondLevel = 1 + floor(sqrt(bond / 15))`,
  so levels come quickly at first and then slow down.
- Level unlocks use **art we already have**. No new sprites are needed for v1:
  - Lv 2: the `treat` pose plays after a lesson.
  - Lv 3: the `love` pose plays when the buddy is tapped.
  - Lv 4: party scene variants (`pond_party_*`, `park_party_*`) on Learn.
  - Lv 5: the `trophy` pose on a new personal best week.
- Bond is **private**. It is not shown on the leaderboard or on public
  profiles in v1, so there is no comparing and no social pressure.

### 1.4 "Today with {name}" care list

This is a small card on the Learn landing, directly above the path. It holds
3 rows and resets at local midnight (Asia/Phnom_Penh on the server):

1. Finish a lesson (always first, always the biggest)
2. Read a story on the blog (0/1 shown; up to 2 count)
3. Share something with a community

A done row shows a check and the buddy's `happy` face. The card never shows a
red or "missed" state. Yesterday's list is simply gone.

### 1.5 Guests

Guests can learn without an account (FIRST_RUN Step 2), so the buddy works
for them too:

- Energy and bond are computed **on device** from lesson completions only.
  Guests cannot post, and blog reads are not counted for guests.
- The same pure Dart function (`BuddyCare.settle`, see §3) runs on both
  client and server rules, so the numbers match.
- On sign-up or sign-in the device state is sent once
  (`PUT /buddy/me` with `energy`, `bond`, `species`, `name`). The server
  **keeps the higher bond and the higher energy** and never lowers either.

## 2. Backend work (`../RIKSA`, Spring Boot)

The pattern matches the existing gamification module: listeners on
domain events and an idempotent ledger.

- **Migration `V34__buddy_care.sql`**:
  ```sql
  create table buddy (
    user_id     uuid primary key references users(id) on delete cascade,
    species     varchar(20) not null,
    name        varchar(16) not null,
    energy      smallint    not null default 60 check (energy between 0 and 100),
    bond        integer     not null default 0  check (bond >= 0),
    updated_at  timestamptz not null default now(),
    created_at  timestamptz not null default now()
  );
  create table buddy_care_event (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references users(id) on delete cascade,
    source_key  varchar(20) not null,
    source_id   uuid not null,
    care_day    date not null,
    energy_gain smallint not null,
    bond_gain   smallint not null,
    created_at  timestamptz not null default now(),
    unique (user_id, source_key, source_id)
  );
  create index on buddy_care_event (user_id, care_day);
  ```
  Check the `users` table name and the uuid default against earlier
  migrations before writing this.
- **Package `com.riksa.buddy`**:
  - `entity`: `Buddy`, `BuddyCareEvent`.
  - `repository`: `BuddyRepository`, with `findByIdForUpdate` using
    PESSIMISTIC_WRITE as in `UserGamificationRepository`.
  - `service/BuddyCareRules`: a pure class holding the constants from §1.1–1.3.
    It exposes `settle(energy, updatedAt, now)`, `gainFor(sourceKey)`,
    `dailyCap(sourceKey)` and `bondLevel(bond)`, and it is unit-tested.
  - `service/BuddyService`: `getOrCreate`, `rename/changeSpecies`,
    `mergeGuestState`, `recordCare(userId, sourceKey, sourceId)`, and
    `today(userId)`, which returns the care list. `recordCare` does the
    following:
    1. Lock the buddy row.
    2. Return early on a duplicate `(user, key, id)`.
    3. Count today's events for the key and return early at the cap.
    4. Settle decay, add the gain, clamp and save.
    5. Insert the event.
    If the learner has no buddy row yet, `recordCare` creates one with the
    default crocodile.
  - `listener/BuddyCareListener`: listens for `LessonCompletedEvent`,
    `PostCreatedEvent` and `BlogPostApprovedEvent`. Use
    `@Async("gamificationTaskExecutor")` and
    `@TransactionalEventListener(AFTER_COMMIT)`, as `XpLedgerListener` does.
    Catch and log failures: buddy care must never break a lesson completion.
  - `controller/BuddyController`, under `/api/v1/buddy` (match the existing
    base path):
    - `GET /me` returns `{species, name, energy (settled), bond, bondLevel, today: [{key, done, count, cap}]}`.
    - `PUT /me` takes `{species?, name?, guestEnergy?, guestBond?}`.
  - Blog: add `POST /blog/{id}/read-complete` (authenticated). It calls
    `buddyService.recordCare(user, BLOG_READ, blogId)`. It does **not** touch
    `viewCount`.
- **Security:** `/buddy/**` requires authentication. Do not add it to
  `SecurityConfig` `permitAll`.
- **Tests:** unit tests for `BuddyCareRules`, covering decay across 0, 71,
  72 and 7200 minutes, the clamp, and the bond levels. Service tests for
  idempotency, the daily cap, the Phnom Penh midnight boundary and the guest
  merge keeping the maximums.

## 3. Flutter work

Everything goes in `lib/features/mascot/`. Do **not** create a parallel
`buddy` feature.

- `domain/buddy_care.dart` (pure, no Flutter imports) mirrors
  `BuddyCareRules`:
  - `class BuddyCare { final int energy; final int bond; final DateTime updatedAt; ... }`
  - `BuddyCare settle(DateTime now)`
  - `BuddyCare gain(BuddyCareSource s, DateTime now)`
  - `int get bondLevel`
  - `BuddyVitality get vitality`, where `BuddyVitality` is one of
    `lively | steady | sleepy | napping`
  - `MascotMood moodFor(BuddyVitality)` and `MascotFace faceFor(BuddyVitality)`,
    following the table in §1.1. Never return `sad` or `crying`.
- `data/buddy_api.dart` wraps `getMe`, `updateMe` and `readComplete(blogId)`
  using the existing Dio client.
- `providers/buddy_care_provider.dart` is a Riverpod 3 `Notifier`:
  - Signed in: it loads `GET /buddy/me` and caches the result in
    SharedPreferences, so there is no blank state offline.
  - Guest: it loads and saves local `BuddyCare`, and adds a lesson gain when
    a lesson completes.
  - It settles the energy on each app resume
    (`AppLifecycleState.resumed`), not on a timer.
  - It exposes `recordLocalGain(source)` for an optimistic update, followed
    by a refetch.
  - On sign-in it calls `updateMe` once with the guest state, then clears
    the local guest keys.
- **Species and name move to the server.** `MascotNotifier.choose(...)`
  continues to write SharedPreferences and, when signed in, also calls
  `PUT /buddy/me`. On sign-in the server value wins for species and name.
- **UI**
  - `presentation/widgets/buddy_care_card.dart` is the "Today with {name}"
    card on the Learn landing (`lesson_catalog_screen.dart`), above the path:
    - The scene band uses `MascotScenes.asset`. At bond level ≥ 4 it uses the
      party scene.
    - The buddy is shown with `MascotView` in the mood for its vitality.
    - A thin energy ring or bar uses `saffron`. It is **not** a big number.
    - Below are the 3 care rows.
    - Tapping the buddy plays `love` (at level ≥ 3) or `happy`. A long press
      opens `/mascot-select`, which closes the guest gap from FIRST_RUN
      Step 4b.
    - Keep it compact: at most about 180 dp tall at 360 dp width.
  - Lesson completion (`learning_result_screens.dart`): the existing
    `lessonCompleted` earned moment adds one line, "+35 energy · {name} is
    full of energy". At bond level ≥ 2 it plays the `treat` pose. **Do not
    add** new confetti or counters (DESIGN.md: one earned moment, never
    delayed).
  - Blog detail: a `ScrollController` plus a stopwatch fires
    `readComplete` once when the reader reaches the bottom and at least
    40 s have passed. If they are signed in, a quiet snackbar shows
    "{name} enjoyed that story". Nothing happens for guests.
  - Compose post: after a successful publish, the existing `postPublished`
    reaction appears. The provider refetches, and there is no new UI.
- **l10n:** every string goes into both `app_en.arb` and `app_km.arb`. Leave
  Khmer as `TODO(km)` only if no speaker is available, and list those
  strings in the PR.
- **Do not touch:** `lib/core/widgets/riksa_bottom_navigation_bar.dart` and
  its goldens (a friend owns them); the leaderboard; XP; public profiles.

## 4. Build order for Codex

Each phase is one PR-sized prompt. Run them in order. Each prompt stands on
its own, so paste it as is.

### Phase A: Backend rules and storage

> In `../RIKSA` (Spring Boot), implement buddy care storage and rules per
> `RIKSA-FLUTTER/BUDDY_CARE_BLUEPRINT.md` §1 and §2:
> - migration `V34__buddy_care.sql`
> - `com.riksa.buddy` entity, repository, `BuddyCareRules`, and `BuddyService`
>   with `recordCare`, `getOrCreate`, `today` and `mergeGuestState`
> - unit and service tests
>
> Do not add listeners or controllers yet. Care points are NOT XP: do not
> call `XpLedgerService`. Mirror the locking and idempotency style of
> `gamification/service/XpLedgerService.java`. Run `./mvnw test` and report
> the results.

### Phase B: Backend wiring

> In `../RIKSA`:
> - Add `BuddyCareListener`, which handles `LessonCompletedEvent`,
>   `PostCreatedEvent` and `BlogPostApprovedEvent`. Use AFTER_COMMIT and
>   async on `gamificationTaskExecutor`, and catch and log failures.
> - Add `BuddyController` with `GET/PUT /buddy/me`, authenticated.
> - Add `POST /blog/{id}/read-complete`. It must not change `viewCount`.
>
> Follow `BUDDY_CARE_BLUEPRINT.md` §1.2 for the gains and caps. Add
> controller tests covering: auth required, the daily cap on a second post,
> and idempotent read-complete. Run `./mvnw test`.

### Phase C: Flutter domain and state

> In RIKSA-FLUTTER, add the following in `lib/features/mascot/`:
> - `domain/buddy_care.dart` (pure Dart, matching §1.1–1.3 exactly)
> - `data/buddy_api.dart`
> - `providers/buddy_care_provider.dart` (Riverpod 3 Notifier, following
>   §3: signed-in versus guest, settle on resume, one guest merge on
>   sign-in)
>
> Make `MascotNotifier.choose` also `PUT /buddy/me` when signed in. Add unit
> tests for `BuddyCare` that use the same decay and cap cases as the backend
> tests, and provider tests using a fake API. No UI changes in this phase.
> Run `flutter analyze` and `flutter test`.

### Phase D: Flutter UI

> In RIKSA-FLUTTER:
> - Build `BuddyCareCard`, following §3 UI, and place it at the top of the
>   Learn landing (`lesson_catalog_screen.dart`) above the path.
> - Add the energy line and the `treat` pose to the lesson completion earned
>   moment.
> - Add read-complete detection to blog detail.
> - Refetch after a community post is published.
> - Add en and km strings.
>
> Tests must use `MediaQuery.disableAnimations: true` in their harness, or
> `pumpAndSettle` hangs on `MascotView`. Precache scene images before
> goldens, following `test/visuals/lesson_experience_golden_test.dart`
> `_precacheImages`. Add goldens for the card at energy 90, 50, 20 and 0,
> in light and dark, at 360 dp. Do not edit the bottom navigation bar or its
> goldens. Run `flutter analyze` and `flutter test`. Two
> `social_feed_screen_golden_test` failures already exist and are unrelated.

## 5. Acceptance checklist

- [ ] A learner away for 10 days opens the app and sees the buddy napping,
      with a warm greeting. Nothing is dead, sick or crying, and there is no
      red "missed" state.
- [ ] One lesson moves energy from 0 to 35 and wakes the buddy.
- [ ] Five community posts in one day give energy once.
- [ ] Opening a blog post and leaving immediately gives nothing. Reading to
      the end over 40 s gives +10, once per post and at most twice a day.
- [ ] XP, rank and the leaderboard are unchanged by posts, reads and
      buddy care.
- [ ] Switching species in Settings keeps energy and bond.
- [ ] Guest progress survives sign-up, and the server never lowers it.
- [ ] Airplane mode: the card shows the cached state and there is no
      spinner wall.
- [ ] The card fits at 360 dp with a long Khmer name and a Khmer UI.
- [ ] `flutter analyze` is clean. `flutter test` passes except the 2 known
      social goldens. `./mvnw test` passes.

## 6. Open decisions for the team

1. **Is death really off the table?** This plan says yes, and it is the
   recommended choice. If the team insists on stakes, the most this plan
   would accept is a "runs away to visit a friend and comes back after one
   lesson" state. That is still not loss.
2. **Are the decay speed and gains right?** At 5 days from full to empty,
   one lesson every 2 days keeps the buddy awake. Tune this after a week of
   real use.
3. **Should bond ever be public?** v1 keeps it private.
4. **Cosmetics shop (hats, scenes) paid with bond?** No for v1. It is
   streak-freeze economics by another name, which `PRODUCT.md` rejects.
