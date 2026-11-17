# drawing-c4-diagrams: one model-invoked skill, grill-first, local Structurizr toolchain

Finalized 2026-07-03 in a grill session, tracked at the time in beads epic `llm-wiki-j1x` (in the separate wiki repo's tracker). Moved here from `DESIGN.md` on 2026-11-17 when the repo adopted mattpocock/skills conventions.

The skill turns a described or pasted architecture into C4 diagrams. The risk it designs against is the user passively accepting generated boxes, so the shape of the skill is driven by the grill as much as by the DSL.

## Decision

| Concern | Resolution |
| --- | --- |
| Distribution | Portable, shareable collection repo (`allensanborn/skills`), on the mattpocock/skills pattern; private now, public and MIT on ship |
| Packaging | One **model-invoked** skill `skills/engineering/drawing-c4-diagrams/`; lean `SKILL.md` (under 500 lines) plus `references/` |
| Runtimes | **Structurizr MCP** is the inner loop (validate and Mermaid preview; local Docker by default, public `mcp.structurizr.com` opt-in). **Structurizr Lite** is the outer loop (browser render and layout at :8080) |
| Capability tiers | Bottom-up: Tier 0 no tools, Tier 1 adds Docker MCP, Tier 2 adds Docker Lite; Docker-first when installing |
| Setup | A `/c4-setup`-style flow: probe the environment, ask preferences, persist `.c4-diagrams.json`, reuse silently, re-probe on drift |
| Knowledge | Self-contained `references/`, distilled from original wiki prose and attributed to Simon Brown; **no book text, no external repo dependency** |
| Grill | Two phases: a pre-generation scoping grill (**hard to skip**) and a post-generation review-checklist grill (**skippable** via "skip the grill", on by default) |
| Image to DSL | Both modes. At onset, assess complexity and ask the user's preference: simple images go one-pass, complex ones push the grill. Build the model level by level |
| Output | `docs/architecture/workspace.dsl` (plus `exports/`), configurable |
| Quality | Evals-first (fixtures from Simon Brown's published example diagrams); **Dagger CI first**, GitHub Actions only when ship-ready |

## Provenance

Authored from the O'Reilly book *The C4 Model* (Simon Brown) and the Structurizr docs (`docs.structurizr.com/local/quickstart`, `/ai/dsl-generation`, `/ai/mcp`), ingested into a separate personal knowledge wiki. The shipped `references/` are original-prose distillations of that ingest: this repo carries no book text and no dependency on the wiki.

## Update, 2026-11-17

The "GitHub Actions only when ship-ready" line is narrowed: issue-triage and changeset-release workflows now run on GitHub Actions (adopted from mattpocock/skills). Quality gates (lint, Vale, markdownlint, render-test) still run in Dagger only; bead `skills-8wp` tracks wiring them into Actions.
