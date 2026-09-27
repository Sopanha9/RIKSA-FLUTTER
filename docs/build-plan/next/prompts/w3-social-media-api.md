# Task
Let community posts carry up to 4 photos with their width/height, and make post titles optional.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA, branch `feature/telegram-auth-options`. Spring Boot, JPA, Postgres, Flyway (next migration: **V40**), Spring GraphQL for social, JUnit.

# Relevant files
- src/main/resources/graphql/social.graphqls — `type Post` (has `mediaUrl: String`), `input CreatePostInput { title: String!, content: String!, mediaUrl: String, categoryId: UUID! }`, `UpdatePostInput` ("null leaves a field unchanged; an empty mediaUrl clears the image").
- src/main/java/com/riksa/social/** — post entity/service/resolvers/DTOs; `controller/PostController.java`.
- src/main/java/com/riksa/media/controller/MediaController.java, media/dto/MediaUploadResponse.java (`record MediaUploadResponse(String id, String url)`).
- Admin moderation reads posts too: src/main/java/com/riksa/admin/service/SocialModerationService.java, admin DTOs — keep them compiling and correct.
- Existing social + media tests under src/test/java/com/riksa/{social,media}/**.

# Contract (source of truth — implement exactly)
```graphql
type PostMedia { url: String!  width: Int  height: Int }
type Post {
  # existing fields unchanged…
  mediaUrl: String          # kept for old clients: equals media[0].url, null if none
  media:    [PostMedia!]!   # 0–4, display order
}
input PostMediaInput { url: String!  width: Int  height: Int }
input CreatePostInput {
  title:      String        # optional, 0–200 chars (null → "")
  content:    String!       # may be "" when media is non-empty
  mediaUrl:   String        # deprecated, still accepted: treated as media=[{url}]
  media:      [PostMediaInput!]   # max 4; if both given, media wins
  categoryId: UUID!
}
# UpdatePostInput: add `media: [PostMediaInput!]` — null = unchanged, [] = clear all.
# `title` becomes optional there too (null = unchanged).
```
`POST /media` response → `{ "id", "url", "width", "height" }` — width/height read from the uploaded image (null if unreadable). No change to size limits.

Validation: at least one of (trimmed title, trimmed content, media) is non-empty; ≤4 media; every media URL must be one this API issued (same host/prefix as `MediaUploadResponse.url`); width/height, when given, 1..10000. Errors use the existing GraphQL error style.

# Do
1. `V40__post_media.sql`: `post_media (post_id FK posts ON DELETE CASCADE, position SMALLINT 0..3, url, width INT NULL, height INT NULL, PRIMARY KEY(post_id, position))`; backfill one row per existing post with a non-empty `media_url`; relax the title NOT NULL/length constraint if the schema has one (keep a 200-char max). Check the actual posts table/column names in earlier migrations first.
2. Entity/repo/service changes; resolver for `Post.media` **without N+1** (batch-load media for a page of posts, e.g. `@BatchMapping` or a single IN query).
3. Keep writing `posts.media_url` = first media url (so any SQL/admin code reading it still works), or remove its readers — pick one and say which.
4. Media upload: read dimensions (ImageIO or the library already used for validation) and return them; store them if media rows are persisted, otherwise just return them.
5. Tests: create with 0/1/4 media; 5 → error; foreign URL → error; title omitted with content → ok; everything empty → error; legacy `mediaUrl` only → `media` has 1 item and `mediaUrl` equals it; update with `media: []` clears; update with `media: null` keeps; feed query with 20 posts issues one media query (assert via repository call count or SQL logging); upload returns width/height for a PNG and JPEG fixture; admin moderation still works.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not change anything under com/riksa/quest/** (another worker owns quests this wave) or `SocialActionEvent`.
- Do not modify files outside: src/main/resources/graphql/social.graphqls, src/main/java/com/riksa/social/**, src/main/java/com/riksa/media/**, src/main/java/com/riksa/admin/** (only what the post change requires), src/main/resources/db/migration/V40__post_media.sql, src/test/java/com/riksa/{social,media,admin}/**.
- Do not use migration numbers other than V40.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `./mvnw test` (Docker-dependent skips noted separately), an example GraphQL query + response with 2 media, and anything needing a live Postgres/S3 to verify.

# Risks
End with a "## Risks" section.
