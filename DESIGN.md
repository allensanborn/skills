# Design notes

## drawing-c4-diagrams

Finalized 2026-07-03 (grill session). Tracked in beads epic `llm-wiki-j1x`.

| Decision | Resolution |
| --- | --- |
| Distribution | Portable/shareable collection repo (`allensanborn/skills`), Pocock-pattern; private now → public + MIT on ship |
| Packaging | One **model-invoked** skill `skills/engineering/drawing-c4-diagrams/`; lean `SKILL.md` (<500 lines) + `references/` |
| Runtimes | **Structurizr MCP** = inner loop (validate + Mermaid preview; local Docker default, public `mcp.structurizr.com` opt-in). **Structurizr Lite** = outer loop (browser render/layout at :8080) |
| Capability tiers | Bottom-up: Tier 0 no-tools/local → Tier 1 +Docker MCP → Tier 2 +Docker Lite; Docker-first when installing |
| Setup | `/c4-setup`-style flow: probe env → ask prefs → persist `.c4-diagrams.json` → silent reuse → re-probe on drift |
| Knowledge | Self-contained `references/`, distilled from original wiki prose; attributed to Simon Brown; **no book text, no external repo dependency** |
| Grill | Two-phase: pre-generation scoping grill (**hard to skip**) + post-generation review-checklist grill (**skippable** via "skip the grill", on by default) |
| Image → DSL | Both modes; onset assesses complexity + asks preference; simple → one-pass, complex → push grill; build model level-by-level |
| Output | `docs/architecture/workspace.dsl` (+ `exports/`), configurable |
| Quality | Evals-first (fixtures from Simon Brown's published example diagrams); **Dagger CI first**, GitHub Actions only when ship-ready |

### Provenance

Authored from the O'Reilly book *The C4 Model* (Simon Brown) and the Structurizr docs
(`docs.structurizr.com/local/quickstart`, `/ai/dsl-generation`, `/ai/mcp`), ingested into a
separate personal knowledge wiki. The shipped `references/` are original-prose distillations
of that ingest — this repo carries no book text and no dependency on the wiki.
