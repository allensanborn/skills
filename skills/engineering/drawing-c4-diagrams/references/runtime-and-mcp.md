# Runtime, setup, and the local Structurizr toolchain

This skill uses local Structurizr runtimes with different jobs:

- **Structurizr MCP** (`structurizr/mcp`): the agent's **inner loop**: validate/parse DSL and
  export views to Mermaid/PlantUML. Fast, no browser. Still its **own image**, not a subcommand.
- **`structurizr/structurizr local`**: the human's **outer loop**: render real C4 diagrams and
  edit layout in a browser at `http://localhost:8080`. (This is what used to be Structurizr Lite.)
- **`structurizr/structurizr` headless subcommands** (`validate` / `export` / `inspect` /
  `generate`): the **headless workhorse** and the **practical default whenever Docker is
  present**: `validate` the DSL, render PNG/SVG (own layout, or Mermaid/PlantUML → rasterise), `inspect` (model
  lint), `generate system-landscape`. No MCP server, no browser. See
  [Headless export](#headless-export-no-mcp-no-browser).

All are optional, but note the shape: **with Docker, the headless CLI is the baseline**
(validate + render images + inspect + generate); **MCP and `local` are enhancements on top** (a
faster in-chat loop, and interactive layout). Work at the highest tier the environment supports
and degrade gracefully: **never assume Docker is installed**, and **don't assume MCP** just
because Docker is there.

> **Structurizr vNext consolidated everything into one tool, one repo
> ([structurizr/structurizr](https://github.com/structurizr/structurizr)), one image.**
> Use `structurizr/structurizr` for everything except MCP. The older standalone
> `structurizr/lite` and `structurizr/cli` images are **frozen**: the CLI, Lite, and the
> on-premises installation "will not receive any further updates from this point forward."
> Their **dated tags remain on Docker Hub** and still run (the old git repos are archived, not
> deleted, so forking is a supported escape hatch), but **`:latest` was replaced with a stub**
> that prints a migration notice and exits; a container started from it dies immediately.
> Don't reach for either; there is no reason to author new diagrams on frozen tooling.
>
> **Old product → new subcommand** ([docs.structurizr.com/eol](https://docs.structurizr.com/eol)):
>
> | End-of-life product | Replacement |
> | --- | --- |
> | Structurizr Lite | `local` |
> | Structurizr CLI | `push`, `pull`, `export`, `validate`, `inspect`, `generate`, … |
> | Structurizr on-premises installation | `server` |
> | Structurizr **cloud service** | **none**: it is being retired outright |
>
> Use the new names in anything you write for the user. Never send a user to the cloud service
> or tell them to sign up for a structurizr.com workspace. Send them to the **playground** or a
> local run instead. Full subcommand set: `playground`, `local`, `server`, `export`, `push`,
> `pull`, `branches`, `create`, `delete`, `lock`, `unlock`, `merge`, `validate`, `inspect`,
> `list`, `generate`, `regenerate-apikey`. To confirm against the installed build rather than
> this list, run **`docker run -it --rm "$IMG" help`**.
>
> Everything is now one Spring Boot app with embedded Tomcat (Java 21), so the `.war` is
> interchangeable with the image: `java -jar structurizr.war <subcommand>` takes the same
> subcommands. Useful when the user can't run Docker but does have a JVM.

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
   - Tier 1 → `docker pull "$IMG"` (the tested release, and
     the only variant that can export PNG/SVG; see below)
   - Tier 2 → also `docker pull "$MCP_IMG"` (MCP is still a **separate image**)
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
  "local": { "port": 8080 },
  "reviewGrill": true
}
```

`mcp.mode` is `local-docker` | `public` | `none`. `tier` is `0` | `1` | `2`. `local.port` is the
`structurizr/structurizr local` port; older configs call that key `lite`, so read `lite` as `local`.

## Tier 2: MCP inner loop

Run the server (local Docker, privacy-preserving default):

```bash
docker pull "$MCP_IMG"
docker run -it --rm -p 3000:3000 -e PORT=3000 "$MCP_IMG" -dsl -mermaid -plantuml
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

## Tier 2: the `local` outer loop

Render the real diagrams and let the user adjust layout:

```bash
docker run -it --rm -p 8080:8080 \
  -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes \
  -v "$(pwd)/docs/architecture:/usr/local/structurizr" \
  "$IMG" local
```

- **Keep `-e STRUCTURIZR_THEMES=…`.** Without it `local` looks for themes in
  `/usr/local/structurizr/themes/`, and a workspace using an installed theme (e.g.
  `theme amazon-web-services-2025.07`) fails to load: *"Theme … does not exist"* in the logs.
  With it, the startup log lists all 16 themes and the browser draws the icons (verified
  2026-11-16 by exporting PNGs from the running page with `export -format png -url
  http://host.docker.internal:8080/workspace/1/diagrams`).

- Mount the configured diagram dir to `/usr/local/structurizr`; `local` reads
  `workspace.dsl` there and serves the diagrams at `http://localhost:8080`.
- Layout edits in the browser auto-save back to disk.
- On first run in an empty dir `local` generates a `workspace.dsl` template; overwrite it
  with the model this skill builds.
- Handle the common failures: Docker not installed → drop to Tier 0; port 8080 busy →
  offer another port and update config. Note `local` and `playground` both bind 8080, so don't
  run them at once on the same port.

## Headless export (no MCP, no browser)

When you have Docker but no MCP server and don't want the browser (common: rendering images
into a repo from a CI-like flow), the same `structurizr/structurizr` image exports views
directly from the DSL. This is the reliable way to produce committable diagrams at Tier 1 and up.

**Preferred for committed images: Structurizr's own SVG export** (PNG only where SVG won't display) (better layout than PlantUML;
see [below](#png-and-svg-with-structurizrs-own-layout-preferred)). The PlantUML pipeline in the next
block is the fallback when you cannot use the `-playwright` image.

```bash
cd docs/architecture   # the dir holding workspace.dsl

# 0. validate the DSL (the purpose-built check); do this before exporting.
#    Keep STRUCTURIZR_THEMES on every command: without it a workspace using an installed theme
#    (e.g. amazon-web-services-2025.07) fails to parse ("Theme ... does not exist").
docker run --rm -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes -v "$PWD:/work" -w /work "$IMG" \
  validate -workspace workspace.dsl

# 1. (fallback path) DSL -> Mermaid and PlantUML (parsing the DSL here also validates it)
docker run --rm -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes -v "$PWD:/work" -w /work "$IMG" \
  export -workspace workspace.dsl -format mermaid  -output exports
docker run --rm -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes -v "$PWD:/work" -w /work "$IMG" \
  export -workspace workspace.dsl -format plantuml -output exports

# 2. PlantUML -> PNG + SVG (rasterise; needs no network)
cd exports
docker run --rm -v "$PWD:/data" -w /data "$PLANTUML_IMG" -tpng "structurizr-*.puml"
docker run --rm -v "$PWD:/data" -w /data "$PLANTUML_IMG" -tsvg "structurizr-*.puml"
```

Notes:

- One `.mmd`/`.puml` file is written **per view**, plus a `*-key.*` legend per view.
- **Prefer `validate -workspace workspace.dsl`** as the parse check: it is the purpose-built
  command and it reports the error without writing any files. **Script on the exit code: `0`
  parses, `1` does not.** On success it prints *nothing*, so silence is a pass; don't wait for a
  confirmation line. On failure it logs `ERROR com.structurizr.command.ValidateCommand -- <message>
  at line N of <file>`, which names the offending line (verified on v2026.10.26). A failed `export` (non-zero exit, or
  a `StructurizrDslParserException` in the output) is an equally valid **validation signal** when
  you were going to export anyway. Treat either exactly like an MCP validation failure and fix
  the DSL. `validate` catches parse errors; `inspect` is the separate **model lint** on top.
- Structurizr's Mermaid uses HTML `<div>` labels; they render in most Mermaid viewers but can
  look rough on GitHub. For diagrams embedded in a repo README, commit the **SVG** output.
- Never use `theme default`: its host died with the cloud service; export logs an EOL warning
  and renders unstyled. Write base styles; for provider icons use an **installed** theme (needs
  `-e STRUCTURIZR_THEMES=/usr/local/structurizr-themes`); see
  [structurizr-dsl.md](structurizr-dsl.md#cloud-icon-themes-aws-azure-gcp-oci-kubernetes).
- **Everything in the prebuilt image is free except `server`.** vNext moved to an **open core**
  model. Free and open source: the CLI functionality (`push`, `pull`, `export`, …), `local`, and
  `playground`. Only `server` (standing up **your own** Structurizr server) is gated. Per
  [docs.structurizr.com/binaries](https://docs.structurizr.com/binaries): *"All Structurizr
  commands are free to use from these binaries except for `server`, which requires a license."*
  So `validate`, `export`, `inspect`, `merge`, `generate` **and** the client commands
  `create`/`push`/`pull`/`list` that talk to someone else's server all cost nothing.
- **What "open core" gates:** the server core is open source; the **closed extensions** are the
  enterprise features: authentication, cloud data storage, Elasticsearch integration, Redis for
  distributed sessions, and the workspace admin API. Building `server` from source is free; the
  **prebuilt** binaries need a license, priced per installation by unique users/year
  (Small 1–20 £300/mo, Medium 21–50 £600/mo, Large 51–100 £900/mo, Enterprise 101+ by quote,
  billed annually). Don't quote these as current without checking; pricing drifts.
- **`server` does not start from the prebuilt image without a license.** The announcement's
  quickstart labels the `server` subcommand "open core version", which is
  misleading: on v2026.10.26 the container boots, prints its config, logs the lines below, and
  exits 1.

  ```text
  No license found
   - check the structurizr.license property has been configured
   - request your 14-day trial license at https://trial.structurizr.com
  ```

  So set `structurizr.license`, use the **14-day trial at trial.structurizr.com**, or build the
  open core from source. Tell the user up front, before they mount a data directory. For the multi-workspace / enterprise landscape-generation pipeline see
  [multi-system-and-enterprise.md](multi-system-and-enterprise.md).
- **`filtered` views and `perspectives` don't survive the text exports.** The PlantUML and Mermaid
  exports silently skip `filtered` views (only the base view is written), and a filtered view
  rejects `autolayout` on its base (*"automatic layout ... is not supported for filtered views"*).
  The PNG/SVG export does the opposite: it writes the filtered view and **skips its base** (verified
  on `2026.10.26-playwright`, 2026-11-18). `perspectives` are an interactive-only overlay in the
  Structurizr UI (the binoculars / `p` key), invisible in every export. So if you need "clean" and "full" variants of a diagram in
  **committed images**, author them as **two explicit views** (e.g. one `include *`, one that
  `exclude`s the platform tag), not one base + a filtered derivative. Both are fine when the
  audience browses the live Structurizr server instead.

### PNG and SVG with Structurizr's own layout (preferred)

`export -format png|svg` runs Structurizr's own renderer (the same Dagre layout as `local`) in headless
Chromium via Playwright. **The default `structurizr/structurizr` tags cannot do it**: they accept the
flag, then fail with *"Exporting to PNG/SVG is not supported in this build"*. Since 2026.04.19
Structurizr publishes an official **`<release>-playwright`** tag (Microsoft's Playwright Java base +
the same war + the bundled themes) that can. Pin the release:

```bash
IMG=…   # the IMG line from SKILL.md, Pinned images
run() { docker run --rm --ipc=host -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes \
          -v "$PWD:/work" -w /work "$IMG" "$@"; }
cd docs/architecture
run validate -workspace workspace.dsl
run export -workspace workspace.dsl -format png -output exports   # to look at and measure
run export -workspace workspace.dsl -format svg -output exports   # to commit
```

Commit the SVGs (and not the PNGs) unless the diagrams go somewhere SVG won't display, such as
slides, chat or email; then commit PNG instead. Delete the `*-key.*` legends you don't use.

`STRUCTURIZR_THEMES` only matters if the DSL uses an installed theme (e.g. AWS icons); it is harmless
otherwise. In zsh, pass `-e` and its value as separate words: a `$T="-e …"` variable is not
word-split, the variable never arrives and `validate` fails with *"Theme … does not exist"*.

Gotchas (all hit for real):

- **A deployment-view relationship must not end on a deployment node** (only on container /
  software-system instances or infrastructure nodes). One such edge makes the whole view collapse to a
  2000x2000 pile of overlapping boxes, with no error, whatever the `autolayout` direction. State
  "provisioned by X" in the node's description instead, or point the edge at an infrastructure node.
- **Check the output size.** A fallback of exactly 2000x2000 means the layout failed; the exporter
  still reports success.
- **Each image (PNG or SVG) carries a render-time footer**, so every re-render changes every image even when the
  model did not. Restore unchanged images (`git checkout`) before committing, or accept the noise.
- **`filtered` views export, but their base doesn't.** The base can't have `autolayout` ("not
  supported for filtered views"); without it the renderer still lays out the filtered view, but
  the base view is not written at all. Perspectives never appear. To ship both a "full" and a
  "clean" image, author two explicit views instead (verified 2026-11-18).
- Verified on `2026.10.26-playwright` (2026-11-13), including an AWS-themed deployment view whose
  icons render in the PNG, the SVG (base64-embedded) and the key. The earlier build-from-source
  recipe (Maven stage + `mcr.microsoft.com/playwright/java`) is only needed for an unreleased
  commit. Output files are named `<view-key>.png` / `.svg`
  (no `structurizr-` prefix, unlike the PlantUML path), plus `<view-key>-key.*` for the legend.

## Image source: PlantUML vs Structurizr's own layout

Two ways to get images, with a real quality/capability tradeoff:

- **Headless export → PlantUML/Mermaid** (the fallback pipeline). These do their **own layout**, so
  images are **regenerable with zero drift**, ideal for CI and repo-committed diagrams. Cost: the
  layout is PlantUML's (rougher on dense diagrams; reduce edges by excluding cross-cutting rather
  than fight it), and **`filtered` views / `perspectives` don't render at all** on this path.
- **Structurizr's own renderer**: `structurizr/structurizr local` in the browser, or the
  licensed server. Uses Structurizr's Dagre layout plus any saved manual layout: the familiar,
  cleaner C4 look, and the **only** way `perspectives` appear (headless PNG/SVG shows `filtered`
  views but drops their base). Cost: needs a
  browser (and, for the server, a license), and hand-tuned layout can drift.
  **vNext rebuilt this**: Dagre was upgraded and properly integrated into the renderer (notably
  better at routing arrows and their labels around elements), and **server-side Graphviz autolayout
  was dropped from the UI**. So auto-layout quality here is meaningfully better than in Lite. If a
  past attempt was abandoned because the automatic layout was a mess, it is worth re-trying. Don't
  offer Graphviz as a UI layout option; it still exists but is no longer wired into the UI.

Default to **headless Structurizr SVG for committed images** (the container build above: same
renderer as `local`, still regenerable, no browser session); fall back to headless PlantUML when that
image cannot be built. Use `local` for interactive layout tweaks or when you need perspectives.

## Tier 0: no tools

Still useful: author and eyeball-validate the DSL, produce a **Mermaid** export as text,
and tell the user to paste the DSL into the playground at **`https://playground.structurizr.com`**
(or the Mermaid into any Mermaid renderer). Offer to move up a tier via the setup flow.

The playground is the **free, open-source** DSL editor; it is *not* the cloud service, which is
end-of-life, so it is the right thing to point a no-tools user at. The old `structurizr.com/dsl`
URL 302-redirects there; use the canonical `playground.structurizr.com` when you write it out.

With Docker, the same playground runs **locally**: worth offering when the DSL is sensitive and
you'd rather it never left the machine:

```bash
docker run -it --rm -p 8080:8080 "$IMG" playground
```
