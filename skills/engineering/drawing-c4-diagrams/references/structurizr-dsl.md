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

`theme default` gives the familiar Structurizr look; the MCP/Lite renderers draw the
legend automatically from your styles.

## Rules of thumb

- One model, many views. Add elements once; show them in the views that need them.
- Every container gets a technology; every relationship gets a description + direction.
- Tag externals and data stores so styling stays consistent across all diagrams.
- After each edit: validate via MCP, preview as Mermaid, then show the user.
