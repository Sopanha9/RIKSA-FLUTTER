# Task
Wire the new moderation engine into blog posts in the RIKSA API. Remove the STEM-only topic gate, publish clean posts instantly, hold borderline ones for review, and add the missing owner edit/delete endpoints.

# Repo
This directory (`RIKSA` API), branch `feature/content-moderation`, which already contains `com.riksa.moderation` from Wave 1. Spring Boot 3, Java 21, Lombok, Postgres, Flyway.

# Relevant files
- `src/main/java/com/riksa/moderation/**`: `ContentModerationService.assess(ModerationInput, Predicate<String> duplicateCheck)`, `requireNotBlocked`, `normalizeForDuplicate`, and `ContentBlockedException` / `RateLimitedException`, already mapped to 422 / 429. Read it first; do not modify it.
- `src/main/java/com/riksa/blog/service/BlogService.java`: `createPost` currently calls `BadWordFilter` + `ContentFilterService` and saves `PENDING`.
- `src/main/java/com/riksa/blog/service/BlogModerationService.java`: `approve()` sets `APPROVED` and publishes `BlogApprovedEvent` + `BlogPostApprovedEvent`. Those events drive XP, buddy care (`BuddyCareListener`) and achievements (`SocialAchievementListener`).
- `src/main/java/com/riksa/blog/controller/BlogController.java`, `src/main/java/com/riksa/common/constants/BlogEndpoints.java`, `blog/dto/*`, `blog/entity/BlogPost.java`, `blog/repository/BlogPostRepository.java`.
- `src/main/java/com/riksa/blog/service/ContentFilterService.java` and `blog/util/BadWordFilter.java` with their tests: to be deleted.
- User creation time: find the user entity/repository (e.g. `auth`/`user` package) for `createdAt`.
- The app's calls (source of truth for the contract): `POST /api/v1/blog`, `PUT /api/v1/blog/{id}` (same body as create), `DELETE /api/v1/blog/{id}`, all returning the existing `BlogPostResponse` (DELETE → 204).

# Decisions (already made)
- D1: the STEM topic gate is removed entirely. Delete `ContentFilterService` + `ContentFilterServiceTest`. Delete `BadWordFilter` + `BadWordFilterTest` (the engine replaces it). Update `BlogServiceTest`.
- D2: ALLOW → the post is published at once through **one shared method** in `BlogModerationService` (e.g. `publishApproved(post, UUID moderatorId)`) that `approve()` also uses. It sets `APPROVED`, and **on the first approval only** sets `first_approved_at` and publishes both events. `moderatorId = null` means system.
- D3: REVIEW → saved as `PENDING` (admin queue unchanged).
- D4: BLOCK → `requireNotBlocked` throws before anything is saved.
- D7: owner `PUT /blog/{id}`: only the author may edit (403 otherwise; use the codebase's existing forbidden exception pattern). Re-assess. ALLOW → `APPROVED`, but events fire only if `first_approved_at` was null. REVIEW → `PENDING`. BLOCK → 422 with the post unchanged. A `REJECTED` post edited to ALLOW becomes `APPROVED` (first approval if never approved). Owner `DELETE /blog/{id}` → 204; admins keep their own paths.
- D8: > 3 blog posts by one author in 10 minutes → throw `RateLimitedException` (429) before assessing.
- Duplicate check: add `normalized_hash` (sha-256 of `normalizeForDuplicate(title + " " + content)`) and a repository query "same author + same hash + created in last 24 h, excluding this post".

# Migration
`src/main/resources/db/migration/V42__blog_moderation.sql` (the number is fixed):
- `blog_post`: add `first_approved_at timestamptz null`, `normalized_hash varchar(64) null`, `moderation_score int null`, `moderation_reasons varchar(500) null` (comma-separated codes).
- Backfill `first_approved_at = coalesce(updated_at, created_at)` where status is approved. Check the real table and enum names in earlier migrations first.
- Index on `(author_id, normalized_hash, created_at)`.

# Do
1. Implement the above. Store `moderation_score` / `moderation_reasons` on every save so admins can see why a post was held (add them to the admin DTO only if an admin blog DTO exists and the change is additive).
2. Keep `BlogPostResponse` backwards compatible; additive fields only.
3. Tests:
   - create with ALLOW publishes and fires both events exactly once;
   - REVIEW is saved as PENDING with no events;
   - BLOCK saves nothing;
   - a non-STEM question ("How do I stay motivated before exams?") publishes;
   - editing an approved post fires no events;
   - editing into REVIEW goes back to PENDING;
   - non-owner PUT/DELETE is forbidden;
   - DELETE works;
   - the rate limit triggers on the 4th post;
   - moderator `approve()` still works and doesn't double-fire after an auto-approval.
   Update `BlogControllerBuddyCareTest` if its assumptions change.
4. Run `./mvnw test` and report the real result.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify `src/main/java/com/riksa/moderation/**`, `GlobalExceptionHandler`, `GraphQlExceptionResolver`, or anything under `social/**`.
- Do not modify files outside `src/main/java/com/riksa/blog/**`, `src/main/java/com/riksa/common/constants/BlogEndpoints.java`, `src/main/java/com/riksa/admin/**` (only additive DTO/response fields for moderation info), `src/main/resources/db/migration/V42__blog_moderation.sql`, and `src/test/java/com/riksa/blog/**`.
- Do not add dependencies.

# Deliverable
Changed files, the endpoint contract as implemented (status codes and bodies), test list with real `./mvnw test` output.

# Risks
End with a "## Risks" section.
