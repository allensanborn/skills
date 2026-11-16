---
type: llm
focus: trace
weight: 1
---

Pulls the consolidated `structurizr/structurizr` image for Tier 1 (the `<release>-playwright` tag, so PNG/SVG export works), not the frozen `structurizr/lite` or `structurizr/cli` images (whose `:latest` is now a stub that exits immediately)
