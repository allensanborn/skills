# Structurizr DSL patterns & common modeling pitfalls

Reusable modeling patterns for common architectures, the Structurizr DSL features that
express them, and the mistakes to catch during the grill. Use this while authoring
([structurizr-dsl.md](structurizr-dsl.md)) and reviewing ([diagram-review-checklist.md](diagram-review-checklist.md)).

Based on Simon Brown's C4 model (c4model.com) and the Structurizr DSL cookbook
(docs.structurizr.com/dsl/cookbook).

## Contents
- Modeling patterns (common use cases)
- DSL feature patterns (from the cookbook)
- Common modeling errors (catch these in the grill)

## Modeling patterns (common use cases)

**Web app (SPA + API + DB).** SPA and API are separate containers (separately
deployable); DB is a container tagged `Database`. Relationships carry the protocol.

```
spa = container "Single-Page App" "UI in the browser" "React"
api = container "API Application" "Business logic" "Node/Express"
db  = container "Database" "State" "PostgreSQL" { tags "Database" }
spa -> api "Calls" "JSON/HTTPS"
api -> db  "Reads/writes" "SQL/TCP"
```

**Message bus / queue / event stream.** Model the broker as its **own container** (it is
separately deployable) — never as an unlabelled arrow. Show publish/subscribe intent.

```
broker = container "Event Bus" "Async messaging" "Kafka" { tags "Queue" }
api      -> broker "Publishes OrderPlaced to" "Kafka"
worker   -> broker "Subscribes to OrderPlaced from" "Kafka"
```

**Microservices.** Each service is a container; a shared broker or API gateway is also a
container. Use [groups](#dsl-feature-patterns-from-the-cookbook) to cluster by
team/domain. Beware the "too many boxes" pitfall — split into multiple container views or
use filtered views if it gets crowded.

**API gateway / BFF.** The gateway is a container that fronts other containers; label each
edge with what it routes.

**External SaaS / third-party.** A dependency you don't own is an **external software
system** (tag `External`), shown on the System Context and as a box off the side of the
Container diagram — not a container inside your system.

```
stripe = softwareSystem "Stripe" "Payments" { tags "External" }
api -> stripe "Takes payments via" "JSON/HTTPS"
```

**Serverless / FaaS.** A function is a container (or component if several share a
deployable unit); the managed platform (e.g. Lambda, API Gateway) appears in the
**deployment** view as infrastructure/deployment nodes, not on the container diagram.

**Shared database (antipattern to surface).** If two systems write the same DB, say so
explicitly and flag the coupling in the grill — don't hide it behind one arrow.

## DSL feature patterns (from the cookbook)

- **Groups** — cluster related elements (by team, domain, bounded context):
  `group "Payments" { api = container ...; ledger = container ... }`.
- **Implied relationships** — a relationship between nested elements can imply one between
  their parents; enable deliberately so context views stay clean.
- **Filtered views** — derive a focused view by include/exclude on tags, instead of a new
  model: good for "too many elements" on large systems.
- **Element / relationship styles + themes** — style by tag (`element "Database" { shape cylinder }`);
  `theme default` for the familiar look; keep styling consistent (the legend is generated).
- **Custom elements** — for things outside the standard C4 set when genuinely needed.
- **Deployment groups** — keep instances of separate environments/tenants from wiring
  together in deployment views.
- **Dynamic view (parallel sequences)** — number interactions; use parallel blocks for
  concurrent flows.
- **Perspectives (static/dynamic)** — overlay a concern (security, performance) on views.
- **Shared components / workspace extension** — reuse component definitions and extend a
  base workspace across teams.

Prefer these built-ins over hand-maintaining duplicate diagrams — one model, many views.

## Common modeling errors (catch these in the grill)

- **Docker/K8s container ≠ C4 container.** A C4 container is a separately
  deployable/runnable unit (an app or data store). A pod, image, or sidecar is deployment
  detail — it belongs on the **deployment** view, not the container diagram.
- **Mixed abstraction levels** — a single diagram showing a whole system next to one class.
  Keep each view at one level.
- **Unlabelled or vague relationships** — every line needs intent **and** direction; avoid
  bare "Uses". Add the technology/protocol for inter-process calls.
- **Missing technology** — every container/component should name its tech.
- **Deployment on the container diagram** — servers, regions, and scaling go on the
  deployment view; the container diagram is logical.
- **External systems omitted** — if it's not owned but is depended on, show it (tagged
  external). "No external systems" is almost always wrong.
- **Too many elements** — split into multiple views, use groups, or a filtered view.
- **Unexplained acronyms / generic names** ("business logic", "backend") — name the real
  responsibility.
- **No legend / inconsistent notation** — colours and shapes must be consistent and
  explained; account for colour-blindness and B/W printing.
- **Diagram drift** — never hand-maintain parallel diagrams; render all views from the one
  model and re-export after edits.
