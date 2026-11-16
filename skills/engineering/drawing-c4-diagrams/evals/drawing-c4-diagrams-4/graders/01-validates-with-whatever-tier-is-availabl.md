---
type: llm
focus: trace
weight: 1
---

Validates with whatever tier is available — MCP tools if connected, otherwise headless `structurizr/structurizr validate -workspace workspace.dsl` (a parser exception / non-zero exit is the validation signal; a failed `export` is the same signal), or careful reading at Tier 0
