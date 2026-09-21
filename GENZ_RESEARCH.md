# Riksa — Gen Z Design Research

> Research pass against [DESIGN.md](DESIGN.md) and [PRODUCT.md](PRODUCT.md),
> plus external research on 2026 Gen Z design conventions and the Cambodian
> mobile context. Nothing in `lib/` was modified to produce this document.

---

## 0. Verdict first

**The system's *behaviour* rules are already Gen Z correct. Its *aesthetic* is
three years behind.**

There is an assumption worth naming before anything else, because the whole team
is probably carrying it:

> "We are anti-Duolingo, so we cannot be Gen Z."

This is false, and it is the most expensive idea in the project. Mascots,
confetti, streak guilt and reward-claim theatre are **millennial-era
gamification** (2012–2018). They are not the Gen Z aesthetic. Research on 2026
conventions points the other way: bold expressive typography, high contrast,
saturated colour, authenticity over polish, and a visible payoff for the user's
actual goal.

PRODUCT.md's anti-references are *correct and should stay*. But DESIGN.md has
quietly translated "not Duolingo" into "quiet, soft, restrained", and those are
different things. Riksa is currently **tasteful and low-energy**. Gen Z reads
low-energy as institutional.

The fix is not to add cartoons. It is to raise contrast, weight and typographic
confidence while keeping every behavioural rule exactly as written.

---

## 1. What the research says

### Gen Z aesthetic conventions, 2026

| Convention | Riksa today | Gap |
|---|---|---|
| Bold / expressive typography as the graphic element | Poppins, `displayLarge` 36 | **Large** |
| High contrast, saturated colour | Pastel surfaces, one violet | **Medium** |
| Soft-tech pastels (still current) | Yes, well executed | None — keep |
| Dark mode as a first-class surface | Neutral graphite, well built | None — keep |
| Authenticity over perfection | Serious, warm tone | None — keep |
| Outcome legible immediately | "The path is the product" | None — keep |

Gen Z's stated preference is for design that carries **emotion and identity**,
and against design that reads as a template. Four of six axes Riksa already
holds. The two it misses are both typographic and chromatic *confidence*, not
behaviour.

### The Cambodian context

Two findings that affect the brief directly:

1. **73% of Cambodian smartphone users are 18–24.** Riksa's stated primary user
   is not a niche inside the market — it is the market's centre of mass.
2. **Mobile data is roughly US$1 per 10GB, among the cheapest in the region.**

Point 2 contradicts PRODUCT.md, which states users are *"often on metered
data"* and uses that to justify restraint. That assumption is worth
re-verifying. If it is stale, Riksa has been under-investing in imagery,
illustration and motion to satisfy a constraint that no longer binds. The
*"cheap phone"* half of principle 7 still holds — mid-range Android GPUs are a
real limit. The *"metered data"* half may not.

---

## 2. The five concrete gaps

Ranked by how much each one moves the needle.

### G1 — Poppins is the single loudest "2019 template" signal in the app

