---
name: drawing-c4-diagrams
description: Create and refine C4-model software architecture diagrams as Structurizr DSL, validated and rendered locally, and interrogate the user Socratically so they engage with and defend the design instead of passively accepting generated output. Use whenever the user wants to diagram, visualize, or document software architecture; mentions C4, system context / container / component diagrams, Structurizr, "draw the architecture", "architecture diagram", or pastes a whiteboard/hand-drawn/existing diagram image to turn into a diagram.
---

# Drawing C4 diagrams

Turn a user's architecture — described in words or pasted as an image — into correct
[C4 model](references/c4-model.md) diagrams, expressed as **Structurizr DSL** (one text
model, many diagrams, no drift), validated and rendered **locally**. The point of this
skill is not to hand over pretty boxes: it is to **make the user think**. You grill them
about audience, scope, abstractions, and boundaries so the diagram means something.

Assume Claude already knows software architecture. Add only C4-specific rigor and the
local Structurizr toolchain.

## Workflow

Copy this checklist and work top to bottom:

```
- [ ] 0. Load capability config (or run setup) and locate the workspace
- [ ] 1. SCOPE — pre-generation grill (hard to skip)
- [ ] 2. AUTHOR — generate/extend Structurizr DSL (from words or a pasted image)
- [ ] 3. VALIDATE + PREVIEW — inner loop (MCP; Mermaid preview)
- [ ] 4. RENDER — outer loop (Structurizr Lite at :8080), if the user wants it
- [ ] 5. REVIEW — post-generation grill (skippable), then export
```

## 0. Capabilities and setup

This skill works at three capability tiers and **degrades gracefully** — never assume a
tool is installed.

| Tier | Needs | You can |
| --- | --- | --- |
| **0 — always** | nothing | author + validate DSL by eye, export **Mermaid** as text, tell the user to paste it into the structurizr.com/dsl playground |
| **1 — +MCP** | Docker (or the public server) | validate/parse DSL and export Mermaid/PlantUML programmatically — the fast inner loop |
| **2 — +Lite** | Docker + a browser | render real C4 diagrams and edit layout at `http://localhost:8080` |

On first use, look for the config file `.c4-diagrams.json` at the repo root. If it is
missing, run the **setup flow** in [references/runtime-and-mcp.md](references/runtime-and-mcp.md):
probe for `docker` and a browser, ask the user which tier they want (offer to
`docker pull` the images — **prefer Docker** when installing tooling), ask where diagrams
should live (default `docs/architecture/`), and persist their answers. On later runs,
read the config silently; only re-prompt if it is missing or a declared tool has gone
away (re-probe on drift).

**Privacy:** default the MCP server to **local Docker**, not the public
`mcp.structurizr.com` — architecture DSL can be sensitive. The public server is opt-in.

**Output location:** the DSL source of truth is `<configured-dir>/workspace.dsl`
(default `docs/architecture/workspace.dsl`); exports go in `<configured-dir>/exports/`.
Create the directory if missing. Never write diagram files outside it.

## 1. SCOPE — the pre-generation grill (hard to skip)

Before writing any DSL, interview the user with the **Section A** questions in
[references/grill-questions.md](references/grill-questions.md). Ask **one question at a
time**, each with a recommended answer, so the user can accept with a word — but do not
skip these. You are pinning what people always leave ambiguous:

- **audience & purpose** — who reads this, and what decision does it support?
- **the system in scope** — the single boundary this diagram is about.
- **workspace scope** — **one** system, or **many**? If the architecture spans multiple systems —
  especially across multiple teams/repos — size the scope (single-system vs one `unscoped` landscape
  workspace vs the decentralized **enterprise** pattern) *before* authoring, using
  [references/multi-system-and-enterprise.md](references/multi-system-and-enterprise.md). Structurizr's
  default is **one software system per workspace**.
- **the people/actors** who use it.
- **the external systems** it depends on.
- **which C4 level(s)** to draw now (start at System Context unless told otherwise).

This is the step that stops "boxes and lines that mean different things to different
people." Do not proceed to DSL until these are answered.

