# Riksa — First-Run & Lesson Loop: Audit Check and Execution Blueprint

> Checks an external UX audit (scored 3/10) against the code on
> `feat/buddy-first-run` @ `06d0f5f`, then gives a step-by-step plan an agent
> can run. Read alongside [ONBOARDING_REVIEW.md](ONBOARDING_REVIEW.md) and
> [PRODUCT.md](PRODUCT.md). Nothing in `lib/` has been changed yet.

---

## Part 1 — Is the audit right?

### Verdict

**Mostly right, and in places it is too kind.** The diagnosis holds. One of
its three fixes (replace reflections with MCQ drills) contradicts this team's
own product rules and should not be done as written.

| Claim | Verdict | Evidence |
|---|---|---|
| 12+ taps before value | **True, and understated** | The shortest path is about **19 taps**: Get Started (1) → 3 intro pages (3) → buddy (1) → language (1) → 7 setup steps, each a pick plus Next (13). Then you reach an auth screen, not content. |
| Forced mascot naming | **Exaggerated** | The name field is pre-filled with the species' default name (`mascot_select_screen.dart:39`), so one tap moves on. The *screen* is required. Naming is not. |
| Screen-locking `Future.delayed` | **Partly true, overstated** | `mascot_select_screen.dart:70` waits 1.1 s after the tap and does nothing else (skipped under reduced motion). `splash_animation_screen.dart:41` enforces a 1.5 s minimum splash. They are annoying but they do not lock the screen. The 350 ms `Timer` in `onboarding_splash_screen.dart:211` only staggers an animation and blocks nothing. |
| Pop quiz has zero state impact | **True, and the problem is wider** | `onboarding_provider.dart:95-103` awards XP and `:120` saves it to `riksa_onboarding_earned_xp`, but **nothing in `lib/` ever reads that key**. The same is true of `goal`, `subject` and `pace`. Setup only changes anything downstream through province and locale. Four of seven steps collect data nothing uses. |
| Immediate hard auth wall | **True** | `app_router.dart:81`: `if (!isLoggedIn && !isAuthRoute && !isPublicRoute) return '/auth/login';`. The last setup step leads to `/auth/telegram` (`interactive_onboarding_screen.dart:122`). The backend does **not** require this: `GET /api/v1/lessons/**`, `/learning/**` and `/categories/**` are `permitAll` (`RIKSA/src/main/java/com/riksa/auth/security/SecurityConfig.java:50-52`). The wall exists only in the client. |
| Lands on social feed, not curriculum | **True** | `app_router.dart:143-144`: branch 0 `/home` → `SocialFeedScreen`. Learn is branch 1 (`:223`). This also contradicts PRODUCT.md's own "Current direction": *"Older sections … that describe Home as the full social feed … are historical."* |
| Lesson forces typed reflections | **True, and the audit missed the worse one** | Reflection: the Save button is disabled while `_reflection.text.trim().isEmpty` (`lesson_experience_screen.dart:630`, `:783`). **Missed:** every multiple-choice or true/false exercise hides its choices until the learner types working into a 3-6 line `TextField` (`:1457-1478`). "Compare answers" stays disabled while `working.isEmpty` (`:594-597`). That means typing on every exercise, not once per lesson. |

### Architectural bottlenecks

- **Blocking timers:** there are two small ones (1.5 s splash, 1.1 s buddy
  cheer) and no real locks.
- **Network during onboarding:** there are **none**. `commitSetup()` only
  writes to `SharedPreferences`, and the buddy choice is local. The audit's
  concern does not apply.
- **Rigid state preventing guest browsing:** yes, in two places:
  1. the router redirect above;
  2. `splash_animation_screen.dart:72-75` routes to `/auth/login` for anyone
     not `Authenticated`, even after onboarding is finished.
  There is no guest concept in `AuthState` (`auth_provider.dart:42-78`).
- **Stale client rule the server dropped:** the backend's
  `SimpleReflectionValidator` defaults `min-words` to **0** and replaces a
  blank reflection with `"Completed lesson successfully"`
  (`LessonCompletionService.java:56-58`). So the required reflection is a
  **client-only** rule, and so is the "Write at least 10 words" error text at
  `lesson_experience_screen.dart:1866`. It can be relaxed without a backend
  change.

