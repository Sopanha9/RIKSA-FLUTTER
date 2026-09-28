# Task
Build a rule-based content moderation engine for the RIKSA API. Add its word lists and map its two new exceptions to HTTP and GraphQL errors. Do **not** wire it into blog or social services yet.

# Repo
This directory (`RIKSA` API), branch `feature/content-moderation`. Spring Boot 3, Java 21, Lombok, Postgres, Flyway, Spring GraphQL, JUnit 5 + AssertJ + Mockito.

# Relevant files
- `src/main/java/com/riksa/blog/util/BadWordFilter.java`: the current filter (4 English substrings). It is replaced in Wave 2; leave it in place now.
- `src/main/java/com/riksa/common/exception/GlobalExceptionHandler.java`: REST error mapping; `errorBody(HttpStatus, String)` builds the body. **You own this file.**
- `src/main/java/com/riksa/common/exception/GraphQlExceptionResolver.java`: GraphQL error mapping. **You own this file.**
- `src/main/resources/application.yml`: add a `moderation:` block.

# Context
- The app is a learning app for Cambodian Grade 12 students (Khmer + English). The code will be read by bank engineers, so it must be readable and conventional.
- Why this exists: posts should publish instantly, with a simple and explainable filter instead of a manual queue. No ML and no third-party API: rules only.
- Wave 2 workers call your service from `BlogService`, `PostService` and `CommentService`. Keep the API small and stable, exactly as specified below.

# Specification (implement exactly)

Package `com.riksa.moderation`:

```java
public enum ModerationVerdict { ALLOW, REVIEW, BLOCK }
public enum ModerationSurface { BLOG, POST, COMMENT }
public enum ModerationReasonCode { PROFANITY, SPAM_LINKS, UNKNOWN_LINK, DUPLICATE, SHOUTING, REPEATED_CHARS, LINK_ONLY, NEW_ACCOUNT, RATE_LIMITED }
public record ModerationReason(ModerationReasonCode code, String detail) {}   // detail must NEVER contain the matched bad word
public record ModerationInput(UUID authorId, OffsetDateTime accountCreatedAt, ModerationSurface surface, String title, String body) {}
public record ModerationResult(ModerationVerdict verdict, int score, List<ModerationReason> reasons) {}

@Service public class ContentModerationService {
    // duplicateCheck: returns true if this author posted the same normalized body in the last 24h; callers pass a repository-backed lambda
    public ModerationResult assess(ModerationInput input, Predicate<String> duplicateCheck);
    public String normalizeForDuplicate(String text);   // stable key callers can store/compare
    public void requireNotBlocked(ModerationResult result); // throws ContentBlockedException if BLOCK
}
public class ContentBlockedException extends RuntimeException { List<ModerationReason> reasons(); }
public class RateLimitedException extends RuntimeException {}
@ConfigurationProperties("moderation") record ModerationProperties(int blockScore /*5*/, int reviewScore /*2*/, List<String> allowedLinkHosts, Duration newAccountAge /*24h*/) {}
```

Algorithm:
1. **Normalize:** NFKC → lowercase. Strip U+200B–U+200D, U+2060 and U+FEFF, but keep the Khmer coeng U+17D2. For the Latin copy only, map leetspeak `0→o 1→i 3→e 4→a 5→s 7→t @→a $→s !→i`. Collapse runs of 3+ identical chars to 2, and also test the 1-char collapse. Build a "squashed" copy that joins single letters separated by spaces or dots (`s p a m`, `s.p.a.m` → `spam`).
2. **Word lists:** `src/main/resources/moderation/en.txt`, `km.txt`, `km-latin.txt`. The format is `term<TAB>weight` per line; `#` comments and blank lines are ignored. Load once at startup through a `WordListLoader` component and fail fast on a malformed line. Weight 3 = severe (a hit alone → BLOCK); 1–2 = mild.
   - **Latin terms match whole tokens** (split on non-letters) in the normalized, 1-collapse and squashed copies. "Scunthorpe", "class", "assess" and "Beware of scam links" must not match unrelated short terms.
   - **Khmer terms match as substrings** of the normalized text.
   - Count each distinct term once per input.
