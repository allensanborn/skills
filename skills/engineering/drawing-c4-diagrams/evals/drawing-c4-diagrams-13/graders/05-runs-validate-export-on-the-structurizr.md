---
type: llm
focus: trace
weight: 1
---

Runs validate/export on the `structurizr/structurizr:<release>-playwright` image with `-e STRUCTURIZR_THEMES=/usr/local/structurizr-themes`, and exports PNG/SVG (not Mermaid/PlantUML) for the icon diagram Docker is blocked inside the `claude plugin eval` sandbox, so a run that attempts this with the correct command and then says plainly it could not render or verify (rather than claiming it did) also passes; the rendering itself is tested by `dagger call render-test`.
