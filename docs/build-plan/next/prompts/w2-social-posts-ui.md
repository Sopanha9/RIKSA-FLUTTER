# Task
Make community posts read and look well: readable body text, clean feed previews, tappable links, a formatting bar with preview in the composer, photos that keep their real shape, and a full-screen zoomable photo viewer.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3, go_router, flutter_markdown_plus (depends on `package:markdown`), url_launcher.

# Relevant files
- lib/features/social/presentation/widgets/social_post_card.dart — feed row; title + `plainTextPreview` (maxLines 4); image forced to `AspectRatio(16/9)` + `BoxFit.cover` (~L142–170); plain `Image.network`, no loading builder.
- lib/features/social/presentation/social_post_detail_screen.dart — `MarkdownBody` (~L524, no `onTapLink`); full-width image with no height cap (~L535–555); `_socialMarkdownStyleSheet` (~L900–954): body `p` is **13px `inkMuted`**, `textAlign: WrapAlignment.spaceBetween`; `_deleteComment` (~L244) subtracts 1 from `commentCount` even when replies are removed with the comment.
- lib/features/social/presentation/compose_community_post_screen.dart — title `TextFormField` (validator: ≥4 chars), body `TextFormField` (≥10 chars), bottom bar with only "Add photo" (~L428–467); image upload via `ImagePicker` (maxWidth/Height 1600, q85).
- lib/features/social/presentation/widgets/post_image_field.dart — composer image preview.
- lib/features/social/data/social_models.dart — `socialMarkdownPreview` (~L301): regex-strips only headings, `-`/`+` bullets, `**`, `__`, backticks.
- lib/features/blog/presentation/widgets/markdown_toolbar.dart — an existing markdown formatting toolbar used by the blog composer. **Reuse it** (import it; don't copy it). If it needs a small generalization, make it backwards-compatible and keep the blog composer working.
- lib/features/auth/data/external_link_opener.dart — `externalLinkOpenerProvider` (url_launcher, external app). Use it for links.
- lib/core/theme/app_theme.dart — `RiksaTypography.bodyStyleFor(text, style)` (Khmer-aware line height), `context.riksa` palette (`ink`, `inkMuted`, `surfaceRaised`, `outline`).

# Context
Validated review findings T1–T5, P1–P4, C6. Feed layout is X-style (avatar column, hairline separators) — keep it. Phone photos (homework, handwritten notes, exam questions) are usually portrait, so the 16:9 crop cuts off the important part. Posts are markdown. A later task will add up to 4 photos per post and server-provided width/height; design the image widget so it can take an optional known aspect ratio and so a grid can reuse it.

# Do
1. **Detail text (T1/T2):** body paragraph 15.5–16px, `ink` color, normal left/start alignment (remove `WrapAlignment.spaceBetween`), keep Khmer-aware line height via `RiksaTypography.bodyStyleFor`. Blockquote: `inkMuted` with a left border. Keep the heading scale.
2. **Links (T4):** `onTapLink` opens only `http`/`https` URLs via `externalLinkOpenerProvider`; ignore other schemes. Links styled with the brand color + underline.
3. **Feed preview (T3):** rewrite `socialMarkdownPreview` to walk the parsed markdown (package:markdown `Document().parseLines` → collect text nodes) instead of regex: link → its text; image → `[photo]` (localized at display time or omitted); list items → `• item`; code fences → their text; collapse runs of blank lines to one line break. Keep the function signature. Add a table-driven unit test covering: bold/italic/`*`/`_`, links, images, `>` quotes, `1.` and `*` lists, headings, code fences, blank lines, Khmer text.
4. **Photos in feed (P1/P4):** new widget `PostPhoto` (lib/features/social/presentation/widgets/post_photo.dart): takes `url` and optional `aspectRatio`. If unknown, resolves the real size from the image stream and animates once from a 4:5 placeholder to the real ratio, clamped to **[4:5 portrait … 16:9 landscape]**, with `BoxFit.cover` inside that clamp. Surface-colored placeholder while loading, error state as today. Decode at display size (`cacheWidth` = layout width × devicePixelRatio). Rounded 16 + hairline border as today.
5. **Viewer (P2/P3):** tapping a photo opens a full-screen viewer route (lib/features/social/presentation/widgets/photo_viewer.dart): black background, Hero from the thumbnail, `InteractiveViewer` pinch zoom + double-tap zoom toggle, swipe down to dismiss, close button with a semantics label, safe areas. Accept a list of URLs + initial index now (single photo today) so multi-photo can reuse it. On the detail screen, cap the photo at ~70% of screen height with `BoxFit.contain` and open the viewer on tap. Reduced motion: no Hero/scale animation.
6. **Composer (T5):** add the markdown toolbar (bold, italic, bullet list, numbered list, quote, link) above the keyboard next to "Add photo", and a **Write / Preview** toggle that renders the body with the same markdown style sheet as the detail screen (extract the style sheet into a shared function so both use it). Do NOT change the title/body validation rules in this task (a later task makes titles optional once the API supports it).
7. **Comment count (C6):** when deleting a comment, subtract the number of comments actually removed from the local list (the comment + its removed replies), not 1.
8. Strings in l10n with prefixes `post…`, `composer…`, `photoViewer…`.
9. Tests: preview table test; link tap calls the opener with https and ignores `javascript:`; portrait image is not cropped to 16:9 (aspect within clamp); tapping a photo opens the viewer and swipe/close dismisses it; composer bold wraps the selection and Preview shows rendered markdown; comment delete count; Khmer at 200% text scale on the detail screen without overflow. Regenerate the social goldens (`test/visuals/social_feed_screen_golden_test.dart`) and list which changed and why.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar.
- Do not change `social_feed_provider.dart`, `social_feed_screen.dart`, `blog_provider.dart` (another worker owns them this wave).
- Do not modify files outside: lib/features/social/presentation/widgets/**, lib/features/social/presentation/social_post_detail_screen.dart, lib/features/social/presentation/compose_community_post_screen.dart, lib/features/social/data/social_models.dart (preview function only), lib/features/blog/presentation/widgets/markdown_toolbar.dart (backwards-compatible changes only), lib/l10n/**, test/features/social/**, test/visuals/social_feed_screen_golden_test.dart + its goldens.
- Do not add dependencies without stating so (no cached_network_image in this task).

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, before/after description of the feed card and detail screen, the list of regenerated goldens, and anything that needs a device to verify (e.g. link opening, pinch zoom feel).

# Risks
End with a "## Risks" section.
