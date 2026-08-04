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

**Cross-cutting dependency (telemetry, feature flags, auth sidecar).** When *every* container
talks to one shared thing, drawing N identical arrows on the main container view is pure
noise. Model the real edges once (tag them, e.g. `"Telemetry"`), keep them **off** the main
view, and give the shared hub its own **star view**:

```
# main container view — hide the cross-cutting hub and its edges so the call graph stays legible
container sys "Containers" {
    include *
    exclude collector          # excluding the element drops all its edges too
}

# dedicated star view — seed the hub, then pull in only its incoming edges
container sys "Telemetry" {
    include collector
    include "->collector"                  # afferent shorthand: adds every source that points at collector
    exclude "relationship.tag==Business"   # strip the source-to-source edges auto-added below
}
```

This keeps the "everything is instrumented / flag-driven" story as one clean fan-in instead
of a hairball, and it's the concrete form of the *filtered views* bullet below. Watch two
traps:

- **Empty-view include expressions resolve to nothing.** On a container view with no baseline,
  `include "* -> collector"` and `include "relationship.tag==Telemetry"` can both add **zero**
  elements. Seed a concrete element first (`include collector`), *then* use the `->hub`
  afferent form to pull in the sources.
- **Views auto-draw every edge between included elements.** Once the source containers are in
  the star view, Structurizr also draws the *business* edges among them. Tag those edges (e.g.
  `"Business"`) and `exclude "relationship.tag==Business"` so only the hub's spokes remain.

**Platform / shared-capability layer (feature flags, telemetry pipeline, shared auth).** A
capability every system consumes (flagd, an OpenTelemetry collector + backends, an auth service)
is modelled as **its own internal software system**, wrapped in a `group "Platform"`. Do **not**
tag it `External` at the org level — you own it. Key moves:

- **Externality is scope-relative.** The same platform is *internal* on the org **System Landscape**
  (you own it) but *external* on a product team's **System Context** (outside that team's boundary
  and control — they code to a stable contract like OTLP/OFREP; self-hosted-vs-SaaS is invisible to
  them). c4model's "External = you don't own it" is relative to the *diagram's* scope, not the org.
  Structurizr styles **globally by tag**, so you can't colour one element differently per view —
  pick the primary audience's viewpoint, and let structural placement (outside the team's boundary)
  carry the rest.
- **Three ownership classes, three styles.** `Ours` (default) / `Platform` (internal, another team —
  a solid distinct fill) / `External` (third-party / SaaS / tooling — a **dashed** border says
  "outside the org"). Flat grey-for-everything-not-ours hides the platform-vs-third-party line.
- **Keep the fan-in off the clean views.** Every system → platform is a hairball; `exclude` the
  platform elements from the landscape/context views and give the fan-in its own **star view**
  (above). (`filtered` views are the "official" tool here but don't survive the headless export —
  see [runtime-and-mcp.md](runtime-and-mcp.md).)
- **Deployment view owns the physical story.** The collector's *topology* (sidecar / per-node agent /
  gateway) and physical facts the static model abstracts away (e.g. two logically-separate databases
  co-located on one instance) belong on a **deployment** view via `deploymentNode` /
  `infrastructureNode` — never on the static container/landscape views.
- **Cross-team ownership at scale:** when a *different* team owns the platform and multiple repos
  consume it, model each system as its own workspace that `extends` a shared **system catalog**, and
  **generate** the landscape from them. Full recipe (incl. the license-free generation pipeline) in
  [multi-system-and-enterprise.md](multi-system-and-enterprise.md).

## DSL feature patterns (from the cookbook)

- **Groups** — cluster related elements (by team, domain, bounded context):
  `group "Payments" { api = container ...; ledger = container ... }`.
- **Implied relationships** (`!impliedRelationships true` at the top of the `model` block) — a
  relationship defined between two containers is automatically rolled up to their parent
  software systems, so the System Context view shows **one** clean arrow to each external
  (e.g. `Shop -> Observability`) instead of you hand-adding duplicate system-level edges that
  drift. Enable it deliberately, then define only the granular container-level edges.
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
- **Shared library modelled as a container.** An embedded SDK / client library is reusable code,
  not a separately deployable unit — model it as a component (or omit it), not a container. (A flag
  *SDK* inside each app ≠ a flagd *service* the apps call.)
- **Message broker as one opaque blob.** When pub/sub topics carry the architecture (who produces
  and consumes what), model the significant topics/queues, not a single undifferentiated "Kafka"
  box. Also check the *scope*: a broker whose producer and all consumers live in one bounded context
  is that system's internal container, not a shared platform.
- **Giant unified landscape.** Wiring every team's systems into one mega-diagram is the classic
  failure mode; scope by bounded context, `group` related systems, and lean on per-system views.
- **Over-detailing external / platform systems.** Show third-party and another-team systems as
  opaque boxes; drawing their internals adds coupling and volatility you don't control.
