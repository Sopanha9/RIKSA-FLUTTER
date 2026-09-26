# Figma screen prompts — one per route (38)

One prompt per navigable route in
[app_router.dart](../lib/app/router/app_router.dart), in the order a learner
meets them. Redirect-only routes (`/`, `/dashboard`, `/learn/resume`) are not
screens and are left out.

**How to use:** paste **Prompt 0** into Codex once at the start of a session,
then paste one numbered prompt at a time. Check the frame in Figma before you
send the next one.

---

## Prompt 0 — Shared rules (send first, once per Codex session)

```
You are recreating the RIKSA Flutter app's screens in Figma, one frame per
route, using the Figma MCP tools. I will send one screen at a time.

SOURCE OF TRUTH
- The Dart code is the source of truth. Read the screen file I name, and every
  widget it builds, before drawing. Match layout, spacing, radius, colors, font,
  font size/weight, icons, copy, and element order exactly as the code renders.
- Theme tokens: lib/core/theme/ (app_theme.dart and related files). Use these
  exact hex values, radii, spacing and text styles. Never invent a color.
- Copy: use the English strings from lib/l10n/ (the .arb files) that the screen
  actually references. No lorem ipsum.
- Assets: use the real images, icons, mascot art and illustrations from assets/.
  Upload them to Figma; do not draw placeholders when the asset exists.
- Screenshots in screenshots/ may be OLDER than the code. Use them only as a
  visual hint; if a screenshot and the code disagree, follow the code.

FIGMA FILE STRUCTURE
- Frame size: 390 x 844 (iPhone 14). Name each frame "NN · Route · Screen name",
  e.g. "01 · /splash · Splash".
- One Figma page per section: "1 Launch & Onboarding", "2 Auth",
  "3 Home · Social · Blog", "4 Learn", "5 AI", "6 Leaderboard", "7 Profile".
- Place frames left to right in number order, 80px apart, on the section's page.
- Use auto layout. Create color and text styles from the theme tokens the first
  time you need them and reuse them afterwards. Build repeated widgets (cards,
  buttons, chips, the bottom nav bar, app bars) as components and reuse them.
- Screens inside the app shell (Home, Learn, AI, Leaderboard, Profile branches)
  show the bottom navigation bar from lib/app/router/app_shell.dart with the
  correct tab selected. Reuse one component for it.
- Draw the default, populated, light-mode state with realistic sample data
  unless the prompt says otherwise. Sheets, dialogs and error states are NOT
  separate frames unless the prompt asks for them.

WHEN DONE WITH EACH SCREEN
- Tell me the frame name, which Dart files you read, and anything you could not
  match exactly (missing asset, dynamic content, animation) so I can check it.
- Do not modify any Dart code.
```

---

## Section 1 — Launch & Onboarding (Figma page "1 Launch & Onboarding")

### 01 · `/splash` · Splash
```
Screen 01. Route /splash. Frame "01 · /splash · Splash".
File: lib/features/auth/presentation/splash_animation_screen.dart
This is the first screen on launch. Draw the first-run welcome state (the one
with the "get started" action shown when no language is selected yet). The
animation cannot be drawn; show its final resting frame.
```

### 02 · `/mascot-select` · Choose your buddy
```
Screen 02. Route /mascot-select. Frame "02 · /mascot-select · Mascot Select".
File: lib/features/mascot/presentation/mascot_select_screen.dart (plus the
widgets it uses in lib/features/mascot/presentation/widgets/).
Comes right after Splash. Use the real mascot artwork from assets/. Show the
default buddy selected.
```

### 03 · `/language-select` · Language Select
```
Screen 03. Route /language-select. Frame "03 · /language-select · Language Select".
File: lib/features/auth/presentation/language_select_screen.dart
Comes after mascot select; the buddy picked on screen 02 is the one asking.
Use the same default buddy as frame 02.
```

