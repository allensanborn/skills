# C4 Diagram Review Checklist

A post-generation checklist for critiquing a C4 diagram *before* shipping it. Walk it
item by item. The core diagnostic test: could someone who was **not** in the room when
the diagram was drawn understand it with **no spoken narrative**? Every "no" is a defect
to fix — it points to missing text, an unexplained notation choice, or an ambiguous
element/relationship.

Based on Simon Brown's C4 model (c4model.com).

---

## General

- [ ] **Title** — Does the diagram have a title?
- [ ] **Type** — Can you tell the diagram's type from the title (System Context,
      Container, Component, Code, Deployment, Dynamic, System Landscape)?
- [ ] **Scope** — Can you tell what the diagram is about — what single thing is "in the
      box" and what this view covers?
- [ ] **Key / legend** — Is there a key/legend, on or near the diagram, explaining every
      shape, colour, icon, border style, and line style used?
- [ ] **Reading order** — Within a set of diagrams, is it clear which to read first and
      how they nest (context to containers to components)?
- [ ] **Consistent notation** — Is the notation used consistently across the diagram (and
      across the set)? Do element placement conventions hold — e.g. if people are at the
      top of the context view, are they at the top of the container view too?

## Elements (the boxes)

- [ ] **Name** — Does every element have a clear name?
- [ ] **Type / abstraction level** — Does every element declare its type — Person,
      Software System, Container, Component, Code, Deployment Node — usually in square
      brackets, e.g. `[Container]`?
- [ ] **Single abstraction level** — Are all elements at the *same* abstraction level?
      No mixing containers with components, or software systems with code, in one view.
- [ ] **Description** — Does every element have a one-line description of its
      responsibilities (not just a bare name)?
- [ ] **Technology** — Where applicable (containers, components), is the key technology
      choice stated, e.g. "Java and Spring Boot", "React SPA", "PostgreSQL"?
- [ ] **No unexplained acronyms** — Are all acronyms, abbreviations, and internal code
      names either spelled out, described, or defined in the key/glossary? (Standard
      technical terms like HTTP/JSON/SQL are fine; internal names like "Plutus" are not.)
- [ ] **Notation meaning** — Is the meaning of every colour, shape, icon, border style,
      and element size explained in the key (or are they deliberately uniform)?

## Relationships (the arrows)

- [ ] **Every line labelled** — Does every arrow carry a label describing the *intent*
      of the relationship? No unlabelled lines.
- [ ] **Specific labels** — Do labels say something specific ("Makes API calls to",
      "Reads from / writes to", "Sends events to") rather than a vague "Uses"?
- [ ] **Direction matches label** — Does the label read correctly in the arrow's
      direction? Ending the label with a preposition (to / from / with) makes it read as
      a sentence: "UI *makes API requests to* Backend."
- [ ] **No ambiguous arrows** — Are arrows unidirectional (pointing from the initiating
      element to the receiving one)? Bidirectional arrows are ambiguous — split into two
      only when the interactions genuinely differ (e.g. sync request + async pub/sub).
- [ ] **Relationship technology** — Where applicable, is the protocol / mechanism stated
      (e.g. "HTTPS", "gRPC", "JMS", "SQL/TCP")?
- [ ] **Relationship notation** — Is the meaning of every line style and arrowhead
      explained (e.g. solid = synchronous, dashed = asynchronous)? Avoid relying on
      subtle arrowhead differences that vanish when zoomed out.

## Common defects to catch

- [ ] **Missing external systems** — Are all external systems the in-scope system depends
      on (or that depend on it) actually shown?
- [ ] **Omitted technology** — Any container/component missing its technology choice?
- [ ] **Mixed abstraction levels** — Any single view that mixes levels?
- [ ] **Generic terms** — Any vague catch-all boxes ("business logic", "backend",
      "utils") that hide real structure?
- [ ] **"C4 container" vs "Docker container"** — Is every box labelled `[Container]`
      actually a C4 container (a running application or data store), not a deployment
      node or an OS-level container image?

## Render and look — visual & scoping defects

The checks above read the *content*; these read the *picture*. **Actually render each view
(PNG/SVG or the live server) and look at it** — the DSL validates fine on diagrams that are
visually broken, and these defects are invisible in the source. This is a first-class part of
the review, not optional.

- [ ] **Empty / near-empty view** — Does a view render as a blank or one-box picture? A
      misscoped `include`/`exclude` silently resolves to **0 elements**. **Verify the per-view
      element and relationship counts** (from the exported `workspace.json`) before trusting any
      view — an empty view is the most common silent failure.
- [ ] **Out-of-scope inclusions** — Did a view drag in elements it shouldn't? `include *` on a
      hub that everything points at pulls the **whole landscape** into one view. Scope it down
      (explicit `include`, or `exclude` the hub).
- [ ] **Hairball** — Too many crossing edges to follow? Usually a **cross-cutting dependency**
      (telemetry, feature flags, auth) drawn on the wrong view. Move it to its own star view or
      `exclude` it and show it separately.
- [ ] **Overlapping boxes** — Do elements overlap or collide? Often caused by too many edges
      forcing the layout engine; reduce edges (exclude cross-cutting), or try a different
      `autolayout` direction (`tb` vs `lr`).
- [ ] **Orphan / disconnected element** — Any box with no relationships (unless it's a
      deliberately standalone actor)? It usually means a missing edge or a wrong-scope include.
- [ ] **Legibility at size** — Is it readable at the size it will actually be viewed (README
      thumbnail, slide)? Dense labels that are fine zoomed-in vanish at the real size.
- [ ] **Styling survives the export** — Do the ownership colours, shapes, borders, and legend
      render as intended in the format you're shipping? PlantUML and Mermaid style differently,
      and a generated workspace has **no theme** unless you add one.

For model-completeness lint (missing descriptions/technology, elements in no view, etc.), see the
Structurizr Inspections list; the DSL-level fixes for scoping problems are in
[structurizr-dsl.md](structurizr-dsl.md) (*View contents*).

---

## How to use it

**First render the views and look at them** (the *Render and look* section) — then hand the
diagram to someone who did not create it, give no verbal narrative, and walk the content list top
to bottom. Each "no" is a concrete fix. A well-tooled workflow can enforce several automatically
(names, keys, consistent notation, empty-view counts); the rest are judgment calls this review
exists to catch.
