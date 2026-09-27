# Task
Fix two feed state bugs: creating a post overwrites changes made while it uploads, and the Communities tab / search can get stuck empty because more pages never load.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3 Notifiers, Dio + GraphQL for social.

# Relevant files
- lib/features/social/providers/social_feed_provider.dart — `SocialFeedNotifier`; `createPost` (~L213–244) captures `final latest = current;` **before** `await createPost(...)` and then writes `state = latest.copyWith(posts: [created, ...latest.posts])`. `toggleReaction` already does it right (reads `state` after the await) — use it as the reference. Also check `updatePost`, `deletePost`, `join/leave`, `loadMore` for the same stale-capture pattern.
- lib/features/blog/providers/blog_provider.dart — `BlogFeedNotifier`; the audit reports the same pattern in `loadMore` and `toggleLike`. Verify and fix if real.
- lib/features/social/presentation/social_feed_screen.dart — `_loadMoreNearEdge` (~L70) is the ONLY trigger for `loadMore` (scroll listener). Filtering is client-side (~L180–184): Communities tab keeps posts whose category is joined; search filters by `_matchesPostSearch`. If the filtered list is empty or shorter than the viewport, the list can't scroll, so nothing more ever loads.

# Context
Validated findings C2 and C4. The backend feed has no category/joined/search filter today, so the fix for C4 stays client-side in this task. Note: an earlier worker (Wave 1) made these providers rebuild when the signed-in user changes (they `watch(currentUserIdProvider)`); keep that intact.

# Do
1. **C2:** in every async mutation in both notifiers, compute the new state from `state` **after** the await (and bail out if `state` is no longer the loaded variant). Prepend a created post only if it isn't already in the list (dedupe by id). Keep optimistic updates and their rollback working.
2. **C4:** after each build of the filtered list, if `hasNextPage` and (the filtered list is empty OR its content is shorter than the viewport), call `loadMore()` automatically — at most N=5 automatic pages per filter/query change, never while a load is in flight, and stop when `hasNextPage` is false. Show a small loading row while it auto-loads, and when the cap is hit with nothing found, show the existing empty message plus a "Load more" button (prefix `feed…` for new strings). Reset the counter when the tab or search query changes.
3. Do the equivalent for the blog feed if the blog screen filters client-side (check `blog_feed_screen.dart`; if it does not filter, leave it).
4. Tests with fake APIs: (a) a reaction toggled while `createPost` is pending survives; (b) `loadMore` completing during `createPost` keeps both the new post and the new page, no duplicates; (c) Communities tab with 0 matches on page 1 and a match on page 3 auto-loads and shows it; (d) auto-load stops at the cap and shows "Load more"; (e) no auto-load when `hasNextPage` is false.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar.
- Do not change post card / detail / composer UI (another worker owns them this wave).
- Do not modify files outside: lib/features/social/providers/**, lib/features/blog/providers/**, lib/features/social/presentation/social_feed_screen.dart, lib/features/blog/presentation/blog_feed_screen.dart (only if needed for step 3), lib/l10n/** (prefix `feed…`), test/features/social/**, test/features/blog/**.
- Do not add dependencies.

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, and a list of every mutation you checked with "was stale / was fine".

# Risks
End with a "## Risks" section.