### Where I disagree with the audit's fix

PRODUCT.md, line 42: *"Explicit anti-pattern: QCM / multiple choice as the
core loop … must require the learner to **produce** something."* Line 39 says
completion is *"backed by a written reflection."*

"Replace reflections with MCQ drills" would reverse a documented product
decision. That is a team call, not a refactor. The friction the audit
describes is real, though. The fix below removes the **keyboard
requirement** and keeps the **produce-something** rule:

- Working becomes optional. A one-tap **"Worked it on paper"** option reveals
  the choices. Grade 12 students solve maths on paper anyway, so this is the
  honest version of "produce first".
- The reflection is optional. A one-tap **confidence chip** (Confident /
  Needs review), which already exists at `:520-533`, becomes the only
  required input.

If the team decides MCQ-first is acceptable after all, only Step 4 changes.

### Constraints this plan respects

- **Do not touch `lib/core/widgets/riksa_bottom_navigation_bar.dart`** or its
  goldens. A teammate owns it. This rules out reordering the shell branches:
  the bar's item order and icons are tied to branch indices. Learn becomes the
  **landing tab** without becoming index 0. The effect for the user is the
  same.
- Competition deadline: every step is contained and reversible, and no
  1,800-line screen gets split.

---

## Part 2 — Execution blueprint

Run the steps in order. Each ends with a check that must pass before the next
one starts. Commands:

```bash
flutter analyze
flutter test
```

### Step 1 — Land on Learn, not the feed

**Goal:** a signed-in user (and later a guest) lands on `/learn`, and the
community feed stays one tab away.

**`lib/app/router/app_router.dart`**

1. Add a single constant beside the providers:
   ```dart
   /// Where a learner lands after first run or sign-in. The study loop is the
   /// product; the community is one tab away.
   const kLandingLocation = '/learn';
   ```
2. `:82`: `if (isLoggedIn && (isAuthRoute || isLanguage)) return '/home';`
   → `return kLandingLocation;`
3. `:86`: `GoRoute(path: '/', redirect: (_, _) => '/home')` →
   `kLandingLocation`.
4. Leave branch order and `/home → SocialFeedScreen` **unchanged** (see
   Constraints).

**Other `context.go('/home')` calls after auth or setup.** Change each one to
`kLandingLocation` (import from the router):

- `lib/features/auth/presentation/splash_animation_screen.dart:73`
- `lib/features/auth/presentation/province_select_screen.dart:60, :80`
- Run `grep -rn "go('/home')" lib` and change every one reached **after
  sign-in or setup**. Leave any that mean "open the feed" alone, such as a
  "Community" button.

**Tests**

- `test/app/router/app_router_test.dart`: add *"authenticated user hitting
  /auth/login is redirected to /learn"* and *"/ redirects to /learn"*.
- Update any test that asserts `/home` after login
  (`test/features/auth/presentation/auth_journey_test.dart`: grep `'/home'`).

**Check:** analyze clean, tests green. A fresh sign-in opens the Learn tab
with the Learn item highlighted in the nav bar.

---

### Step 2 — Guest mode and deferred auth

**Goal:** a new user can browse the syllabus and open lessons without an
account. Auth is asked for only when an action needs a server identity.

**2a. `lib/features/auth/providers/auth_provider.dart`**

Do not add a new `AuthState`. The sealed hierarchy is switched over in many
places. Treat `Unauthenticated` as "guest" and gate by route instead.

**2b. `lib/app/router/app_router.dart` redirect (`:59-84`)**

Replace the blanket wall with an allow-list of guest-browsable routes:

```dart
bool _guestCanView(String loc) =>
    loc == '/learn' ||
    loc.startsWith('/learn/roadmap/') ||
    (loc.startsWith('/learn/') &&
        !loc.startsWith('/learn/saved') &&
        !loc.startsWith('/learn/completion'));

// replaces :81
if (!isLoggedIn && !isPublicRoute && !_guestCanView(state.matchedLocation)) {
  return '/auth/login?from=${Uri.encodeComponent(state.uri.toString())}';
}
```

