# Multi-system landscapes and the enterprise pattern

When an architecture is **one** software system, one workspace holds it (System Context +
Container views). When it's **many** systems — especially across **many teams** — Structurizr's
own guidance changes: *"A workspace should contain the model, views, documentation, and decisions
for a single software system"* and *"Don't model every software system in a single workspace"*
(docs.structurizr.com/workspaces/recommendations). This file covers **when** to escalate and the
two concrete structures, including a **license-free landscape generation pipeline** that works
with just Docker.

## Assess scope up front (part of the pre-generation grill)

Before authoring, decide the **workspace scope**. Structurizr names three
(docs.structurizr.com/workspaces/scope):

- **`softwareSystem`** — one system per workspace. The **default**.
- **`landscape`** — a workspace of people + systems with no single focus (the org map).
- **`unscoped`** — several systems merged into one workspace. Allowed *"particularly for smaller
  software systems"*, but the docs warn the result is *"cluttered."*

Recommend a **graduated** strategy (not a hard gate):

| Signal | Recommend |
|---|---|
| One system | single **`softwareSystem`** workspace |
| A few small systems, **one team**, one repo | **`unscoped`** single workspace (accept some clutter) |
| Multiple systems and/or **multiple teams**, separate repos, cross-system relationships, need for an org landscape, workspace pushing past the **1–2 MB** budget | the **enterprise** pattern below |

Signals that say "enterprise": >1 system owned by **different teams**; systems in **separate
repos** / independent deploy lifecycles; you need an **org-wide landscape**; or the single
workspace is getting large/cluttered. (docs.structurizr.com/workspaces/enterprise)

## Structure A — single-workspace landscape (`unscoped`)

One `workspace.dsl` with every system as a top-level `softwareSystem`, `group`ed by domain, plus a
`systemLandscape` view and per-system `container` views. Simple; fine for one repo/team. Its cost:
the container view of a large system is a wall of boxes, and there's no per-team ownership boundary.

## Structure B — the enterprise / decentralized pattern

One workspace **per software system**, each owned by a team, all sharing a **system catalog**, with
a **generated** landscape. This is what the docs recommend at multi-team scale.

```
workspaces/
├── system-catalog/workspace.dsl   every softwareSystem, DEFINITIONS ONLY (no containers)
├── _shared/styles.dsl             one styles block, !included by every workspace
├── <system>/workspace.dsl         one PER SYSTEM: extends the catalog, adds its own
│                                  containers + the relationships it ORIGINATES, + views
└── landscape/                     GENERATED from the per-system workspaces (see pipeline)
```

**System catalog** — only the system definitions (name, description, ownership tags); *"the
internal details … should be omitted"* (enterprise docs). Team workspaces `extends` it.

**Per-system workspace template** (verified):

```
workspace extends ../system-catalog/workspace.dsl {
    model {
        !impliedRelationships true          # REQUIRED — see pipeline note
        !element <catalogId> {              # reopen the catalog's system, add containers
            svc = container "..." "..." "Tech"
        }
        svc -> <otherCatalogId> "Calls" "gRPC"   # cross-system: reference catalog systems
        svc -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }
    views {
        systemContext <catalogId> "Context" { include *; autolayout lr }
        container     <catalogId> "Containers" { include *; exclude obsPlatform; autolayout lr }
        !include ../_shared/styles.dsl
        theme default
    }
}
```

Notes / gotchas (all verified against `structurizr/structurizr`):
- `extends` accepts a **relative file path** (not only an HTTPS URL) — good for a monorepo/local.
- Each workspace declares only the relationships it **originates** (ownership); a per-system Context
  view therefore shows *outgoing* dependencies — callers appear in the callers' workspaces. The
  landscape aggregates.
- An `extends` workspace **can't take an inline name** (`workspace extends <file> "Name"` fails).
- Externality is scope-relative: on a team's Context view the Platform and other teams' systems are
  external dependencies it consumes but doesn't own — see the platform pattern in
  [patterns-and-pitfalls.md](patterns-and-pitfalls.md).

## The landscape generation pipeline (local, no server, no license)

The landscape is **generated**, never hand-authored — that's the point of decentralization.

```bash
# 1. merge per-system workspaces; DERIVE system→system edges from each team's container edges
docker run --rm -v "$PWD:/work" -w /work structurizr/structurizr \
  generate system-landscape -i /work -o /work/landscape/_generated.json \
  -exclude 'workspace\.json' -relationships first

# 2. the generated workspace has MODEL ONLY (no views, no styles) — post-process to add them
#    (a small script: inject configuration.styles; add a systemLandscape view whose `elements`
#     list the system ids you want — e.g. exclude the Platform systems for the clean view)

# 3. render
docker run --rm -v "$PWD:/work" -w /work structurizr/structurizr \
  export -workspace landscape/workspace.json -format plantuml -output landscape/exports
```

Critical requirements (each was a real failure mode):
- **`!impliedRelationships true` in every per-system workspace.** Relationships are declared at the
  container level (`svc -> otherSystem`); without the implied-relationship rollup there is no
  *system-to-system* edge for the generator to merge, and the landscape comes out with **zero
  relationships**.
- **`generate` loads files named `workspace.{dsl,json}`.** Use `-exclude 'workspace\.json'` so the
  generated landscape isn't fed back into its own input on re-runs. `-relationships first` collapses
  duplicate edges to one per system pair.
- **The generated model has no views or styles** — you must add a `systemLandscape` view (its
  `elements`/`relationships` are explicit id lists in the JSON) and a `configuration.styles` block,
  then export. Include a base `Software System` / `Person` style, since there's no `theme`.
- **JSON gotcha:** in a Structurizr workspace JSON, relationships are nested **under their source
  element**, not in a top-level `model.relationships` array. Parse accordingly or you'll wrongly
  conclude "0 relationships."

## What needs a licensed server — and what doesn't

`generate`, `export`, `merge`, `validate`, `inspect` are **local commands** — no server, no
license. So the whole pipeline above runs offline.

**Only `server` costs money.** Per [docs.structurizr.com/binaries](https://docs.structurizr.com/binaries),
*"All Structurizr commands are free to use from these binaries except for `server`, which requires
a license."* That means:

- `server` — stands up your own Structurizr UI/API. **Licensed** from the prebuilt image (the
  container **exits with "No license found"** without one). It is open core, so building from
  source is free, minus the enterprise extras (SAML, role-based access, cloud storage).
- `create` / `push` / `pull` / `list` — **free**. They are client commands; they need *a* server
  to talk to, but they don't themselves need a license. (Older guidance in this skill said these
  were licensed. They aren't.)
- The **cloud service is end-of-life with no replacement** — it is not a `push` target to plan
  around. Self-host `server`, or keep the pipeline fully local as above.

The licensed path (each team `push`es its workspace to a shared server; the landscape is `pull`ed
and `generate`d server-side) and the local pipeline produce the **same landscape**. Recommend the
local pipeline unless the team already runs a licensed Structurizr server for live collaboration.

## Anti-pattern

Cramming every system into one giant workspace at scale: *"The Structurizr tooling was never
designed to handle workspaces that contain hundreds or thousands of software systems"*
(enterprise docs). Decompose by bounded context / team and generate the landscape.
