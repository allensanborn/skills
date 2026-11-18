---
type: llm
focus: trace
weight: 1
---

Pulls the consolidated `structurizr/structurizr` image for Tier 1 at the pinned reference from SKILL.md (the `IMG` line: the `<release>-playwright` tag plus its digest, so PNG/SVG export works and nothing else runs), not the frozen `structurizr/lite` or `structurizr/cli` images (whose `:latest` is now a stub that exits immediately) and not a bare name or `latest`
