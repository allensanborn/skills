#!/usr/bin/env bash
# Portable quality checks for the skills collection.
# Run locally (`bash ci/check.sh`) or from the Dagger module in .dagger/.
# Intentionally dependency-light: only needs bash + npx (Node).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> skill-lint"
# Validates SKILL.md name/description limits, allowed frontmatter fields,
# one-level references, referenced-files-exist, <500 lines.
npx --yes skill-lint ./skills

echo "==> reference link check (one level deep, files exist)"
fail=0
while IFS= read -r skill; do
  dir="$(dirname "$skill")"
  # extract markdown links to local .md files and confirm they resolve
  grep -oE '\]\(([^)]+\.md)\)' "$skill" | sed -E 's/^\]\(//; s/\)$//' | while read -r link; do
    case "$link" in
      http*|"") continue ;;
    esac
    if [ ! -f "$dir/$link" ]; then
      echo "BROKEN LINK in $skill -> $link"
      fail=1
    fi
  done
  [ "$fail" -eq 1 ] && exit 1 || true
done < <(find skills -name SKILL.md)

echo "==> OK"
