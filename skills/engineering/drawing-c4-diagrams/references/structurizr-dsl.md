# Writing Structurizr DSL

Structurizr DSL is a text notation for the [C4 model](c4-model.md): you define **one
model** and render **many views** from it. That single-source-of-truth property is the
whole point — never hand-draw diagrams that can drift from each other.

Always validate DSL with the MCP tools after editing (see [runtime-and-mcp.md](runtime-and-mcp.md));
the authoritative grammar is at docs.structurizr.com/dsl. Below is the working subset.

## Contents
- Skeleton
- Model elements (person, softwareSystem, container, component)
- Relationships
- Views (systemContext, container, component, dynamic, deployment)
- Styles, tags, themes
- Worked example

## Skeleton

```
workspace "Name" "Optional description" {
    model {
        # elements and relationships
    }
    views {
        # one view per C4 level you want to show
        # styles { ... } — see "Styles, tags, themes" (never `theme default`: it is dead)
    }
}
```

## Model elements

Identifiers (left of `=`) are how you wire relationships and choose what a view shows.

```
model {
    user = person "Customer" "A user of the bank."

    bank = softwareSystem "Internet Banking System" "Lets customers view accounts." {
        web   = container "Web Application" "Serves the SPA" "Java/Spring MVC"
        spa   = container "Single-Page App" "Runs in the browser" "React"
        api   = container "API Application" "Business logic + API" "Java/Spring Boot" {
            signin = component "Sign In Controller" "Handles auth" "Spring MVC"
        }
        db    = container "Database" "Stores accounts, txns" "PostgreSQL" {
            tags "Database"
        }
    }

    mainframe = softwareSystem "Mainframe Banking System" "Core banking." {
        tags "External"
    }
    email = softwareSystem "Email System" "Microsoft Exchange." {
        tags "External"
    }
}
```

- **person** — a human role/actor.
- **softwareSystem** — the highest abstraction; the thing in scope, or an external
  dependency (tag externals so they can be styled differently).
- **container** — a separately deployable/runnable unit (app, service, SPA, data store).
  **Not** a Docker container. Give every container a **technology** (the 4th argument).
- **component** — a grouping of related functionality *inside* one container. Optional
  and often auto-generated; keep it current or omit it.

## Relationships

`source -> destination "Description" "Technology"` — always describe intent, and add the
technology/protocol where it matters.

```
    user -> spa "Uses"
    spa -> api "Makes API calls to" "JSON/HTTPS"
    api -> db "Reads from and writes to" "SQL/TCP"
    api -> mainframe "Fetches balances from" "XML/HTTPS"
    api -> email "Sends e-mail using" "SMTP"
```

**Tagging a relationship** (to style or filter it later — e.g. async, telemetry, feature
flags): the tag is the **5th positional argument**, after description and technology:

```
    api -> broker "Publishes OrderPlaced to" "Kafka" "Async"
```

Do **not** put a `{ tags "Async" }` block on the *same line* as the relationship — the parser
rejects it with `Too many tokens, expected: <identifier> -> <identifier> [description]
[technology] [tags]`. Use the positional form above, or move the block onto its own lines:

```
    api -> broker "Publishes OrderPlaced to" "Kafka" {
        tags "Async"
    }
```

The same one-line-brace trap applies to **elements**: `softwareSystem "X" { tags "Platform" }` on a
single line fails the same way. Tags is the last positional argument — `softwareSystem "Name"
"Description" "Tag"` (person/softwareSystem) or `container "Name" "Description" "Technology" "Tag"` —
or put a `{ tags "..." }` block on its **own lines**.

## Views

Render one view per level. `include *` pulls in the relevant elements; always set
`autolayout` (`tb`, `bt`, `lr`, or `rl`) so it renders without manual layout.

```
views {
    systemContext bank "SystemContext" "The big picture." {
        include *
        autolayout lr
    }
    container bank "Containers" {
        include *
        autolayout lr
    }
    component api "Components" {
        include *
        autolayout lr
    }
    dynamic bank "SignIn" "How a user signs in." {
        user -> spa "Enters credentials"
        spa -> api "Validates credentials"
        api -> db "Looks up user"
        autolayout lr
    }
}
```

Deployment views map container **instances** onto infrastructure:

```
    deploymentEnvironment "Live" {
        deploymentNode "Customer's computer" {
            deploymentNode "Web Browser" {
                containerInstance spa
            }
        }
        deploymentNode "Amazon Web Services" {
            deploymentNode "EC2" {
                containerInstance api
            }
            deploymentNode "RDS" {
                containerInstance db
            }
        }
    }
```
```
    deployment bank "Live" "LiveDeployment" {
        include *
        autolayout lr
    }
```

