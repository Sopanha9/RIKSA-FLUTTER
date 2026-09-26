# Figma Make — design exploration prompts

> These explore two screens before any Dart is written. Figma Make outputs
> React, so **nothing here ships**. The output is a reference to build against,
> not a source to port. Tokens below are copied from
> [app_theme.dart](lib/core/theme/app_theme.dart) so what comes back is in our
> system rather than Figma defaults.

## Vocabulary rule

**The app never says "STEM", "Grade 12", or names a specific exam in its own
chrome.** Those are institutional words; no student describes themselves that
way. The product is general — the onboarding already offers foundations for
grades 9–11 and a general-curiosity track alongside exam prep, so the narrow
framing lives only in the copy and the docs, not in the product.

What stays specific is the *student's* screen. Whatever destination they chose
in step 1 is the destination their roadmap shows, with a real countdown to it.
General vocabulary, specific experience. Never a generic "keep learning!" —
always their own named goal.

## Before you start

**Fonts.** Poppins and Koulen are both on Google Fonts, so Make can load them.
**Khmer OS Siemreap is not** — use `Noto Sans Khmer` as the stand-in and treat
any Khmer line length you see as approximate. Koulen has one weight only; if
the output shows bold Koulen, it is faking it and the real screen will differ.

**Credits.** A full generation costs far more than an edit. One loaded prompt
then targeted follow-ups ("make the numeral 2x larger", "remove the card
shadow") is much cheaper than re-prompting from scratch. Budget roughly 3–4
full generations and spend the rest on edits.

**Ask for one screen, not an app.** Every extra screen is billed work we throw
away.

---

## Prompt 1 — The completion moment (build this first)

```
Design a single mobile screen, 390x844, for a learning app used by secondary
school students in Cambodia. This is the screen shown the instant a student
finishes a lesson. It is the emotional high point of the entire product and
currently does not exist.

CONCEPT: This screen is drenched — a dark full-bleed ground, in deliberate
contrast to the rest of the app which is white with pastel cards. It should
feel like the lights dimming for one moment. The student should feel they
placed a stone on a path toward a goal they chose themselves, not that they
won a prize.

COLOR — use these exact values and no others:
- Full-screen background: #1D1533 (deep aubergine-ink, never pure black)
- The one big number: #D5F06A (lime)
- Primary action button: #7657EE (violet), white label
- Secondary text on dark: #FFFFFF at 70% opacity
- Optional single accent surface: #EDE8FE (pale lavender)

TYPE:
- Display numeral: Poppins, 56px, weight 800, line-height 1.05
- Heading: Poppins, 22px, weight 600
- Body: Poppins, 16px, weight 400, line-height 1.55
- Show a Khmer variant of the heading in Koulen and body in Noto Sans Khmer

CONTENT:
- One large lime numeral: the count of lessons completed on their path
- A short honest line under it, for example "Chapter 3 complete" — factual,
  not congratulatory
- A visual roadmap: a vertical path of stones/nodes rising toward a labelled
  destination marker. That marker shows the goal THIS student chose when they
  signed up, plus a real countdown — treat the label as dynamic text, and use
  "My exam · 118 days" as placeholder copy only. The stone just completed is
  filled and is the visual focus. Stones ahead are outlined and dim.
- Primary button: "Continue"
- A quiet text link: "Back to path"

HARD RULES — the product spec bans these outright:
- NO mascot, NO character, NO confetti, NO particles, NO celebration burst
- NO trophy, medal, badge, star-rating or flattering exclamation language
- NO gradient on text and NO gradient on content cards. A subtle gradient on
  the full-bleed background only is acceptable.
- NO streak flames or fire emoji
- Do NOT use the words "STEM", "Grade 12", or any specific exam name
- Nothing rounded beyond 24px radius
- Restraint is the brief. If it looks like Duolingo, it is wrong.

Give me 2 layout directions: one where the numeral dominates and the roadmap
is a small strip, one where the roadmap dominates and the numeral is small.
```

---

## Prompt 2 — Onboarding step 5 (the produced answer)

Run this *after* Prompt 1, so the payoff already exists to design toward.

```
Design a single mobile screen, 390x844, the fifth step of a 7-step first-run
flow for a learning app used by secondary school students in Cambodia. The
four previous steps collected: the student's own goal, starting subject,
province, and daily study pace.

CONCEPT: Every competitor opens with a multiple-choice quiz. We are doing the
opposite. This app is about reading and reflecting, not selecting from four
options — so the student's very first interaction must be producing something
in their own words, not tapping a letter. Nothing is graded. The point is that
they leave onboarding having already made something that belongs to them.

LAYOUT:
- A slim progress indicator at top showing step 5 of 7
- A real worked maths example presented as a small card on a pale surface:
  the problem "y = 3x + 5", with the solution steps shown and the answer given.
  The student is NOT solving it.
- Below it, the question: "In one sentence — what makes a problem like this
  hard for you?"
- A free-text input, 3 lines, with a soft placeholder
- A small AI assistant cameo: a single compact row, an avatar disc with the
  label "Kru AI", saying it will remember this. Keep it understated — a quiet
  helper, not a chat bubble takeover.
- Primary button "Continue", plus a low-emphasis "Skip" text link

COLOR — exact values only:
- Page background: #FFFFFF
- Worked-example card: #DDEFFB (pale blue)
- Kru AI row surface: #EAE4FD (pale lavender)
- Primary button: #7657EE (violet), white label
- Body text: #1D1533   Secondary text: #6E6886
- Input border: #6E6886 at 30%, focus border #7657EE

TYPE:
- Question heading: Poppins 22px weight 600
- Body and input: Poppins 16px weight 400, line-height 1.55
- Show the question also in Khmer using Koulen for the heading

HARD RULES:
- NO mascot, NO confetti, NO gradients on cards
- NO multiple choice, NO A/B/C/D letters, NO right-answer indication anywhere
- Do NOT use the words "STEM", "Grade 12", or any specific exam name
- The free-text field must not feel like homework — it should read as low
  stakes and genuinely skippable
- Max 24px corner radius

Give me 2 directions: one where the worked example is large and the input is
compact, one where the input is the hero and the example is a collapsed
reference.
```

---

## What to look for in the output

Judge these, and ignore everything else:

1. **Does the dark screen feel confident or gloomy?** That is the whole G3 bet
   from [GENZ_RESEARCH.md](GENZ_RESEARCH.md). If it reads gloomy, the answer is
   more lime and more white space, not a lighter ground.
2. **Is 56px actually too big?** This is the cheapest possible test of the
   `displayXL` proposal. Try 48 and 64 as edits.
3. **Does the free-text field feel like work?** This is the one real risk in
   Option B from [ONBOARDING_REVIEW.md](ONBOARDING_REVIEW.md). If it does,
   the fix is usually the placeholder copy, not the field.
4. **Does Khmer break the layout?** Koulen runs taller. Any heading that only
   just fits in Latin will wrap in Khmer.
5. **Does the destination marker survive being generic?** If the roadmap only
   reads well when the label names a specific exam, the personalised version
   will feel weaker and we need to know that now.

Do **not** judge: exact spacing, shadow values, or icon style. Those are
Figma Make defaults and are not decisions we are making here.

---

## Copy cleanup this implies (not Figma work)

Found while pulling tokens. Independent of whatever the designs come back as:

| Where | Current | Problem |
|---|---|---|
| `app_en.arb` `splashDescription` | "Your Grade 12 STEM learning companion…" | First sentence anyone reads |
| `app_en.arb` `gradeStemLabel` | "Grade 12 · STEM" | Both banned words |
| `app_en.arb` `noSubjectsYet` | "No STEM subjects yet" | Jargon |
| `app_en.arb` `everySubjectFinishedBody` | "…the whole Grade 12 STEM syllabus." | Jargon |
| `app_en.arb` `examDestination` | "Bac II · Grade 12" | Should be the student's own goal |
| `app_en.arb` `readyForExam` | "Ready for Bac II" | Should be the student's own goal |
| `ai_study_coach_hub.dart:71` | "Grade 12 BakII Prep" | Also misspelled |
| `lesson_experience_screen.dart:1326,1340` | fallback `"STEM Lesson"` | Sent to the AI as context |

Also: the exam is spelled four ways across the codebase — `BakII`, `BacII`,
`Bac II`, `បាក់ឌុប`. Worth normalising wherever it survives the rewrite.

Khmer replacements for these are on the team, not on Claude — see
[KHMER_TODO.md](KHMER_TODO.md).
