---
"allensanborn-skills": patch
---

`drawing-c4-diagrams` now checks legibility by measuring instead of eyeballing: each rendered view's width is compared with about 3.4× the width it will be shown at (about 3000 px for an 880 px GitHub README), and a view over that budget is fixed by tighter spacing, then a different layout direction, then a split. Crowded deployment views have a split-by-concern pattern (edge, data, async).