**Relationships in a deployment environment must end on instances** (`containerInstance`,
`softwareSystemInstance`) **or `infrastructureNode`s, never on a `deploymentNode`.** An edge like
`tool -> region` (to say "provisions everything inside") compiles and exports, but collapses the
rendered view into a 2000x2000 pile. Put that fact in the node's description instead.

## View contents: include / exclude, expressions, and layout

`include`/`exclude` decide *what* a view shows. This is where most "the diagram is wrong"
problems live — the mechanics below each correspond to a real failure mode.

**Identifiers.** `include *` pulls in the elements in scope; `include <id> [<id> …]` and
`exclude <id>` add/remove specific ones. **Excluding an element also removes its
relationships** — use that to drop a chatty shared dependency (`exclude collector`) and get a
clean view.

**Expressions.** `include`/`exclude` also take expressions (quote them):
- `include "->x"` — *afferent*: everything pointing **at** `x`. `"x->"` — *efferent*: everything
  `x` points at. Also `"* -> x"`, `"x -> *"`.
- `include "element.tag==Foo"` / `include "relationship.tag==Foo"` (and the `exclude` forms) —
  filter by tag.

Two expression gotchas, both verified:
- **An expression-only include on an *empty* view can resolve to nothing.** `include "* -> x"`
  or `include "relationship.tag==Foo"` on a view with no baseline may add **zero** elements.
  Seed a concrete element first (`include x`), *then* the afferent form (`include "->x"`).
- **A view auto-draws *every* relationship between its included elements** — so a "star" view
  around a hub also shows the spokes' business edges to each other. Tag those edges and
  `exclude "relationship.tag==Business"`. Full star-view recipe in
  [patterns-and-pitfalls.md](patterns-and-pitfalls.md).

**Implied relationships** — `!impliedRelationships true` at the top of `model`. A relationship
between two containers is rolled up to their parent software systems, so a System Context /
Landscape view shows **one** clean arrow to each external instead of hand-added duplicates. It's
also **required** for `generate system-landscape` (the rollup is what the generator merges — see
[multi-system-and-enterprise.md](multi-system-and-enterprise.md)).
> **Gotcha:** implied relationships do **not** inherit the source relationship's custom tags —
> the implied edge carries only the default `Relationship` tag. So you **cannot** tag-filter
> implied edges; keep the granular (tagged) relationships explicit if a view needs to filter on
> them. This is why the star-view recipe filters container-level edges, not implied ones.

**Filtered views** (`filtered "<baseKey>" exclude "<tag>" "<newKey>"`) derive a focused view
from a base by tag. Two hard limits make them a poor fit for committed images:
- the **base view must use manual layout** — `autolayout` on a filtered view's base is rejected;
- the **headless export silently skips filtered views** — only the base is written
  ([runtime-and-mcp.md](runtime-and-mcp.md)).

So for repo images, author a "clean" and a "full" view **explicitly** (one `include *`, one that
`exclude`s the noisy tag/element). Filtered views are fine only when the audience browses the
live Structurizr server.

**Layout.** `autolayout <lr|rl|tb|bt> [rankSep] [nodeSep]` — e.g. `autolayout lr 300 150` widens
spacing; `tb` often untangles a fan-in that `lr` crowds. But note the **image-source caveat**:
PlantUML/Mermaid do their *own* layout on export, so `autolayout` mainly drives the interactive
server — where vNext's upgraded Dagre routes arrows and labels noticeably better than Lite did.
For a dense view, the fix is still **fewer edges** (exclude the cross-cutting ones), not layout
knobs.

**Verify before trusting a view.** A misscoped `include`/`exclude` can yield an **empty** view
(0 elements) that renders as a blank box — a silent failure. Check the per-view element and
relationship counts (from the exported `workspace.json`, where **relationships nest under their
source element**, not a top-level `model.relationships` array) before shipping.

## Styles, tags, themes

Notation is secondary but must be **consistent and explained** (a legend). Style by tag:

```
    views {
        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Database" {
                shape cylinder
            }
        }
    }
```

The MCP/`local` renderers draw the legend automatically from your styles.

**Never write `theme default`.** It points at `static.structurizr.com`, which died with the cloud
service (EOL 30 Sep 2026). It still parses; export logs an EOL warning and renders **unstyled**, with
no error. For the familiar C4 look, write the base styles yourself:

```
        styles {
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Database" {
                shape cylinder
            }
        }
```

Set `color` per element type, **never on `"Element"`**: that also hits deployment and infrastructure
nodes, whose white background then hides every label (verified — invisible text, no error).

### Cloud icon themes (AWS, Azure, GCP, OCI, Kubernetes)

Provider icons ship **inside** the `structurizr/structurizr` image at `/usr/local/structurizr-themes`;
reference one by bare name — no URL, no network, no CORS:

```
    views {
        theme amazon-web-services-2025.07
    }
```

