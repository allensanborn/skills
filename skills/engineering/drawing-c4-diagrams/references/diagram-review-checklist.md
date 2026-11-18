# C4 Diagram Review Checklist

A post-generation checklist for critiquing a C4 diagram *before* shipping it. Walk it
item by item. The core diagnostic test: could someone who was **not** in the room when
the diagram was drawn understand it with **no spoken narrative**? Every "no" is a defect
to fix: it points to missing text, an unexplained notation choice, or an ambiguous
element/relationship.

Based on Simon Brown's C4 model (c4model.com).

---

## General

- [ ] **Title**: Does the diagram have a title?
- [ ] **Type**: Can you tell the diagram's type from the title (System Context,
      Container, Component, Code, Deployment, Dynamic, System Landscape)?
- [ ] **Scope**: Can you tell what the diagram is about: what single thing is "in the
      box" and what this view covers?
- [ ] **Key / legend**: Is there a key/legend, on or near the diagram, explaining every
      shape, colour, icon, border style, and line style used?
- [ ] **Reading order**: Within a set of diagrams, is it clear which to read first and
      how they nest (context to containers to components)?
- [ ] **Consistent notation**: Is the notation used consistently across the diagram (and
      across the set)? Do element placement conventions hold? For example, if people are at
      the top of the context view, are they at the top of the container view too?

## Elements (the boxes)

- [ ] **Name**: Does every element have a clear name?
- [ ] **Type / abstraction level**: Does every element declare its type (Person,
      Software System, Container, Component, Code, Deployment Node), usually in square
      brackets, e.g. `[Container]`?
- [ ] **Single abstraction level**: Are all elements at the *same* abstraction level?
      No mixing containers with components, or software systems with code, in one view.
- [ ] **Description**: Does every element have a one-line description of its
      responsibilities (not just a bare name)?
- [ ] **Technology**: Where applicable (containers, components), is the key technology
      choice stated, e.g. "Java and Spring Boot", "React SPA", "PostgreSQL"?
- [ ] **No unexplained acronyms**: Are all acronyms, abbreviations, and internal code
      names either spelled out, described, or defined in the key/glossary? (Standard
      technical terms like HTTP/JSON/SQL are fine; internal names like "Plutus" are not.)
- [ ] **Notation meaning**: Is the meaning of every colour, shape, icon, border style,
      and element size explained in the key (or are they deliberately uniform)?

## Relationships (the arrows)

- [ ] **Every line labelled**: Does every arrow carry a label describing the *intent*
      of the relationship? No unlabelled lines.
- [ ] **Specific labels**: Do labels say something specific ("Makes API calls to",
      "Reads from / writes to", "Sends events to") rather than a vague "Uses"?
- [ ] **Direction matches label**: Does the label read correctly in the arrow's
      direction? Ending the label with a preposition (to / from / with) makes it read as
      a sentence: "UI *makes API requests to* Backend."
- [ ] **No ambiguous arrows**: Are arrows unidirectional (pointing from the initiating
      element to the receiving one)? Bidirectional arrows are ambiguous; split into two
      only when the interactions genuinely differ (e.g. sync request + async pub/sub).
- [ ] **Relationship technology**: Where applicable, is the protocol / mechanism stated
      (e.g. "HTTPS", "gRPC", "JMS", "SQL/TCP")?
- [ ] **Relationship notation**: Is the meaning of every line style and arrowhead
      explained (e.g. solid = synchronous, dashed = asynchronous)? Avoid relying on
      subtle arrowhead differences that vanish when zoomed out.

## Common defects to catch

- [ ] **Missing external systems**: Are all external systems the in-scope system depends
      on (or that depend on it) actually shown?
- [ ] **Omitted technology**: Any container/component missing its technology choice?
- [ ] **Mixed abstraction levels**: Any single view that mixes levels?
- [ ] **Generic terms**: Any vague catch-all boxes ("business logic", "backend",
      "utils") that hide real structure?
- [ ] **"C4 container" vs "Docker container"**: Is every box labelled `[Container]`
      actually a C4 container (a running application or data store), not a deployment
      node or an OS-level container image?

## Render and look: visual & scoping defects

The checks above read the *content*; these read the *picture*. **Actually render each view
(PNG/SVG or the live server) and look at it**, because the DSL validates fine on diagrams that are
visually broken, and these defects are invisible in the source. This is a first-class part of
the review, not optional.

- [ ] **Empty / near-empty view**: Does a view render as a blank or one-box picture? A
      misscoped `include`/`exclude` silently resolves to **0 elements**. **Verify the per-view
      element and relationship counts** (from the exported `workspace.json`) before trusting any
      view. An empty view is the most common silent failure.
- [ ] **Out-of-scope inclusions**: Did a view drag in elements it shouldn't? `include *` on a
      hub that everything points at pulls the **whole landscape** into one view. Scope it down
      (explicit `include`, or `exclude` the hub).
