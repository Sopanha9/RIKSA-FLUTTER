# Task
Independently review the content-moderation change in this repository and report findings only. Change nothing.

# Repo
This directory: a disposable copy of either the RIKSA API (Spring Boot 3, Java 21) or the RIKSA Flutter app. The change being reviewed is the diff from the baseline commit named by the orchestrator in the first line of this prompt. The orchestrator also commits the working tree in this copy, so `git show` and `git diff` see it.

# What was built
- API: a rule-based moderation engine (`com.riksa.moderation`):
  - normalization: NFKC, lowercase, zero-width strip, leetspeak, repeat collapse, squashing spaced letters;
  - word lists with weights (Latin whole-token matching, Khmer substring matching);
  - spam signals (links, unknown hosts, duplicates, shouting, repeated chars, link-only, new account);
  - a verdict ALLOW / REVIEW / BLOCK.
- Blog posts no longer need STEM keywords. ALLOW publishes at once and fires the approval events once. REVIEW → PENDING. BLOCK → 422 `CONTENT_BLOCKED`. Rate limit → 429. Owner PUT/DELETE were added. Migration V42.
- Community posts/comments: block only; rate-limited.
- App: localized messages for blocked/rate-limited content, a "Published" state, drafts kept on rejection.

# Look for
1. **Bypasses:** text that is obviously offensive but gets ALLOW (spacing, punctuation, homoglyphs such as Cyrillic `а`, full-width letters, emoji between letters, mixed Khmer/Latin).
2. **False positives:** normal student questions that get REVIEW or BLOCK. Test in your head: "How do I assess my weak topics?", "Scunthorpe", "class", "Is this a scam?", "I hate chemistry", a post with 2 YouTube links, a Khmer sentence about maths.
3. **XP / events:**
   - can a user earn approval XP twice (edit, reject then edit, delete then repost)?
   - do auto-approval and moderator approval ever both fire?
4. **Security:**
   - can a non-owner edit or delete?
   - does any error, log or response echo the matched bad word or the post text?
   - can the rate limit be bypassed by editing instead of creating?
5. **Correctness:** thresholds read from config, word-list loading failures, migration backfill correctness, transaction boundaries (nothing saved when blocked).
6. **App:** the draft is lost on any rejection path; hard-coded English; Khmer strings missing; a navigation or back behaviour regression.

# Do
- Use your built-in file reading tools for file contents.
- To enumerate files, run exactly `git ls-files` with no arguments.
- Repository inspection may use exactly, with no arguments added:
  git status · git diff · git log · git show · git ls-files
  Any other command, or any of these with arguments, will be denied, so do not attempt it.

# Do NOT
- Do not run builds, tests, package managers, Flutter, Maven, or any command that changes state.
- Do not modify, create, or delete files.
- Do not ask for broader permissions.

# Deliverable
Findings, most severe first. For each: `file:line`, what is wrong, a concrete input or sequence that shows it, and a suggested fix. Then a short list of what you checked and found fine.

# Risks
End with a "## Risks" section: anything you could not check.
