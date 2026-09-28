# Task
Fix the comment UI on the community post detail screen of the RIKSA Flutter app. Make the comment cards match the rest of the page, turn the fake "Like" and "Hide" text into real behaviour or remove it, fix the composer's look, and show moderation rejections on comments without losing the typed text.

# Repo
This directory (`RIKSA-FLUTTER`), branch `staging`. Flutter, Riverpod 3, go_router, Dio, GraphQL over Dio for social. Bilingual en/km (Khmer is the first-run default). A competition entry judged on UX/UI: polish matters, and so does keeping the existing design language.

# Relevant files
- `lib/features/social/presentation/social_post_detail_screen.dart`: the whole screen. Comment parts:
  - comment list: ~lines 395–470;
  - `_CommentCard`: ~751;
  - `_CommentActionRow`: ~885;
  - `_relativeCommentAge`: ~961;
  - `_Avatar`, `_CountBadge`, `_EmptyComments`;
  - `_CommentComposer`: ~1125.
- `lib/features/social/data/social_api.dart`: `react({postId, reaction})` only handles posts. The GraphQL input is `ReactInput { postId: UUID, commentId: UUID, type: ReactionType! }`, and `react` returns `Post!`.
- `lib/features/social/data/social_models.dart`: `SocialComment` has `myReaction` but **no like count** (the API has none either).
- `lib/core/network/moderation_error.dart` (from Wave 1): parses `CONTENT_BLOCKED` / `RATE_LIMITED` into a `ModerationRejection`. `SocialApiException` carries it. There is a localized message helper from Wave 1; reuse it and don't duplicate it.
- `lib/core/theme/app_theme.dart`: `context.riksa` palette, `AppRadii`, `RiksaTypography`.
- Goldens: `test/visuals/goldens/social_post_detail_editorial_en_{light,dark}.png` (the test is in `test/visuals/social_feed_screen_golden_test.dart`). Widget tests: `test/features/social/presentation/social_post_detail_screen_test.dart`.

# Problems to fix (seen in the current goldens and code)
1. **The comment card runs to the right edge of the screen.** It is a full-bleed white block with only a top border. The timestamp ("35d") and "Hide" touch the screen edge, and there are no rounded corners, unlike the post and the other cards. Give root comments a proper card: `AppRadii` corners, horizontal padding on both sides, the page's surface + outline tokens, and consistent spacing between cards. Show replies as an indented thread inside or under their root (a thin left rail is fine), not as separate full-width blocks.
2. **The card is too tall.** There's a big empty band under the action row, because the 48 px tap targets inflate the row. Keep 48 px hit areas (accessibility) without adding visual height, e.g. with `materialTapTargetSize`, a negative margin, or a hit-test padding widget.
3. **The actions are fake or faint:**
   - "Like" is plain text that does nothing. Make it a real toggle:
     - add `SocialApi.reactToComment({required String commentId, required SocialReaction? reaction})` using the `react` mutation with `commentId`. Check `social_api.dart`'s existing `react` for how "remove reaction" is expressed; if the API has no un-react, toggle with the same mutation the post like uses;
     - update the comment optimistically (`myReaction`) and roll back on error;
     - show a filled heart when liked;
     - show **no count** (the API has none).
   - "Hide" is plain text that does nothing, and there is no user-facing hide or report endpoint. **Remove it.** Don't invent a fake control.
   - Actions use `inkMuted` at 60 % alpha, which is too faint. Use the palette's muted ink at full strength; keep Delete in the error colour.
   - `'ចូលចិត្ត' / 'Like'` and `'លាក់' / 'Hide'` are hard-coded with an `isKhmer` check. Use l10n keys, and reuse existing keys where they exist (`reply`, `delete`, and a like key if one exists). `_relativeCommentAge` also hard-codes `'ឥឡូវ' / 'now'` and English `d/h/m`: localize it with plural-aware keys (`commentAge…`).
4. **The composer looks broken in light mode.** The field uses a white→black glass gradient plus a heavy shadow, so it renders as a grey smudge. The send button stacks two circles with two shadows, so a doubled ring shows under it. Make it clean and theme-correct in both modes:
   - an opaque surface pill with an outline;
   - one subtle shadow at most;
   - the send button as a single filled brand circle when there is text, and muted/disabled when empty or submitting.
   - Keep `BackdropFilter` only if it still looks right over the content; otherwise drop it.
   - Keep the reply indicator bar, styled to match.
5. **Moderation:** when sending a comment fails with a `ModerationRejection`, show the Wave 1 localized sentence (SnackBar or inline under the field), **keep the typed text and the reply target**, and re-enable sending.
6. **Count check:** the header shows `post.commentCount` (e.g. 4) while the golden shows 1 comment. Find out whether replies are fetched lazily (`Comment.replies(cursor, limit)`) and so missing. If replies aren't loaded, load them or show a "View N replies" control per thread. At minimum, the header count and the visible list must not contradict each other without explanation.

# Do
1. Fix the six items. Keep existing `ValueKey`s used by tests (`comment-card-…`, `comment-reply-button-…`, `comment-delete-button-…`, `comment-composer`, `send-comment-button`, `reply-indicator-bar`, `cancel-reply-button`, `comment-author-name-…`, `post-detail-comment-count`). Add `comment-like-button-<id>`.
2. Add l10n keys (prefix `comment…`) to **both** `app_en.arb` and `app_km.arb` with natural Khmer (it will be reviewed). Run `flutter gen-l10n` if you can.
3. Tests in `test/features/social/presentation/social_post_detail_screen_test.dart`:
   - like toggles optimistically and rolls back on error;
   - no "Hide" text;
   - the Khmer locale shows no English action labels;
   - a moderation rejection keeps the text and the reply target;
   - the tap target of Reply is ≥ 48×48 while the row stays visually compact.
4. You cannot run Flutter in this sandbox (the SDK cache is outside the workspace). The orchestrator runs `flutter analyze`, `flutter test`, and reviews the golden diffs visually. Do **not** run `--update-goldens`; list the goldens you expect to change.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside `lib/features/social/presentation/social_post_detail_screen.dart`, `lib/features/social/presentation/widgets/**` (only if you extract comment widgets there, into new files), `lib/features/social/data/social_api.dart` (only the new `reactToComment`), `lib/features/social/data/social_models.dart` (only additive `copyWith`-style helpers for comments), `lib/l10n/**`, and `test/features/social/**`.
- Do not change the post body, the post header/back button, or the feed screen.
- Do not touch `lib/core/widgets/riksa_bottom_navigation_bar.dart` or the router.
- Do not add dependencies.

# Deliverable
Changed files, a before → after description of each of the six items, the l10n keys added, tests added, expected golden changes, and anything unverified because Flutter couldn't run.

# Risks
End with a "## Risks" section.
