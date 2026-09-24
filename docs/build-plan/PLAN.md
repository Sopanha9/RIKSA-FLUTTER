# RIKSA build plan — Codex orchestration

**Goal:** turn six separate features into one daily loop.

> Buddy gives today's tasks → learner does a lesson (XP) → streak grows,
> province climbs → friends see it and react → resources shared on lessons.

Repos:

| Repo | Path | Stack | Branch |
|---|---|---|---|
| App | `RIKSA-FLUTTER` | Flutter, Riverpod, go_router, Dio | `feat/buddy-first-run` |
| API | `../RIKSA` | Spring Boot, Postgres, Flyway, GraphQL (social) | `feature/telegram-auth-options` |

## Ground rules for every worker

1. Codex runs with `-s workspace-write --worktree`. Never the bypass flag.
2. A worktree starts from the **last commit**. Commit the baseline in both
   repos before any wave (see Wave 0).
3. One writer per file. Each task below owns an explicit path list; anything
   outside it is rejected at review.
4. **Do not touch the bottom navigation bar.** A teammate is redesigning it.
   The floating buddy is layered in the app shell *above* page content; it does
   not edit the nav widget.
5. Every user-facing string goes in `lib/l10n/app_en.arb` and `app_km.arb`
   (Khmer is the first-run default). Regenerate with `flutter gen-l10n`.
6. Respect reduced motion (`MediaQuery.disableAnimationsOf` / `RiksaMotion`).
7. Workers do not commit. The orchestrator reviews the diff, runs the checks,
   then integrates.

Checks the orchestrator runs after every task:

```bash
flutter analyze && flutter test
```
```bash
./mvnw test
```

## Wave 0 — baseline (you)

- [x] Buddy picker and province step back in first run
      (Get started → language → buddy → subject → province → start).
- [x] Fixed: the chosen province was wiped by `completeOnboarding()` before
      sign-in could send it to the profile.
- [x] Commit the Flutter working tree (it holds all recent redesign work).
- [x] Commit the backend working tree.
- [x] Known red: the social post-detail goldens differed 0.03% after the
      social layout change. They were regenerated against the current redesign
      and now pass.

Baseline checks (2026-09-24): Flutter analysis and the full 475-test suite pass.
The API compiles with Java 21; its full test run has 4 pre-existing failures in
`ExerciseAttemptServiceTest` and `LessonServiceTest`, and 5 Docker-dependent
tests skip because Docker is unavailable. In Wave 1, the 7 quest-specific API
tests pass; the same 4 baseline API failures remain. Keep these separate from
wave results.

## Waves (max 3 concurrent workers)

| Wave | Task | Run in (`-C`) | Prompt | Migration |
|---|---|---|---|---|
| 1 | Notifications that actually fire | App | `prompts/w1-notifications.md` | — |
| 1 | Daily quests API | API | `prompts/w1-quests-api.md` | V35 |
| 1 | Floating buddy head + quest sheet | App | `prompts/w1-floating-buddy.md` | — |
| 2 | Lesson resources API | API | `prompts/w2-resources-api.md` | V36 |
| 2 | Lesson resources section | App | `prompts/w2-resources-ui.md` | — |
| 2 | Milestone posts — API half | API | `prompts/w2-social-milestones.md` | V37 |
| 2 | Milestone posts — app half | App | `prompts/w2-social-milestones.md` | — |
| 3 | Guest answer check — API half | API | `prompts/w3-guest-check-lesson-lite.md` | — |
| 3 | Guest check + one-tap finish — app half | App | `prompts/w3-guest-check-lesson-lite.md` | — |
| 4 | Computer Skills starter subject | API | `prompts/w3-computer-skills-seed.md` | V38 |
| 4 | Read-only review | App | `prompts/w3-review.md` (`-s read-only`, no worktree) | — |
| 4 | Read-only review | API | `prompts/w3-review.md` (`-s read-only`, no worktree) | — |

App tasks build against the contracts below with a fake API in tests, so they
run in the same wave as their API half. Integrate a whole wave, run the
checks, commit, then start the next wave from that commit.

**Shared files, merged by hand:** `lib/l10n/app_en.arb` and `app_km.arb`
are the only files two workers in one wave may both touch. Each task uses its
own key prefix (`reminder…`, `quest…`/`buddyHead…`, `resource…`,
`milestone…`, `guest…`). Merge the keys, then run `flutter gen-l10n` once.
`lesson_experience_screen.dart` is touched in waves 1, 2 and 3, never twice in
one wave.

**Backlog (after the competition):** follow graph, user-built roadmaps,
server push notifications (FCM).

## Integration checklist

- [x] Wave 1 — local streak reminders, daily quests, and floating buddy
      integrated in both repos; Flutter analysis and all 475 tests pass; all 7
      quest API tests pass. API full suite retains the 4 baseline failures and
      5 Docker-dependent skips recorded above.
- [x] Wave 2 — lesson resources and milestone posts, app and API integrated.
      `flutter analyze` is clean and all 488 Flutter tests pass. The focused API
      suite passes all 48 tests; the full API suite runs 412 tests with the same
      4 baseline failures and 5 Docker-dependent skips recorded above. Commit
      checkpoints are recorded in the Wave 2 note below.
