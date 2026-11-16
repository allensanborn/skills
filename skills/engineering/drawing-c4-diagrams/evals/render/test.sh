#!/usr/bin/env bash
# Render test: AWS icon theme through every Structurizr export path.
# Asserts today's behaviour -- what works AND what doesn't -- so an upstream change fails here
# and the docs (references/structurizr-dsl.md, "Icons outside the Structurizr renderer") get updated.
# Needs Docker and network: pulls pinned images; the URL-theme cases fetch icons from GitHub.
# Usage: bash evals/render/test.sh [output-dir]   render with Docker, then check (output kept when given)
#        bash evals/render/test.sh --check DIR    check renders someone else made (the Dagger renderTest)
# The pins below are mirrored in .dagger/src/index.ts; bump both together.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
STRUCTURIZR=structurizr/structurizr:2026.10.26-playwright
PLANTUML=plantuml/plantuml:1.2026.10
MERMAID=minlag/mermaid-cli:12.0.0
# Pinned to the structurizr/structurizr release tag matching $STRUCTURIZR, so upstream pushes cannot change results
THEME_URL=https://raw.githubusercontent.com/structurizr/structurizr/v2026.10.26/structurizr-themes/amazon-web-services-2025.07/theme.json

render() {
  mkdir -p "$WORK"
  cp "$HERE/aws-deployment.dsl" "$WORK/installed.dsl"
  sed "s#theme amazon-web-services-2025.07#theme $THEME_URL#" "$HERE/aws-deployment.dsl" >"$WORK/url.dsl"
  dockerq() { docker run --rm --ipc=host -v "$WORK:/work" -w /work "$@" >"$WORK/last.log" 2>&1 || { cat "$WORK/last.log"; exit 1; }; }
  structurizr() { dockerq -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes "$STRUCTURIZR" "$@"; }

  echo "== rendering"
  structurizr export -workspace installed.dsl -format svg -output installed/svg
  structurizr export -workspace installed.dsl -format plantuml -output installed/plantuml
  structurizr export -workspace installed.dsl -format mermaid -output installed/mermaid
  structurizr export -workspace url.dsl -format plantuml -output url/plantuml
  structurizr export -workspace url.dsl -format plantuml/c4plantuml -output url/c4plantuml
  structurizr export -workspace url.dsl -format mermaid -output url/mermaid
  dockerq "$PLANTUML" -tsvg url/plantuml/structurizr-Deployment.puml
  dockerq -u "$(id -u):$(id -g)" -e HOME=/tmp "$MERMAID" -i url/mermaid/structurizr-Deployment.mmd -o url/mermaid/structurizr-Deployment.svg
}

if [ "${1:-}" = "--check" ]; then
  WORK="${2:?usage: test.sh --check DIR}"
else
  WORK="${1:-$(mktemp -d)}"
  render
fi

pass=0 fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok   $1 ($3)"; pass=$((pass + 1))
  else echo "FAIL $1: expected $2, got $3"; fail=$((fail + 1)); fi
}
count() { # a missing file must not pass as "0 icons"
  [ -f "$2" ] || { echo "missing"; return; }
  { grep -o "$1" "$2" || true; } | wc -l | tr -d ' '
}

echo "== installed theme (bundled in the image; icons inlined as data: URIs)"
check "SVG export embeds icons" 9 "$(count 'data:image/png;base64' "$WORK/installed/svg/Deployment.svg")"
check "PlantUML drops data: icons" 0 "$(count '<img:' "$WORK/installed/plantuml/structurizr-Deployment.puml")"
check "Mermaid drops data: icons" 0 "$(count '<img ' "$WORK/installed/mermaid/structurizr-Deployment.mmd")"

echo "== URL theme (same theme from GitHub raw; icons become https URLs)"
check "PlantUML references every icon" 9 "$(count '<img:https://' "$WORK/url/plantuml/structurizr-Deployment.puml")"
check "C4-PlantUML: no deployment icons (exporter writes \$tags=\"\")" 0 "$(count 'img:' "$WORK/url/c4plantuml/structurizr-Deployment.puml")"
check "Mermaid: icons on infrastructure nodes only" 3 "$(count "<img src='https://" "$WORK/url/mermaid/structurizr-Deployment.mmd")"

echo "== rendered URL-theme exports"
check "PlantUML SVG embeds every fetched icon" 9 "$(count 'xlink:href="data:image/png' "$WORK/url/plantuml/structurizr-Deployment.svg")"
check "Mermaid SVG links 3 icons (remote URLs, need network to view)" 3 "$(count '<img src="https://' "$WORK/url/mermaid/structurizr-Deployment.svg")"

echo "== $pass passed, $fail failed (output: $WORK)"
[ "$fail" -eq 0 ]
