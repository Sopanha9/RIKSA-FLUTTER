# Task
Add a daily quests API to the RIKSA backend: three quests per learner per day, progress from domain events, claim for XP.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA, Spring Boot + Postgres + Flyway, Testcontainers for tests. Read AGENTS.md first and follow its conventions (cursor pages, one *Endpoints constants class per module, DTO style).

# Relevant files
- src/main/java/com/riksa/gamification/service/XpLedgerService.java — `awardXp(userId, amount, sourceType, sourceId)`; use it for every XP award
- src/main/java/com/riksa/learning/event/LessonCompletedEvent.java — published by LessonCompletionService
- src/main/java/com/riksa/learning/service/ — exercise answers are checked here; there is NO answer event yet
- src/main/java/com/riksa/social/service/ReactionService.java — publishes ReactionReceivedEvent(postId, post AUTHOR), not the reacting user
- src/main/java/com/riksa/social/service/CommentService.java
- src/main/java/com/riksa/common/constants/
- src/main/resources/db/migration/ — latest is V34; use V35

# Context
The app shows these quests in a floating buddy sheet and is being built in parallel against this fixed contract:

GET /api/v1/quests/today →
`{ "date": "2026-09-24", "quests": [ { "id": uuid, "type": "COMPLETE_LESSON|CORRECT_ANSWERS|SOCIAL_ACTION", "title": str, "titleKm": str, "target": int, "progress": int, "xpReward": int, "completed": bool, "claimed": bool } ], "allClaimedBonusXp": 30 }`

POST /api/v1/quests/{id}/claim → the updated quest. 409 when not completed or already claimed; 404 when not the caller's.

Rules: day boundary is Asia/Phnom_Penh. Quests are created lazily on the first GET of the day, idempotent under concurrent requests (unique (user_id, quest_date, type)). Defaults: COMPLETE_LESSON 1 → 20 XP, CORRECT_ANSWERS 3 → 15 XP, SOCIAL_ACTION 1 → 10 XP. XP via XpLedgerService with sourceType "QUEST"; claiming the last of the three also awards 30 XP as "QUEST_BONUS". Progress never exceeds target. Events before the first GET of the day still count (create the day's quests on the event if missing).

# Do
1. New package com.riksa.quest (entity, repository, service, controller, DTOs, QuestEndpoints).
2. V35 migration for `daily_quest`.
3. Publish a new `ExerciseAnsweredEvent(userId, exerciseId, correct)` where answers are checked; count correct ones.
4. Publish a new `SocialActionEvent(actorUserId)` from reaction and comment creation (do not change ReactionReceivedEvent). Ignore actions on your own posts.
5. Listen with `@TransactionalEventListener(phase = AFTER_COMMIT)`.
6. Tests: lazy generation, idempotency, progress per event type, claim XP + bonus, 409/404 cases, day rollover in Asia/Phnom_Penh.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside: src/main/java/com/riksa/quest/**, src/main/resources/db/migration/V35__*.sql, src/test/java/com/riksa/quest/**, the new event classes, and the minimal publish lines in the learning answer service, ReactionService and CommentService.
- Do not change existing endpoint paths or response shapes.
- Do not add dependencies without stating so.

# Deliverable
Changed files, real `./mvnw test` output (say plainly if Docker/Testcontainers could not run in your sandbox), and a curl example for both endpoints.

# Risks
End with a "## Risks" section.