### 04 · `/onboarding/setup` · Interactive onboarding
```
Screen 04. Route /onboarding/setup. Frame "04 · /onboarding/setup · Onboarding Setup".
File: lib/features/auth/presentation/interactive_onboarding_screen.dart
This screen has internal steps. Draw the FIRST step as frame 04. Then list the
other steps for me and ask whether I want them as extra frames (04a, 04b...).
```

### 05 · `/onboarding` · Onboarding splash
```
Screen 05. Route /onboarding. Frame "05 · /onboarding · Onboarding Splash".
File: lib/features/auth/presentation/onboarding_splash_screen.dart
This is the entry shown to returning users who picked a language but haven't
seen onboarding. If it has pages, draw the first page and tell me how many
pages there are.
```

### 06 · `/province-select` · Province Select
```
Screen 06. Route /province-select. Frame "06 · /province-select · Province Select".
File: lib/features/auth/presentation/province_select_screen.dart
Show the list of provinces with none selected yet.
```

## Section 2 — Auth (Figma page "2 Auth")

### 07 · `/auth/login` · Login
```
Screen 07. Route /auth/login. Frame "07 · /auth/login · Login".
File: lib/features/auth/presentation/auth_switcher_screen.dart
Draw the LOGIN tab of the switcher, empty fields, default state.
```

### 08 · `/auth/register` · Register
```
Screen 08. Route /auth/register. Frame "08 · /auth/register · Register".
File: lib/features/auth/presentation/auth_switcher_screen.dart (initialPage:
PageState.register).
Same widget as frame 07, but the REGISTER tab is active. Reuse frame 07's
components; only the active tab and form fields change.
```

### 09 · `/auth/recover` · Account Recovery
```
Screen 09. Route /auth/recover. Frame "09 · /auth/recover · Account Recovery".
File: lib/features/auth/presentation/account_recovery_screen.dart
(class AccountRecoveryScreen). It has steps: draw the first step (enter
identifier), empty.
```

### 10 · `/auth/verify-email` · Email Verification
```
Screen 10. Route /auth/verify-email. Frame "10 · /auth/verify-email · Email Verification".
File: lib/features/auth/presentation/account_recovery_screen.dart
(class EmailVerificationScreen). Draw the success/verified state.
```

### 11 · `/auth/telegram` · Telegram sign-in
```
Screen 11. Route /auth/telegram. Frame "11 · /auth/telegram · Telegram Auth".
File: lib/features/auth/presentation/telegram_auth_screen.dart
Draw the first step (before a code is sent), empty.
```

## Section 3 — Home · Social · Blog (Figma page "3 Home · Social · Blog")

All frames on this page show the bottom nav bar with the Home tab selected.

### 12 · `/home` · Home feed
```
Screen 12. Route /home. Frame "12 · /home · Home Feed".
File: lib/features/social/presentation/social_feed_screen.dart
Default feed tab with 3–4 realistic posts. Bottom nav: Home tab selected.
```

### 13 · `/community` · Home feed, communities view
```
Screen 13. Route /community. Frame "13 · /community · Feed (Communities)".
File: lib/features/social/presentation/social_feed_screen.dart with
startInCommunities: true. Same widget as frame 12; reuse its components and
show the communities view that this flag opens.
```

### 14 · `/communities` · Communities
```
Screen 14. Route /communities. Frame "14 · /communities · Communities".
File: lib/features/social/presentation/communities_screen.dart
List of communities, some joined and some not.
```

### 15 · `/communities/create` · Create Community
```
Screen 15. Route /communities/create. Frame "15 · /communities/create · Create Community".
File: lib/features/social/presentation/create_community_screen.dart
Empty form.
```

### 16 · `/communities/:id` · Community Detail
```
Screen 16. Route /communities/:id. Frame "16 · /communities/:id · Community Detail".
File: lib/features/social/presentation/community_detail_screen.dart
One community with its header and a few posts.
```

### 17 · `/progress` · Progress History
```
Screen 17. Route /progress. Frame "17 · /progress · Progress History".
File: lib/features/userProfile/presentation/progress_history_screen.dart
Populated with a realistic week or two of activity.
```