- [ ] **Hairball**: Too many crossing edges to follow? Usually a **cross-cutting dependency**
      (telemetry, feature flags, auth) drawn on the wrong view. Move it to its own star view or
      `exclude` it and show it separately. If the crowding is services-to-stores rather than one
      shared hub, **split by role**: a request-path view with the stores excluded, plus a small data
      view per store group ([patterns](patterns-and-pitfalls.md#crowded-container-view-split-by-role)).
- [ ] **Collapsed deployment view**: Is a deployment view a pile of overlapping boxes in one
      corner, or exactly 2000x2000 px? A relationship ending on a **deployment node** (instead of an
      instance or infrastructure node) breaks Structurizr's layout silently. Retarget the edge or move
      the fact into the node's description. Check image dimensions for every deployment view.
- [ ] **Invisible labels / missing icons**: Can you read every node's name? White text on a
      deployment or infrastructure node means `color` was set on `"Element"`; set it per type. If
      the DSL uses a cloud theme, does every tagged node show its icon? A missing icon means the tag
      doesn't match that theme version's `theme.json` exactly. Unstyled grey boxes everywhere mean a
      `theme default` slipped in.
- [ ] **Overlapping boxes**: Do elements overlap or collide? Often caused by too many edges
      forcing the layout engine; reduce edges (exclude cross-cutting), or try a different
      `autolayout` direction (`tb` vs `lr`).
- [ ] **Orphan / disconnected element**: Any box with no relationships (unless it's a
      deliberately standalone actor)? It usually means a missing edge or a wrong-scope include.
- [ ] **Legibility at size**: Measure it; don't eyeball the full-size render. Viewers shrink a
      wide image to fit: a GitHub README column is about **880 px**, a full-screen slide about
      **1920 px** (if the user hasn't said where it goes, assume a README). Structurizr draws
      names and relationship labels at 24 px, so labels shrink to `24 × target ÷ image width`
      px, and below about 7 px they can't be read. That puts the **image width budget at about
      3.4× the target**: roughly **3000 px for a README**, 6500 px for a slide. Read the width
      from the export (`file exports/<key>.png`; an SVG's `width` attribute is the same number), and if a resize tool is
      available (`sips --resampleWidth 880`, ImageMagick) look at the shrunk copy too.
      Over budget, fix it before showing the user; don't just offer to. In this order:
      1. **Tighten the spacing.** Arrows' labels between two rows sit side by side in that gap,
         so a few elements with many labelled arrows still render wide; external systems also
         land in the bottom row beside the boundary, leaving an empty corner the automatic
         layout can't remove. `autolayout tb 200 50` (rank, node separation) instead of the
         default 300/300 cut a 6-element container view from 3345 to 2878 px (v2026.10.26).
         Wider spacing only makes it worse.
      2. **Try the other direction.** `tb` is usually narrower than `lr`, especially for deeply
         nested deployment nodes; measure both if the first is still over.
      3. **Split the view** (see [patterns](patterns-and-pitfalls.md#modeling-patterns-common-use-cases)).
         Past about **12-15 elements** this is usually the only fix.
- [ ] **Styling survives the export**: Do the ownership colours, shapes, borders, and legend
      render as intended in the format you're shipping? PlantUML and Mermaid style differently,
      and a generated workspace has **no theme** unless you add one.

The DSL-level fixes for scoping problems are in [structurizr-dsl.md](structurizr-dsl.md)
(*View contents*); the machine-checkable model-completeness lint is **Inspections**, below.

## Inspections: the automatable lint

Structurizr ships an enumerated model lint ([docs](https://docs.structurizr.com/workspaces/inspections)).
**Run it locally (no server, no license):**

```bash
docker run --rm -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes -v "$PWD:/work" -w /work structurizr/structurizr:2026.10.26-playwright inspect -workspace <workspace.dsl>
```

It reports (all default to `error`; tune to `warning` / `info` / `ignore`):

- **Workspace**: `workspace.scope` (is a scope set?), `workspace.tooling`.
- **Model**: `model.empty`; a **description** on every person / software system / container /
  component / relationship (`model.*.description`); a **technology** on every container / component /
  deployment node / infrastructure node (`model.*.technology`); `model.element.disconnected`
  (orphan); `model.element.noview` (element on no view); `model.softwaresystem.documentation` and
  `.decisions` (a system *with containers* should have both); `model.deploymentnode.empty`.
- **Views**: `views.empty`, `views.view.empty`, `views.view.key`, `views.view.layout`.

These are the checks a human shouldn't have to eyeball. Run `inspect` and fix the real hits before
the render-and-look and content passes. **Caveat for the decentralized pattern:** run against a
single per-system workspace, `inspect` flags the catalog-referenced *other* systems as
`disconnected` / `noview`. That is expected (they're external to that workspace); read those as noise.

---

## How to use it

**First render the views and look at them** (the *Render and look* section), then hand the
diagram to someone who did not create it, give no verbal narrative, and walk the content list top
to bottom. Each "no" is a concrete fix. A well-tooled workflow can enforce several automatically
(names, keys, consistent notation, empty-view counts); the rest are judgment calls this review
exists to catch.