- [x] Wave 3 — guest answer check and one-tap finish integrated. The milestone
      app half was already integrated with Wave 2 (`7d25542`). App analysis is
      clean and all 492 Flutter tests pass; all 10 focused API tests pass.
- [x] Wave 4 — Computer Skills starter subject seeded, catalog visibility
      fixed, and app/API read-only review findings resolved. Final app and API
      checks and commits are recorded below.

Wave 2 checkpoints (2026-09-24): Flutter `7d25542` and API `4e5a426`.
Flutter analysis is clean and all 488 tests pass. The focused API suite passes
all 48 tests; the full suite has 4 pre-existing learning-service failures and
5 Docker-dependent skips (412 tests total).

Wave 3 checkpoints (2026-09-24): API `10148ec` and Flutter `c6513af`. Guest
lesson checks are rate-limited and do not persist attempts or award XP. The
answer flow hides explanations until a correct response. Flutter analysis is
clean and all 492 tests pass; the focused API suite passes all 10 tests. This
API wave also resolves the four learning-service failures recorded at baseline.

Wave 4 checkpoints (2026-09-24): API `faf526c` and Flutter `8925ee4`. The API
seeds the bilingual Computer Skills category, Digital basics unit, five lessons,
and fifteen multiple-choice exercises. The app includes that category in the
learning catalog, and buddy care remains usable when local preference storage
fails. Flutter analysis is clean and all 492 tests pass. The full API suite
passes all 417 tests with 5 Docker-dependent skips.

The migration's documented smoke check is to request
`GET /api/v1/lessons/roadmap?categoryId=c3800000-0000-0000-0000-000000000001`,
confirm the Digital basics unit has five lessons, then request
`GET /api/v1/lessons/{lessonId}` for each and confirm each lesson has bilingual
descriptions and three `MULTIPLE_CHOICE` exercises. The migration could not be
applied to a live PostgreSQL instance in this environment because Docker was
unavailable. The only regenerated visual baseline is
`test/visuals/goldens/lesson_reflection_en_light.png`, reflecting the optional,
collapsed reflection step.

## API contracts (source of truth)

All JSON, Bearer JWT, base `/api/v1`. Day boundaries use `Asia/Phnom_Penh`.

### Daily quests

`GET /quests/today`

```json
{
  "date": "2026-09-24",
  "quests": [
    {
      "id": "uuid",
      "type": "COMPLETE_LESSON",
      "title": "Finish 1 lesson",
      "titleKm": "បញ្ចប់មេរៀន 1",
      "target": 1,
      "progress": 0,
      "xpReward": 20,
      "completed": false,
      "claimed": false
    }
  ],
  "allClaimedBonusXp": 30
}
```

Types (three per day, generated lazily on first request):
`COMPLETE_LESSON` (1, 20 XP), `CORRECT_ANSWERS` (3, 15 XP),
`SOCIAL_ACTION` (1 reaction or comment, 10 XP).

`POST /quests/{id}/claim` → the updated quest. 409 if not completed or already
claimed. Awards XP through the existing XP transaction path with
`sourceType = "QUEST"`. Claiming the last quest also awards the bonus
(`sourceType = "QUEST_BONUS"`).

### Lesson resources

`GET /learning/lessons/{lessonId}/resources?cursor=&limit=20` →
`CursorPage<Resource>` (`edges`, `hasNextPage`, `endCursor`), ordered by
`saveCount desc, createdAt desc`.

`Resource`:

```json
{
  "id": "uuid",
  "lessonId": "uuid",
  "title": "Past paper 2023 — Chemistry",
  "url": "https://…",
  "kind": "LINK",
  "author": { "id": "uuid", "displayName": "Dara", "avatarUrl": null },
  "saveCount": 4,
  "savedByMe": false,
  "createdAt": "2026-09-24T10:00:00Z"
}
```

`kind`: `LINK | PDF | VIDEO`. `POST /learning/lessons/{lessonId}/resources`
body `{ "title", "url", "kind" }` — `http`/`https` only, title 3–120 chars,
max 10 posts per user per day (429). `POST /resources/{id}/save` and
`DELETE /resources/{id}/save` → the updated resource. First save by a
different user gives the author 5 XP (`sourceType = "RESOURCE_SAVED"`), once
per saver. Reporting reuses the existing report flow.

### Milestone posts (GraphQL)

`Post.kind: PostKind!` with `enum PostKind { USER MILESTONE }` and
`Post.milestone: Milestone` (`type`, `title`, `titleKm`, `value`). Created
server-side for: streak milestones (existing `StreakUpdatedEvent`), rank-up
(`RankChangedEvent`), finishing the last lesson of a roadmap unit. Never for
single lessons (spam). Users can turn it off
(`UpdateProfileRequest.shareMilestones`, default `true`).

## How to launch a wave

From `RIKSA-FLUTTER`, per task (`$OUT` = a scratch folder per task):

```bash
codex exec -C "<repo>" -s workspace-write --worktree -o "$OUT/last.md" < docs/build-plan/prompts/<task>.md > "$OUT/log.txt" 2>&1
```

After each worker: read `last.md`, diff the worktree against its start
commit, reject out-of-scope paths, run the checks above, then integrate.