### 18 · `/community/create` · Compose Post
```
Screen 18. Route /community/create. Frame "18 · /community/create · Compose Post".
File: lib/features/social/presentation/compose_community_post_screen.dart
(class ComposeCommunityPostScreen). Default post mode, empty. If question
mode (?type=question) looks different, tell me what changes.
```

### 19 · `/community/posts/:id/edit` · Edit Post
```
Screen 19. Route /community/posts/:id/edit. Frame "19 · /community/posts/:id/edit · Edit Post".
File: lib/features/social/presentation/compose_community_post_screen.dart
(class SocialPostEditScreen). Pre-filled with an existing post.
```

### 20 · `/community/posts/:id` · Post Detail
```
Screen 20. Route /community/posts/:id. Frame "20 · /community/posts/:id · Post Detail".
File: lib/features/social/presentation/social_post_detail_screen.dart
One post with 3 comments, one of them with a reply, and the comment input bar.
```

### 21 · `/blog` · Blog Feed
```
Screen 21. Route /blog. Frame "21 · /blog · Blog Feed".
File: lib/features/blog/presentation/blog_feed_screen.dart
Populated with 3–4 articles.
```

### 22 · `/blog/create` · Blog Composer
```
Screen 22. Route /blog/create. Frame "22 · /blog/create · Blog Composer".
File: lib/features/blog/presentation/blog_composer_screen.dart
(class BlogComposerScreen). Empty.
```

### 23 · `/blog/my-posts` · My Posts
```
Screen 23. Route /blog/my-posts. Frame "23 · /blog/my-posts · My Posts".
File: lib/features/blog/presentation/my_posts_screen.dart
Populated with the user's posts (mix of published and draft if supported).
```

### 24 · `/blog/:id/edit` · Edit Blog Post
```
Screen 24. Route /blog/:id/edit. Frame "24 · /blog/:id/edit · Edit Blog Post".
File: lib/features/blog/presentation/blog_composer_screen.dart
(class BlogPostEditScreen). Pre-filled with an existing article.
```

### 25 · `/blog/:id` · Blog Detail
```
Screen 25. Route /blog/:id. Frame "25 · /blog/:id · Blog Detail".
File: lib/features/blog/presentation/blog_detail_screen.dart
Top of an article at default text size.
```

## Section 4 — Learn (Figma page "4 Learn")

All frames show the bottom nav bar with the Learn tab selected, unless the code
hides it (e.g. the lesson player). Tell me if it does.

### 26 · `/learn` · Lesson Catalog (landing screen)
```
Screen 26. Route /learn. Frame "26 · /learn · Lesson Catalog".
File: lib/features/learning/presentation/lesson_catalog_screen.dart
This is where learners land after first run / sign-in. Signed-in state with
some progress. Include the floating buddy if the code shows it here
(lib/features/mascot/presentation/widgets/floating_buddy.dart).
```

### 27 · `/learn/roadmap/:categoryId` · Subject Roadmap
```
Screen 27. Route /learn/roadmap/:categoryId. Frame "27 · /learn/roadmap/:categoryId · Subject Roadmap".
File: lib/features/learning/presentation/subject_roadmap_screen.dart
(class LearningRoadmapScreen). A subject with some lessons done, one current,
the rest locked.
```

### 28 · `/learn/:id` · Lesson Player
```
Screen 28. Route /learn/:id. Frame "28 · /learn/:id · Lesson Player".
File: lib/features/learning/presentation/lesson_experience_screen.dart
First exercise of a lesson. It has internal steps; list the exercise types for
me and ask whether I want extra frames (28a, 28b...).
```

### 29 · `/learn/completion` · Lesson Completion
```
Screen 29. Route /learn/completion. Frame "29 · /learn/completion · Lesson Completion".
File: lib/features/learning/presentation/learning_result_screens.dart
(class LessonCompletionScreen). Use xpEarned 40, a lesson title and category
name, totalExercises 8, needsReview false. Final frame of any animation.
```

