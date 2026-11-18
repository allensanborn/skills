# allensanborn-skills

## 0.2.1

### Patch Changes

- [#29](https://github.com/allensanborn/skills/pull/29) [`8f4dae6`](https://github.com/allensanborn/skills/commit/8f4dae6af1fa487ceb42eb911aa814b45fa228fb) Thanks [@allensanborn](https://github.com/allensanborn)! - `drawing-c4-diagrams` now commits SVG for diagrams that go into a repo (about 10x smaller than PNG, renders on GitHub, zoomable, icons embedded). It still renders PNG to look at and measure each view, and commits PNG instead only where SVG won't display, such as slides, chat or email.

## 0.2.0

### Minor Changes

- [#12](https://github.com/allensanborn/skills/pull/12) [`44d391d`](https://github.com/allensanborn/skills/commit/44d391d93320f68cad07cabba8e6bc9cfada00e4) Thanks [@allensanborn](https://github.com/allensanborn)! - The skills now install as a Claude Code plugin from this repo's own marketplace (`claude plugin install allensanborn-skills@allensanborn`), and `drawing-c4-diagrams` has a docs page at `docs/engineering/drawing-c4-diagrams.md`.

### Patch Changes

- [#13](https://github.com/allensanborn/skills/pull/13) [`78fbf50`](https://github.com/allensanborn/skills/commit/78fbf50e367f29dc39a3d4bfec0f9b457df9a368) Thanks [@allensanborn](https://github.com/allensanborn)! - `drawing-c4-diagrams` now checks legibility by measuring instead of eyeballing: each rendered view's width is compared with about 3.4× the width it will be shown at (about 3000 px for an 880 px GitHub README), and a view over that budget is fixed by tighter spacing, then a different layout direction, then a split. Crowded deployment views have a split-by-concern pattern (edge, data, async).