Everything else (`/home`, `/community/*`, `/ai`, `/leaderboard`, `/profile`)
still needs an account. Tapping those tabs as a guest opens the login screen,
which is the deferred prompt.

**2c. Return to where the user came from after login**

`/auth/login` reads `state.uri.queryParameters['from']`. On `Authenticated`,
the redirect at `:82` sends them to `from ?? kLandingLocation`. Accept `from`
only if it starts with `/` and not `//`, so it cannot become an open redirect.

**2d. `requireAccount` helper for in-screen actions**

New file `lib/features/auth/presentation/require_account.dart`:

```dart
/// Sends a guest to sign in before an action that needs an identity, and
/// brings them back afterwards. Returns true if already signed in.
bool requireAccount(BuildContext context, WidgetRef ref, {required String reason}) {
  if (ref.read(authProvider) is Authenticated) return true;
  final here = GoRouterState.of(context).uri.toString();
  context.push('/auth/login?from=${Uri.encodeComponent(here)}&reason=$reason');
  return false;
}
```

Call it at the top of:

- lesson **completion** (`lesson_experience_screen.dart` `_complete`, `:782`),
  reason `save_progress`. Completion is a POST that awards XP and a streak,
  so this is the "streak save" trigger;
- exercise **answer submission** (`_submitAnswer`), same reason. The backend
  needs attempts to be recorded before completion (`LessonCompletionService`:
  "every exercise has a correct attempt");
- community post / question compose entry points, reason `post`;
- lesson **save/bookmark**, reason `save_lesson`.

`AuthSwitcherScreen` can show one line of copy per `reason` (add
`authReason*` keys to `app_en.arb` and `app_km.arb`).

**2e. Screens that assume a user on guest-visible routes**

`lesson_catalog_screen.dart:130-138` watches `authProvider` and
`profileDashboardProvider`. As a guest, guard with
`auth is Authenticated ? … : null` and hide the streak and XP header rather
than calling an authenticated endpoint. Do the same for
`communityStreakProvider` (`:235`). Grep every provider the catalog, roadmap
and lesson screens watch, and confirm each one hits only `permitAll` GETs or
is skipped for guests.

**Tests**

- Router: an unauthenticated user can open `/learn`,
  `/learn/roadmap/<id>` and `/learn/<id>`, and is redirected to
  `/auth/login?from=…` for `/home`, `/profile` and `/learn/saved`.
- Router: after login with `from=/learn/abc`, the user lands on `/learn/abc`.
  `from=//evil.com` falls back to `/learn`.
- Lesson: as a guest, tapping "Check answer" pushes `/auth/login` and makes
  no API POST (use a fake `LearningApi` that fails if called).

**Check:** from a cold start with no account, the user can open a lesson and
read it. Answering the first exercise asks them to sign in, and after sign-in
they are back on the same lesson.

---

### Step 3 — Compress onboarding to three decisions

**Target flow:** Splash (Get Started) → **Language** → **Subject/track** →
Learn tab, showing that subject's roadmap. That is 3 taps, with an optional
buddy pick later.

**3a. Route changes**

- `splash_animation_screen.dart:82-85` `_getStarted`: go to
  `/language-select`. Skip the 3-page intro and the buddy.
- `language_select_screen.dart:58`: already goes to `/onboarding/setup`. Keep
  it.
- `language_select_screen.dart:72` uses the mascot's name in the title. With
  no buddy chosen yet, it falls back to `MascotProfile.defaultName(species)`,
  so no crash. Check that the copy still reads naturally.
- `onboarding_splash_screen.dart` (the 3-page intro) and `/mascot-select` stay
  reachable, but not in the default path. Offer the buddy from the Learn tab
  or the profile drawer as "Pick your study buddy", after the first lesson.
  **Do not delete the screens.** The team built the buddy branch deliberately
  (`feat/buddy-first-run`), and this change only moves it out of the way.

**3b. `interactive_onboarding_screen.dart`: from 7 steps to 1 or 2**

- `_totalPages` `:62` → `2`, `_payoffPage` `:63` → `1`. Order: **Subject**
  (`_SubjectStep`) → payoff/confirm. Goal becomes optional: it can go back as
  a chip row on the subject step if the team wants it, but it must not add a
  page.
