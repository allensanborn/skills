---
type: llm
focus: trace
weight: 1
---

Runs `structurizr inspect` for the model-completeness lint (missing descriptions/technology, disconnected elements, elements on no view) Docker is blocked inside the `claude plugin eval` sandbox, so a run that attempts this with the correct command and then says plainly it could not render or verify (rather than claiming it did) also passes; the rendering itself is tested by `dagger call render-test`.
