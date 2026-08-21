# Runtime, setup, and the local Structurizr toolchain

This skill uses local Structurizr runtimes with different jobs:

- **Structurizr MCP** (`structurizr/mcp`) — the agent's **inner loop**: validate/parse DSL and
  export views to Mermaid/PlantUML. Fast, no browser. Still its **own image**, not a subcommand.
- **`structurizr/structurizr local`** — the human's **outer loop**: render real C4 diagrams and
  edit layout in a browser at `http://localhost:8080`. (This is what used to be Structurizr Lite.)
- **`structurizr/structurizr` headless subcommands** (`validate` / `export` / `inspect` /
  `generate`) — the **headless workhorse** and the **practical default whenever Docker is
  present**: `validate` the DSL, export Mermaid/PlantUML → rasterise to PNG/SVG, `inspect` (model
  lint), `generate system-landscape`. No MCP server, no browser. See
  [Headless export](#headless-export-no-mcp-no-browser).

All are optional, but note the shape: **with Docker, the headless CLI is the baseline**
(validate + render images + inspect + generate); **MCP and `local` are enhancements on top** (a
faster in-chat loop, and interactive layout). Work at the highest tier the environment supports
and degrade gracefully — **never assume Docker is installed**, and **don't assume MCP** just
because Docker is there.

> **Structurizr vNext consolidated everything into one tool, one repo
> ([structurizr/structurizr](https://github.com/structurizr/structurizr)), one image.**
> Use `structurizr/structurizr` for everything except MCP. The older standalone
> `structurizr/lite` and `structurizr/cli` images are now **deprecated redirect stubs** —
> their entrypoint just prints a migration notice and exits, so a container started from them
> dies immediately. Don't reach for them.
>
> **Old product → new subcommand** ([docs.structurizr.com/eol](https://docs.structurizr.com/eol)):
>
> | End-of-life product | Replacement |
> | --- | --- |
> | Structurizr Lite | `local` |
> | Structurizr CLI | `push`, `pull`, `export`, `validate`, `inspect`, `generate`, … |
> | Structurizr on-premises installation | `server` |
> | Structurizr **cloud service** | **none** — it is being retired outright |
>
> Use the new names in anything you write for the user. Never send a user to the cloud service
> or tell them to sign up for a structurizr.com workspace — send them to the **playground** or a
> local run instead. Full subcommand set: `playground`, `local`, `server`, `export`, `push`,
> `pull`, `branches`, `create`, `delete`, `lock`, `unlock`, `merge`, `validate`, `inspect`,
> `list`, `generate`, `regenerate-apikey`.

## Contents
- Setup flow (first run)
- Config file schema
- Tier 1: headless `structurizr/structurizr` (see [Headless export](#headless-export-no-mcp-no-browser))
- Tier 2: MCP inner loop
- Tier 2: the `local` outer loop
- Tier 0: no tools

Tier numbers match the table in `SKILL.md`: **1 = Docker headless** (the practical default),
**2 = MCP and/or a browser** on top of it.

## Setup flow (first run)

Run when `.c4-diagrams.json` is absent (or a declared tool has gone missing):

1. Probe: is `docker` on PATH? Is a browser available? Is an MCP server reachable?
2. Ask the user which tier they want. **Prefer Docker** when offering to install tooling:
   - Tier 1 → `docker pull structurizr/structurizr`
   - Tier 2 → also `docker pull structurizr/mcp` (MCP is still a **separate image**)
3. Ask where diagrams should live (default `docs/architecture/`).
4. Ask whether the post-generation review grill is on (default: on).
5. Confirm MCP privacy: local Docker (default) vs public `mcp.structurizr.com` (opt-in).
6. Persist answers to `.c4-diagrams.json`. On later runs, read it silently.

## Config file schema

`.c4-diagrams.json` at the repo root:

```json
{
  "tier": 2,
  "diagramDir": "docs/architecture",
  "mcp": { "mode": "local-docker", "url": "http://localhost:3000/mcp" },
  "lite": { "port": 8080 },
  "reviewGrill": true
}
```

`mcp.mode` is `local-docker` | `public` | `none`. `tier` is `0` | `1` | `2`.

## Tier 2 — MCP inner loop

Run the server (local Docker, privacy-preserving default):

```bash
docker pull structurizr/mcp
docker run -it --rm -p 3000:3000 -e PORT=3000 structurizr/mcp -dsl -mermaid -plantuml
```

Client config (Claude Desktop can't do raw http; bridge with mcp-remote):

```json
{
  "mcpServers": {
    "structurizr-mcp": {
      "command": "npx",
      "args": ["mcp-remote", "http://localhost:3000/mcp"]
    }
  }
}
```

Then, after every DSL edit, call the fully-qualified tools:

- `structurizr-mcp:*` DSL tools to **validate/parse** `workspace.dsl` (validator → fix → repeat).
- `structurizr-mcp:*` export tool to render a **Mermaid** view for inline preview.

(Confirm exact tool names from the server's tool list at runtime; enable groups with the
`-dsl -mermaid -plantuml` flags above. Public instance: `mcp.structurizr.com`, opt-in only.)

## Tier 2 — the `local` outer loop

Render the real diagrams and let the user adjust layout:

```bash
docker pull structurizr/structurizr
docker run -it --rm -p 8080:8080 \
  -v "$(pwd)/docs/architecture:/usr/local/structurizr" \
  structurizr/structurizr local
```

- Mount the configured diagram dir to `/usr/local/structurizr`; `local` reads
  `workspace.dsl` there and serves the diagrams at `http://localhost:8080`.
- Layout edits in the browser auto-save back to disk.
- On first run in an empty dir `local` generates a `workspace.dsl` template — overwrite it
  with the model this skill builds.
- Handle the common failures: Docker not installed → drop to Tier 0; port 8080 busy →
  offer another port and update config. Note `local` and `playground` both bind 8080 — don't
  run them at once on the same port.

## Headless export (no MCP, no browser)

When you have Docker but no MCP server and don't want the browser (common: rendering images
into a repo from a CI-like flow), the same `structurizr/structurizr` image exports views
directly from the DSL. This is the reliable way to produce committable diagrams at Tier 2.

```bash
cd docs/architecture   # the dir holding workspace.dsl

# 0. validate the DSL — the purpose-built check; do this before exporting
docker run --rm -v "$PWD:/work" -w /work structurizr/structurizr \
  validate -workspace workspace.dsl

# 1. DSL -> Mermaid and PlantUML (parsing the DSL here also validates it)
docker run --rm -v "$PWD:/work" -w /work structurizr/structurizr \
  export -workspace workspace.dsl -format mermaid  -output exports
docker run --rm -v "$PWD:/work" -w /work structurizr/structurizr \
  export -workspace workspace.dsl -format plantuml -output exports

# 2. PlantUML -> PNG + SVG (rasterise; needs no network)
cd exports
docker run --rm -v "$PWD:/data" -w /data plantuml/plantuml -tpng "structurizr-*.puml"
docker run --rm -v "$PWD:/data" -w /data plantuml/plantuml -tsvg "structurizr-*.puml"
```

Notes:
- One `.mmd`/`.puml` file is written **per view**, plus a `*-key.*` legend per view.
- **Prefer `validate -workspace workspace.dsl`** as the parse check — it is the purpose-built
  command and it reports the error without writing any files. A failed `export` (non-zero exit, or
  a `StructurizrDslParserException` in the output) is an equally valid **validation signal** when
  you were going to export anyway — treat either exactly like an MCP validation failure and fix
  the DSL. `validate` catches parse errors; `inspect` is the separate **model lint** on top.
- Structurizr's Mermaid uses HTML `<div>` labels; they render in most Mermaid viewers but can
  look rough on GitHub. For diagrams embedded in a repo README, prefer the **PNG/SVG** output.
- The export needs the cloud theme only for exact colours; if `theme default` can't be fetched
  offline the export still succeeds with fallback styling.
- **Everything in the prebuilt image is free except `server`.** Per
  [docs.structurizr.com/binaries](https://docs.structurizr.com/binaries): *"All Structurizr
  commands are free to use from these binaries except for `server`, which requires a license."*
  So `validate`, `export`, `inspect`, `merge`, `generate`, `playground`, `local` — **and** the
  client commands `create`/`push`/`pull`/`list` that talk to someone else's server — cost nothing.
  Only standing up **your own** server does. (`server` is open core: free if you build from
  source, minus the enterprise extras — SAML, role-based access, cloud storage. The prebuilt
  container **exits with "No license found"**.) For the multi-workspace / enterprise
  landscape-generation pipeline see
  [multi-system-and-enterprise.md](multi-system-and-enterprise.md).
- **`filtered` views and `perspectives` do NOT survive this export path.** The CLI silently skips
  `filtered` views — only the base view is written — and a filtered view additionally rejects
  `autolayout` on its base (*"automatic layout ... is not supported for filtered views"*).
  `perspectives` are an interactive-only overlay in the Structurizr UI (the binoculars / `p` key),
  invisible in PlantUML/Mermaid output. So if you need "clean" and "full" variants of a diagram in
  **committed images**, author them as **two explicit views** (e.g. one `include *`, one that
  `exclude`s the platform tag), not one base + a filtered derivative. Both are fine when the
  audience browses the live Structurizr server instead.

## Image source: PlantUML vs Structurizr's own layout

Two ways to get images, with a real quality/capability tradeoff:

- **Headless export → PlantUML/Mermaid** (the pipeline above). These do their **own layout**, so
  images are **regenerable with zero drift** — ideal for CI and repo-committed diagrams. Cost: the
  layout is PlantUML's (rougher on dense diagrams — reduce edges by excluding cross-cutting rather
  than fight it), and **`filtered` views / `perspectives` don't render at all** on this path.
- **Structurizr's own renderer** — `structurizr/structurizr local` in the browser, or the
  licensed server. Uses Structurizr's dagre layout plus any saved manual layout: the familiar,
  cleaner C4 look, and the **only** way `filtered` views and `perspectives` appear. Cost: needs a
  browser (and, for the server, a license), and hand-tuned layout can drift.

Default to **headless PlantUML for committed images**; use the Structurizr renderer for a polished
one-off, interactive layout tweaks, or when you need filtered/perspective views.

## Tier 0 — no tools

Still useful: author and eyeball-validate the DSL, produce a **Mermaid** export as text,
and tell the user to paste the DSL into the playground at **`https://playground.structurizr.com`**
(or the Mermaid into any Mermaid renderer). Offer to move up a tier via the setup flow.

The playground is the **free, open-source** DSL editor — it is *not* the cloud service, which is
end-of-life, so it is the right thing to point a no-tools user at. The old `structurizr.com/dsl`
URL 302-redirects there; use the canonical `playground.structurizr.com` when you write it out.

With Docker, the same playground runs **locally** — worth offering when the DSL is sensitive and
you'd rather it never left the machine:

```bash
docker run -it --rm -p 8080:8080 structurizr/structurizr playground
```
