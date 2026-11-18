---
type: llm
focus: trace
weight: 1
---

Checks legibility against the README budget (about 880 px of display, so an image no wider than about 3000 px): measures the rendered width, or, since Docker is blocked inside the `claude plugin eval` sandbox, judges it from the view (13 elements, many datastore and bus edges, `autolayout lr`) and says plainly that it could not measure
