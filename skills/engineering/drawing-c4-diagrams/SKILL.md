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
- [ ] 4. RENDER — outer loop (`structurizr/structurizr local` at :8080), if the user wants it
- [ ] 5. REVIEW — render-and-look (always) + post-generation grill (skippable), then export
```

## 0. Capabilities and setup

This skill works at three capability tiers and **degrades gracefully** — never assume a
tool is installed.

| Tier | Needs | You can |
| --- | --- | --- |
| **0 — always** | nothing | author + eyeball-validate DSL, export **Mermaid** as text, tell the user to paste it into the playground at **`playground.structurizr.com`** |
| **1 — +Docker** (the practical default) | Docker | **headless** `structurizr/structurizr`: `validate` (parse check), render **PNG/SVG** (export → PlantUML), `inspect` (model lint), `generate system-landscape`, `playground` (local editor). **No MCP or browser required.** |
| **2 — +MCP and/or browser** | Docker + MCP / a browser | **MCP** (`structurizr/mcp`): fast in-chat validate + Mermaid/PlantUML preview (inner loop). **`structurizr/structurizr local`**: interactive render + layout tweaks at `http://localhost:8080` (outer loop). |

> **Naming:** Structurizr vNext consolidated Lite, the CLI, and the on-premises install into the
> single `structurizr/structurizr` image — they are now the `local`, `export`/`validate`/…, and
> `server` subcommands. The **cloud service is end-of-life with no replacement**; never point a
> user at it. See [references/runtime-and-mcp.md](references/runtime-and-mcp.md) for the full map.

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
- **Verify each view isn't empty.** Parsing OK ≠ view correct — a misscoped `include`/`exclude`
  renders **0 elements**. Check the per-view element/relationship counts (from the exported
  `workspace.json`) before moving on.
- If Docker is present, run **`structurizr inspect`** for the model-completeness lint (missing
  descriptions/technology, orphans, elements on no view, empty views) — no server needed; see
  [references/diagram-review-checklist.md](references/diagram-review-checklist.md) (*Inspections*).

See [references/runtime-and-mcp.md](references/runtime-and-mcp.md) for exact tool names and
fallbacks. If Docker is present but MCP is not connected, use **`structurizr/structurizr validate
-workspace workspace.dsl`** as the inner loop — it is the purpose-built parse check and writes no
files. A failed `export` (parser exception / non-zero exit) is the same signal when you were
exporting anyway. At Tier 0 (no Docker), validate by careful reading and give the user the DSL
plus a Mermaid export to paste into `playground.structurizr.com`.

## 4. RENDER — the outer loop (optional)

When the user wants the real, polished C4 render or to nudge layout, start
**`structurizr/structurizr local`** (Docker, mounts the diagram dir, serves `http://localhost:8080`) per
[references/runtime-and-mcp.md](references/runtime-and-mcp.md). Layout tweaks auto-save
back to disk. Skip this entirely at Tier 0/1.

## 5. REVIEW — the post-generation grill (skippable), then export

Review has **two passes**, both driven by [references/diagram-review-checklist.md](references/diagram-review-checklist.md):

1. **Render and look** (not optional) — actually render the views (PNG/SVG or the live server)
   and eyeball them against the *Render and look* checklist. DSL validation passes on diagrams
   that are visually broken: empty views, a view that pulled in the whole landscape, hairballs,
   overlapping boxes, orphans. These are invisible in the source.
2. **The content grill** — walk the **Section C** review questions in the grill bank: challenge
   each box's abstraction level, demand a label + direction for every relationship, flag missing
   externals and omitted technology. Length scales with the diagram, not a fixed count.

The **content grill (pass 2) is skippable**: if the user says "skip the grill" (or set it off in
config), skip it. The **render-and-look pass (pass 1) is not** — always render and eyeball before
export, even when the grill is skipped. Both default on.

Finally, export the finished views into `<configured-dir>/exports/` and tell the user where
they are — Mermaid/PlantUML via MCP, PNG/SVG by adjusting layout in `local`, or **headlessly via
`structurizr/structurizr export`** (DSL → Mermaid/PlantUML, then rasterise PlantUML → PNG/SVG;
see [references/runtime-and-mcp.md](references/runtime-and-mcp.md)). For diagrams committed to a
repo, prefer PNG/SVG — Structurizr's Mermaid uses HTML labels that render poorly on GitHub.

## References

- [references/c4-model.md](references/c4-model.md) — the C4 model itself: abstractions, the four levels, supplementary diagrams, notation.
- [references/structurizr-dsl.md](references/structurizr-dsl.md) — how to write correct Structurizr DSL.
- [references/patterns-and-pitfalls.md](references/patterns-and-pitfalls.md) — modeling patterns for common architectures, DSL cookbook features, and errors to catch.
- [references/multi-system-and-enterprise.md](references/multi-system-and-enterprise.md) — when an architecture is many systems / many teams: the scope decision, the per-system-workspace enterprise pattern, and the license-free landscape generation pipeline.
- [references/runtime-and-mcp.md](references/runtime-and-mcp.md) — setup flow, the vNext subcommand map, the MCP inner loop, and the `local` render loop.
- [references/image-to-dsl.md](references/image-to-dsl.md) — turning a pasted image into DSL (one-pass vs grilled, level-by-level).
- [references/grill-questions.md](references/grill-questions.md) — the two-phase Socratic question bank.
- [references/diagram-review-checklist.md](references/diagram-review-checklist.md) — the pre-ship review checklist.