### 30 · `/learn/saved` · Saved Lessons
```
Screen 30. Route /learn/saved. Frame "30 · /learn/saved · Saved Lessons".
File: lib/features/learning/presentation/saved_lessons_screen.dart
Populated with 3–4 saved lessons.
```

## Section 5 — AI (Figma page "5 AI")

### 31 · `/ai` · AI Tutor
```
Screen 31. Route /ai. Frame "31 · /ai · AI Tutor".
File: lib/features/ai/presentation/ai_tutor_screen.dart
Default state with some past chats if the screen lists them. Bottom nav: AI
tab selected.
```

### 32 · `/ai/chat/:id` · AI Chat
```
Screen 32. Route /ai/chat/:id. Frame "32 · /ai/chat/:id · AI Chat".
File: lib/features/ai/presentation/ai_chat_screen.dart
A conversation with 2 user messages and 2 tutor replies, input bar at the
bottom.
```

## Section 6 — Leaderboard (Figma page "6 Leaderboard")

### 33 · `/leaderboard` · Leaderboard
```
Screen 33. Route /leaderboard. Frame "33 · /leaderboard · Leaderboard".
File: lib/features/leaderBoard/presentation/leaderboard_screen.dart
Populated ranking with the current user visible. Bottom nav: Leaderboard tab
selected.
```

## Section 7 — Profile (Figma page "7 Profile")

### 34 · `/profile` · My Profile
```
Screen 34. Route /profile. Frame "34 · /profile · My Profile".
File: lib/features/userProfile/presentation/user_profile_screen.dart
Populated signed-in profile. Bottom nav: Profile tab selected.
```

### 35 · `/profile/setup` · Profile Setup Overview
```
Screen 35. Route /profile/setup. Frame "35 · /profile/setup · Profile Setup".
File: lib/features/userProfile/presentation/profile_setup_overview_screen.dart
```

### 36 · `/profile/edit` · Edit Profile
```
Screen 36. Route /profile/edit. Frame "36 · /profile/edit · Edit Profile".
File: lib/features/userProfile/presentation/edit_profile_screen.dart
Pre-filled with the same user as frame 34.
```

### 37 · `/profile/settings` · Settings
```
Screen 37. Route /profile/settings. Frame "37 · /profile/settings · Settings".
File: lib/features/userProfile/presentation/profile_settings_screen.dart
Default settings, light mode.
```

### 38 · `/profile/:userId` · Public Profile
```
Screen 38. Route /profile/:userId. Frame "38 · /profile/:userId · Public Profile".
File: lib/features/userProfile/presentation/public_profile_screen.dart
Another user's profile (not the signed-in user). This route is outside the app
shell, so no bottom nav bar unless the code adds one.
```

---

# Phase 2 — Reusable components + Light/Dark mode

Run this **after all 38 screens are done**, one prompt at a time, in order.
The order matters: colors become variables first, components are built on
those variables, then the screens use the components, and only then does dark
mode work everywhere with one switch.

The app already has a real dark theme: `RiksaPalette.light` and
`RiksaPalette.dark` in `lib/core/theme/app_theme.dart` (plus
`RiksaFeatureColors` and `RiksaSemanticColors`, each with `light`/`dark`).
Figma must use those exact values, not invented dark colors.

## Prompt 39 — Audit (read-only)
```
Phase 2, step 39. Do NOT change anything in Figma yet.
Go through all 38 frames and give me:
1. Every hard-coded color used, grouped by which RiksaPalette / RiksaFeatureColors
   / RiksaSemanticColors token it matches in lib/core/theme/app_theme.dart.
   List any color that matches NO token.
2. Every element that repeats across 2+ frames (buttons, inputs, cards, chips,
   tabs, app bars, list rows, avatars, badges, bottom nav, sheets, empty states…)
   with the frames it appears in and the Dart widget it comes from
   (check lib/core/widgets/ first, then feature widgets/ folders).
3. Every text style used, matched to the theme's text styles.
Output this as a table. This list is the plan for the next steps.
```

