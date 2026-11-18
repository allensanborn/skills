#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Allen Sanborn
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
  echo "==> claude plugin validate (strict, except the root CLAUDE.md warning)"
  # --strict, minus one warning: CLAUDE.md/AGENTS.md at the root are for contributors,
  # not plugin context, and the validator flags them on every repo with that layout.
  claude plugin validate . --json | python3 -c '
import json, sys
r = json.load(sys.stdin)
bad = [f"{p['file']}: {m['message']}"
       for p in [r["manifest"], *r["contents"]]
       for m in p["errors"] + p["warnings"]
       if not m["message"].startswith("CLAUDE.md at the plugin root")]
print("\n".join(bad) or "marketplace + plugin: OK")
sys.exit(1 if bad or not r["success"] else 0)'
else
  echo "==> claude plugin validate: skipped (claude CLI not installed)"
fi

echo "==> plugin.json version matches package.json"
node scripts/sync-plugin-version.mjs --check

echo "==> script tests, with coverage floors (90% lines, 80% branches)"
npm test --silent

echo "==> skill-lint"
# Validates SKILL.md name/description limits, allowed frontmatter fields,
# one-level references, referenced-files-exist, <500 lines.
npx --yes skill-lint ./skills

echo "==> docker images in skills are pinned by digest, and match the render test"
c4=skills/engineering/drawing-c4-diagrams
unpinned=$(grep -rnE 'docker (run|pull)|--entrypoint|^[[:space:]]+(structurizr|plantuml)/' "$c4/SKILL.md" "$c4/references" \
  | grep -E '(structurizr/structurizr|structurizr/mcp|plantuml/plantuml)(:[A-Za-z0-9._-]+)?([^@:A-Za-z0-9._/-]|$)' || true)
if [ -n "$unpinned" ]; then echo "UNPINNED image:"; echo "$unpinned"; exit 1; fi
for var in STRUCTURIZR PLANTUML; do
  img=$(sed -nE "s/^$var=(.*)/\1/p" "$c4/evals/render/test.sh")
  grep -qF "\`$img\`" "$c4/SKILL.md" || { echo "SKILL.md Pinned images lacks $img (from test.sh)"; exit 1; }
done

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
