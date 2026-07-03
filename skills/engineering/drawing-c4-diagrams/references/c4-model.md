# The C4 Model — Reference

A working reference for generating software-architecture diagrams with the C4 model.
Optimized for an LLM producing correct, unambiguous diagrams rather than prose.

The C4 model was created by Simon Brown (c4model.com). This reference is an original
summary — see the book *The C4 Model* and c4model.com for depth.

## Contents

- [Core idea](#core-idea)
- [The static abstractions](#the-static-abstractions)
- [The four levels](#the-four-levels)
  - [Level 1 — System Context](#level-1--system-context)
  - [Level 2 — Container](#level-2--container)
  - [Level 3 — Component](#level-3--component)
  - [Level 4 — Code](#level-4--code)
- [Supplementary diagrams](#supplementary-diagrams)
  - [Dynamic diagram](#dynamic-diagram)
  - [Deployment diagram](#deployment-diagram)
  - [System Landscape diagram](#system-landscape-diagram)
- [Notation guidance](#notation-guidance)
- [Quick decision guide](#quick-decision-guide)

## Core idea

**Abstractions first, notation second.** Most architecture diagrams fail not because the
shapes are wrong but because teams never agree on *what the boxes mean*. The word
"component," for instance, is used at two different levels of detail ("the web app is a
component of the system" vs. "the web app is made of components"). C4 fixes the vocabulary
before worrying about visuals.

**The map/zoom metaphor.** C4 is a set of hierarchical diagrams like Google Maps: zoom out
for the whole country, zoom in for one street. Each level tells a different story to a
different audience, at a consistent level of abstraction. Because the vocabulary is fixed,
C4 is **notation-independent** — use any shapes/colours/lines you like, as long as a legend
explains them. (The familiar blue-and-gray boxes are *not* an official notation.)

**Diagrams must stand alone.** A good diagram is readable with no verbal narration — any
spoken explanation should *complement*, not *decode*, it. The test: hand it to someone with
no context and see if they interpret it correctly.

## The static abstractions

One sentence: *A software system is made up of one or more containers, each of which
contains one or more components, which are implemented by one or more code elements — and
people use the software systems we build.*

- **Person** — a human user, role, persona, or actor (human or otherwise) that uses the
  system. Sits at the top of the model.
- **Software System** — the highest level of abstraction: something that delivers value to
  its users. Includes the system you're describing *and* the external systems it depends
  on. Heuristic: typically what a single team builds, owns, and can see inside of (often one
  repo, one team boundary). *Not* a product domain, DDD bounded context, business
  capability, or squad.
- **Container** — an application or a data store; something that must be **running** for the
  system to work. **This is NOT a Docker/Kubernetes container** (call it a "C4 container" if
  the clash bothers you). It is a **separately deployable/runnable unit** — a runtime
  boundary with a degree of isolation, independent of *how* it's deployed. Communication
  between containers is usually an out-of-process/remote call (process or network boundary).
  - *Applications:* server-side web apps, SPAs, desktop apps, mobile apps, console apps,
    serverless functions, shell scripts.
  - *Data stores:* databases/schemas, document/graph/key-value stores, blob/object stores,
    CDNs, file systems.
- **Component** — a grouping of related functionality behind a well-defined interface,
  running **inside** a container. Essentially a collection of code (classes, a module, a
  package/directory). **Components are NOT separately deployable** — the container is the
  deployable unit; components in a container run in the same process and talk via in-process
  calls. ("Containers contain components.")
- **Code element** — the internals of a component in the language's own building blocks:
  classes, interfaces, enums, functions, objects.

## The four levels

| Level | Diagram | Zooms into | Primary audience |
|---|---|---|---|
| 1 | System Context | the world around the system | everyone (technical + non-technical) |
| 2 | Container | inside one software system | architects, engineers (+ ops, QA, security) |
| 3 | Component | inside one container | engineers/architects |
| 4 | Code | inside one component | engineers only (optional, usually generated) |

Keep element placement **consistent across levels** (e.g. if people are on top at Level 1,
keep them on top at Level 2).

### Level 1 — System Context

- **Shows:** the one system in scope as a single box, the people who use it, and the
  external systems it interacts with. Deliberately low-detail. Answers: what is this system,
  who uses it, and how does it fit the surrounding landscape.
- **Scope/boundary:** a single software system; show only people/systems with a direct
  relationship to it.
- **Elements:** People (usually as roles), Software Systems (the one in scope + external
  ones), Relationships (labeled, directional).
- **Keep off it:** technologies, protocols, data formats, internal structure.
- **Common mistakes:** too much detail; unlabeled/non-directional "mystery lines"; not
  tagging box types (e.g. `[Person]`, `[Software System]`); bloating the actor list with
  every admin/operator who merely reads logs.

### Level 2 — Container

- **Shows:** how the system decomposes into applications and data stores, their
  responsibilities, the **primary technology choices**, and how they communicate. Helps an
  engineer answer "where do I add code for this feature?"
- **Scope/boundary:** the same single software system (draw a system boundary box, e.g. a
  dashed rectangle, around the containers). Repeat the external people/systems from Level 1
  for continuity.
- **Elements:** Containers (name + technology + description/responsibilities), People,
  external Software Systems, the system boundary, Relationships labeled with a description
  **and** the technology/protocol (JSON/HTTP, gRPC, etc.) since these are usually
  inter-process calls. Sync vs. async can be shown via line style.
- **Keep off it:** deployment/infrastructure (Docker, Kubernetes, load balancers,
  firewalls, API gateways, cloud regions) — that goes on a deployment diagram.
- **Container vs. external system call:** the test is *ownership/responsibility*, not
  hosting. A cloud-hosted object-store bucket you control the contents and structure of is a
  *container*; a stable third-party service you merely call (e.g. a transactional email
  service) is an *external software system*.
- **Common mistakes:** confusing a C4 container with a Docker container; putting deployment
  infra on it; omitting technology choices (defeats the feasibility-review value); unlabeled
  relationships; dropping the Level-1 external people/systems; mis-modeling an integral data
  store as external (or vice versa).

### Level 3 — Component

- **Shows:** how one container decomposes into components, their responsibilities, how they
  collaborate, and their frameworks/libraries. The components should mirror the codebase's
  **actual** structure and architectural style (layered, ports-and-adapters, etc.).
- **Scope/boundary:** a **single container** — draw one component diagram *per* container,
  never a combined one. Draw a container boundary box; optionally show the system boundary
  too.
- **Elements:** Components (name + technology + responsibilities), plus People, external
  systems, and other containers repeated for continuity. Relationships have a description
  and, *only if applicable*, a protocol — most component-to-component calls are in-process
  and need **no** protocol label.
- **Biggest risk — drift.** Component diagrams rot fastest because they map directly to code
  that changes constantly. Prefer generating them from code / keeping them close to it.
- **Common mistakes:** one diagram for multiple containers; letting it drift from the code;
  over-annotating in-process calls with protocols; drawing an idealized structure instead of
  the real one; cramming in so many components the arrows criss-cross.
- **Note:** for most systems the Container diagram is the practical stopping point; add
  component diagrams selectively.

### Level 4 — Code

- **Shows:** the internals of a single component as code-level building blocks — typically a
  UML class diagram for OO languages. Which elements are public/exported vs. internal, and
  how big/complex the component is.
- **Scope/boundary:** a **single component** (keeping scope this tight is the whole point;
  full-application class diagrams are the classic UML failure mode).
- **Optional and usually skipped.** Reading the code usually answers the same questions.
  When you do draw one: include only enough to tell the story (a pattern, a request/response
  shape), never every property/method; **prefer auto-generation** from the IDE/tooling so it
  stays truthful.
- **Common mistakes:** diagramming a whole application; including every member; hand-drawing
  and hand-maintaining it; drawing one at all when it adds nothing.

## Supplementary diagrams

The four levels describe **static structure**. Three more diagram types cover what they
can't. Each reuses the same abstractions, shapes, and notation.

### Dynamic diagram

- **Purpose:** show *behaviour* — how a **subset** of elements collaborate at runtime to
  deliver one feature/use case/story.
- **Form:** a UML sequence diagram (instances left-to-right, time top-to-bottom) or a
  numbered collaboration/communication diagram (free-form boxes with numbered arrows for
  ordering). Both convey the same thing; the numbered style is easy on a whiteboard.
- **Scope:** varies with the story — from software systems collaborating (business
  capability) down to code elements in a component. Constrain it as tightly as possible.
- **Audience:** mirrors the static level you draw it at.
- **Use sparingly**, only when the static views can't easily show how a feature works.

### Deployment diagram

- **Purpose:** map **instances** of containers/software systems onto infrastructure for
  **one deployment environment** (dev, test, staging, live). This is where all the
  deployment detail excluded from the container diagram belongs.
- **Element types:** container instances (the primary content), software-system instances,
  **deployment nodes** (infrastructure software is *deployed into* — physical/virtual/
  containerized infra, server environments; can be **nested**), and **infrastructure nodes**
  (services *used* rather than deployed into — DNS, routers, load balancers, firewalls).
- **Why it exists:** a single system is usually deployed to several environments at once
  (e.g. plain JVM on a laptop in dev, a Docker image on cloud in prod). Give each
  environment its own diagram instead of overloading one container diagram.
- **Scope:** one software system in one environment (relax to shared infra if you own
  several systems on it). **Audience:** container-diagram audience + operations/support.

### System Landscape diagram

- **Purpose:** zoom *out past* Level 1 to map **many** software systems and people across a
  group/department/organization — a system context diagram with **no single focus**.
- **Elements:** just People and Software Systems (same as Level 1).
- **Answers:** how do systems fit together; impact of changing/removing a system; impact of
  reorganizing.
- **Scope:** your choice — an org (only for small ones), a department, a product domain, a
  business capability, a bounded context. **Audience:** same as Level 1.
- **Use** when reasoning about a *collection* of systems (impact analysis, portfolio
  conversations) rather than one.

## Notation guidance

Notation is secondary, but good notation makes diagrams self-describing.

- **Self-describing diagrams.** Title each diagram with its **type + scope** (e.g. "System
  Context: Internet Banking System"). Avoid cryptic acronyms and internal code names
  (technical abbreviations like HTTP/JSON/SQL are fine); expand code names or put them in the
  key/glossary.
- **Always include a legend/key.** Explain every variation in shape, colour, icon, and line
  style — even when it "seems obvious," because different readers assume different things.
  Beware ambiguous terms like "internal/external" (relative to *what* boundary?).
- **Add more words.** Don't ship name-only rectangles. Per element, include: **Name**;
  **Type** in square brackets (e.g. `[Container]`); **Technology** for containers/components
  (the one or two most significant choices, e.g. "Java and Spring Boot"; version optional);
  and a short **Description** of responsibilities.
- **Labelled, directional relationships.** Prefer **unidirectional** arrows from the
  initiating (active) element to the receiving (passive) one; avoid bidirectional arrows
  (ambiguous, can't be labeled both ways). Show two arrows only when the interactions
  genuinely differ (e.g. sync API request + async event). Labels: be specific (avoid vague
  "uses"), and end with a preposition (to/from/with) so the label reads as a sentence in the
  arrow's direction ("UI *makes API requests to* Backend").
- **Line style as a data layer.** e.g. solid = synchronous, dashed = asynchronous. Avoid
  relying on different *arrowheads* (they vanish when zoomed out). Whatever you use, put it
  in the key.
- **Layout / size / colour / shape / icons.** No mandated orientation, but keep placement
  consistent across levels. Start with same-sized plain rectangles focused on content; add
  shape (cylinders for data stores, folders for file systems, pipes for queues, stick
  figures for people), colour (encode new-vs-existing, build-vs-buy, ownership — survive
  colour-blindness and B&W printing), and icons later. Every visual variation goes in the
  key. Draw elements roughly the same size unless size deliberately signals
  significance/complexity.

## Quick decision guide

- New system, need scope and stakeholders → **System Context**.
- Show apps, data stores, tech choices, how they talk → **Container** (usually the most
  valuable and the practical stopping point).
- Explain the internals of one complex container → **Component** (one per container;
  generate if possible).
- Rarely, illustrate a pattern inside one component → **Code** (generate, don't hand-draw).
- Walk through one feature at runtime → **Dynamic**.
- Show how/where it runs per environment → **Deployment** (one per environment).
- Map a whole portfolio of systems → **System Landscape**.
