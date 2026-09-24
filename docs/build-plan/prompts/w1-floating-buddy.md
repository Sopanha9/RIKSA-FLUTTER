# Task
Add a floating buddy head that stays on screen across the app and opens a "today" sheet with daily quests when tapped.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, Flutter + Riverpod + go_router + Dio.

# Relevant files
- lib/app/router/app_shell.dart — the shell around tab pages; mount the head here in a Stack layer ABOVE page content
- lib/features/mascot/presentation/widgets/mascot_face.dart — `MascotFaceView` / `MascotFaceAvatar` already render expression images
- assets/images/mascots/<species>/faces/ — expression frames (annoyed, confused, cool, crying, determined, happy, …)
- lib/features/mascot/domain/mascot.dart (MascotMood), buddy_behavior.dart, buddy_care.dart
- lib/features/mascot/providers/mascot_provider.dart — species and name
- lib/features/mascot/presentation/widgets/buddy_companion.dart — the in-lesson buddy; keep it as is
- lib/features/learning/data/learning_api.dart — copy its API client pattern
- lib/features/auth/presentation/require_account.dart — guest gate helper

# Context
Today the buddy only exists inside lessons. It should feel alive everywhere, like a chat head, and be the daily entry point. The backend quests API is built in parallel; use this fixed contract:

GET /api/v1/quests/today → `{ "date", "quests": [ { "id", "type": "COMPLETE_LESSON|CORRECT_ANSWERS|SOCIAL_ACTION", "title", "titleKm", "target", "progress", "xpReward", "completed", "claimed" } ], "allClaimedBonusXp" }`
POST /api/v1/quests/{id}/claim → the updated quest; 409 when not claimable.

# Do
1. `lib/features/quests/`: models, api, providers (`todayQuestsProvider`; a claim action that refreshes quests and the gamification profile).
2. `FloatingBuddy` in lib/features/mascot/presentation/widgets/floating_buddy.dart: 56px circular head showing the current mood's face; draggable; snaps to the nearest left/right edge; position saved in SharedPreferences (wrapped in try/catch); never covers the bottom nav bar or system insets; badge with the number of claimable quests.
3. Mood: claimable quest → happy; streak at risk after 18:00 with no lesson today → crying; nothing done yet → greeting before noon, idle otherwise; all claimed → cool. Idle blink/bob only when motion is allowed.
4. Tap → bottom sheet: buddy line (l10n, uses the buddy's name), current streak, the three quests with progress bars and Claim buttons, and a "Start a lesson" button to /learn.
5. Guests: the sheet previews the three quest types and shows "Save your streak — sign in" via require_account.dart. No API calls for guests.
6. Hide the head on lesson routes (/learn/:id and children), onboarding, auth, and while the keyboard is open.
7. Long-press → "Hide buddy for today" (stored locally).
8. All strings in lib/l10n/app_en.arb + app_km.arb; run `flutter gen-l10n`.
9. Tests with a fake quests API: shows on /learn, hidden on a lesson route, badge count, claim flow, guest preview, drag snapping, Khmer at 200% text scale in the sheet without overflow.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do NOT modify the bottom navigation bar widget or its styling; a teammate owns it. In app_shell.dart only add the overlay layer.
- Do not modify files outside: lib/features/quests/**, lib/features/mascot/presentation/widgets/floating_buddy*.dart, lib/app/router/app_shell.dart (overlay layer only), lib/l10n/**, test/features/quests/**, test/features/mascot/floating_buddy*_test.dart.
- Do not add dependencies without stating so.

# Deliverable
Changed files, real output of `flutter analyze` and `flutter test`, a short description of each visual state, and anything that needs the real API to verify.

# Risks
End with a "## Risks" section.
