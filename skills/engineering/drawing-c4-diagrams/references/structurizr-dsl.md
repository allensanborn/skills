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
        theme default
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
    theme default
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

`theme default` gives the familiar Structurizr look; the MCP/`local` renderers draw the
legend automatically from your styles.

## Rules of thumb

- One model, many views. Add elements once; show them in the views that need them.
- Every container gets a technology; every relationship gets a description + direction.
- Tag externals and data stores so styling stays consistent across all diagrams.
- After each edit: validate via MCP, preview as Mermaid, then show the user.