## Prompt 40 — Variables with Light and Dark modes
```
Phase 2, step 40. Create the design tokens as Figma variables.
Source: lib/core/theme/app_theme.dart.

- Collection "Color" with TWO modes: "Light" and "Dark".
  - One variable per RiksaPalette field (canvas, surface, surfaceRaised, ink,
    inkMuted, inkFaint, outline, jade, jadeStrong, jadeSoft, onJade, saffron,
    saffronSoft, blushSoft, creamSoft, math, science, language, technology,
    humanities, general, brand, brandStrong, brandSoft, onBrand, anchor,
    onAnchor). Light value from RiksaPalette.light, Dark from RiksaPalette.dark.
  - Groups "feature/…" and "semantic/…" for every field of RiksaFeatureColors
    and RiksaSemanticColors, again light/dark from the code.
  - Name them with slashes so they group: "surface/canvas", "text/ink",
    "brand/brand", "semantic/success", etc. Keep the Dart field name visible
    in the variable description.
- Collection "Size" (one mode): spacing and radius values the code uses
  (read the theme and lib/core/widgets for the constants).
- Text styles for every theme text style, with the real fonts.
- Keep the old color styles until step 44, then delete them.
Report every token you created with its light and dark values.
```

## Prompt 41 — Component library page
```
Phase 2, step 41. Create a Figma page "0 Components" and build the reusable
components from the step-39 list. Rules:
- Every fill, stroke and text color is BOUND to a "Color" variable. No raw hex.
  Spacing and radius bound to "Size" variables where possible.
- Match the Dart widget exactly: read its file before building it.
  Start with lib/core/widgets/: riksa_components.dart (RiksaSearchField,
  RiksaPastelCard, RiksaStateView, RiksaPageHeader, RiksaSkeleton,
  LessonCardSkeleton, IllustratedEmptyState), riksa_search_bar.dart,
  riksa_segmented_tabs.dart, riksa_glass.dart, riksa_avatar_image.dart,
  riksa_rank_badge.dart, riksa_bottom_navigation_bar.dart, language_toggle.dart,
  riksa_logo.dart / riksa_brand.dart. Then the repeated feature widgets
  (post card, lesson card, community card, comment row, chat bubble, etc.).
- Use variants for real states the code has: e.g. Button → type
  (primary/secondary/text), state (default/pressed/disabled/loading);
  Input → state (empty/filled/focused/error); Tab → selected true/false;
  Bottom nav → active tab (home/learn/ai/leaderboard/profile).
- Use component properties for text, icon swap and boolean show/hide, so
  instances are edited without detaching.
- Use auto layout everywhere so components resize with their content.
- Lay the page out in labeled sections (Buttons, Inputs, Cards, Navigation,
  Feedback, Avatars & Badges, …). Add each component's Dart file path to its
  description.
Tell me the full list of components and variants you created.
```

## Prompts 42a–42g — Swap screens to use the components (one section each)
Send one per section so each change is small enough to check.
```
Phase 2, step 42a. On page "1 Launch & Onboarding" (frames 01–06):
replace every hand-drawn copy of an element that now exists on "0 Components"
with an INSTANCE of that component, set to the right variant and properties.
Rebind any remaining fill, stroke or text color to a "Color" variable.
The frames must look identical before and after: compare each frame and
fix any difference. Report what you swapped and any leftover raw hex values.
```
Then send the same prompt with only the page and frames changed:

| Step | Page | Frames |
|---|---|---|
| 42b | 2 Auth | 07–11 |
| 42c | 3 Home · Social · Blog | 12–25 |
| 42d | 4 Learn | 26–30 |
| 42e | 5 AI | 31–32 |
| 42f | 6 Leaderboard | 33 |
| 42g | 7 Profile | 34–38 |