3. **Spam signals:**

   | Signal | Points | Code |
   |---|---|---|
   | more than 3 links (`http(s)://` or `www.` or bare `domain.tld/path`) | 2 | SPAM_LINKS |
   | each link whose host is not in `allowedLinkHosts` (max 3 points) | 1 | UNKNOWN_LINK |
   | `duplicateCheck` returns true | 3 | DUPLICATE |
   | > 70 % capitals among letters and ≥ 20 letters | 1 | SHOUTING |
   | the same char or emoji (grapheme) repeated ≥ 8 times in a row | 1 | REPEATED_CHARS |
   | link chars > 60 % of body and < 40 non-link chars | 2 | LINK_ONLY |
   | account younger than `newAccountAge`, only if any other signal fired | 1 | NEW_ACCOUNT |

4. **Verdict:** any severe term → BLOCK (reason PROFANITY). Otherwise score = mild weights + spam points; `≥ blockScore` → BLOCK, `≥ reviewScore` → REVIEW, else ALLOW. Mild word hits add reason PROFANITY.
5. Title and body are assessed together; blank input → ALLOW with score 0.

Word lists to seed:
- `en.txt`: a sensible moderate list of real English profanity, slurs (weight 3), sexual terms (3), and scam phrases ("free money", "click here to win", "crypto giveaway", weight 2). About 60–120 lines. Do **not** include ordinary words like `fake`, `hate`, `scam`, `spam` alone (they appear in legitimate questions).
- `km.txt` and `km-latin.txt`: a **placeholder** with a header comment `# DRAFT: to be written by a Khmer speaker (PLAN.md H1)` and at most 5 clearly offensive entries you are confident about. If you are not confident, leave only the header.
- `application.yml` → `moderation: { block-score: 5, review-score: 2, new-account-age: 24h, allowed-link-hosts: [youtube.com, youtu.be, wikipedia.org, khanacademy.org, github.com, riksa.app] }` (subdomains of allowed hosts count as allowed).

Error mapping:
- REST (`GlobalExceptionHandler`): `ContentBlockedException` → **422** with body `{ "status", "error", "message", "code": "CONTENT_BLOCKED", "reasons": ["PROFANITY", ...] }`, keeping the existing `errorBody` fields. `RateLimitedException` → **429** with `code: "RATE_LIMITED"`.
- GraphQL (`GraphQlExceptionResolver`): `ContentBlockedException` → `ErrorType.BAD_REQUEST` with extensions `{ "code": "CONTENT_BLOCKED", "reasons": [...] }`; `RateLimitedException` → extensions `{ "code": "RATE_LIMITED" }`. Keep the existing mappings working.
- Messages are English and short; the app localizes by `code`/`reasons`.

# Do
1. Implement the package and resources above with Javadoc on the public types explaining the rules (a bank engineer should understand the algorithm from the Javadoc alone).
2. Unit tests in `src/test/java/com/riksa/moderation/`: normalization (leet, zero-width, squashing, repeats), whole-token matching with no Scunthorpe false positives, Khmer substring, each spam signal, thresholds, NEW_ACCOUNT only when combined, severe → BLOCK, `detail` never contains the matched word, and loader failure on a malformed line. Test the handler mappings (MockMvc or a direct handler unit test) and the GraphQL resolver.
3. Run `./mvnw test` and report the real result. If Docker-based tests are skipped, say so.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside: `src/main/java/com/riksa/moderation/**`, `src/main/resources/moderation/**`, `src/main/resources/application.yml` (only the new block), `src/main/java/com/riksa/common/exception/GlobalExceptionHandler.java`, `src/main/java/com/riksa/common/exception/GraphQlExceptionResolver.java`, `src/test/java/com/riksa/moderation/**`, and tests for the two exception classes.
- Do not touch `blog/**` or `social/**` (Wave 2 wires the engine in).
- Do not add a Flyway migration. Do not add dependencies without stating so (the JDK's `java.text.Normalizer` covers NFKC).

# Deliverable
Changed files, a short description of the algorithm as implemented, test list with real `./mvnw test` output, and any deviation from the spec with the reason.

# Risks
End with a "## Risks" section: anything unsure, unverified, or out of scope.
