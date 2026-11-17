# Structurizr icons and themes (research, 2026-11-13)

For `drawing-c4-diagrams`. Bead: skills-3ad.

## TL;DR

- Cloud icon themes ship **inside** the `structurizr/structurizr` Docker image and are referenced by
  bare name: `theme amazon-web-services-2025.07`. No network, no CORS.
- `static.structurizr.com` no longer resolves (DNS `ENOTFOUND`). Every URL-based theme in the
  official docs/cookbook (and `theme default`, which the parser still maps to that host) is dead.
- The skill used `theme default` in 6 places across 4 reference files. It still parses; export
  logs a cloud-EOL warning and renders unstyled, exit 0.
- The official `structurizr/structurizr:<release>-playwright` tag (since 2026.04.19) exports
  PNG/SVG, so the skill's build-from-source recipe is no longer needed.

## Bundled themes

`structurizr-themes/` in [structurizr/structurizr](https://github.com/structurizr/structurizr/tree/main/structurizr-themes),
copied to `/usr/local/structurizr-themes` in every image variant (`eclipse-temurin-*`, `playwright-java-noble`):

| Provider | Installed names |
| --- | --- |
| AWS | `amazon-web-services-2020.04`, `-2022.04`, `-2023.01`, `-2025.07` |
| Azure | `microsoft-azure-2019.09`, `-2020.07`, `-2021.01`, `-2023.01`, `-2024.07`, `-2025.11` |
| GCP | `google-cloud-platform-v1.5`, `-2025.09` |
| Oracle | `oracle-cloud-infrastructure-2020.04`, `-2021.04`, `-2023.04` |
| Kubernetes | `kubernetes` |

Installed names drop the day (`2023.01`, not the old URL's `2023.01.31`). `theme.json` is Apache-2.0;
the PNG icons are the vendors' copyright.

## How a theme becomes icons

- A theme is `theme.json` = `{name, elements:[{tag, icon, ...}]}`; icons are relative PNG filenames
  next to it. `amazon-web-services-2025.07`: 345 element styles, 0 relationship styles.
- An element gets the icon by **carrying the exact tag**, e.g.
  `deploymentNode "CloudFront" { tags "Amazon Web Services - CloudFront" }`. Tags differ between
  versions; look them up in the chosen version's `theme.json`.
- The CLI resolves installed themes from `./themes/` next to the workspace, else `$STRUCTURIZR_THEMES`
  (`AbstractCommand.installThemes`). The entrypoint does **not** set it: pass
  `-e STRUCTURIZR_THEMES=/usr/local/structurizr-themes`. `local`/`server` use property
  `structurizr.themes` (default `<data dir>/themes`); docs say set the env var under Docker.
- Icons from installed themes are **inlined as base64 data URIs** into the workspace
  (`ThemeUtils.inlineStylesUsedFromInstalledThemes`), so the browser renderer and PNG/SVG export avoid
  the CORS failures the notation docs warn about.
- Custom icons: `element "X" { icon <file|url> }`. PNG/JPG via file, HTTPS URL (needs CORS) or data
  URI. The notation page contradicts itself on SVG. Icons sit top/left/bottom inside elements; on
  deployment nodes, groups and boundaries only bottom-left.
- Your own theme: `export -workspace x.dsl -format theme`, drop it in `./themes/<name>/`.

AWS 2025.07 tags for a typical web stack (verified in `theme.json`): `Route 53`, `CloudFront`, `WAF`,
`Load Balancing`, `API Gateway`, `Elastic Container Service`, `Fargate`, `Lambda`, `Aurora`,
`ElastiCache`, `Simple Storage Service`, `OpenSearch Service`, `Simple Queue Service`,
`Simple Email Service`, `Cognito`, `AWS Cloud`, `Region`, `Virtual private cloud VPC`,
`Public subnet`, `Private subnet` (all prefixed `"Amazon Web Services - "`). No Availability Zone tag.

## Where icons render

- Structurizr browser renderer (`local`, `playground`, `server`, PNG/SVG export): yes.
- PlantUML / Mermaid exports: only with a URL-loaded theme; see the verification log below.
- C4 puts provider icons on **deployment** views only; context/container views stay logical.

## Changelog points

- library v6.0.0 (2026-02-01): adds installed themes; "Removes `theme default`" (the parser in
  `main` still accepts it and maps it to the dead URL); removes `branding`.
- app 2026.03.06: theme install for `push`/`validate`/etc.; removes `export -themes`.
- app 2026.04.19: `export -format png|svg -workspace` added; `-playwright` image tags appear on
  Docker Hub the same day (latest: `2026.10.26-playwright`).

## Verified 2026-11-13 (`structurizr/structurizr:2026.10.26-playwright`, OrbStack)

- `/usr/local/structurizr-themes` holds all 16 themes listed above.
- A blogging-app workspace (Route 53 → CloudFront → ALB → ECS/Fargate → Aurora + S3, in AWS Cloud /
  Region nodes) with `theme amazon-web-services-2025.07`: `validate` passes; PNG and SVG export in
  ~3 s; every tagged node shows its AWS icon, in the diagram and the key; SVG embeds icons as base64.
- Without `-e STRUCTURIZR_THEMES=…`: `validate` fails, *"Theme amazon-web-services-2025.07 does not
  exist at /work/amazon-web-services-2025.07"*.
- `color #ffffff` on `"Element"` makes deployment/infrastructure node labels invisible (white on white).
- `theme default`: WARN *"The Structurizr cloud service will reach its End of Life (EOL) on 30
  September 2026 and this theme will not be available"*, then exports unstyled, exit 0.
- PlantUML/Mermaid (2026-11-14, `evals/render/test.sh`, plantuml 1.2026.10, mermaid-cli 12.0.0):
  exporters accept only `http*` icons (`AbstractPlantUMLExporter.isSupportedIcon`,
  `MermaidDiagramExporter.elementStyleHasSupportedIcon`), so installed-theme `data:` icons are
  dropped (0 of 9). With the theme loaded from raw.githubusercontent.com: Structurizr PlantUML 9/9,
  rendered and embedded; C4-PlantUML 0/9 (`Deployment_Node(..., $tags="")`); Mermaid 3/9 with
  `mermaid.icons` = true (infrastructure nodes only; subgraphs get none; remote `<img>` in SVG).
- Still untested: `local` (port 8080) picking up installed themes. `static.structurizr.com` DNS failed from two networks; permanent per the EOL warning.

## Sources

- <https://docs.structurizr.com/server/diagrams/themes>
- <https://docs.structurizr.com/server/diagrams/notation>
- <https://docs.structurizr.com/dsl/cookbook/themes/>
- <https://docs.structurizr.com/dsl/cookbook/amazon-web-services>
- <https://docs.structurizr.com/export>
- github.com/structurizr/structurizr: `structurizr-themes/`, `changelog-*.md`,
  `structurizr-application/Dockerfiles/*`, `AbstractCommand.java`, `ThemeUtils.java`, `ThemeParser.java`
- <https://hub.docker.com/r/structurizr/structurizr/tags>
- Third-party: awslabs/aws-icons-for-plantuml ships `dist/aws-icons-structurizr-theme.json`
