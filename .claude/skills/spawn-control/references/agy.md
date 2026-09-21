# Agy CLI

Verified against `agy 1.2.7`. Re-run `agy --help` at session preflight; **the
installed help wins** over anything below.

## Capability posture — read this before promising a write

Agy is **review-only by orchestration policy**. It is *not* trusted as
technically read-only.

On one observed run (agy 1.2.7, default settings), a headless instruction to
create a file produced no file and no output, and exited 0 — consistent with
confirmation-requiring tools being soft-denied. That is a single observation of
one version under one permission configuration. It is not a guarantee, and it
does not transfer across versions, settings, tools, or paths.

So: **never rely on agy's permission system to protect the user's tree.** Point
agy at a disposable **independent clone or copy** — one with its own `.git`, not
a `git worktree`, which shares the repository's common Git directory. Treat
anything agy leaves there as discardable, and never auto-integrate its changes.

If the user asks agy to implement something, say that this policy does not allow
agy writes into the real project, and offer the alternatives — analysis, a
proposed patch you review and apply, or codex for the write. Never silently
substitute codex. Never report a write as done without confirming it in a diff.

## Shape

```bash
agy --add-dir "$ISOLATED" --model <model> --output-format text \
  -p "$(cat "$OUT/prompt.md")" > "$OUT/last.md" 2>"$OUT/log.txt"
```

`$ISOLATED` is a disposable independent clone or copy — never the user's working
tree, and not a shared `git worktree`:

```bash
ISOLATED=$SCRATCH/agy-review
git clone --quiet --no-hardlinks --local "$REPO" "$ISOLATED"
```

`--no-hardlinks` keeps the copy's object store physically separate. To review
uncommitted work, copy the dirty files in after cloning rather than pointing agy
at the real tree.

Three invocation rules — breaking any one makes the run fail *silently*,
returning empty output with exit status 0:

1. **`-p` consumes the next token.** Every other flag goes before `-p`; the
   prompt is the last argument. `agy -p --model x "..."` makes `--model` the
   prompt. The CLI sometimes catches this and says the prompt "was left as an
   argument and ignored".
2. **`--add-dir` is required.** Agy does not inherit the shell's working
   directory. Without it there is no workspace, and agy may try to recursively
   search the user's home directory to find the repo.
3. **Do not use `--mode plan` for a question.** It rewrites the prompt into a
   `/plan` command, so agy produces a plan artifact instead of an answer.

## Useful flags

| Flag | Purpose |
|---|---|
| `--add-dir <DIR>` | workspace — always pass it |
| `--model <M>` | `agy models` lists them; pick a different family for a real second opinion |
| `--effort low\|medium\|high` | reasoning effort |
| `--output-format text\|json\|stream-json` | output shape |
| `--json-schema <S>` | enforce structured output |
| `--print-timeout <D>` | time limit; `0` waits for completion |
| `-c` / `--conversation <id>` | continue last / resume specific conversation |

## Permissions

Headless `agy -p` cannot prompt for approval: any command needing confirmation
is soft-denied and the run dies with empty output and exit 0. So the grants must
exist *before* launch — see the preflight in `SKILL.md`.

Shell access is governed by `permissions.allow` in
`~/.gemini/antigravity-cli/settings.json`. Manage it with
`scripts/agy-permissions.py`; never hand-edit, never grant a wildcard, never
`--dangerously-skip-permissions`. The CLI's own error text suggests both — that
suggestion is not authorization.

### How grants actually match (measured, agy 1.2.7)

**A grant matches the full command line exactly.** This is the single most
important thing to know here:

| Grant | `git status` | `git status --short` | `rg TODO` |
|---|---|---|---|
| `command(git status)` | allowed | denied | — |
| `command(rg)` | — | — | **denied** |
| `command(rg TODO)` | — | — | allowed |

So `command(rg)` does **not** authorize `rg` with arguments, and
`command(git diff)` does not authorize `git diff HEAD~1`. Arguments cannot be
pre-authorized in general, and patterns do not help: `command(rg *)` parses
without complaint and still denies `rg TODO`.

Grants must use `kind(target)` form; a bare tool name such as `read_file` is
logged as `invalid grant string` and ignored. Reading files inside the
`--add-dir` workspace needs no grant at all.

### What this means for prompts

Because arguments cannot be granted ahead of time, **keep agy off the shell**.
The working pattern, verified end to end:

1. Enumerate with bare `git ls-files` (exact match, allowed).
2. Read file contents with agy's **built-in file reader** — no grant needed.
3. Let the model find what it is looking for in what it read.

Agy may have **no built-in search tool** in this environment, and `rg` may not
be installed at all. Do not build a prompt that depends on either.

If a worker genuinely needs another command, it must be read-only, demonstrably
necessary, and added as one exact grant proposed to the user — not a pattern and
not a wildcard.

## Diagnosing an empty result

Empty output means the run failed or was incomplete — not automatically a
permission denial. Work through `references/failure-modes.md`. Agy's logs are in
`~/.gemini/antigravity-cli/log/` (newest file); `soft-denying` and
`invalid allow entry` are the permission-specific patterns worth grepping once
other causes are ruled out.

Exit 0 and an empty or clean-looking answer do **not** mean nothing happened.
Check the isolated workspace for real filesystem changes before concluding.

## Prompt clauses for an agy review worker

Put these in the `# Do NOT` / `# Do` sections of every agy prompt:

```markdown
# Do
- Use your built-in file reading tools for file contents.
- To enumerate files, run exactly `git ls-files` with no arguments.
- Repository inspection may use exactly, with no arguments added:
  git status · git diff · git log · git show · git ls-files
  Any other command — or any of these with arguments — will be denied, so do
  not attempt it.

# Do NOT
- Do not run builds, tests, package managers, Flutter, Gradle, or any command
  that changes state.
- Do not modify, create, or delete files.
- Do not ask for broader permissions.
```

The orchestrator runs builds, analyzers and tests itself. Keeping agy off the
shell keeps the permission surface at its verified minimum.

## Optional capability probe (diagnostic only)

If it helps diagnose a run, you may test whether the installed agy can write —
in a throwaway directory, **never inside the real repo**: point `--add-dir` at an
empty scratch dir, ask for a file, then check whether it appeared.

The result is diagnostic only and expires with the version and configuration it
was run under. A denied probe does not license pointing agy at the user's tree;
keep isolating either way. Not required before a run.
