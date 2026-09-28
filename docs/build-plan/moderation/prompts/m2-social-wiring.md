# Task
Screen community posts and comments with the new moderation engine in the RIKSA API. Block clearly bad content and rate-limit comment floods. Posts and comments otherwise publish as today.

# Repo
This directory (`RIKSA` API), branch `feature/content-moderation`, which already contains `com.riksa.moderation` from Wave 1. Spring Boot 3, Java 21, Spring GraphQL.

# Relevant files
- `src/main/java/com/riksa/moderation/**`: `ContentModerationService.assess(ModerationInput, Predicate<String> duplicateCheck)`, `requireNotBlocked`, `normalizeForDuplicate`, `ContentBlockedException` and `RateLimitedException`. GraphQL errors for both are already mapped (`extensions.code` = `CONTENT_BLOCKED` / `RATE_LIMITED`). Read it first; do not modify it.
- `src/main/java/com/riksa/social/service/PostService.java`: `createPost(...)` and `updatePost(...)`.
- `src/main/java/com/riksa/social/service/CommentService.java`: `createComment(...)` and `updateComment(...)`.
- `src/main/java/com/riksa/social/repository/*`: for the duplicate and rate-limit queries.
- User creation time: find the user entity/repository for `createdAt`.

# Decisions (already made)
- D5: **block only.** The community has no review state. BLOCK → `requireNotBlocked` throws before saving. REVIEW and ALLOW both publish normally. Log REVIEW at INFO with post/comment id, score and reason codes, but **never the text**.
- Title + content are assessed for posts; content for comments. Surface = `POST` / `COMMENT`.
- Duplicate check: same author and same normalized content in the last 24 h, compared in Java against that author's recent rows (at most the last 50). **No migration** in this task.
- D8: > 10 comments by one author in 10 minutes → `RateLimitedException` before assessing. Posts: > 5 in 10 minutes.
- Edits are re-screened with the same rules (BLOCK → throw, post/comment unchanged).
- Media-only posts (empty title and content) are ALLOW.

# Do
1. Inject `ContentModerationService` into `PostService` and `CommentService` and apply the rules above at the start of create/update, after the existing permission checks and before any save or event.
2. Tests in `src/test/java/com/riksa/social/**`:
   - a severe term blocks create and update of posts and comments, with no save and no event;
   - a REVIEW-level post still saves;
   - a comment flood triggers `RateLimitedException` on the 11th;
   - a media-only post passes;
   - one GraphQL-level test (if the project already has GraphQL tests to copy) showing `extensions.code == "CONTENT_BLOCKED"`.
   Keep all existing social tests green; update mocks where constructors change.
3. Run `./mvnw test` and report the real result.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify `src/main/java/com/riksa/moderation/**`, the exception handlers, anything under `blog/**`, or any migration.
- Do not modify files outside `src/main/java/com/riksa/social/**` and `src/test/java/com/riksa/social/**`.
- Do not add dependencies.

# Deliverable
Changed files, where exactly the check runs in each method, test list with real `./mvnw test` output.

# Risks
End with a "## Risks" section.
