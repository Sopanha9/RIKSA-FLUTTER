# Riksa — Product Context

## Register

`product` — Riksa is an app people use repeatedly, not a campaign site. Design
serves the study session; it does not perform.

## Users

**Primary: Grade 12 students in Cambodia preparing for the Bac II exam.**

- 16–19 years old, studying in Khmer and English.
- Mid-range Android phones, small screens, often metered data.
- Study happens in stolen time: late evening after school and private tutoring,
  on the way home, between classes. Sessions are 5–20 minutes.
- The real motivator is not points. It is the exam, and the fear of arriving at
  it unprepared. Gamification is a scaffold for consistency, not the reward.
- Many have no structured revision plan. "What should I study next?" is the
  question the product must answer before anything else.

**Secondary: Riksa content admins** authoring subjects, units, lessons and
reflection prompts through `riksa_admin` (separate React/Vite project).

## Product purpose

Give a Grade 12 STEM student a clear, ordered path through the year's syllabus,
and make it possible to move one honest step along that path in fifteen minutes.

Scope today: STEM only (Mathematics, Physics, Chemistry, Biology, Computer
Science / Technology), Grade 12, Cambodia.

## Learning model

Riksa teaches by **read and reflect**, not by quiz.

- A lesson is a short piece of written explanation the student reads.
- The student then answers in their own words: what they understood, where they
  are still unsure.
- Completion is self-declared understanding, backed by a written reflection,
  not a score out of ten.

**Explicit anti-pattern: QCM / multiple choice as the core loop.** Multiple
choice teaches students to recognize an answer, not to hold an idea. It also
makes every lesson feel identical. Any future checking mechanic must require
the learner to produce something, not select something.

XP is earned per completed lesson. Streaks count days with at least one
completed lesson. Both are quiet consequences of studying, never the headline.

## Structure

```
Subject (Mathematics)
  └── Unit (ordered chapter of the Grade 12 syllabus)
        └── Lesson (5–15 min read + reflection)
```

The subject roadmap is the spine of the product. It must always answer three
questions on sight: where I started, where I am, where this ends.

## Tone

Serious, warm, unpatronizing. Speaks to someone doing real work under real
pressure. Never cute, never congratulatory beyond what was actually earned.
Khmer and English are equals, not a translation layer bolted on.

## Anti-references

- **Duolingo.** Mascots, streak guilt, cartoon celebration, streak-freeze
  economics. Riksa is exam preparation, not a language game.
- **Uniform card feeds.** Not pastel cards, which are right for Riksa, but
  *identical* ones: a vertical stack of same-sized rounded rectangles in one
  pastel family, each with a chip, a title and a circular arrow button. This is
  what the learning tab currently is, and the reason it reads as flat: every
  lesson looks equally important, colour carries no state, and nothing tells the
  student where they are in the year.
- **Editorial spec-sheet minimalism.** Hairline rules, mono labels, tabular
  columns, restrained neutrals. Correct for a design system document, wrong for
  Riksa. The product is playful.
- **SaaS dashboard gamification.** Big-number hero tiles, badge shelves, XP as
  the dominant visual element.
- **Generic MOOC catalog.** Search-and-browse as the primary metaphor. Riksa's
  primary metaphor is a path, not a library.

## Strategic principles

1. **The path is the product.** One dominant answer to "what next" on every
   screen. Browsing is secondary.
2. **Show the destination.** Progress is only meaningful against a visible end:
   the finished syllabus, the exam.
3. **Difference means difference.** Two lessons that look alike should be alike.
   Current, done, locked, and up-next must be legible from across the room.
4. **Reading deserves the whole screen.** Lesson content is the one place where
   product chrome retreats entirely.
5. **Earned, not thrown.** Rewards land at the moment of real completion, at the
   scale of what was done.
6. **Khmer-first typography.** Long Khmer titles, Koulen display, Kantumruy body.
   Layouts must survive text that is 40% longer and taller than the English.
7. **Cheap phone, tired student.** High contrast, large touch targets, works at
   360dp, readable under a fluorescent tube at 9pm.
# Current direction (September 2026)

> **Note:** The signed-in product is being rebuilt around a daily study loop,
> province/community proximity, and the learner's chosen buddy. Older sections
> below that describe Home as the full social feed or treat features as an
> equal-weight dashboard are historical and must not override that direction.
