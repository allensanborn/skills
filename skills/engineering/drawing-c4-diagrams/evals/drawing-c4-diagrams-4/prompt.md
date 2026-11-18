---
tags: [drawing-c4-diagrams]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Here's some Structurizr DSL I wrote but it won't render. Fix it.

```text
workspace "Bookshop" {
    model {
        customer = person "Customer" "Buys books online."
        shop = softwareSystem "Bookshop" "Sells books online." {
            web = container "Web App" "Serves the storefront." "React"
        }
        api = container "API" "Handles orders and payments." "Node.js"
        db = container "Database" "Stores orders." "PostgreSQL"
        customer -> web "Browses and buys books using"
        web -> api "Makes API calls to" "JSON/HTTPS"
        api -> db "Reads from and writes to" "SQL/TCP"
    }
    views {
        container shop "Containers" {
            include *
            autolayout tb
        }
    }
}
```