- Remove province, pace and both quiz steps from the `switch` at `:315-390`
  and from `_isStepComplete` `:84-95`. Keep the widget classes for now (dead
  but cheap to restore). Mark them `// ignore: unused_element` or remove them
  in a follow-up after judging.
- Make selecting a subject **advance on its own** (call `_next` from the
  `onSelect` at `:1034`), so it costs one tap and not two.
- The payoff step shows "Your {subject} roadmap is ready" with one button,
  **Start learning**. It no longer promises XP that nothing awarded
  (ONBOARDING_REVIEW.md T3).
- `_next` `:122`: `_saveAndNavigate('/auth/telegram')` →
  `_saveAndNavigate(kLandingLocation)`, then call
  `localeProvider.notifier.completeOnboarding()` so the splash does not send
  them back through setup.
- Remove the Google button (`_handleGoogleAuth` `:150-165`) from onboarding.
  Sign-in now happens through `requireAccount` (Step 2d).
- **Province:** it feeds the leaderboard. Ask for it the first time the user
  opens `/leaderboard` or signs up, not during first run. `/province-select`
  already exists as a standalone route, so reuse it.

**3c. Make the subject choice do something**

It is currently never read. In `lesson_catalog_screen.dart`, read
`onboardingProvider.select((s) => s.subject)` and, when it is set, sort that
subject's roadmap card first and give it the primary "Start here" call to
action. Match `OnboardingSubject.id` (`math`, `physics`, `chemistry`,
`biology`; `onboarding_models.dart:53-85`) to `LearningCategory.name`
case-insensitively. **Check the actual category names the backend returns
first** (the V28 seed migration). If they are Khmer or differently worded,
add an explicit `id → categoryId` map instead of matching strings.

**3d. Remove the delays**

- `mascot_select_screen.dart:67-72`: remove the `Future.delayed`. Fire
  `_stage.react(MascotMood.celebrate)` and navigate at once. The celebration
  can play on the next screen's buddy.
- `splash_animation_screen.dart:41`: cut the minimum from 1500 ms to 600 ms.
  The 1100 ms entrance animation already covers the brand moment, and a
  returning user should not wait for it.

**3e. Drop dead onboarding state**

In `onboarding_provider.dart`, stop saving `earnedXp` (`:120`) and remove
`setQuizAnswer1/2` once the quiz steps are gone. Keep `_xpKey` reads for one
release, or clear the key, so old installs don't keep a stale value.

**Tests**

- `test/features/mascot/mascot_select_screen_test.dart`: remove any
  `pump(Duration(milliseconds: 1100))` waits and assert navigation happens on
  the next frame.
- `test/features/auth/presentation/interactive_onboarding_screen_test.dart`:
  rewrite it for the 2-step flow. Picking a subject leads to the payoff, and
  Start learning leads to `/learn` with the subject saved.
- End-to-end: from a fresh install with a fake clock, Get Started → pick a
  language → pick Physics → Start learning lands on `/learn` with the Physics
  roadmap first. Assert **≤ 4 taps**.

**Check:** fresh install to the first lesson in 4 taps or fewer, with no
screen waiting more than 600 ms.

---

### Step 4 — Lesson loop without the keyboard

**4a. Optional working before choices** (`lesson_experience_screen.dart`)

- In the exercise card, under the working `TextField` (`:1463-1478`), add a
  secondary button, **"I worked it on paper"**
  (`key: ValueKey('lesson-worked-on-paper-${exercise.id}')`). It calls the
  same `onCompare` that the action bar uses.
- In the action bar (`:594-597`): `working.isEmpty ? null : …` →
  always enabled, labelled `l10n.lessonShowChoices` when `working.isEmpty`,
  otherwise `l10n.lessonCompareAnswers`.