## 2. AUTHOR — generate the Structurizr DSL

Write or extend `workspace.dsl` following [references/structurizr-dsl.md](references/structurizr-dsl.md).
Build the model **one C4 level at a time** (System Context → Containers → Components);
render many views from the one model. For common architectures (SPA+API+DB, message
queues, microservices, external SaaS, serverless) and the DSL features that express them
cleanly — plus the modeling errors to catch — use
[references/patterns-and-pitfalls.md](references/patterns-and-pitfalls.md).

**If the user pastes an image**, follow [references/image-to-dsl.md](references/image-to-dsl.md):
assess its complexity and ask whether they want a one-pass conversion or to be grilled.
Simple image → one pass is fine. Complex image → strongly encourage the grill, and run
the **Section B interpretation grill** (confirm each element's C4 mapping; reject silent
Docker-container-vs-C4-container or infra-vs-software-system confusion) before emitting DSL.

## 3. VALIDATE + PREVIEW — the inner loop

After every DSL edit, if MCP is available, validate and preview **before** showing the
user (validator → fix → repeat):

- Validate/parse with `structurizr-mcp:*` DSL tools.
- Export a **Mermaid** view for an inline preview (renders in chat/Markdown, no browser).

See [references/runtime-and-mcp.md](references/runtime-and-mcp.md) for exact tool names and
fallbacks. If Docker is present but MCP is not connected, use the **headless `structurizr/structurizr
export`** command as the inner loop — a failed export (parser exception / non-zero exit) is your
validation signal. At Tier 0 (no Docker), validate by careful reading and give the user the DSL
plus a Mermaid export to paste into the playground.

## 4. RENDER — the outer loop (optional)

When the user wants the real, polished C4 render or to nudge layout, start **Structurizr
Lite** (Docker, mounts the diagram dir, serves `http://localhost:8080`) per
[references/runtime-and-mcp.md](references/runtime-and-mcp.md). Layout tweaks auto-save
back to disk. Skip this entirely at Tier 0/1.

## 5. REVIEW — the post-generation grill (skippable), then export

Walk the diagram against [references/diagram-review-checklist.md](references/diagram-review-checklist.md)
using the **Section C** review questions in the grill bank — challenge each box's
abstraction level, demand a label + direction for every relationship, flag missing
externals and omitted technology. Length scales with the diagram, not a fixed count.

This grill **is skippable**: if the user says "skip the grill" (or set it off in config),
skip straight to export. It is on by default.

Finally, export the finished views into `<configured-dir>/exports/` and tell the user where
they are — Mermaid/PlantUML via MCP, PNG/SVG by adjusting layout in Lite, or **headlessly via
`structurizr/structurizr export`** (DSL → Mermaid/PlantUML, then rasterise PlantUML → PNG/SVG;
see [references/runtime-and-mcp.md](references/runtime-and-mcp.md)). For diagrams committed to a
repo, prefer PNG/SVG — Structurizr's Mermaid uses HTML labels that render poorly on GitHub.

## References

- [references/c4-model.md](references/c4-model.md) — the C4 model itself: abstractions, the four levels, supplementary diagrams, notation.
- [references/structurizr-dsl.md](references/structurizr-dsl.md) — how to write correct Structurizr DSL.
- [references/patterns-and-pitfalls.md](references/patterns-and-pitfalls.md) — modeling patterns for common architectures, DSL cookbook features, and errors to catch.
- [references/multi-system-and-enterprise.md](references/multi-system-and-enterprise.md) — when an architecture is many systems / many teams: the scope decision, the per-system-workspace enterprise pattern, and the license-free landscape generation pipeline.
- [references/runtime-and-mcp.md](references/runtime-and-mcp.md) — setup flow, the MCP inner loop, and the Lite render loop.
- [references/image-to-dsl.md](references/image-to-dsl.md) — turning a pasted image into DSL (one-pass vs grilled, level-by-level).
- [references/grill-questions.md](references/grill-questions.md) — the two-phase Socratic question bank.
- [references/diagram-review-checklist.md](references/diagram-review-checklist.md) — the pre-ship review checklist.