Installed names: `amazon-web-services-2020.04|2022.04|2023.01|2025.07`,
`microsoft-azure-2019.09|2020.07|2021.01|2023.01|2024.07|2025.11`,
`google-cloud-platform-v1.5|2025.09`, `oracle-cloud-infrastructure-2020.04|2021.04|2023.04`,
`kubernetes`. Cookbook URLs like `.../amazon-web-services-2023.01.31/theme.json` are dead; the
installed names drop the day.

- **The CLI must be told where they are**: `docker run -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes …`.
  Without it, `validate`/`export` fail: *"Theme amazon-web-services-2025.07 does not exist at /work/…"*.
  (Alternatively a `themes/` dir next to `workspace.dsl` is used first.)
- **An element gets an icon by carrying the exact tag** from that version's `theme.json`; tags change
  between versions. Verified AWS 2025.07 tags for a typical web stack, all prefixed
  `Amazon Web Services - `: `AWS Cloud`, `Region`, `Virtual private cloud VPC`, `Public subnet`,
  `Private subnet`, `Route 53`, `CloudFront`, `WAF`, `Load Balancing`, `API Gateway`,
  `Elastic Container Service`, `Fargate`, `Lambda`, `Aurora`, `ElastiCache`,
  `Simple Storage Service`, `OpenSearch Service`, `Simple Queue Service`, `Simple Email Service`,
  `Cognito`. There is no Availability Zone tag. List a version's tags with
  `docker run --rm --entrypoint cat structurizr/structurizr /usr/local/structurizr-themes/<name>/theme.json`.
- **Icons go on the deployment view only** — tag `deploymentNode`s and `infrastructureNode`s, never
  the logical containers (an Aurora icon on the "Database" container conflates C4 levels).
- Icons are inlined as base64 into the workspace, so PNG/SVG export embeds them. They appear in the
  generated key too.
- The theme supplies icons only; keep your base styles alongside it.
- **Licensing:** the icons belong to the vendors (Structurizr licenses only `theme.json`). Vendors
  invite diagrams of *their own services*, but only Kubernetes grants a real licence. AWS grants
  nothing for third-party publications, and AWS/Oracle terms bar redistribution. Never copy icon
  files into a repo; reference a theme. Don't distort icons (AWS §9, Azure, Oracle), which is a
  strike against Mermaid's stretched icons. Google Cloud wants an attribution line. If the user
  will publish commercially, tell them to check the vendor's terms. Details: the skills repo's
  `docs/architecture/README.md`.

### Icons outside the Structurizr renderer (PlantUML, Mermaid)

The text exporters only emit icons whose URL starts with `http`; an **installed** theme's icons are
`data:` URIs, so PlantUML and Mermaid silently drop them. To get icons there, load the **same theme
by URL** — Structurizr's GitHub copy works (relative icon names resolve against it):

```
        theme https://raw.githubusercontent.com/structurizr/structurizr/v2026.10.26/structurizr-themes/amazon-web-services-2025.07/theme.json
```

| Export | Icons with the URL theme |
| --- | --- |
| `-format plantuml` (Structurizr style) | **All**, on deployment and infrastructure nodes. PlantUML fetches and embeds them at render time. |
| `-format plantuml/c4plantuml` | **None** on deployment views: the exporter writes every `Deployment_Node` with `$tags=""`, so the tag sprites never attach. |
| `-format mermaid` | **Infrastructure nodes only**, and only with `properties { "mermaid.icons" "true" }`. Deployment nodes become subgraphs with no icon; icons stretch to node width; the SVG keeps remote `<img>` URLs (blank offline). |

Costs of the URL theme: network at export/render time. The URL above is pinned to the release tag
that matches the Docker image, so output stays reproducible; bump both together and re-run
`evals/render/test.sh`. Prefer the installed theme + PNG/SVG export; use the URL theme only
when PlantUML output is required. `evals/render/test.sh` asserts all of this (Docker + network).

```
    deploymentEnvironment "Live" {
        deploymentNode "AWS" {
            tags "Amazon Web Services - AWS Cloud"
            deploymentNode "us-east-1" {
                tags "Amazon Web Services - Region"
                alb = infrastructureNode "ALB" {
                    tags "Amazon Web Services - Load Balancing"
                }
                deploymentNode "ECS on Fargate" {
                    tags "Amazon Web Services - Fargate"
                    apiInstance = containerInstance api
                }
                deploymentNode "Aurora PostgreSQL" {
                    tags "Amazon Web Services - Aurora"
                    containerInstance db
                }
                alb -> apiInstance "Forwards to"
            }
        }
    }
```

## Rules of thumb

- One model, many views. Add elements once; show them in the views that need them.
- Every container gets a technology; every relationship gets a description + direction.
- Tag externals and data stores so styling stays consistent across all diagrams.
- After each edit: validate via MCP, preview as Mermaid, then show the user.
