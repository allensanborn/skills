#!/usr/bin/env bash
# Portable quality checks for the skills collection.
# Run locally (`bash ci/check.sh`) or from the Dagger module in .dagger/.
# Intentionally dependency-light: only needs bash + npx (Node).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> plugin manifest lists exactly the shipped skills"
# Shipped = every SKILL.md outside in-progress/, personal/, misc/, deprecated/.
shipped="$(find skills -name SKILL.md \
  -not -path 'skills/in-progress/*' -not -path 'skills/personal/*' \
  -not -path 'skills/misc/*' -not -path 'skills/deprecated/*' \
  -exec dirname {} \; | sed 's|^|./|' | sort)"
listed="$(grep -oE '"\./skills/[^"]+"' .claude-plugin/plugin.json | tr -d '"' | sort)"
if [ "$shipped" != "$listed" ]; then
  echo "plugin.json 'skills' is out of sync with skills/ (< on disk, > in plugin.json):"
  diff <(echo "$shipped") <(echo "$listed") || true
  exit 1
fi

if command -v claude >/dev/null 2>&1; then
  echo "==> claude plugin validate --strict"
  claude plugin validate . --strict
  claude plugin validate .claude-plugin/plugin.json --strict
else
  echo "==> claude plugin validate: skipped (claude CLI not installed)"
fi

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
