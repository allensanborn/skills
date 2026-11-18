# allensanborn-skills

## 0.2.2

### Patch Changes

- [#33](https://github.com/allensanborn/skills/pull/33) [`8980411`](https://github.com/allensanborn/skills/commit/8980411c0d0ad22addb466de01e05280c575aae2) Thanks [@allensanborn](https://github.com/allensanborn)! - drawing-c4-diagrams: each Docker image is pinned once, by tag and digest, in SKILL.md's "Pinned images"; every command uses `$IMG`, `$MCP_IMG` or `$PLANTUML_IMG`. Parse errors are explained as the modeling mistake behind them, and the references now say correctly which headless exports write filtered views (PNG/SVG write the filtered view and skip its base).

- [#33](https://github.com/allensanborn/skills/pull/33) [`7315a65`](https://github.com/allensanborn/skills/commit/7315a652ee166dc93a1241794cbebbdb8cf616c5) Thanks [@allensanborn](https://github.com/allensanborn)! - drawing-c4-diagrams: filtered-view and perspective guidance now lives in one place (structurizr-dsl.md, *Filtered views*), and the references no longer suggest filtered views for crowded diagrams in committed images.

- [#33](https://github.com/allensanborn/skills/pull/33) [`7f19bad`](https://github.com/allensanborn/skills/commit/7f19bad2812eb0a06e60be087d42307838deefb2) Thanks [@allensanborn](https://github.com/allensanborn)! - drawing-c4-diagrams: views default to `autolayout tb` (taller, never wider), with a rule against hand-tuning layout: split, filter, or shorten labels instead. The tier table names the `plantuml/c4plantuml` fallback.

- [#31](https://github.com/allensanborn/skills/pull/31) [`b42c7bf`](https://github.com/allensanborn/skills/commit/b42c7bfdf56384e6e3704254a1fe5150e7dfe383) Thanks [@allensanborn](https://github.com/allensanborn)! - drawing-c4-diagrams: declare `license: MIT` in the skill's frontmatter.

- [#33](https://github.com/allensanborn/skills/pull/33) [`de96e2f`](https://github.com/allensanborn/skills/commit/de96e2fde2a67cbcb3d098f55d21417a28433cb5) Thanks [@allensanborn](https://github.com/allensanborn)! - drawing-c4-diagrams: every Docker command now names a pinned image tag (the versions the render test runs), so an upstream push can't change what runs on your machine.

## 0.2.1

### Patch Changes

- [#29](https://github.com/allensanborn/skills/pull/29) [`8f4dae6`](https://github.com/allensanborn/skills/commit/8f4dae6af1fa487ceb42eb911aa814b45fa228fb) Thanks [@allensanborn](https://github.com/allensanborn)! - `drawing-c4-diagrams` now commits SVG for diagrams that go into a repo (about 10x smaller than PNG, renders on GitHub, zoomable, icons embedded). It still renders PNG to look at and measure each view, and commits PNG instead only where SVG won't display, such as slides, chat or email.

## 0.2.0

### Minor Changes

- [#12](https://github.com/allensanborn/skills/pull/12) [`44d391d`](https://github.com/allensanborn/skills/commit/44d391d93320f68cad07cabba8e6bc9cfada00e4) Thanks [@allensanborn](https://github.com/allensanborn)! - The skills now install as a Claude Code plugin from this repo's own marketplace (`claude plugin install allensanborn-skills@allensanborn`), and `drawing-c4-diagrams` has a docs page at `docs/engineering/drawing-c4-diagrams.md`.

### Patch Changes

- [#13](https://github.com/allensanborn/skills/pull/13) [`78fbf50`](https://github.com/allensanborn/skills/commit/78fbf50e367f29dc39a3d4bfec0f9b457df9a368) Thanks [@allensanborn](https://github.com/allensanborn)! - `drawing-c4-diagrams` now checks legibility by measuring instead of eyeballing: each rendered view's width is compared with about 3.4× the width it will be shown at (about 3000 px for an 880 px GitHub README), and a view over that budget is fixed by tighter spacing, then a different layout direction, then a split. Crowded deployment views have a split-by-concern pattern (edge, data, async).
