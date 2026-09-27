# Task
Support up to 4 photos per community post in the app (compose, feed, detail, viewer), use server-provided photo sizes to avoid layout jumps, and make post titles optional.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3, GraphQL over Dio for social.

# Relevant files
- lib/features/social/data/social_models.dart — `SocialPost` (single `mediaUrl`, `hasMedia`), `fromJson`, `copyWith`.
- lib/features/social/data/social_api.dart — GraphQL queries/mutations for posts (field selections), `uploadMedia` (returns url).
- lib/features/social/presentation/widgets/post_photo.dart and photo_viewer.dart — added in Wave 2: `PostPhoto(url, aspectRatio?)` clamps 4:5…16:9; the viewer takes a list + initial index.
- lib/features/social/presentation/widgets/social_post_card.dart, social_post_detail_screen.dart, compose_community_post_screen.dart, widgets/post_image_field.dart.
- lib/features/social/providers/social_feed_provider.dart — `createPost` / `updatePost` signatures (currently `mediaUrl`).

# Context
The API (built in the previous wave) now exposes:
```graphql
type PostMedia { url: String!  width: Int  height: Int }
type Post { … mediaUrl: String   media: [PostMedia!]! }   # media: 0–4, ordered; mediaUrl = media[0].url
input PostMediaInput { url: String!  width: Int  height: Int }
input CreatePostInput { title: String  content: String!  mediaUrl: String  media: [PostMediaInput!]  categoryId: UUID! }
# UpdatePostInput.media: null = unchanged, [] = clear
```
`POST /media` returns `{ "id", "url", "width", "height" }`. Validation: at least one of title/content/media non-empty; max 4 media.
Titles become optional (decision D5): the feed/detail fall back to the first line of the body when the title is empty.

# Do
1. Models: `SocialPostMedia(url, width?, height?)`, `SocialPost.media` (from `media`, falling back to `[mediaUrl]` for old payloads), keep `mediaUrl` getter for compatibility; `uploadMedia` returns url + size.
2. API/provider: request `media { url width height }`; create/update send `media` (and stop sending `mediaUrl`); update distinguishes unchanged vs cleared.
3. Composer: pick up to 4 images (multi-select from gallery, or camera one at a time); thumbnails row with remove + drag-to-reorder; each uploads immediately with its own progress/error + retry; submit disabled while any upload is pending. Title field optional (no min length); body required only when there are no photos; show one clear inline message when everything is empty.
4. Feed layout (inside the existing card, X-style): 1 → `PostPhoto` with known aspect ratio; 2 → side by side (each 4:5 crop); 3 → one large left + two stacked right; 4 → 2×2 grid. Rounded outer corners only, 2px gaps, "+N" never needed (max 4). Tapping any photo opens the viewer at that index.
5. Detail: the same grid, larger; single photo keeps the Wave-2 height cap with `BoxFit.contain`.
6. Viewer: swipe between photos (PageView), page indicator "2 / 4", zoom resets per page.
7. Title fallback: when `title` is empty, the card shows the body preview as the main text (no empty bold line) and the detail header uses the first line of the body.
8. Strings: prefix `postPhotos…`.
9. Tests: parse old (mediaUrl only) and new payloads; 1/2/3/4 layouts (goldens light+dark); tapping photo 3 opens viewer on index 2; composer: add 4, 5th blocked, remove, reorder, one failed upload blocks submit until retried or removed; post with only photos and no title/body submits; empty post shows the message; update with photos removed sends `[]`.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar.
- Do not modify files outside: lib/features/social/**, lib/l10n/** (prefix `postPhotos…`), test/features/social/**, social goldens.
- Do not add dependencies without stating so (multi-image picking should use `image_picker`'s `pickMultiImage`, already a dependency).

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, the list of new/updated goldens, and anything needing the real API or a device to verify.

# Risks
End with a "## Risks" section.
