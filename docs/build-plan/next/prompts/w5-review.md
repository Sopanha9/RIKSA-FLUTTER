# Task
Read-only review of everything changed in Waves 1–5 in this repo. Report bugs; change nothing.

# Repo
The repository you were started in (`-C`): either C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER (Flutter app, branch `staging`) or C:\Users\dvdphobia\Desktop\workspaces\RIKSA (Spring Boot API, branch `feature/telegram-auth-options`). Review the diff from the Wave 0 baseline commit recorded in docs/build-plan/next/PLAN.md (app repo) to HEAD. For the API repo, review migrations V39–V41 and the `quest`, `social`, `media`, `market`, `gamification`, `buddy` packages changed since that baseline.

# What this batch built
- W1 (app): user-specific providers rebuild on account change (`currentUserIdProvider`); AI chat cache + saved lessons + guest buddy scoped per user; token refresh no longer logs out on network errors; JSON body guard; Khmer TODO strings and hard-coded English fixed.
- W2 (app): post text/markdown/link/photo/viewer improvements; feed stale-state and stuck-empty fixes; lesson double-submit guard; returning-user onboarding; iOS notification delegate.
- W3: weekly quests + chest (API V39, app panel); post media + optional title (API V40); floating head without circle + panel growing from the head.
- W4: market API (V41: `xp_balance`, catalog, inventory, equipped, purchase with Idempotency-Key, chest item drop, public look); server-first buddy + `BuddyLook`; multi-photo posts.
- W5: market + wardrobe screens.

# Focus
1. **Money/XP correctness (API):** can `xp_balance` go negative or double-charge (concurrency, retries, idempotency key reuse across items/users)? Does any path lower `total_xp` or write negative `xp_transaction` rows? Is `awardXp` still idempotent and does it update both totals under the same lock? Chest open idempotent? Weekly claim idempotent? Week boundary correct in Asia/Phnom_Penh?
2. **Privacy:** any remaining per-user data not reset on account switch or not scoped in storage; public look leaks anything beyond species/name/equipped asset keys.
3. **API contracts:** app models vs API DTOs for every endpoint in PLAN.md "API contracts" — field names, nullability, old-payload compatibility.
4. **Async/lifecycle:** mounted checks after awaits, disposed controllers, optimistic updates with rollback, double-tap guards (claim, open chest, buy, equip, submit answer).
5. **N+1 queries** (post media, leaderboard looks) and missing indexes on new tables.
6. **UX regressions:** bottom navigation bar untouched; panel never covers it; Khmer at 200% text scale; reduced motion honored; every new string in both ARB files.

# Do NOT
- Do not modify, create, or delete any file. Do not commit, push, or switch branches.
- Do not run commands that change state. Reading files and running the test suite (`flutter test` / `./mvnw test`) is fine if the sandbox allows it; report real output only.
- Do not report style nits or "add more tests" without a concrete bug.

# Deliverable
Findings ordered by severity, each as:
### [R#] title
- **Severity:** critical | high | medium | low
- **Location:** `path:line`
- **Evidence:** quoted code
- **What goes wrong:** concrete scenario
- **Suggested fix:** 1–3 sentences
- **Confidence:** high | medium | low

Then "## Files reviewed" and "## Not reviewed".

# Risks
End with a "## Risks" section.
