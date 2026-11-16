/**
 * Quality gates for the skills collection.
 *
 *   dagger call lint --source=.
 *   dagger call render-test --source=.
 */
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

// Mirrors the pins in skills/engineering/drawing-c4-diagrams/evals/render/test.sh; bump both together.
const STRUCTURIZR = "structurizr/structurizr:2026.10.26-playwright"
const PLANTUML = "plantuml/plantuml:1.2026.10"
const MERMAID = "minlag/mermaid-cli:12.0.0"
const THEME_URL =
  "https://raw.githubusercontent.com/structurizr/structurizr/v2026.10.26/structurizr-themes/amazon-web-services-2025.07/theme.json"
const RENDER = "skills/engineering/drawing-c4-diagrams/evals/render"

@object()
export class Skills {
  /**
   * skill-lint + reference link check (ci/check.sh)
   */
  @func()
  async lint(source: Directory): Promise<string> {
    return dag
      .container()
      .from("node:22-bookworm")
      .withDirectory("/src", source, { exclude: ["**/node_modules", ".dagger/sdk"] })
      .withWorkdir("/src")
      .withExec(["bash", "ci/check.sh"])
      .stdout()
  }

  /**
   * drawing-c4-diagrams: render the AWS fixture through every export path, then run test.sh --check
   */
  @func()
  async renderTest(source: Directory): Promise<string> {
    const fixture = await source.file(`${RENDER}/aws-deployment.dsl`).contents()
    const work = dag
      .directory()
      .withNewFile("installed.dsl", fixture)
      .withNewFile("url.dsl", fixture.replace("theme amazon-web-services-2025.07", `theme ${THEME_URL}`))

    let structurizr: Container = dag
      .container()
      .from(STRUCTURIZR)
      .withEnvVariable("STRUCTURIZR_THEMES", "/usr/local/structurizr-themes")
      .withDirectory("/work", work)
      .withWorkdir("/work")
    for (const [dsl, format, out] of [
      ["installed.dsl", "svg", "installed/svg"],
      ["installed.dsl", "plantuml", "installed/plantuml"],
      ["installed.dsl", "mermaid", "installed/mermaid"],
      ["url.dsl", "plantuml", "url/plantuml"],
      ["url.dsl", "plantuml/c4plantuml", "url/c4plantuml"],
      ["url.dsl", "mermaid", "url/mermaid"],
    ]) {
      structurizr = structurizr.withExec(["export", "-workspace", dsl, "-format", format, "-output", out], {
        useEntrypoint: true,
      })
    }
    let rendered = structurizr.directory("/work")

    rendered = dag
      .container()
      .from(PLANTUML)
      .withDirectory("/data", rendered, { owner: "appuser" })
      .withExec(["-tsvg", "url/plantuml/structurizr-Deployment.puml"], { useEntrypoint: true })
      .directory("/data")

    rendered = dag
      .container()
      .from(MERMAID)
      .withDirectory("/data", rendered, { owner: "mermaidcli" })
      .withExec(
        ["-i", "url/mermaid/structurizr-Deployment.mmd", "-o", "url/mermaid/structurizr-Deployment.svg"],
        { useEntrypoint: true },
      )
      .directory("/data")

    return dag
      .container()
      .from("debian:bookworm-slim")
      .withDirectory("/src", source.directory(RENDER))
      .withDirectory("/out", rendered)
      .withExec(["bash", "/src/test.sh", "--check", "/out"])
      .stdout()
  }
}
