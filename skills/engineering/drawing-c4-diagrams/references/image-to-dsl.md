# Turning a pasted image into Structurizr DSL

Users often start from a picture — a whiteboard photo, a hand-drawn sketch, an existing
architecture diagram, or a screenshot. This skill converts that into
[C4 model](c4-model.md) DSL. Structurizr's own guidance: convert **one C4 level at a
time**, iteratively, and treat generated DSL as a **draft to refine**, not a finished
artifact.

## Two modes — pick based on complexity

When an image is pasted, first **assess its complexity** (element count, whether it's
already clearly C4, how much abstraction-level ambiguity it has), then ask the user which
mode they want:

- **One-pass** — read the whole image and emit multi-level DSL in a single go. Suitable
  for **simple** images (a handful of clearly-typed boxes). Faster, less rigorous.
- **Grilled, level-by-level** — the default for **complex or ambiguous** images. Strongly
  encourage it: it is where this skill earns its keep.

State your read of the complexity and your recommendation; let the user choose.

## The grilled flow (recommended for anything non-trivial)

1. **Interpret** — describe what you see, mapped onto C4 abstractions (person / software
   system / container / component). Do not silently guess.
2. **Interpretation grill** — run Section B of [grill-questions.md](grill-questions.md).
   Challenge every mapping and **reject silent mis-mapping**:
   - a drawn "cloud"/server box may be a **deployment node**, not a software system;
   - a box labelled like a Docker container is a **C4 container** only if it's a
     separately deployable/runnable unit — otherwise it's a component;
   - an outside box is an **external software system**, not part of the system in scope.
3. **Generate one level** — usually System Context first. Write it to `workspace.dsl`
   following [structurizr-dsl.md](structurizr-dsl.md).
4. **Validate + preview** — via MCP (see [runtime-and-mcp.md](runtime-and-mcp.md)).
5. **Layer the next level** — "add the containers" from a second image or by interviewing;
   append to the **same** model. Repeat for components if useful.

## The one-pass flow (simple images only)

1. Read the image, map elements to C4 abstractions, and emit the full DSL.
2. Validate via MCP and show a Mermaid preview.
3. Still run the **post-generation review grill** unless the user skipped it — one-pass
   trades rigor up front, so the review catches what the fast read missed.

## Notes

- Multiple images (one per level) are supported; a single rich image is **decomposed into
  levels**, not dumped into one flat diagram.
- Hand-drawn text is often ambiguous — confirm names rather than guessing acronyms.
- Preserve the user's intent; when the drawing violates C4 (mixed abstraction levels,
  unlabelled arrows), surface it in the grill instead of quietly "fixing" it.
