# Runtime, setup, and the local Structurizr toolchain

This skill uses two local Structurizr runtimes with different jobs:

- **Structurizr MCP** — the agent's **inner loop**: validate/parse DSL and export views to
  Mermaid/PlantUML. Fast, no browser.
- **Structurizr Lite** — the human's **outer loop**: render real C4 diagrams and edit
  layout in a browser at `http://localhost:8080`.

Both are optional. Work at the highest tier the environment supports and degrade
gracefully — **never assume Docker is installed**.

## Contents
- Setup flow (first run)
- Config file schema
- Tier 1: MCP inner loop
- Tier 2: Lite outer loop
- Tier 0: no tools

## Setup flow (first run)

Run when `.c4-diagrams.json` is absent (or a declared tool has gone missing):

1. Probe: is `docker` on PATH? Is a browser available? Is an MCP server reachable?
2. Ask the user which tier they want. **Prefer Docker** when offering to install tooling:
   - Tier 1 → `docker pull structurizr/mcp`
   - Tier 2 → also `docker pull structurizr/structurizr`
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

## Tier 1 — MCP inner loop

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

## Tier 2 — Lite outer loop

Render the real diagrams and let the user adjust layout:

```bash
docker pull structurizr/structurizr
docker run -it --rm -p 8080:8080 \
  -v "$(pwd)/docs/architecture:/usr/local/structurizr" \
  structurizr/structurizr local
```

- Mount the configured diagram dir to `/usr/local/structurizr`; Lite reads
  `workspace.dsl` there and serves the diagrams at `http://localhost:8080`.
- Layout edits in the browser auto-save back to disk.
- On first run in an empty dir Lite generates a `workspace.dsl` template — overwrite it
  with the model this skill builds.
- Handle the common failures: Docker not installed → drop to Tier 1/0; port 8080 busy →
  offer another port and update config.

## Tier 0 — no tools

Still useful: author and eyeball-validate the DSL, produce a **Mermaid** export as text,
and tell the user to paste the DSL into the playground at `https://structurizr.com/dsl`
(or the Mermaid into any Mermaid renderer). Offer to move up a tier via the setup flow.
