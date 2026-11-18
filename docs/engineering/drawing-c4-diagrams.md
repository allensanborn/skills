## What it does

`drawing-c4-diagrams` turns an architecture, described in words or pasted as a whiteboard photo, into [C4 model](https://github.com/allensanborn/skills/blob/main/skills/engineering/drawing-c4-diagrams/references/c4-model.md) diagrams written as one Structurizr DSL workspace, then validates and renders them on your own machine. One text model feeds every view, so the context, container, and deployment diagrams can't drift apart.

It will not draw until you have told it who the diagram is for and what system it is about. The point is not pretty boxes: it **grills** you on audience, scope, abstraction level, and boundaries, so the diagram means the same thing to everyone who reads it.

To see a whole run before installing, read the [sample output](https://github.com/allensanborn/skills/tree/main/docs/examples/drawing-c4-diagrams): a grilled run from a one-line prompt, and an AWS deployment view with icons, each with its full transcript, DSL, and rendered diagrams.

## When to reach for it

Type `/drawing-c4-diagrams`, or the agent reaches for it automatically when you ask to diagram, visualize, or document software architecture, mention C4 or Structurizr, or paste a diagram image.

| You want | What happens |
| --- | --- |
| A new set of architecture diagrams | Scoping grill, then DSL one C4 level at a time |
| To convert a whiteboard or old diagram | It sizes the image and asks: one-pass conversion (simple) or grilled interpretation (complex) |
| To fix DSL that won't render | Validate, fix, re-validate, with the errors explained in C4 terms |
| Many systems across many teams | It sizes the workspace first: one landscape workspace, or one workspace per system |
| A deployment view with AWS, Azure, GCP, or Kubernetes icons | Installed Structurizr icon themes, rendered and checked before you see them |

For a general design argument that isn't about drawing (should this be one service or two?), a trade-off or grilling skill fits better. This one assumes the architecture exists and pins down how to show it.

## Prerequisites

Nothing is required: the skill degrades by **capability tier**.

| Tier | Needs | You get |
| --- | --- | --- |
| 0 | nothing | DSL plus a Mermaid export to paste into `playground.structurizr.com` |
| 1 | Docker | Headless validate, model lint (`inspect`), PNG/SVG render, cloud icon themes |
| 2 | Docker plus MCP or a browser | In-chat preview through Structurizr MCP, interactive layout at `localhost:8080` |

On first use it asks which tier you want and where diagrams live, then writes `.c4-diagrams.json` at the repo root so later runs don't ask again. Diagrams go to `docs/architecture/workspace.dsl` and `docs/architecture/exports/` unless you choose otherwise.

## The grill

The skill runs two grills around one generation step:

- **Scoping grill, before any DSL.** Audience and purpose, the system in scope, one system or many, the people, the external systems, the level to draw. One question at a time, each with a recommended answer you can accept in a word. This is the part that's hard to skip.
- **Review grill, after rendering.** It challenges each box's abstraction level, demands a label and direction on every arrow, and flags missing externals and technology. Length scales with the diagram.

Between them sits **render-and-look**: the views are actually rendered and inspected before you see them, because DSL that parses can still produce an empty view, a hairball, or a view that pulled in the whole landscape.

## Common questions

**Does "skip the grill" skip everything?**

No. It replaces the scoping questions with a short **Assumptions** list (audience, system, one or many, people, externals, level) that you can correct, and it skips the review grill. It never skips render-and-look. Earlier versions did skip the render pass along with the grill; that was a bug, now fixed.

**The questions come one at a time. Can I go faster?**

Answer with a word to accept each recommended answer, or put the scope in your first message: when audience, system, actors, externals, and level are already stated, the scoping grill has nothing left to ask. "Skip the grill" is the fastest route, at the cost of the skill guessing and listing its guesses.

**Do I need Structurizr MCP?**

No. MCP is a convenience for in-chat preview. With Docker alone, the headless `structurizr/structurizr` image validates, lints, and renders PNG/SVG. Without Docker you still get correct DSL and a Mermaid export.

**Where did Structurizr Lite and the cloud service go?**

Lite, the CLI, and on-premises were merged into the single `structurizr/structurizr` image as the `local`, `export`/`validate`, and `server` subcommands. The Structurizr cloud service is end-of-life with no replacement, so the skill never points you at it. The free open-source playground and the self-hosted server cover the same ground.

**The DSL validated, so why is my view empty?**

Parsing proves syntax, not content. A mis-scoped `include` or `exclude` renders zero elements without an error. That is what render-and-look and the per-view element counts are there to catch.

**Can I put AWS icons on the deployment view, and can I publish them?**

Yes to drawing them: Structurizr bundles AWS, Azure, GCP, OCI, and Kubernetes themes, and the skill tags each infrastructure node to pick them up. Publishing is murkier. Only Kubernetes grants an actual licence, and the AWS and Oracle site terms restrict redistribution, so this repo ships no icon files. See the [icon licensing notes](https://github.com/allensanborn/skills/blob/main/docs/architecture/README.md#icon-licensing-not-legal-advice-checked-2026-11-14-to-2026-11-16).

**Which image format ends up in my repo?**

SVG. It is about a tenth the size of the PNG, renders on GitHub, stays sharp when you zoom, and keeps cloud icons embedded. The skill still renders PNG to check each diagram, and commits PNG instead only where SVG won't display, such as slides, chat or email. Mermaid is fine as a quick in-chat preview but renders poorly on GitHub, so it isn't committed.

## It's working if

- You were asked who the diagram is for before you saw a single box, or you saw an Assumptions list you could correct.
- Every arrow on the diagram has a label and a direction.
- The SPA, API, and database show up as containers with technologies, not as Docker containers or as separate systems.
- The images you're shown were rendered first: nothing arrives empty or as a hairball.
- Each diagram reads at the size you'll view it (a README column, a slide). A big deployment arrives as a few focused views, not one poster you have to zoom.
- `workspace.dsl` is the only source; the context and container views agree because they come from the same model.

## Where it fits

A reach-for-it-anytime standalone: there is one model per system, and you come back to it whenever the architecture changes. The C4 model behind it is Simon Brown's; the skill's own design decisions are in [ADR 0001](https://github.com/allensanborn/skills/blob/main/.agents/adr/0001-drawing-c4-diagrams-design.md).
