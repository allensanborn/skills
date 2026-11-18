---
type: llm
focus: trace
weight: 1
---

Runs `validate` (or treats a failed export) as the validation signal; verifies each view is non-empty via the exported workspace.json counts Docker is blocked inside the `claude plugin eval` sandbox, so a run that attempts this with the correct command and then says plainly it could not render or verify (rather than claiming it did) also passes; the rendering itself is tested by `dagger call render-test`.