`RiksaTypography.latinFamily = 'Poppins'` ([app_theme.dart:439](lib/core/theme/app_theme.dart#L439)).

Poppins and Montserrat are now specifically associated with free templates and
budget projects through extreme overuse. The geometric sans-serifs that defined
the 2010s are being replaced by humanist and expressive alternatives. For a
competition judge who looks at a lot of student projects, Poppins is the fastest
possible read of "default choice".

**Candidates**, all free and all Khmer-pairable:

| Face | Character | Fit |
|---|---|---|
| **Space Grotesk** | Squared curves, technical, open apertures | Strong — STEM register without sterility |
| **Sora** | Geometric with brand character | Strong |
| **Outfit** | Modern geometric, closest to Poppins | Safe swap, smallest gain |
| **Plus Jakarta Sans** | Contemporary workhorse | Good body, less display presence |
| **Hanken Grotesk** | Friendly humanist | Good body |

**Recommendation: Space Grotesk for display + Plus Jakarta Sans for body.**
Space Grotesk's technical feel suits a STEM exam product and gives the display
scale actual personality; Jakarta is a calmer reading face for lesson copy.

**Hard constraint the team must respect:** whatever is chosen has to sit beside
**Koulen** (display) and **Khmer OS Siemreap** (body). Koulen has one weight and
runs taller. Any Latin face with a very low x-height or tight leading will
diverge visibly from Khmer in mixed strings. `RiksaTypography.titleStyleFor`
already handles the per-script swap, so the machinery exists — but every Khmer
golden must be re-reviewed after the change, not just regenerated.

### G2 — The type scale is too timid for the aesthetic

`displayLarge` is **36 / 700**. In current Gen Z work, display type *is* the
graphic element, frequently 48–72 on mobile. Riksa's largest step is smaller
than many apps' headline.

DESIGN.md already reserves `displayLarge` for "the one big number on an earned
screen" — that restraint is right. But when the budget is one big moment per
flow, **that moment should actually be big.** A 36pt number is a heading, not an
event.

**Proposal:** add `displayXL` at 48–56 / 700–800, used only where `displayLarge`
is used today, and let `displayLarge` drop back to a section-opening role. This
is additive, touches one earned screen, and costs nothing elsewhere.

### G3 — There is no high-contrast counterpoint

The palette is pastel surfaces + `ink` text + one saturated violet. Well built,
and "soft-tech pastels" is genuinely a current direction — so this is **not**
wrong. But an all-pastel system has no top end. Everything sits in the same
tonal band, which is why the app reads as calm rather than confident.

`anchor` (`#1D1533`) and `onAnchor` already exist as the dark counterpoint and
are barely used. DESIGN.md mentions "one drenched screen per flow" — that is
exactly the right instrument, and it is under-deployed.

**Proposal:** no new colours. Use `anchor` deliberately — the earned/completion
screen, and one focal surface per major flow. Dark ground, lime `#D5F06A`
numeral, violet action. That combination is high-contrast, on-brand, and
unmistakably contemporary.

### G4 — The gradient ban is now too broad

DESIGN.md bans gradients outright. Expressive gradient transitions have returned
as a mainstream 2026 direction, and `profile_cover.dart` **already ships eight
gradient sets** — so the ban is already violated in the one place it would
actually be appropriate.

**Proposal:** narrow the ban rather than lift it. Keep "no gradient text" and
"no gradient on content cards" — those genuinely hurt legibility and flatten
hierarchy. Allow gradient on identity surfaces only: profile covers, the earned
screen, community banners. Then move `profile_cover.dart`'s eight hardcoded sets
into theme tokens so the exception is governed instead of accidental.

### G5 — Motion is correct but has no signature

`RiksaMotion` (100 / 200 / 550 / 650, `easeOutCubic`, 30ms stagger) is
well-reasoned and consistently applied. `RiksaCountUp` and "values arrive, they
do not appear" is a genuinely good principle that most competition entries will
not have.

What is missing is one **memorable** motion — the thing a judge remembers ninety
seconds after closing the app. `easeOutBack` is already reserved for lesson
completion, which is the right slot. It is just not doing much there.

**Proposal:** invest in exactly one moment — lesson completion. Not confetti,
not a mascot. The roadmap stone filling and the path visibly extending toward
the exam. That is on-thesis ("show the destination"), it is earned, and it is
the kind of thing that gets described out loud by a judge to another judge.

---

## 3. What must not change

Research actively supports keeping these. They are competitive advantages, not
conservatism:

- **No mascot, no confetti, no streak guilt.** Gen Z reads performative
  celebration as patronising. PRODUCT.md is right and ahead of the trend.
- **Read-and-reflect over multiple choice.** Produce, not select.
- **Khmer-first typography.** Nothing in the redesign may regress this. It is
  the strongest thing in the codebase.
- **Earned, not thrown.**
- **"The path is the product."** Gen Z research is unambiguous that every
  feature must visibly serve the outcome the user came for.
- **The neutral dark mode.** Correct, and Gen Z skews dark-default.

---

## 4. Proposed order

| # | Work | Risk | Effort |
|---|---|---|---|
| 1 | Swap Poppins → Space Grotesk + Plus Jakarta Sans; re-review every Khmer golden | Medium | 1 day |
| 2 | Add `displayXL`; apply to the earned screen only | Low | 2 hours |
| 3 | Deploy `anchor` as the drenched counterpoint on completion | Low | half day |
| 4 | Narrow the gradient ban; move `profile_cover.dart` gradients into tokens | Low | 3 hours |
| 5 | Build the one signature completion motion | Medium | 1 day |

Item 1 carries the most visual payoff **and** the most risk, because it touches
every Khmer layout. It should land on a branch with the golden suite green, and
every Khmer golden must be reviewed by eye rather than blanket-regenerated.

Items 2–4 are additive, cheap, and independently shippable.

---

## 5. Open questions for the team

1. **Is "metered data" still true?** It drives several restraint decisions and
   the external data contradicts it.
2. ~~**Does the competition judge see the app, the code, or both?**~~
   **Answered: both.** The ACLEDA / AUB competition awards four prizes —
   overall, Best UX/UI, Best Innovative Concept and Technical Excellence — and
   the winning team's source is submitted to the bank, with IP transferring to
   it. Design and code are scored separately, so neither can be traded for the
   other. The font swap in G1 therefore stays a post-judging item: it is the
   one change that could regress Khmer layout on the screens the UX/UI judges
   look at.
3. **Does the onboarding quiz stay?** Still unresolved from
   [REDESIGN_PROPOSAL.md](REDESIGN_PROPOSAL.md). It blocks Phase 2, and it is
   the screen most at odds with everything in this document.

---

## Sources

- [What Gen Z Design Aesthetics Say About Modern Branding & UX](https://www.supercharged.studio/blog/gen-z-design-trends)
- [Gen Z Design: Need-To-Know Design Trends](https://pageflows.com/resources/gen-z-design-need-to-know-design-trends/)
- [13 Mobile App UI/UX Design Trends to Watch in 2026](https://www.designstudiouiux.com/blog/mobile-app-ui-ux-design-trends/)
- [Graphic Design Trends 2026](https://reallygooddesigns.com/graphic-design-trends-2026/)
- [Building Apps and Platforms That Win Over Gen Z Learners](https://www.softcircles.com/blog/apps-platforms-gen-z-learners)
- [Popular Fonts Designers Actually Use (2026)](https://madegooddesigns.com/popular-fonts/)
- [5 Google Fonts to Use Instead of Poppins](https://jenwagner.co/5-google-fonts-to-use-instead-of-poppins/)
- [Smartphone Users in Cambodia Audience](https://www.start.io/audience/smartphone-users-in-cambodia)
- [Getting connected in Cambodia](https://www.lonelyplanet.com/articles/getting-connected-in-cambodia)
