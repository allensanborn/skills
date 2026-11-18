---
type: llm
focus: trace
weight: 1
---

Actually renders the view and looks at it (render-and-look is not skippable), not just DSL validation. Docker is blocked inside the `claude plugin eval` sandbox, so a run that attempts this with the correct command and then says plainly it could not render or verify (rather than claiming it did) also passes; the rendering itself is tested by `dagger call render-test`.
