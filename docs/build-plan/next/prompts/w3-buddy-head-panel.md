# Task
Redesign the floating buddy: a free-floating head (no circle), and tapping it grows a full-size quest panel out of the head with Today / This week tabs, a streak tile, and a weekly chest.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3, go_router, Dio.

# Relevant files
- lib/features/mascot/presentation/widgets/floating_buddy.dart — current head: 56px `Container` with `BoxShape.circle`, surface fill, brand border, box shadow, `Clip.antiAlias` (~L210–241); badge anchored to the circle's corner (~L242–270); drag + edge snap + saved position; `_faceFor` mood logic (~L284); hidden routes; `_showTodaySheet` → `showModalBottomSheet` with `_TodayQuestsSheet` (~L320–600): plain cards, progress shown three times, small TextButton claim, `_StreakPill`.
- lib/features/mascot/presentation/widgets/mascot_face.dart — `MascotFaceAvatar` / `MascotFaceView`; faces are transparent PNGs, wider than tall (crocodile 138×101, capybara 118×92) in assets/images/mascots/<species>/faces/.
- lib/features/quests/{data/quest_models.dart, data/quests_api.dart, providers/today_quests_provider.dart} — daily quests (`GET /quests/today`, `POST /quests/{id}/claim`). Note: a previous wave made these providers watch `currentUserIdProvider`; keep that.
- lib/features/auth/presentation/require_account.dart — guest gate.
- lib/core/theme/app_theme.dart — `context.riksa` palette, `RiksaTypography`, `RiksaMotion` / reduced motion.
- test/features/mascot/floating_buddy_test.dart — existing tests to keep green (update expectations where the design intentionally changed).

# Context
Design decisions (from docs/build-plan/BUDDY_MARKET_PLAN.md §8):
- The head is just the face, floating. The circle clips future hats, and the free head reads as a character, not an app icon.
- The panel must NOT show less than the old sheet — only its origin and shape change. It is nearly screen-width and grows from the head like a speech bubble with a tail pointing at the head.
- A later wave adds a market (spend XP on hats/glasses) and a `BuddyLook` widget that will replace the face rendering here; keep the head rendering in one small widget so it can be swapped.

The weekly API is built in parallel. Use this fixed contract and a fake API in tests:

`GET /api/v1/quests/today` → existing shape plus `"resetsAt": "2026-09-28T00:00:00+07:00"`.
`GET /api/v1/quests/week` →
`{ "weekStart", "resetsAt", "quests": [ { "id", "type": "WEEKLY_LESSONS|WEEKLY_CORRECT_ANSWERS|WEEKLY_ACTIVE_DAYS|WEEKLY_SOCIAL", "title", "titleKm", "target", "progress", "xpReward", "completed", "claimed" } ], "chest": { "id", "points", "target", "maxPoints", "opened", "xpReward", "rewardItem": null | { "id", "slot", "assetKey", "name", "nameKm" } } }`
`POST /api/v1/quests/{id}/claim` → the quest (daily or weekly); 409 when not claimable.
`POST /api/v1/quests/chest/open` → the chest; 409 when not openable.

# Do
1. **Head:** render the face PNG with no circle/border/clip. Shape-following shadow (a blurred, darkened copy of the same image offset downward — not a BoxShadow). In dark mode add a thin light outline (e.g. the image drawn slightly larger in a light tint behind it). Hit target stays ≥56×56. Replace the circular ink ripple with a small squash/bounce on tap (skip under reduced motion). Badge sits beside the face on the side facing the screen center. Keep drag, edge snap, saved position, hidden routes, long-press hide-for-today, keyboard hiding.
2. **Weekly data:** extend lib/features/quests with weekly models, `weeklyQuestsProvider`, `claim` routing for weekly ids, and `openChest()`; after any claim or chest open, refresh today + week + the gamification profile (as the daily claim does now).
3. **Panel presentation:** tapping the head opens a `PopupRoute`/`showGeneralDialog` route (so back button, focus trap and screen-reader dismiss work). The panel scales + fades out of the head's position with a tail pointing at the head; the head stays visible above the scrim with a talking/happy face. Width = screen − 24 (max 380), max height ≈ 75% of the screen minus insets and nav bar; content scrolls inside. Open downward when the head is in the top half, upward otherwise; align to the edge the head is snapped to. Close by tapping outside, tapping the head, back, or pressing `Go →`; it shrinks back into the head. Reduced motion → fade only. Dragging the head is disabled while open.
4. **Fallback:** if the panel can't fit (height < ~420 logical px available, landscape phones, or text scale ≥ 1.6), show the same content in the existing modal bottom sheet. Build the content once (`BuddyPanelContent`) and use it in both.
5. **Content (top → bottom):**
   a. Buddy line: live mood face + chat-style speech bubble. The line reacts to state: claimable → "Claim your XP!", 1 lesson left with streak at risk → "1 lesson left and your streak is safe", all claimed → "All done — see you tomorrow", else a greeting. Uses the buddy's name.
   b. Two tiles: **Streak** (days + last-7-days dots) and **Weekly chest** (points/target + bar; when openable, an "Open" button; after opening, show +XP and the item name if `rewardItem` is set).
   c. **Today / This week** segmented control with a dot/count of claimable items per tab.
   d. Quest rows: icon inside a progress ring, title, subline "progress/target · +XP", and ONE trailing action — filled `Claim` when claimable; `Go →` when not done (lesson/answers types → `/learn`, social types → `/social`, active days → `/learn`); faded + strike-through when claimed.
   e. Footer: daily all-claimed bonus + "Resets in Xh Ym" countdown from `resetsAt` (Today tab) or the weekly `resetsAt` (Week tab).
   f. Guests: same layout, claim/open buttons show a lock and route through `requireAccount`; one sign-in button at the bottom; no API calls for guests.
6. **Claim feedback:** the claimed row's XP counts up and flies toward the tile area, the buddy switches to a celebrate/happy face, light haptic. Reduced motion → static "+15 XP" label.
7. Strings in l10n with prefixes `buddyPanel…`, `weekly…`, `chest…` (en + km; mark km as draft).
8. Tests (fake quests API): head has no circular clip and keeps a ≥56px hit target; panel opens from a right-edge and a left-edge head and stays on screen; top-half head opens downward; back closes it; fallback sheet at 200% text scale; Today/Week switching; claim a weekly quest; open the chest at 15/15 and 409 handling; `Go →` navigates and closes; guest sees locks and no network calls; Khmer at 200% without overflow; reduced motion path. Update floating_buddy goldens if present and list them.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar widget or its styling. The panel must not cover it.
- Do not modify files outside: lib/features/mascot/presentation/widgets/floating_buddy*.dart, new files under lib/features/mascot/presentation/widgets/buddy_panel/**, lib/features/quests/**, lib/l10n/**, test/features/mascot/**, test/features/quests/**, related goldens.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, a short description (or golden list) of each visual state: head light/dark, panel from left/right, top/bottom, fallback sheet, guest, claim animation; and anything that needs the real API or a device to verify.

# Risks
End with a "## Risks" section.
