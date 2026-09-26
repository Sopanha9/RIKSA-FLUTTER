# Task
Add lesson resources to the RIKSA backend: learners share links/PDFs/videos on a lesson, others save them, authors earn XP.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA, Spring Boot + Postgres + Flyway, Testcontainers. Read AGENTS.md first and follow its conventions (CursorPage, *Endpoints constants, DTO style).

# Relevant files
- src/main/java/com/riksa/learning/controller/LessonController.java — lesson routes live under /api/v1/learning
- src/main/java/com/riksa/gamification/service/XpLedgerService.java — `awardXp(userId, amount, sourceType, sourceId)`
- src/main/java/com/riksa/report/ — existing report flow; make resources reportable through it
- src/main/java/com/riksa/auth/security/SecurityConfig.java — GET must be public (guests can browse lessons)
- src/main/resources/db/migration/ — use V36 (V35 is taken by daily quests)

# Context
Resources belong INSIDE a lesson, not in a separate feed. Fixed contract (the app is built against it in parallel):

GET /api/v1/learning/lessons/{lessonId}/resources?cursor=&limit=20 → CursorPage<Resource> (`edges`, `hasNextPage`, `endCursor`), ordered by saveCount desc, createdAt desc. Public; `savedByMe` is false for guests.

Resource: `{ "id", "lessonId", "title", "url", "kind": "LINK|PDF|VIDEO", "author": { "id", "displayName", "avatarUrl" }, "saveCount", "savedByMe", "createdAt" }`

POST /api/v1/learning/lessons/{lessonId}/resources body `{ "title", "url", "kind" }` (auth) → Resource. Validation: http/https only, title 3–120 chars, lesson must exist, max 10 per user per day → 429.
POST /api/v1/resources/{id}/save and DELETE /api/v1/resources/{id}/save (auth) → Resource. Idempotent.
XP: the first save by a user other than the author gives the author 5 XP, sourceType "RESOURCE_SAVED", at most once per (resource, saver) even after unsave/resave.
Deleting: the author (or an admin) can DELETE /api/v1/resources/{id}.

# Do
1. New package com.riksa.resource with entity, repos, service, controller, DTOs, ResourceEndpoints.
2. V36 migration: `lesson_resource`, `lesson_resource_save` (unique resource_id+user_id), a table or column guaranteeing the once-per-saver XP rule.
3. Hook resources into the report flow as a new target type if the report module supports types; otherwise note it under Risks.
4. Tests for every rule above, including guest GET and the XP-once rule.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside: src/main/java/com/riksa/resource/**, src/main/resources/db/migration/V36__*.sql, src/test/java/com/riksa/resource/**, SecurityConfig.java (public GET rule only), and minimal additions in src/main/java/com/riksa/report/**.
- Do not change existing endpoint paths or response shapes.
- Do not add dependencies without stating so.

# Deliverable
Changed files, real `./mvnw test` output (say plainly if Testcontainers could not run), curl examples.

# Risks
End with a "## Risks" section.
