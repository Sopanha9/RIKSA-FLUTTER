# Riksa Whole-App Design System & Experience Plan

**Status:** Direction proposed — approve before production UI coding  
**Prepared:** 2026-08-16  
**Working design name:** **Riksa Neo-Khmer**  
**Audience:** Cambodian high-school and university students, with Gen Z as the
primary audience  
**Product context:** Competition entry; Android and iOS Flutter app

## 1. Recommendation

Riksa should not look like a generic school dashboard, an X/Reddit clone, or a
Duolingo imitation. The recommended direction is:

> **Neo-Khmer learning game:** a calm, warm learning journal underneath bold
> game-like progress, tactile motion, local student identity, and expressive
> moments that are earned through learning.

The experience should feel:

- **bold, not noisy;**
- **playful, not childish;**
- **Cambodian, not souvenir-like;**
- **competitive, not stressful;**
- **social, not attention-extractive;**
- **modern, not trend-dependent.**

The current warm paper and deep-green Flutter direction is the better starting
point. Keep it, strengthen it with energetic accents, and add a complete dark
theme. Retire the older “black + gold X.com clone” as the main visual language.
Gold remains meaningful for earned XP, rank, and achievement moments.

## 2. Why this direction is current

This is a selective interpretation of current guidance, not a collection of
fashion effects:

- Google’s current Material 3 Expressive direction uses color, shape, scale,
  motion, and containment to emphasize important actions. Its research found
  that expressive hierarchy can help people find key UI substantially faster.
  Riksa should apply that energy to primary learning actions and rewards, not to
  every element. [Google expressive-design research](https://design.google/library/expressive-material-design-google-research)
- Material’s 2026 system adds flexible typography, contrasting shapes,
  expressive motion physics, button groups, and richer progress components.
  These map well to learning stages, confidence controls, and XP progress.
  [Material Design 3](https://m3.material.io/)
- Apple’s current material guidance treats Liquid Glass as a functional layer
  for controls/navigation and warns against using it throughout the content
  layer. Riksa can use subtle translucency on navigation and sheets while
  keeping reading surfaces solid and legible.
  [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/materials)
- Adobe’s 2026 creative forecast emphasizes sensory depth, human connection,
  play, and authentic local culture. Riksa can express these through tactile
  reward motion, real student stories, Khmer language, krama-inspired patterns,
  and locally reviewed illustration rather than generic AI aesthetics.
  [Adobe 2026 Creative Trends](https://business.adobe.com/resources/creative-trends-report.html)
- Current Android guidance treats adaptive layout as a baseline: layouts should
  reflow into panes and navigation should change for larger screens rather than
  stretching a phone UI. [Android adaptive-layout guidance](https://developer.android.com/design/ui/mobile/guides/layout-and-content/adapt-layout)
- Accessibility is part of the visual quality bar. WCAG 2.2 requires at least
  4.5:1 contrast for normal text, 3:1 for large text, scalable content, visible
  focus, and usable targets. [WCAG 2.2](https://www.w3.org/TR/WCAG22/)

## 3. What wins the competition

A beautiful screen is not enough. Judges should understand Riksa’s difference
within the first minute:

1. **Cambodia-first identity** — Khmer is a first-class language; culture is
   built with local voices and creators.
2. **A unique learning loop** — Read → Practice → Reflect is visibly different
   from multiple-choice learning apps.
3. **A personal artifact** — lesson completion celebrates the learner’s own
   highlighted idea and reflection, not only a score.
4. **Meaningful gamification** — XP, rank, streak, and achievements prove
   progress without punishing the user.
5. **Community and local competition** — students can learn with Cambodian
   peers and see provincial/national progress.
6. **System quality** — light/dark themes, English/Khmer layouts, accessibility,
   loading/error states, and adaptive screens show this is a real product.

The hero experience is not the leaderboard by itself. It is the emotional arc:

```text
Curiosity → focused reading → effort → reflection → earned celebration →
local recognition → sharing with the learning community
```

## 4. Design principles

### 4.1 Calm base, energetic payoff

Learning and reading screens use quiet paper-like surfaces. Strong color,
animation, sound, and haptics appear when the user makes progress, completes a
stage, earns an achievement, or ranks up.

### 4.2 One obvious next action

Every screen has one dominant action. Secondary actions stay visually quieter.
Expressive size and shape must improve hierarchy rather than decorate it.

### 4.3 Bilingual by construction

Components are designed with real Khmer and English text from the beginning.
Khmer is never treated as a translation pass after the English layout is done.

### 4.4 Local culture belongs to local people

Use Khmer language, contemporary student life, local places, krama weaving,
province identity, and Cambodian illustrators. Avoid repeating Angkor Wat,
temple silhouettes, or “royal gold” as shorthand for all Cambodian culture.
Culturally sensitive art must be reviewed by Cambodian students/creators.

### 4.5 Competition without anxiety

Show personal best, progress, and nearby rank. Never shame a broken streak or
make a student feel academically inferior. Provide streak recovery and private
progress options when the product supports them.

### 4.6 Social with an end

Community content should have clear sections and stopping points. Learning is
the primary job; the app should not become an infinite-scroll distraction.

### 4.7 Delight is earned

Confetti, glow, count-up animation, and sound are reserved for meaningful
events. Small actions receive subtle motion and haptics.

### 4.8 Accessible is premium

Contrast, focus, readable Khmer, text scaling, reduced motion, semantics, and
large targets are release requirements, not optional polish.

## 5. Product architecture

### Recommended primary navigation

| Destination | Purpose | Backend/product modules |
|---|---|---|
| **Today** | Personalized next step, streak, progress, recent community activity | learning, gamification, leaderboard, social |
| **Learn** | Lesson discovery and the Read → Practice → Reflect loop | learning |
| **Community** | Discussions and educational articles in one social/content destination | social, blog, report |
| **Rank** | XP, achievements, streak, provincial and national leaderboards | gamification, leaderboard |
| **Me** | Identity, learning journal, posts, saved achievements, settings | auth/profile, learning, social, gamification |

Recommendations:

- Put **AI Tutor** in context as “Ask Riksa” from a lesson, reflection, or help
  action. It can also have a secondary inbox/history entry. Do not spend a
  permanent primary tab on an incomplete backend feature.
- Put **Blog** inside Community as `Discussions | Stories`, and surface selected
  stories on Today/Learn. Users should not need to understand the API boundary.
- Use a bottom navigation bar on compact screens and a navigation rail plus
  optional supporting pane on wider screens.
- Keep labels visible with icons. Do not use icon-only primary navigation.

### Core flow hierarchy

```text
Launch
  ├─ First run → Language → Auth → Province completion → Today
  └─ Returning → Session restore → Province gate → Today

Today
  ├─ Continue lesson → Read → Practice → Reflect → Completion
  ├─ Daily/personal challenge
  ├─ Progress → Rank / Achievements / Leaderboard
  └─ Community preview → Discussion or Story

Me
  ├─ Profile identity
  ├─ Learning journal and reflections
  ├─ Posts and achievements
  └─ Settings, language, theme, logout
```

## 6. Brand foundation

### Brand idea

**Riksa turns effort into visible momentum.**

The visual metaphor is a living notebook: calm pages for thought, highlighted
ideas, hand-made marks, collected badges, and energetic overlays when progress
is earned.

### Brand voice

- Direct and encouraging: “Ready for the next idea?”
- Specific: “2 key terms left” instead of “Almost there!”
- Respectful: “Try this part again” instead of “Wrong.”
- Human: “Explain it to a friend” instead of “Submit response.”
- Competitive with perspective: “You moved up 3 places” before “You are #42.”
- Short enough to translate naturally into Khmer.

The existing Khmer splash line `រៀន. គិត. អភិវឌ្ឍន៍.` is a strong foundation.
Its English companion should be **Learn. Reflect. Grow.** after native-language
copy review.

### Logo recommendation

- Create a real vector mark, not only a styled Flutter `RichText` wordmark.
- Use a bold `រ`-inspired abstract mark built from simple layered shapes.
- Pair it with a custom Riksa wordmark; keep the mark recognizable at 24 px.
- Prepare full, mark-only, monochrome, dark, and app-icon versions.
- Avoid detailed temple art in the icon; it will fail at small size and feel
  predictable.

## 7. Color system

The palette keeps the current warm paper + deep green identity and introduces
high-energy accents with strict semantic roles.

### Core semantic tokens

| Token | Light | Dark | Foreground | Use |
|---|---:|---:|---:|---|
| `canvas` | `#FFF8EE` | `#0D1511` | `ink` | App background |
| `surface` | `#FFFFFF` | `#151F1A` | `ink` | Cards, reading pages, fields |
| `surfaceRaised` | `#F3F5EF` | `#1C2A23` | `ink` | Sheets, selected containers |
| `ink` | `#17211B` | `#F2F7F3` | — | Primary text/icons |
| `inkMuted` | `#59655E` | `#A9B8AF` | — | Secondary text |
| `outline` | `#D5DED8` | `#35473D` | — | Borders and separators |
| `primary` | `#18533D` | `#82DDAA` | light: white; dark: dark canvas | Main CTA, active navigation |
| `spark` | `#C8F560` | `#D6FF76` | dark ink | Selection, highlight, fresh energy |
| `gold` | `#F2B544` | `#FFC857` | dark ink | XP, rank, achievement only |
| `indigo` | `#5B62D6` | `#A9ACFF` | light: white; dark: dark canvas | Learning and knowledge |
| `coral` | `#E85D4A` | `#FF9385` | dark ink | Streak and high-energy moments |
| `success` | `#147D56` | `#71D6A7` | light: white; dark: dark canvas | Correct, complete, positive |
| `error` | `#B3261E` | `#FFB4AB` | light: white; dark: dark canvas | Errors and destructive actions |

The primary text/background pairs above were checked at or above WCAG AA for
normal text. Accent color alone never communicates status.

### Color rules

- Green is the brand/action color; gold is earned, not a generic button color.
- Spark/lime always uses dark foreground text.
- Use one feature accent per screen, normally covering less than 15% of the
  visible area.
- Gradients are reserved for progress heroes, completion, and rank moments.
- Province colors appear in identity chips, crests, and leaderboard highlights,
  not as competing page themes.
- Dark mode uses designed surfaces and recolored illustrations, not simple color
  inversion.

## 8. Typography

### Recommended family

Use [**Kantumruy Pro**](https://fonts.google.com/specimen/Kantumruy%2BPro) as
the primary UI family because it supports Khmer and Latin and can create a
consistent bilingual rhythm. Start with weights 400, 500, 600, and 700. Keep
the custom wordmark separate from UI typography.

If testing shows the Latin cut lacks enough display personality, use one Latin
display family only for large English hero text; Khmer remains Kantumruy Pro.
Do not mix display families inside the same bilingual component.

### Type roles

| Role | Size / line height | Weight | Use |
|---|---|---:|---|
| Hero | 48 / 56 | 700 | Completion, rank, major metric |
| Display | 40 / 48 | 700 | Splash and campaign moments |
| Heading 1 | 32 / 40 | 700 | Primary page title |
| Heading 2 | 24 / 32 | 700 | Section/hero title |
| Heading 3 | 20 / 28 | 600 | Card and sheet title |
| Body large | 18 / 30 | 400 | Lesson reading |
| Body | 16 / 24 | 400 | Default content |
| Body small | 14 / 20 | 400 | Supporting content |
| Label | 14 / 20 | 600 | Buttons, tabs, filters |
| Caption | 12 / 18 | 500 | Metadata; never critical instructions |

Typography rules:

- Add extra vertical breathing room for Khmer; never crop marks or force Latin
  line-height assumptions.
- Do not letter-space Khmer text.
- Support at least 200% text scaling without losing actions or content.
- Use tabular numerals for XP, timers, streaks, rank, and live counters.
- Limit lesson/body reading width to roughly 55–75 Latin characters per line;
  validate Khmer reading width separately with native readers.
- Avoid all caps except short Latin-only labels such as `XP`.

## 9. Layout, spacing, shape, and depth

### Grid and spacing

- Base unit: **4 dp**.
- Main spacing scale: `4, 8, 12, 16, 20, 24, 32, 40, 48, 64`.
- Compact-screen horizontal margin: **20 dp**; 16 dp only on constrained screens.
- Touch target: design at **48 × 48 dp** minimum.
- Text/forms use a readable maximum width rather than stretching on tablets.
- Compact: one pane; medium: one or two panes; expanded: navigation rail plus
  list/detail or primary/supporting pane.

### Shape language

Use contrast rather than making everything a pill:

| Shape | Radius | Use |
|---|---:|---|
| Tight | 8 | Small badges, progress details |
| Control | 12 | Inputs, compact buttons, menu rows |
| Card | 20 | Main content cards |
| Hero | 28 | Hero cards, large sheets, completion panels |
| Full | 999 | Tags, avatars, segmented controls, primary pill CTA when intentional |

Expressive moments may pair a round hero container with tighter internal
controls. Avoid random radii on sibling components.

### Depth

- Content uses solid surfaces, borders, and spacing as the default hierarchy.
- Use a soft ambient shadow only for raised sheets or floating actions.
- A 2–3 dp offset “sticker” shadow can appear on achievements or a primary
  challenge card.
- Subtle translucent blur is allowed on bottom navigation, compact floating
  toolbars, and modal controls. It is not used behind lesson text, forms, or
  dense feed content.

## 10. Icons, illustration, imagery, and texture

### Icons

- Use one rounded icon family with consistent optical size and stroke.
- Use filled state for active navigation and outline state for inactive.
- Do not ship emoji as final navigation or action icons.
- Every icon-only control needs a semantic label and at least a 48 dp target.

### Illustration system

- Build achievements and ranks as collectible “patches” with a consistent
  silhouette, border, depth, and rarity treatment.
- Use a krama-inspired weave grid as a subtle pattern in onboarding, profile
  banners, and empty states—never behind long text.
- Show contemporary Cambodian students, devices, classrooms, and communities.
- Province marks should be respectful, scalable, and created/reviewed locally.
- If a mascot is retained, make it useful: the tutor signals hints, reflection,
  and recovery. Avoid copying the language-app owl archetype.

### Photography and generated imagery

- Prefer real student photography or commissioned local illustration for hero
  content.
- Generated art may support ideation, but culturally specific final artwork
  requires human/local review and a consistent production style.
- Define crop, focal point, attribution, loading, error, and dark-mode behavior
  for every media component.

## 11. Motion, haptics, and sound

### Motion tokens

| Token | Duration | Use |
|---|---:|---|
| `instant` | 80–120 ms | Press, toggle, icon response |
| `quick` | 160–220 ms | Chip, tab, field, small state change |
| `standard` | 260–340 ms | Route/container transition |
| `expressive` | 420–600 ms | Stage unlock, achievement, hero change |
| `celebration` | 700–1200 ms | Lesson completion or rank-up only |

- Default movement is spring-based with low/medium bounce.
- Use shared-axis/container transitions to preserve spatial context.
- Progress should move toward its destination; it should not pulse endlessly.
- Correct answer: short success snap and light haptic.
- Incorrect answer: no aggressive shake; use a gentle horizontal nudge plus a
  clear path back to the source material.
- Major completion: XP count-up, badge settle, controlled particles, optional
  sound, and medium haptic.
- Respect reduced-motion and reduced-transparency settings. Replace travel,
  parallax, particles, and count-up with short fades/static end states.

Sound is opt-in and muted by default until product testing proves it adds value.
Never attach sound to routine navigation.

## 12. Component system

Components are built once with light/dark, English/Khmer, text-scale, loading,
disabled, focus, pressed, error, and offline states.

### Foundation components

- `RiksaScaffold`, safe area, max-width/pane container
- top app bar, large title header, contextual header
- compact bottom navigation and expanded navigation rail
- divider, section header, sticky action area
- skeleton, empty state, error state, offline banner

### Actions and input

- primary, secondary, tonal, text, icon, and destructive buttons
- connected button/confidence group
- text, password, search, OTP, multiline reflection, and select fields
- chips for category, difficulty, province, filter, and status
- bottom sheet, dialog, menu, snackbar/toast, inline banner

### Identity and content

- avatar, avatar stack, profile identity card, province mark
- article hero/card, post card, comment row, reaction/vote group
- metadata row, author line, content warning/report affordance
- empty/loading/error versions of lists and feeds

### Learning

- lesson card, resume card, key-term highlight/popover
- three-stage stepper: Read, Practice, Reflect
- reading progress ring and gate checklist
- confidence selector
- exercise prompt, correct/incorrect feedback, re-read link
- reflection journal card and completion artifact

### Gamification

- XP pill/counter, streak chip, rank badge, tier progress
- achievement patch in earned/locked/new states
- leaderboard row, current-user row, top-three podium
- challenge card and reward breakdown
- rank-up/completion celebration sheet

## 13. Screen-family direction

### Splash, language, and auth

- Minimal, brand-led, and calm; one expressive mark and one dominant action.
- Paper canvas with a controlled spark/green accent, not a dense illustration.
- Native and Flutter splash backgrounds must match.
- Forms remain solid and highly legible; no glass fields.
- Province is a focused one-time profile-completion screen after authentication,
  not an extra field crowded into login or repeated on every launch.

### Today

- Personalized greeting and “continue” action above the fold.
- One progress hero combines rank, XP-to-next, and streak without becoming a
  dashboard of tiny statistics.
- A small bento composition is acceptable for quick actions, but the layout
  should retain a clear vertical reading order.

### Learn and lesson detail

- Discovery can be more energetic through category colors and cover art.
- The selected lesson hero explains value, length, difficulty, and reward.
- “Start/Resume” is always the dominant action.

### Read → Practice → Reflect

- This is the visual showpiece and uses a journal metaphor.
- Read is quiet, spacious, and content-first.
- Practice is focused, with one prompt and one response at a time.
- Reflect feels personal: a generous writing surface, human prompt, and visible
  ownership of the response.
- The three stages share one stepper and preserve progress when moving backward.

### Completion

- The learner’s reflection is the hero; XP/rank/streak support it.
- Reveal rewards in a short sequence rather than displaying every card at once.
- Provide a shareable summary card only with explicit user action and privacy
  controls.

### Rank and leaderboard

- Combine personal progress and social position.
- Keep the user anchored while scrolling the leaderboard.
- Use gold only for the winner/earned rank; silver and bronze remain distinct.
- Show movement and personal best to reduce unhealthy fixation on absolute rank.

### Community and stories

- Use `Discussions | Stories` at the destination level.
- Discussions favor efficient rows and clear reply/reaction actions.
- Stories favor editorial typography, larger imagery, and comfortable reading.
- Compose happens on a dedicated focused surface, not a cramped feed box.

### Profile and learning journal

- Identity hero: avatar, name, province, short bio, rank.
- Tabs prioritize `Journal`, `Achievements`, and `Posts` based on product value.
- The learning journal collects reflections and highlighted ideas—the clearest
  long-term proof that Riksa creates understanding, not only points.

### AI Tutor

- Enter contextually with the lesson source visible.
- Show what context is being used and allow the learner to remove it.
- Clearly distinguish AI responses and avoid pretending the tutor is human.
- Use the same re-read/reflection patterns as the learning loop.

## 14. State design

Every component/screen spec must include:

- loading and skeleton;
- empty first-use and empty filtered;
- offline with cached content;
- recoverable server error;
- permission/auth expired;
- disabled with a visible reason;
- success confirmation;
- rate-limited/cooldown when applicable;
- long English, long Khmer, and 200% text scale;
- reduced motion and reduced transparency;
- light and dark themes.

Do not use a blank spinner as the only state for a page. Preserve layout with a
skeleton or show a useful explanation and retry action.

## 15. Accessibility and inclusive design bar

- WCAG 2.2 AA contrast minimum; aim higher for Khmer body text and muted labels.
- 48 dp touch targets, with sufficient spacing between adjacent controls.
- Visible keyboard focus and logical focus order for tablet/desktop users.
- Screen-reader names, roles, values, and live announcements for progress and
  OTP/error states.
- Color plus icon/text/pattern for every state.
- System text scaling and layout reflow; no clipped Khmer.
- Autofill and password-manager support; allow paste in password and OTP fields.
- Reduced-motion and reduced-transparency alternatives.
- Avoid time pressure. OTP expiry is explained and resend is accessible.
- Test with both low-end Android hardware and users who read Khmer as their
  primary language.

## 16. Performance quality bar

- Target smooth interaction on a representative low/mid-range Android device.
- Prefer vector icons, cached images, and bounded image sizes.
- Avoid stacked blurs, large live shadows, and simultaneous particle effects.
- Skeletons match final layout to reduce visual shift.
- Hero art and fonts must not delay the first useful screen.
- Preserve usable offline reading/resume states when the data layer supports it.

## 17. What to keep, evolve, and retire

| Existing idea | Decision |
|---|---|
| Warm paper background | **Keep and formalize** as `canvas` |
| Deep green primary | **Keep and strengthen** as the brand/action anchor |
| Muted rose accent | **Evolve** into a clearer semantic coral accent |
| Khmer splash tagline | **Keep**, with native copy review |
| Black + gold full-app direction | **Retire** as the default; use gold for earned rewards |
| X-style content density | **Use selectively** for community rows, not as the brand |
| Reddit vote pattern | **Keep only if product/backend semantics support it** |
| Pill buttons everywhere | **Retire**; use shape contrast and reserve pills intentionally |
| Glass/blur headers | **Restrict** to functional navigation/overlay layers |
| Emoji as final artwork/icons | **Replace** with a coherent icon and illustration system |
| Current auth/blog screens | **Treat as functional prototypes**, then reskin from approved components |
| Read → Practice → Reflect | **Elevate** as the signature experience |
| Reflection completion card | **Elevate** as the demo’s emotional payoff |

This document supersedes the old visual instruction built around X.com,
Cambodian identity, and Reddit voting. It does not replace API contracts;
backend source and the feature API plans remain the contract source of truth.

## 18. Design-first execution plan

No broad production UI implementation should begin until the first three design
gates are approved.

### Gate A — Brand and mood direction (Day 1)

Deliver:

- [ ] one Riksa Neo-Khmer moodboard;
- [ ] brand personality and anti-reference board (“not this” examples);
- [ ] light/dark palette with checked contrast;
- [ ] typography sample containing real long English and Khmer;
- [ ] logo direction and krama-pattern exploration;
- [ ] three small style tiles: auth, lesson, achievement.

Approval question: **Does this feel recognizably Riksa and recognizably
Cambodian without feeling traditional or childish?**

### Gate B — Foundations and component kit (Days 2–3)

Deliver:

- [ ] color, type, spacing, shape, elevation, motion, and icon tokens;
- [ ] compact/medium/expanded layout grid;
- [ ] buttons, fields, navigation, tabs, chips, cards, sheets, feedback states;
- [ ] lesson, reflection, XP, streak, rank, achievement, and post components;
- [ ] light/dark and English/Khmer variants;
- [ ] component naming and state/property specification.

Approval question: **Can every main screen be assembled from this system without
inventing one-off styles?**

### Gate C — Competition hero screens (Days 4–6)

Design these first at high fidelity:

1. Splash/language moment.
2. Login, registration, and province-completion family.
3. Today/home.
4. Lesson detail.
5. Read stage with key-term interaction.
6. Practice stage, including incorrect → re-read.
7. Reflect stage.
8. Completion with personal reflection + reward reveal.
9. Provincial leaderboard.
10. Community discussion and learner profile/journal.

Required variants:

- one complete Khmer path;
- one complete dark-mode path;
- loading, error, offline, locked, and empty examples;
- compact phone and one expanded/tablet example.

Approval question: **Does the core learning story feel unique enough to win a
demo, and is every screen obviously part of the same product?**

### Gate D — Clickable prototype and user test (Days 7–8)

Prototype three flows:

- first launch → language → auth → province completion → Today;
- continue lesson → Read → Practice → Reflect → Completion;
- Completion → Rank/leaderboard → share/view profile journal.

Test with 5–8 target users, ideally Cambodian students across Khmer/English
preferences. Observe rather than explain.

Measure:

- Can users identify the primary action in under 5 seconds?
- Can they explain the three-stage learning loop after one run?
- Can they recover from an incorrect practice answer?
- Do they understand XP, rank, and streak without instruction?
- Does Khmer feel natural and complete rather than translated?
- Which moment do they remember and want to share?

Revise the system, not only individual screens, when patterns fail repeatedly.

### Gate E — Design freeze and Flutter handoff (Days 9–10)

Deliver:

- [ ] approved design-system source file and token table;
- [ ] responsive behavior and component state specs;
- [ ] export-ready logo, icons, patterns, badges, and illustration assets;
- [ ] content/copy sheet for EN/KM;
- [ ] motion storyboard with timings and reduced-motion variants;
- [ ] accessibility annotations;
- [ ] golden-screen list and acceptance checklist;
- [ ] design decisions and known backend-dependent states.

Only after Gate E should the Flutter theme and shared components be implemented
at scale.

## 19. Flutter implementation order after approval

1. Font and asset setup.
2. Semantic color, type, spacing, shape, elevation, and motion tokens.
3. `ThemeData` light/dark plus Riksa `ThemeExtension`s.
4. Internal component-gallery route with every state and locale.
5. Navigation shell and adaptive pane behavior.
6. Shared loading/empty/error/offline components.
7. Auth family from `AUTH_SCREEN_PLAN.md`.
8. Today and signature learning loop.
9. Completion/gamification/leaderboard.
10. Community/stories/profile.
11. Golden tests, semantics tests, performance profiling, and visual QA.

Feature screens must consume system components. They should not introduce raw
hex colors, arbitrary radius values, or new text styles.

## 20. Competition demo story

Suggested three-minute sequence:

| Time | Moment | What judges understand |
|---:|---|---|
| 0:00–0:15 | Riksa mark, Khmer/English, auth, one-time province identity | Cambodia-first and polished |
| 0:15–0:35 | Today recommends a lesson and shows momentum | Personalized next step |
| 0:35–1:00 | Read: open key term and highlight core idea | Active reading, not skimming |
| 1:00–1:25 | Practice: answer, confidence, wrong → re-read | Learning from source, not guessing |
| 1:25–1:50 | Reflect: explain to a friend | Learner produces understanding |
| 1:50–2:15 | Completion: reflection returns, XP/rank/streak reveal | Emotional payoff and evidence |
| 2:15–2:35 | Provincial leaderboard and achievement | Local competition and retention |
| 2:35–2:50 | Profile learning journal/community share | Identity and connection |
| 2:50–3:00 | Dark mode + Khmer + tablet/system board | Real product quality |

The demo should use one learner story and one lesson. Do not tour every screen.

## 21. Anti-patterns

Do not ship:

- glassmorphism on every surface;
- five gradients on one screen;
- black/gold styling as a substitute for Cambodian identity;
- tiny grey metadata with poor Khmer readability;
- dashboard grids of equally important cards;
- unlabeled bottom-navigation icons;
- celebratory animation for routine actions;
- streak-loss shame, fake urgency, or manipulative notifications;
- random AI-generated 3D art with inconsistent style;
- emoji as production iconography;
- English-perfect screens followed by compressed Khmer layouts;
- a clone of another education/social product.

## 22. Definition of design-ready

- [ ] Riksa Neo-Khmer direction is approved.
- [ ] Logo, palette, type, spacing, shape, motion, and illustration rules exist.
- [ ] All core colors pass required contrast in both themes.
- [ ] The component kit covers every shared interaction and state.
- [ ] Hero screens are complete in English/Khmer, light/dark, and compact/expanded.
- [ ] Read → Practice → Reflect is the strongest visual and interaction story.
- [ ] The reflection artifact is the completion hero.
- [ ] Target-user testing has produced concrete revisions.
- [ ] The three-minute competition prototype works without verbal rescue.
- [ ] Assets and specs are ready for Flutter without designers inventing values
  during implementation.