- Default the working field to collapsed (a single-line "Add your working
  (optional)" row that expands on tap), so the keyboard never opens unless the
  user asks for it.
- `_complete` (`:793-803`) already includes working only when it is not
  empty. No change needed.

**4b. Optional reflection** (`lesson_experience_screen.dart`)

- Required input becomes the confidence chip: `_needsReview != null`.
- `:630`: `_reflection.text.trim().isEmpty ? null : …` →
  `_needsReview == null ? null : () => _complete(detail)`.
- `:783`: guard on `_needsReview == null` instead of the text.
- `:536-542`: replace `lessonReflectionRequired` with
  `lessonConfidenceRequired` ("Tap how it went to finish") and relabel the
  `TextField` hint as optional.
- Move the chips **above** the text field, so the one-tap path comes first
  and the text field is extra.
- `:1865-1866`: delete the stale "at least 10 words" mapping, or reword it to
  a generic message. The server no longer enforces it.
- The payload (`:793`) already sends `[confidence]` plus text. With empty
  text the server stores it and scores it 1, which is correct.

**4c. l10n**

Add `lessonShowChoices`, `lessonWorkedOnPaper`, `lessonConfidenceRequired`
and `lessonReflectionOptionalHint` to **both** `app_en.arb` and
`app_km.arb`. Get the Khmer checked by a native speaker (see KHMER_TODO.md).
Then:

```bash
flutter gen-l10n
```

**Tests** (`test/features/learning/presentation/lesson_journey_test.dart`)

- MCQ exercise: tapping "I worked it on paper" with no typing shows the
  choices.
- Reflection phase: Save is disabled until a confidence chip is tapped, then
  enabled with an empty text field. Completion POSTs, and `reflectionText`
  contains the confidence tag.
- Regression: the typed working and the reflection are still sent when
  present.
- Goldens: `test/visuals/lesson_experience_golden_test.dart` will change.
  Regenerate with `flutter test --update-goldens
  test/visuals/lesson_experience_golden_test.dart` and **review the images**
  before committing. Leave any nav-bar golden failures alone.

**Check:** you can complete a lesson with only taps, never opening the
keyboard.

---

### Step 4b — Buddy picker entry point (done, was missed in Step 3a)

Once first run stopped passing `/mascot-select`, nothing linked to it. Now:
- **Settings → Your buddy** row opens the picker.
- The picker's Continue pops back to where it was opened from. It only
  carries on to `/language-select` when nothing is below it.

Gap: `/profile/settings` needs an account, so a guest still cannot choose a
buddy until they sign in.

### Step 5 — The buddy in the lesson (done)

Decided with the user: **scene header + reactions**, not a full-screen
backdrop. This reverses the old rule that the buddy stays out of reading.

- `_LessonBuddyScene` replaces `_LessonArtCard`. The buddy's pond or park
  scene is a 168dp band above the content, and the lesson text stays on the
  plain canvas. It shrinks to 92dp while answering, so the exercise and its
  feedback stay above the fold.
- Mood follows the phase: idle while reading, thinking while answering, happy
  after a correct answer, celebrate on section passed, happy while
  reflecting. `alive: false`, so there is no fidgeting or dozing beside the
  text. It stays idle when buddy reactions are turned off.
- The answer feedback card shows the buddy's face
  (`BuddyBehavior.answerCorrect` / `answerIncorrect`) in place of the tick
  and bulb icons.
- The lesson test harnesses set `disableAnimations`, as the onboarding tests
  do. The buddy's sprite ticker never settles otherwise.

## Validation checklist (whole change)

- [ ] `flutter analyze`: 0 issues
- [ ] `flutter test`: green, except known nav-bar goldens owned elsewhere
- [ ] Fresh install → first lesson content: **≤ 4 taps**, no auth prompt
- [ ] Guest answers an exercise → sign-in → returns to the same lesson
- [ ] Signed-in cold start lands on `/learn`, Learn tab highlighted
- [ ] Lesson completable with the keyboard never opening
- [ ] Khmer at 200% text scale: onboarding subject step and lesson reflection
      step do not overflow
- [ ] `git diff --stat lib/core/widgets/riksa_bottom_navigation_bar.dart` is
      empty

## Open decisions for the team (not for the agent)

1. **MCQ doctrine.** Step 4 keeps "produce, don't select". If the team wants
   true MCQ drills, that is a PRODUCT.md change first.
2. **Where the buddy goes.** It is off the critical path here. Decide whether
   it appears after lesson 1, in the drawer, or both.
3. **Goal (BacII / STEM / curiosity).** It is not used anywhere today. Drop
   it, or use it to change the catalog.
