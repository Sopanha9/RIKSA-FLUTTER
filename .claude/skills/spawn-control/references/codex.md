# Codex CLI

Verified against `codex-cli 0.155.1`. Re-run `codex exec --help` at session
preflight; **the installed help wins** over anything below.

## Shape

Prompt on stdin, final answer to a file, transcript to a log:

```bash
codex exec -C "$REPO" -s <sandbox> -o "$OUT/last.md" \
  < "$OUT/prompt.md" > "$OUT/log.txt" 2>&1
```

`codex exec` is non-interactive. It reads the prompt from stdin when none is
given as an argument, so heredocs and prompt files work well on Windows, where
inline multi-line quoting is unreliable.

## Sandbox modes

| Mode | Use |
|---|---|
| `read-only` | **default** — review, investigation, analysis |
| `workspace-write` | implementation; pair with `--worktree` unless told otherwise |
| `danger-full-access` | never |

## Isolation

`--worktree` runs the session in a managed Git worktree, so writes never land in
the user's tree. Combined with the sandbox, this is the posture for any writing
codex run. Note a worktree shares the repository's common Git directory — it
isolates files, not Git metadata. That is acceptable here because the sandbox is
part of the protection; a worker you trust less needs an independent clone.

Record `BASE=$(git -C "$WT" rev-parse HEAD)` once the worktree exists, before the
run, so `scripts/check-scope.sh` can see commits the worker makes.

To integrate afterwards: locate the worktree (`git worktree list`), read its
diff from `$BASE`, verify it, then apply it with ordinary Git — a reviewed
cherry-pick, or the reviewed diff applied. **Do not use `codex apply` as the
integration path for a local managed-worktree run.**

## Useful flags

| Flag | Purpose |
|---|---|
| `-C, --cd <DIR>` | working root for the agent |
| `-o <FILE>` | write final message to file (always use this) |
| `-m, --model <M>` | model override |
| `--add-dir <DIR>` | extra writable path alongside the workspace |
| `--json` | JSONL events — use when you need to see tool calls |
| `--output-schema <FILE>` | JSON Schema for the final response shape |
| `--skip-git-repo-check` | allow running outside a Git repo |
| `--ephemeral` | don't persist session files |

Follow-up turn on the same session:

```bash
codex exec resume --last -o "$OUT/last2.md" < "$OUT/followup.md"
```

## Prohibited

`--dangerously-bypass-approvals-and-sandbox`, `--dangerously-bypass-hook-trust`.

A sandbox denial is a finding about the task, not a reason to widen the sandbox.
If a run genuinely needs more access, the narrow fix is `--add-dir` for a
specific path — proposed to the user, not assumed.

## Notes

- `codex exec review` runs a code review non-interactively; `codex review` is the
  interactive form.
- `codex agents` only browses sessions on the local daemon. There is no
  `agents/*.yaml` worker-definition file to author.
