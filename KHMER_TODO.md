# Khmer strings needed — Block 3

Fill in the `km:` lines. I will move all of these into `app_en.arb` /
`app_km.arb` and wire up the call sites. Do not edit the Dart files — I will
handle that.

Source: `lib/features/ai/presentation/widgets/ai_study_coach_hub.dart`

The `prompt` is what gets sent to the AI when the student taps the card, so it
should read as something a student would actually type.

---

## 1. Mathematics Coach — `studyCoachMath*`

- **title** en: `Mathematics Coach`
  - km:
- **subtitle** en: `Step-by-step algebra, calculus & geometry problem solver`
  - km:
- **prompt** en: `Can you help me solve a math problem step-by-step?`
  - km:

## 2. Science Explainer — `studyCoachScience*`

- **title** en: `Science Explainer`
  - km:
- **subtitle** en: `Physics laws, chemistry formulas & biology made simple`
  - km:
- **prompt** en: `Can you explain a scientific concept to me with an everyday example?`
  - km:

## 3. Khmer Language Coach — `studyCoachKhmer*`

- **title** en: `Khmer Language Coach`
  - km:
- **subtitle** en: `Spelling, grammar, respectful speech & classical essays`
  - km:
- **prompt** en: *(see line 51 of the source — confirm wording)*
  - km:

## 4. English Practice — `studyCoachEnglish*`

- **title** en: `English Practice`
  - km:
- **subtitle** en: `Conversation partner with gentle grammar corrections`
  - km:
- **prompt** en: *(see line 62 of the source — confirm wording)*
  - km:

## 5. Grade 12 BakII Prep — `studyCoachBakii*`

- **title** en: `Grade 12 BakII Prep`
  - km:
- **subtitle** en: `Typical national exam questions & revision strategies`
  - km:
- **prompt** en: *(see line 73 of the source — confirm wording)*
  - km:

---

## Already have Khmer — no work needed from you

I will move these into ARB as-is:

| File | Khmer | English |
|---|---|---|
| `leaderboard_podium.dart:599` | `ចាប់ផ្តើមរៀន 🚀` | `Start a 5-Min Lesson 🚀` |
| `leaderboard_states.dart:211` | `ជ្រើសរើសខេត្ត →` | `Choose My Province →` |

Note: I will drop the literal `🚀` and `→` from the ARB values. An emoji baked
into a translated string is a localization smell, and the arrow should be a
widget, not a character.

---

## Product question for you (not a translation task)

`studyCoachTopics` ships **Khmer Language Coach** and **English Practice**.

PRODUCT.md says:

> Scope today: STEM only (Mathematics, Physics, Chemistry, Biology, Computer
> Science / Technology), Grade 12, Cambodia.

Two of the five coach topics are outside that stated scope, and there is no
Computer Science / Technology coach even though it is in scope.

I am not changing this on my own — it is a product call. Options:

1. Keep all five and update PRODUCT.md to say the AI coach is broader than the
   lesson catalog.
2. Drop the two language coaches, add a Technology coach, and stay STEM-only.
3. Leave it and decide after the competition.

Tell me which and I will follow it. If you pick 2, you do not need to translate
sections 3 and 4 above.
