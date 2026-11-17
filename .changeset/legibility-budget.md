---
"allensanborn-skills": patch
---

`drawing-c4-diagrams` now checks legibility by measuring instead of eyeballing: each rendered view's width is compared with about 3× the width it will be shown at (880 px for a GitHub README), and a view over that budget gets split. Crowded deployment views have a split-by-concern pattern (edge, data, async).
