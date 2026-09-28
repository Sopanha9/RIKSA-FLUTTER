# RIKSA moderation: Codex orchestration (Waves 0–3)

**Goal:** remove the STEM-only gate on blog posts and publish clean posts
instantly. A simple, explainable rule-based filter screens posts
instead. The same filter also guards community posts and comments.

> Engine (W1) → wire into blog + social, fix the comment UI (W2) → independent review (W3).

## Why

- `ContentFilterService` rejects any blog post that doesn't contain a word such
  as "math" or "code". Real questions fail ("How do I stay motivated?"), and
  off-topic spam passes as long as it says "code".
- Every blog post then waits as `PENDING` for a moderator. In a demo, a judge's
  post disappears into "In review".
- `BadWordFilter` is four English substrings (`spam`, `scam`, `fake`, `hate`)
  plus two Khmer words. It blocks "Beware of scam links" and misses anything
  disguised (`sp@m`, `s p a m`).
- Community posts and comments have no content check at all.
- The comment UI on a post looks unfinished:
  - comment cards run to the screen edge;
  - "Like" and "Hide" are plain text that does nothing, hard-coded in two languages;
  - the composer renders as a grey smudge with a doubled send-button ring in light mode.
  W2 `m2-comment-ui` fixes it. The API supports liking a comment
  (`react` with `commentId`) but has no count and no user report/hide, so
  Like becomes real and Hide is removed.
- **Found while planning:** the app calls `PUT /api/v1/blog/{id}` and
  `DELETE /api/v1/blog/{id}` (owner edit/delete), but the API has neither
  endpoint. Both actions fail today. W2 adds them.

## Repos

| Repo | Path | Stack | Branch |
|---|---|---|---|
| App | `RIKSA-FLUTTER` | Flutter, Riverpod 3, go_router, Dio | `staging` |
| API | `../RIKSA` | Spring Boot 3, Java 21, Postgres, Flyway, GraphQL (social) | new `feature/content-moderation` from `feature/realtime` |

## Ground rules for every worker

1. Codex runs with `--enable worktrees -s workspace-write --worktree`, model
   **gpt-6-luna at max effort** (`-m gpt-6-luna -c model_reasoning_effort="max"`).
   **Never** the bypass flag.
2. A worktree starts from the **last commit**. Wave 0 must be committed first.
3. **One writer per file.** Each prompt owns an explicit path list; anything
   outside it is rejected at review.
4. Every user-facing string goes in `lib/l10n/app_en.arb` **and**
   `app_km.arb`. Run `flutter gen-l10n`. Khmer written by a worker is a
   **draft**.
5. Workers do not commit. The orchestrator reviews the diff, runs the checks,
   then integrates.
6. The Codex sandbox cannot run Flutter (SDK cache is outside the workspace).
   The orchestrator runs `flutter analyze && flutter test` itself.
7. **Resuming a Codex session:** `codex exec resume` writes to the *shell's
   current directory*, not the session's worktree. `cd` into the worktree
   first and check the log's `workdir:` line.

Checks after every task:

```bash
flutter analyze && flutter test
```
```bash
./mvnw test
```

## Decisions (defaults chosen; change them here before the wave that uses them)

| # | Decision | Default | Used in |
|---|---|---|---|
| D1 | Topic gate | **Removed.** Delete `ContentFilterService` and its test. Blog posts still need a category. | W2 blog |
| D2 | Clean blog post | **Published at once** (`APPROVED`), through the same code path as a moderator approval, so `BlogApprovedEvent` + `BlogPostApprovedEvent` fire (XP, buddy care, achievements). `moderatorId = null` means "system". | W2 blog |
| D3 | Borderline blog post | **Held** as `PENDING` in the existing admin queue (students are the audience; the queue already exists). Change to "publish + flag" here if wanted. | W2 blog |
| D4 | Clearly bad content | **Rejected before saving:** HTTP **422**, body `{ "code": "CONTENT_BLOCKED", "message", "reasons": [..] }`. GraphQL: error with `extensions.code = "CONTENT_BLOCKED"` and `extensions.reasons`. The draft stays in the app. | W1, W2 |
| D5 | Community posts/comments | **Block only** (no review state exists there). REVIEW verdicts publish normally. | W2 social |
| D6 | Word lists | Server resource files, never in the app. English seeded by Codex; **Khmer + romanized Khmer written by a teammate (H1).** | W1 |
| D7 | Owner edit of an approved post | Re-screened. ALLOW → stays `APPROVED`, **no second XP** (events fire only on the first approval, tracked by `first_approved_at`). REVIEW → back to `PENDING`. BLOCK → 422, post unchanged. | W2 blog |
| D8 | Rate limit | > 3 blog posts or > 10 comments in 10 minutes → HTTP **429** `{ "code": "RATE_LIMITED" }`. | W2 |
| D9 | AI/ML moderation service | **Not used.** Rules only: no cost, no latency, no student text sent to a third party, explainable to judges. | — |

## The algorithm (source of truth for W1)

`ContentModerationService.assess(ModerationInput) → ModerationResult`

```text
ModerationInput  { authorId, accountCreatedAt, surface: BLOG|POST|COMMENT, title?, body }
ModerationResult { verdict: ALLOW|REVIEW|BLOCK, score: int, reasons: List<Reason> }
Reason           { code, detail? }   // detail never echoes the matched bad word
```

1. **Normalize** (in this order):
   - Unicode NFKC, then lowercase.
   - Strip zero-width and format characters (U+200B–U+200D, U+2060, U+FEFF).
     Keep the Khmer coeng U+17D2.
   - Map leetspeak for the Latin copy only:
     `0→o 1→i 3→e 4→a 5→s 7→t @→a $→s !→i`.
   - Collapse runs of 3+ identical characters to 2, and also test with 1
     (`fuuuck` → `fuuck` / `fuck`).
   - Build a **squashed** copy where single letters separated by spaces or dots
     are joined (`s p a m` → `spam`).
