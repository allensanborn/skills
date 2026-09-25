#!/usr/bin/env bash
# Dev-only: symlink every skill in this repo into the local skill directories, so edits
# are live in the next session and `git pull` is the only update step.
#   ~/.claude/skills  — Claude Code
#   ~/.agents/skills  — Codex and other Agent Skills-compatible harnesses
# Don't also install the allensanborn-skills plugin on the same machine: you'd get every
# skill twice.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.claude/skills" "$HOME/.agents/skills")

names=()
srcs=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  names+=("$(basename "$src")")
  srcs+=("$src")
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/deprecated/*' -print0)

fail=0
for DEST in "${DESTS[@]}"; do
  # A DEST that is itself a symlink into this repo would make us write links into skills/.
  if [ -L "$DEST" ]; then
    case "$(readlink -f "$DEST")" in
      "$REPO"|"$REPO"/*) echo "error: $DEST is a symlink into this repo; remove it and re-run" >&2; exit 1 ;;
    esac
  fi
  mkdir -p "$DEST"

  for i in "${!names[@]}"; do
    target="$DEST/${names[$i]}"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      # Only replace an empty directory. Anything with content may be another install.
      if rmdir "$target" 2>/dev/null; then :; else
        echo "skip $target: exists and is not an empty dir or symlink (remove it yourself)" >&2
        fail=1
        continue
      fi
    fi
    ln -sfn "${srcs[$i]}" "$target"
    echo "linked ${names[$i]} -> ${srcs[$i]#"$REPO"/} ($DEST)"
  done
done
exit "$fail"
