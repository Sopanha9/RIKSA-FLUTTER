# Riksa — First-Run Flow Review

> A side-by-side of the onboarding as built against what PRODUCT.md asks for,
> written so the team can decide together. This is a refinement proposal, not
> a deletion proposal. Nothing has been changed in `lib/`.
>
> Supersedes the characterisation in [REDESIGN_PROPOSAL.md](REDESIGN_PROPOSAL.md)
> §P3 on two points of fact — see [Corrections](#corrections-to-the-earlier-review).

---

## What exists today

Built in `0b5ccdb`, 18 Sep 2026. Seven full-screen steps:

| # | Step | State captured |
|---|---|---|
| 1 | Academic target goal | `goal` |
| 2 | Starting subject | `subject` |
| 3 | Province + leaderboard pride | `provinceId` |
| 4 | Daily study pace | `pace` |
| 5 | Challenge question 1 + Kru AI cameo | `quizAnswer1Index` |
| 6 | Challenge question 2 + Kru AI cameo | `quizAnswer2Index` |
| 7 | Streak & XP payoff + 1-tap conversion | — |

Files: `interactive_onboarding_screen.dart` (1,746), `onboarding_models.dart`
(386), `onboarding_provider.dart` (124), plus a 234-line test.

---

## What is genuinely strong here

Worth stating plainly, because the earlier review led with its objections.

- **The first four steps are exactly right.** Goal, subject, province and pace
  are the four things the product needs in order to answer "what should I
  study next?", which PRODUCT.md names as the question the product must answer
  before anything else. Nothing in this proposal touches them.
- **The quiz content is real.** Subject-specific, curated per starting subject,
  and academically honest: the slope of `y = 3x + 5`, solving `2x - 4 = 10`.
  This is Grade 12 STEM, not engagement filler.
- **It is fully bilingual.** Every goal, subject, pace, question and option
  carries both `*En` and `*Km`. The Khmer was written, not deferred.
- **It has a test.** 234 lines, shipped with the feature.
- **Province placement is correct.** Asking it here, tied to leaderboard
  pride, is better motivated than the standalone `/province-select` screen.

---

## The three real tensions

### T1 — Multiple choice is a named anti-pattern

PRODUCT.md:

> "Explicit anti-pattern: QCM / multiple choice as the core loop... Any future
> checking mechanic must require the learner to **produce** something, not
> select something."

Steps 5 and 6 are four lettered options with a `correctIndex`.

**The honest counter-argument:** the rule says *core loop*. Onboarding is not
the core loop. A one-off placement check is arguably a different thing from
teaching by quiz. The team should decide whether it reads that narrowly.

**The honest counter-counter-argument:** whatever the rule says, this is the
first interaction a new student has with Riksa. It teaches them what the
product is. Two multiple-choice questions teach them it is a quiz app.

### T2 — Two questions cannot place a learner

Whatever the mechanic, two questions produce almost no signal. A learner who
guesses both correctly and one who knows both are indistinguishable, and the
result does not change what they are shown next. So the step is not currently
diagnostic — it is pacing.

If it stays, it should either **do something** with the answers, or stop
presenting itself as an assessment.

### T3 — The payoff celebrates something that has not happened

Step 7 reads `'Day 1 Streak Started! 🔥'` with a reward claim, before the
student has read a single lesson. Against:

> "Never cute, never congratulatory beyond what was actually earned."
> "Earned, not thrown. Rewards land at the moment of real completion, at the
> scale of what was done."

A streak that begins before any studying is a streak awarded for installing
an app.

### Secondary: seven steps before any content

PRODUCT.md describes sessions as 5–20 minutes of stolen time. Seven full
screens sit between install and the first lesson.

---

## Three options

### Option A — Keep the quiz, make it earn its place

Keep all seven steps. Change what the quiz *is*:

- Rename it from "Challenge" to a placement check, and say so in the copy.
- **Use the answers.** Route a learner who answers both correctly to a later
  starting unit; route a learner who misses both to the foundations unit.
  This turns T2 from a criticism into the feature's justification.
- Replace step 7's streak claim with a plain statement of the plan: subject,
  unit count, and the first lesson's title.

*Cost:* smallest change. *Risk:* multiple choice stays, so T1 is accepted
rather than resolved. Needs backend support to map a score to a start unit.

### Option B — Swap the mechanic, keep the shape (recommended)

Keep seven steps and the Kru AI cameo. Replace the two multiple-choice
questions with **one short produced answer**:

> "In one sentence, what makes this problem hard for you?"
> *(shown beside a real worked example from their chosen subject)*

Nothing is graded. The answer is stored and becomes the first entry in their
reflection history, so the product's actual mechanic — read and reflect — is
what the student meets first.

- Satisfies T1 directly: the learner produces, not selects.
- Resolves T2: there is no score to be falsely diagnostic about.
- Keeps Phaleap's step structure, the Kru AI cameo, the progress chrome and
  most of the widget tree.
- Step 7 still changes per T3.

*Cost:* moderate; one step rebuilt, one deleted. *Risk:* a free-text field as
the first interaction may feel like work. Mitigate by making it skippable.

### Option C — Four steps, no challenge

The original [REDESIGN_PROPOSAL.md](REDESIGN_PROPOSAL.md) Phase 2: Goal →
Subject → Province + Pace → Auth, landing on a Learn tab that already has a
Continue card.

*Cost:* deletes the most recent work. *Risk:* highest team cost, and it gives
up the Kru AI cameo, which is a genuine differentiator for the Best Innovative
Concept category.

---

## Recommendation

**Option B.** It resolves both PRODUCT.md tensions, keeps the structure and
personality Phaleap built, and preserves the AI cameo. Option C is cleaner on
paper but throws away work that is mostly right, and the four setup steps were
never the problem.

Regardless of which is chosen, two things should happen:

1. **Move the strings to ARB.** The screen is bilingual but localises through
   `*En` / `*Km` model fields and inline `lang == 'km' ? … : …` ternaries
   rather than `AppLocalizations`. Every other feature uses ARB. This is the
   one part of the file that is unambiguously worth changing whatever else is
   decided, and it is mechanical.
2. **Drop `🔥` from UI copy.** Emoji baked into a translated string is a
   localisation smell, and DESIGN.md already bans mascot celebration.

---

## Competition context

The ACLEDA / AUB competition awards **Best UX/UI** and **Best Innovative
Concept** as separate prizes. First run is the first thing a judge sees, and
the Kru AI cameo is a real innovation claim. That argues for refining this
screen rather than removing it — and against leaving the streak-before-study
moment in place, since a judge reading PRODUCT.md alongside the app will see
the contradiction.

---

## Corrections to the earlier review

[REDESIGN_PROPOSAL.md](REDESIGN_PROPOSAL.md) §P3 states two things this review
does not support:

1. **"It is also the app's only unlocalized screen."** Not accurate. The
   screen is fully bilingual; the Khmer exists for every option, question and
   answer. What is true is that it localises through a *different mechanism*
   than the rest of the app. That is an architectural inconsistency worth
   fixing, not missing translation work.
2. **"engagement theater."** The questions are curated Grade 12 STEM content
   per subject. The criticism that two questions cannot place a learner stands;
   the implication that the content is not serious does not.
