#!/usr/bin/env bash
#
# Audit a beads repo against the desired state. Run with no args in a repo, or pass paths.
# Exits non-zero if any repo has a problem, so it works in CI or a pre-flight check.
#
# COPY. Canonical version and the reasoning behind each check live in:
#   https://github.com/allensanborn/beads-roundtrip-probe/blob/main/BEADS-PROCEDURE.md  (§9)
# If you change the checks, change them there first, then re-copy to the other beads repos
# (llm-wiki, skills, floci-harness). There is no shared package; these are independent copies.
#
set -uo pipefail

audit_one() {
  local d=$1 bad=0
  cd "$d" 2>/dev/null || { echo "$d: not a directory"; return 1; }
  printf '%-24s' "$(basename "$d")"

  # Hooks: covers BOTH arrangements — pre-commit-installed, and core.hooksPath (bd's
  # tracked hooks). Do NOT reduce to `ls .git/hooks | grep -v sample`: `ls` is aliased on
  # some machines and that version reports DEAD while hooks are fine.
  if [ -n "$(git config --get core.hooksPath)" ] || [ -f .git/hooks/pre-push ]; then
    printf 'hooks:OK '
  else printf 'hooks:DEAD '; bad=1; fi

  bd list >/dev/null 2>&1 && printf 'db:OK ' || { printf 'db:MISSING '; bad=1; }

  # `bd dolt remote list`, never `bd dolt show` — the latter reports (none) even when a
  # remote is configured and working. A missing remote is the precondition for the one
  # genuinely unrecoverable beads failure.
  bd dolt remote list 2>/dev/null | grep -q origin && printf 'remote:OK ' \
    || { printf 'remote:NONE '; bad=1; }

  [ -n "$(git config --get beads.role)" ] && printf 'role:OK ' || printf 'role:UNSET '

  local p; p=$(stat -f "%Lp" .beads 2>/dev/null || stat -c "%a" .beads 2>/dev/null)
  [ "$p" = "700" ] && printf 'perm:OK ' || printf 'perm:%s ' "$p"

  local up; up=$(git log --oneline @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  printf 'unpushed:%s' "$up"

  echo
  return $bad
}

rc=0
for d in "${@:-$PWD}"; do audit_one "$d" || rc=1; done
exit $rc
