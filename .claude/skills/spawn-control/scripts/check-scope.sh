#!/usr/bin/env bash
# check-scope.sh <worktree> <base-sha> <allowed-path-or-prefix>...
#
# Fails non-zero if the worktree changed anything outside the declared scope,
# relative to the commit the worker started from. Inspects only; never modifies
# the repository.
#
#   BASE=$(git -C "$WT" rev-parse HEAD)     # before spawning the worker
#   check-scope.sh "$WT" "$BASE" lib/auth/ test/auth/
#
# Four sources are checked, so a worker cannot hide a change by committing it:
#   BASE..HEAD        committed
#   HEAD..index       staged
#   index..worktree   unstaged
#   untracked files
#
# A trailing "/" means "this directory and everything under it".
# Without one, the entry matches that exact path or anything beneath it.
#
# Known limit: untracked detection honours .gitignore, so changes to ignored
# paths (build output, caches) are not reported.

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "usage: check-scope.sh <worktree> <base-sha> <allowed-path-or-prefix>..." >&2
  exit 2
fi

wt=$1
base=$2
shift 2
allowed=("$@")

if ! git --no-optional-locks -C "$wt" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "check-scope: not a git worktree: $wt" >&2
  exit 2
fi

if ! git --no-optional-locks -C "$wt" rev-parse --verify --quiet "${base}^{commit}" >/dev/null; then
  echo "check-scope: not a commit in $wt: $base" >&2
  exit 2
fi

in_scope() {
  local p=$1 a
  for a in "${allowed[@]}"; do
    case "$a" in
      */) [ "${p#"$a"}" != "$p" ] && return 0 ;;
      *)
        [ "$p" = "$a" ] && return 0
        [ "${p#"$a"/}" != "$p" ] && return 0
        ;;
    esac
  done
  return 1
}

paths=()
srcs=()
source_label=""

record() {
  paths+=("$1")
  srcs+=("$source_label")
}

# `git diff --name-status -z` emits the status as its own NUL-terminated field,
# followed by one path — or two, for renames and copies.
collect_name_status() {
  local fields=() f st
  while IFS= read -r -d '' f; do fields+=("$f"); done
  local i=0 n=${#fields[@]}
  while [ "$i" -lt "$n" ]; do
    st=${fields[$i]}
    i=$((i + 1))
    case "$st" in
      R* | C*)
        [ "$i" -lt "$n" ] && { record "${fields[$i]}"; i=$((i + 1)); }
        [ "$i" -lt "$n" ] && { record "${fields[$i]}"; i=$((i + 1)); }
        ;;
      *)
        [ "$i" -lt "$n" ] && { record "${fields[$i]}"; i=$((i + 1)); }
        ;;
    esac
  done
}

collect_plain() {
  local f
  while IFS= read -r -d '' f; do record "$f"; done
}

g() { git --no-optional-locks -C "$wt" "$@"; }

source_label=committed
collect_name_status < <(g diff --name-status -z "$base" HEAD)

source_label=staged
collect_name_status < <(g diff --cached --name-status -z)

source_label=unstaged
collect_name_status < <(g diff --name-status -z)

source_label=untracked
collect_plain < <(g ls-files --others --exclude-standard -z)

# Collect violations, deduping by path — the same path often shows up from
# more than one source. Compared as array elements, so newlines or tabs in a
# path cannot confuse the grouping.
bad_paths=()
bad_srcs=()
i=0
n=${#paths[@]}
while [ "$i" -lt "$n" ]; do
  p=${paths[$i]}
  s=${srcs[$i]}
  if ! in_scope "$p"; then
    seen=0
    j=0
    while [ "$j" -lt "${#bad_paths[@]}" ]; do
      if [ "${bad_paths[$j]}" = "$p" ]; then
        case " ${bad_srcs[$j]} " in
          *" $s "*) : ;;
          *) bad_srcs[$j]="${bad_srcs[$j]} $s" ;;
        esac
        seen=1
        break
      fi
      j=$((j + 1))
    done
    if [ "$seen" -eq 0 ]; then
      bad_paths+=("$p")
      bad_srcs+=("$s")
    fi
  fi
  i=$((i + 1))
done

if [ "${#bad_paths[@]}" -eq 0 ]; then
  echo "check-scope: OK — ${n} change record(s) since ${base:0:8}, all within scope"
  exit 0
fi

echo "check-scope: OUT OF SCOPE — ${#bad_paths[@]} path(s) since ${base:0:8}:" >&2
i=0
while [ "$i" -lt "${#bad_paths[@]}" ]; do
  printf '  [%s] %s\n' "${bad_srcs[$i]}" "${bad_paths[$i]}" >&2
  i=$((i + 1))
done
echo "allowed: ${allowed[*]}" >&2
exit 1