## Prompt 43 — Dark mode frames
```
Phase 2, step 43. On every page 1–7, duplicate each frame and place the copy
directly BELOW the original (same x, 120px gap). Rename it with " · Dark" at
the end. On each copy set the "Color" variable mode to "Dark" at the frame
level. Do not recolor anything by hand; if something looks wrong in dark,
the cause is a raw color or a missing binding, so fix the binding
(in the component, not the instance) and tell me.
Check images and illustrations: if the Dart code swaps an asset or changes
opacity in dark mode (search for Brightness.dark / isDark in the screen and
widget files), do the same. Report anything that still looks wrong.
```

## Prompt 44 — Final QA
```
Phase 2, step 44. Check the whole file and report:
1. Any fill/stroke/text color not bound to a variable (list frame + layer).
2. Any detached instance, or hand-drawn element that should be an instance.
3. Any component not used anywhere, and any variant nobody uses.
4. Light vs dark: for each of the 38 pairs, anything with low contrast in dark
   (text under 4.5:1 against its background).
Fix 1 and 2. Only list 3 and 4 for me. Then delete the old color styles that
step 40 replaced, if nothing uses them.
```

**Tip:** to show dark/light as a switch in prototypes too, you only need the
variable modes: select any frame and change the "Color" mode in the right
panel.

---

# Phase 3 — One page + clickable prototype

Run **after Phase 2** (so every color is already a variable and dark mode
works). Save a Figma version first.

## Prompt 45 — All screens on one page
```
Phase 3, step 45. Create a page "App" and MOVE (not copy) every screen frame
from pages 1–7 onto it, light and dark. Keep "0 Components" as its own page.
Layout:
- One horizontal row per section, in route order (01 → 38), 80px apart:
  Row 1 Launch & Onboarding, Row 2 Auth, Row 3 Home · Social · Blog,
  Row 4 Learn, Row 5 AI, Row 6 Leaderboard, Row 7 Profile.
- Each section's Dark frames sit directly under its Light frames.
- Put a large text label at the left of each row with the section name, and
  wrap each section in a Figma Section named after it.
- 400px vertical gap between sections.
Then delete the now-empty pages 1–7. Confirm the count: 38 light + 38 dark
frames (plus any 04a/28a extras), and that no instance lost its component link.
```

## Prompt 46 — Clickable prototype (follow the real app navigation)
```
Phase 3, step 46. Wire the LIGHT frames on page "App" into a prototype that
behaves like the app. The navigation must come from the code, not guesses:
- Read lib/app/router/app_router.dart and search lib/ for context.go(,
  context.push(, context.pop(, router.go( and GoRouter calls. For each screen,
  list which element leads to which route.
- Add a prototype interaction on that element in Figma:
  context.go → "Navigate to" (instant or dissolve),
  context.push → "Navigate to" with Slide in from right,
  pop / back button → "Back".
- Bottom nav bar: in the bottom-nav COMPONENT, link each tab to its tab root
  (Home → 12, Learn → 26, AI → 31, Leaderboard → 33, Profile → 34), so every
  screen's nav works at once.
- Sheets and dialogs are not frames, so skip those taps.
- Starting point: frame 01 Splash, flow name "First run".
  Add a second flow "Signed in" starting at 26 Lesson Catalog.
- Theme switch: in 37 Settings, if the code has a theme/dark-mode control, give
  it the action "Set variable mode → Color: Dark" (and Light for the other
  option), so the whole prototype switches theme live.
Then copy the same interactions onto the Dark frames, or set the Dark frames'
flow to start at 01 · Dark.
Report a table: frame → element → destination, plus any route you could not
connect and why.
```

## Prompt 47 — Prototype check
```
Phase 3, step 47. Walk both flows in presentation order and report:
1. Frames that cannot be reached from any flow start.
2. Frames with no way back or forward (dead ends) that the real app doesn't have.
3. Any interaction pointing to the wrong frame compared with the code.
Fix what you can and list the rest.
```
