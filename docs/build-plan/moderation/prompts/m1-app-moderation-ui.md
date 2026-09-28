# Task
Update the RIKSA Flutter app for instant publishing with server-side moderation. Clean blog posts publish at once, borderline ones go to review, and blocked or rate-limited blog posts, community posts and comments show a clear localized message that keeps the draft.

# Repo
This directory (`RIKSA-FLUTTER`), branch `staging`. Flutter, Riverpod 3, go_router, Dio, GraphQL over Dio for social. Bilingual en/km (Khmer is the first-run default).

# Relevant files
- `lib/features/blog/data/blog_api.dart`: `POST /blog`, `PUT /blog/{id}`, `DELETE /blog/{id}`.
- `lib/features/blog/data/blog_models.dart`: `BlogStatus { pending, approved, rejected }`.
- `lib/features/blog/presentation/blog_composer_screen.dart`: after submit it always shows the "In review" state (`blogReviewPendingTitle`, `blogReviewSubmittedBody`, `blogReviewBackTitle`, `blogReviewBackBody`), except for an approved edit.
- `lib/features/blog/presentation/my_posts_screen.dart`: **hard-coded English** `'In review'` / `'Published'` at ~lines 25–26 and ~395–396.
- `lib/features/blog/providers/blog_provider.dart`: pending count.
- `lib/features/auth/data/auth_api.dart`: `dioErrorMessage(DioException)` reads `body['message']`.
- `lib/features/social/data/social_api.dart`: `SocialApiException(message)` built from GraphQL errors.
- `lib/features/social/presentation/compose_community_post_screen.dart` (community composer). **Not** `social_post_detail_screen.dart`: comments are the Wave 2 task `m2-comment-ui`, which reuses your parser and message helper, so make both public and documented.
- `lib/l10n/app_en.arb`, `lib/l10n/app_km.arb`.

# Server contract (being built in parallel; use a fake API in tests)
- `POST /blog` and `PUT /blog/{id}` return `BlogPostResponse` with `status` `APPROVED` (published now) or `PENDING` (held for review).
- Blocked: HTTP **422** `{ "code": "CONTENT_BLOCKED", "message": "...", "reasons": ["PROFANITY" | "SPAM_LINKS" | "UNKNOWN_LINK" | "DUPLICATE" | "SHOUTING" | "REPEATED_CHARS" | "LINK_ONLY" | "NEW_ACCOUNT"] }`.
- Rate-limited: HTTP **429** `{ "code": "RATE_LIMITED", "message": "..." }`.
- GraphQL (community posts/comments): an error with `extensions.code` = `CONTENT_BLOCKED` (plus `extensions.reasons`) or `RATE_LIMITED`.
- There is **no topic restriction** any more; a blog post about anything publishes if it is clean.

# Do
1. Add a small shared parser, e.g. `lib/core/network/moderation_error.dart`:
   - `ModerationRejection { kind: blocked|rateLimited, reasons }`;
   - `ModerationRejection? fromDio(DioException)`;
   - `ModerationRejection? fromGraphQlErrors(List errors)`.
   Make `SocialApi` throw a `SocialApiException` that carries the rejection (additive field) when present.
2. A widget or helper that turns a rejection into one localized sentence. Pick the most specific reason:
   - PROFANITY → "Please remove offensive words before posting."
   - SPAM_LINKS / UNKNOWN_LINK / LINK_ONLY → "This looks like spam because of its links. Remove some links and try again."
   - DUPLICATE → "You already posted this. Try adding something new."
   - SHOUTING / REPEATED_CHARS → "Please write in normal text (not all capitals or repeated characters)."
   - rate limited → "You're posting very fast. Wait a few minutes and try again."
   - fallback → "This post can't be published."
   Keys use the `moderation…` prefix in both ARB files. Write natural Khmer (it will be reviewed by a Khmer speaker). Run `flutter gen-l10n`.
3. Blog composer:
   - after create/edit, `APPROVED` → a "Published" success state (new `moderationPublished…` strings) whose primary action opens the post (`/blog/{id}`, pushed so back works);
   - `PENDING` → the existing review state, reworded so it reads as the exception ("A moderator will take a quick look at this one…"). Update the existing four `blogReview…` strings in both ARBs rather than adding duplicates;
   - 422/429 → show the localized sentence inline or in a SnackBar, **keep the draft and the form**, and don't navigate.
4. Community composer: on a rejection, show the same sentence and keep the typed text. (Comments are handled in Wave 2.)
5. `my_posts_screen.dart`: replace the hard-coded `'In review'` / `'Published'` (and any other hard-coded English in that file) with l10n keys (reuse `blogStatusPending` / `blogStatusApproved` if they already exist).
6. Tests, using fake APIs as the existing tests do:
   - the parser, for REST and GraphQL shapes;
   - composer APPROVED → published state;
   - PENDING → review state;
   - 422 keeps the draft and shows the PROFANITY message in `km` and `en`;
   - a community post rejection keeps the text.
7. You cannot run Flutter in this sandbox (the SDK cache is outside the workspace). Write code carefully; the orchestrator runs `flutter analyze` and `flutter test`. Run `dart format` if it works.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside `lib/features/blog/**`, `lib/features/social/data/social_api.dart`, `lib/features/social/presentation/compose_community_post_screen.dart`, `lib/core/network/moderation_error.dart` (new), `lib/core/widgets/moderation_message.dart` (new, the message helper), `lib/l10n/**`, and `test/**` (not `test/**/goldens/**`).
- Do not modify `lib/core/widgets/riksa_bottom_navigation_bar.dart` or the router.
- Do not run `--update-goldens`; list goldens you expect to change instead.
- Do not add dependencies.

# Deliverable
Changed files, new l10n keys (en + km), tests added, expected golden changes, and anything unverified because Flutter couldn't run.

# Risks
End with a "## Risks" section.
