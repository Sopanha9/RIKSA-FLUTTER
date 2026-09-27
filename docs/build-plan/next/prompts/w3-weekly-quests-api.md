# Task
Add weekly quests and a weekly chest to the quest API, next to the existing daily quests.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA, branch `feature/telegram-auth-options`. Spring Boot, JPA, Postgres, Flyway (next migration: **V39**), JUnit.

# Relevant files
- src/main/java/com/riksa/quest/service/QuestService.java — `DAY_ZONE = Asia/Phnom_Penh`; `getToday`, `claim` (locks with `findForUpdate`, awards via `xpLedgerService.awardXp(userId, xp, "QUEST", questId)`, all-claimed bonus `"QUEST_BONUS"` with a name-based UUID source id), `recordLesson/recordCorrectAnswer/recordSocialAction`, `ensureQuests` (lazy `insertIfAbsent`).
- src/main/java/com/riksa/quest/entity/{DailyQuest,QuestType}.java, repository/DailyQuestRepository.java (`incrementProgress`, `insertIfAbsent`, `findForUpdate`, `countByUserIdAndQuestDateAndClaimedFalse`).
- src/main/java/com/riksa/quest/listener/QuestProgressListener.java — `@Async("gamificationTaskExecutor")` + `@TransactionalEventListener(AFTER_COMMIT)` for `LessonCompletedEvent`, `ExerciseAnsweredEvent` (correct only), `SocialActionEvent` (actor only; no target id).
- src/main/java/com/riksa/quest/controller/QuestController.java, com/riksa/common/constants/QuestEndpoints.java.
- src/main/java/com/riksa/gamification/service/XpLedgerService.java — the single XP entry point; idempotent per (userId, sourceType, sourceId); pessimistic lock.
- src/main/resources/db/migration/V35__daily_quests.sql — daily table shape to mirror.
- Existing quest tests under src/test/java/com/riksa/quest/** — follow their style (clock injection).

# Contract (source of truth — implement exactly)
All JSON, Bearer JWT, base `/api/v1`. Week = Monday 00:00 → next Monday 00:00 in `Asia/Phnom_Penh`.

`GET /quests/today` → existing response **plus** `"resetsAt"` (next local midnight, ISO-8601 with offset).

`GET /quests/week`:
```json
{ "weekStart": "2026-09-28", "resetsAt": "2026-10-05T00:00:00+07:00",
  "quests": [ { "id": "uuid", "type": "WEEKLY_LESSONS", "title": "Finish 7 lessons", "titleKm": "បញ្ចប់មេរៀន 7",
                "target": 7, "progress": 3, "xpReward": 100, "completed": false, "claimed": false } ],
  "chest": { "id": "uuid", "points": 9, "target": 15, "maxPoints": 21, "opened": false, "xpReward": 50, "rewardItem": null } }
```
Weekly types, created lazily (4 per user per week):

| Type | Target | XP | Progress |
|---|---|---|---|
| `WEEKLY_LESSONS` | 7 | 100 | +1 per completed lesson |
| `WEEKLY_CORRECT_ANSWERS` | 30 | 60 | +1 per correct answer |
| `WEEKLY_ACTIVE_DAYS` | 5 | 80 | number of distinct local days this week with ≥1 completed lesson |
| `WEEKLY_SOCIAL` | 5 | 40 | +1 per social action (same event as the daily social quest) |

Suggested Khmer titles (drafts): "បញ្ចប់មេរៀន 7", "ឆ្លើយត្រូវ 30", "រៀន 5 ថ្ងៃក្នុងសប្តាហ៍", "ចូលរួមសហគមន៍ 5 ដង".

`POST /quests/{id}/claim` — accepts daily **and** weekly quest ids; returns the quest in the same shape; 404 unknown/not yours/not current period; 409 not completed or already claimed. Weekly claims: `awardXp(userId, xp, "WEEKLY_QUEST", questId)`. Daily behavior unchanged.

Chest: `points` = count of **daily** quests claimed with `quest_date` in the current week (cap 21). `POST /quests/chest/open` → the chest; 409 if `points < 15` or already opened; awards `awardXp(userId, 50, "QUEST_CHEST", chestId)`; `rewardItem` is always `null` in this task (a later task adds an item drop).

# Do
1. `V39__weekly_quests.sql`: `weekly_quest` (id, user_id FK users ON DELETE CASCADE, week_start DATE, type VARCHAR(32) CHECK in the 4 types, target, progress CHECK 0..target, xp_reward, claimed, claimed_at, created_at, UNIQUE(user_id, week_start, type), index on (user_id, week_start)) and `quest_chest` (id, user_id, week_start, opened_at nullable, created_at, UNIQUE(user_id, week_start)).
2. Entities, repositories (mirror the daily ones: `insertIfAbsent`, atomic capped `incrementProgress`, `findForUpdate`), `WeeklyQuestType` enum with title/titleKm/target/xp.
3. Service: `getWeek`, weekly progress in the existing `record*` methods (same transaction pattern; keep daily logic unchanged), active-days computed idempotently (set progress = distinct days, never double-count a day), claim routing (daily first, then weekly), chest points/open with row lock. Put the week helpers (`weekStart(date)`, `resetsAt`) in one place and reuse `DAY_ZONE`.
4. Controller + `QuestEndpoints`: `GET /quests/week`, `POST /quests/chest/open`; add `resetsAt` to today's DTO.
5. Tests (clock-controlled): lazy creation; week boundary Sunday 23:59 vs Monday 00:00 Phnom Penh; each progress source; active days counts a day once; claim weekly awards `WEEKLY_QUEST` once (repeat → 409); chest points from claimed dailies; open at 15 awards once; open twice → 409; open below target → 409; daily tests still pass; controller tests for both endpoints incl. 401 without JWT.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not change `SocialActionEvent` or anything under com/riksa/social/** (another worker owns social this wave).
- Do not change XpLedgerService's behavior.
- Do not modify files outside: src/main/java/com/riksa/quest/**, src/main/java/com/riksa/common/constants/QuestEndpoints.java, src/main/resources/db/migration/V39__weekly_quests.sql, src/test/java/com/riksa/quest/**.
- Do not use migration numbers other than V39.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `./mvnw test` (note Docker-dependent skips separately), sample JSON from a test for both endpoints, and anything needing a live Postgres to verify.

# Risks
End with a "## Risks" section.
