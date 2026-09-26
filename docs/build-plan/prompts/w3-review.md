# Task
Independent read-only review of the gamification loop work across the app and the API before the competition demo.

# Repos
- App: C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER (Flutter)
- API: C:\Users\dvdphobia\Desktop\workspaces\RIKSA (Spring Boot)
You run read-only in one of them (-C). Review that one.

# Context
Recently added: floating buddy + daily quests, notification fixes, lesson resources, milestone posts, guest answer checks, lighter lesson completion, restored first run (language → buddy → subject → province → learn), Computer Skills seed.

# Do
Review for, in order:
1. Correctness bugs: wrong day boundaries (must be Asia/Phnom_Penh), double XP awards, race conditions on claim/save, event listeners that fire before commit, guest paths calling authenticated endpoints.
2. Security: public endpoints leaking data, URL validation on resources (javascript:, data:), missing auth on mutations, rate limits.
3. App: states that can overflow in Khmer at 200% text, missing l10n keys, the floating buddy covering controls or the bottom nav, reduced-motion violations, SharedPreferences calls not wrapped in try/catch.
4. Contract drift between the app models and the API (field names, enums, nullability).

# Do NOT
- Do not modify any file. Read-only.

# Deliverable
Findings as `file:line — what's wrong — concrete failing scenario`, most severe first. No style nits.

# Risks
End with a "## Risks" section listing what you could not check.