2. **Word lists:** `src/main/resources/moderation/{en,km,km-latin}.txt`.
   Each line is `term<TAB>weight`; `#` starts a comment.
   - Weight **3** = severe: a hit alone is BLOCK.
   - Weight **1–2** = mild.
   - Latin terms match **whole tokens** (split on non-letters), in the
     normalized and squashed copies. So "Scunthorpe" and "class" never match
     short terms inside them.
   - Khmer terms match as **substrings** (Khmer has no spaces). Keep the list
     short and exact to avoid false positives.
3. **Spam signals** (points):

   | Signal | Points | Code |
   |---|---|---|
   | more than 3 links | 2 | `SPAM_LINKS` |
   | each link to a host not in `moderation.allowed-link-hosts` (max 3) | 1 | `UNKNOWN_LINK` |
   | same normalized body by the same author in the last 24 h | 3 | `DUPLICATE` |
   | > 70 % capital letters and ≥ 20 letters | 1 | `SHOUTING` |
   | a character or emoji repeated ≥ 8 times | 1 | `REPEATED_CHARS` |
   | body is mostly a link (link chars > 60 % of body) and < 40 chars of text | 2 | `LINK_ONLY` |
   | account younger than 24 h | +1 if any other signal fired | `NEW_ACCOUNT` |

4. **Verdict:** any severe term → BLOCK. Otherwise
   `score = sum(mild weights) + spam points`: **≥ 5 BLOCK, 2–4 REVIEW,
   0–1 ALLOW**. Thresholds live in `application.yml` under `moderation.*`.
5. **Deterministic and fast:** no I/O except the duplicate lookup (a
   repository query passed in as a function). Word lists load once at startup.

Reason codes the app must understand: `PROFANITY`, `SPAM_LINKS`,
`UNKNOWN_LINK`, `DUPLICATE`, `SHOUTING`, `REPEATED_CHARS`, `LINK_ONLY`,
`NEW_ACCOUNT`, `RATE_LIMITED`.

## Wave 0: baseline (you, not Codex)

- [ ] Commit the Flutter working tree: nav/back-button fixes, streak sheet fix,
      realtime + notifications work. Record the hash.
- [ ] API: `git -C ../RIKSA switch -c feature/content-moderation feature/realtime`,
      confirm clean, record the hash. `./mvnw test` green.
- [ ] **H1 (a Khmer speaker, parallel with W1–W2):** write
      `km.txt` (Khmer script) and `km-latin.txt` (romanized Khmer slang) in the
      format above. W1 ships with a small placeholder list if this isn't ready.

Baseline commits: Flutter `________` · API `________`

## Waves (max 3 concurrent workers)

| Wave | Task | Repo (`-C`) | Prompt | Migration |
|---|---|---|---|---|
| 1 | Moderation engine + word lists + 422/429 error mapping | API | `prompts/m1-moderation-engine.md` | — |
| 1 | App: publish-now UX, blocked/rate-limited errors, l10n | App | `prompts/m1-app-moderation-ui.md` | — |
| 1 | Clean lesson flow (Read/Respond/Reflect, feedback, completion) | App | `prompts/l1-lesson-clean.md` | — |
| 2 | Blog wiring: auto-approve, owner PUT/DELETE, remove STEM gate | API | `prompts/m2-blog-wiring.md` | V42 |
| 2 | Social wiring: block-only on posts + comments | API | `prompts/m2-social-wiring.md` | — |
| 2 | Comment UI: real cards, working Like, remove fake Hide, clean composer, rejections | App | `prompts/m2-comment-ui.md` | — |
| 3 | Independent review (Agy, read-only) | both | `prompts/m3-review.md` | — |

W1 app builds against the contract above with a **fake API in tests**, so it
runs beside the engine. W2 needs the engine committed; `m2-comment-ui` also
needs W1 app's `moderation_error.dart` and message helper.

**Shared files:** none within a wave. `GlobalExceptionHandler.java` belongs to
m1-engine only. `BlogController.java` belongs to m2-blog only. The l10n prefix
for the app tasks is `moderation…` (W1) and `comment…` (W2).
`social_post_detail_screen.dart` and `social_api.dart` belong to
`m2-comment-ui` in W2 (W1 app only adds rejection parsing to `social_api.dart`).

## Integration checklist

- [ ] Wave 1: engine unit tests green; app analyze/test green; goldens reviewed.
- [ ] Wave 2 manual check on the dev API:
  - a normal non-STEM blog post ("How do I stay motivated?") publishes instantly and awards XP once;
  - editing it doesn't award XP again;
  - `sp@m`, `s p a m` and a severe term are blocked with the draft kept;
  - five links go to review;
  - the 4th blog post in 10 minutes gets 429;
  - owner edit/delete work from the app;
  - a comment with a severe term is blocked and the typed text stays;
  - comment Like toggles, and there is no dead "Hide";
  - the comment cards and composer look right in light and dark.
- [ ] Wave 3: review findings resolved or recorded.

## How to launch a task

From `RIKSA-FLUTTER`, per task (`$OUT` = a scratch folder per task):

```bash
codex exec --enable worktrees -m gpt-6-luna -c model_reasoning_effort="max" -C "<repo>" -s workspace-write --worktree -o "$OUT/last.md" < docs/build-plan/moderation/prompts/<task>.md > "$OUT/log.txt" 2>&1
```

API tasks use `-C ../RIKSA`. After each worker: read `last.md`, diff the
worktree against its start commit, reject out-of-scope paths
(`.claude/skills/spawn-control/scripts/check-scope.sh`), run the checks, then
integrate.
