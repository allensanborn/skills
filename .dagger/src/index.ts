// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Allen Sanborn
/**
 * Quality gates for the skills collection.
 *
 *   dagger call lint --source=.
 *   dagger call render-test --source=.
 *   dagger call markdownlint --source=.
 *   dagger call vale --source=.
 *   dagger call gitleaks --source=.
 *   dagger call zizmor --source=.
 *   dagger call skill-scanner --source=.
 */
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

// Mirrors the pins in skills/engineering/drawing-c4-diagrams/evals/render/test.sh; bump both together.
const STRUCTURIZR = "structurizr/structurizr:2026.10.26-playwright"
const PLANTUML = "plantuml/plantuml:1.2026.10"
const MERMAID = "minlag/mermaid-cli:12.0.0"
const THEME_URL =
  "https://raw.githubusercontent.com/structurizr/structurizr/v2026.10.26/structurizr-themes/amazon-web-services-2025.07/theme.json"
const MARKDOWNLINT = "davidanson/markdownlint-cli2:v0.24.0"
const VALE = "jdkato/vale:v3.25.0"
const GITLEAKS = "zricethezav/gitleaks:v8.30.1"
const ZIZMOR = "1.32.0"
const SKILL_SCANNER = "2.3.2"
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
   * markdownlint-cli2 over every Markdown file (config: .markdownlint-cli2.jsonc)
   */
  @func()
  async markdownlint(source: Directory): Promise<string> {
    return dag
      .container()
      .from(MARKDOWNLINT)
      .withDirectory("/workdir", source, { exclude: ["**/node_modules", ".dagger/sdk"] })
      .withWorkdir("/workdir")
      .withExec(["**/*.md"], { useEntrypoint: true })
      .stdout()
  }

  /**
   * Vale prose lint with the House style (config: .vale.ini, rules in .vale/styles/House/)
   */
  @func()
  async vale(source: Directory): Promise<string> {
    return dag
      .container()
      .from(VALE)
      .withDirectory("/src", source, { exclude: ["**/node_modules", ".dagger/sdk", ".beads"] })
      .withWorkdir("/src")
      .withExec(["--glob=!{node_modules,.beads,.dagger}/**", "."], { useEntrypoint: true })
      .stdout()
  }

  /**
   * gitleaks over the working tree (history is covered by GitHub push protection)
   */
  @func()
  async gitleaks(source: Directory): Promise<string> {
    return dag
      .container()
      .from(GITLEAKS)
      .withDirectory("/src", source, { exclude: ["**/node_modules", ".dagger/sdk", ".git"] })
      .withExec(["dir", "/src", "--no-banner", "--redact"], { useEntrypoint: true })
      .stdout()
  }

  /**
   * zizmor security lint of .github/workflows (offline: no GitHub API calls)
   */
  @func()
  async zizmor(source: Directory): Promise<string> {
    return dag
      .container()
      .from("python:3.13-slim")
      .withExec(["pip", "install", "--no-cache-dir", `zizmor==${ZIZMOR}`])
      .withDirectory("/src/.github", source.directory(".github"))
      .withWorkdir("/src")
      .withExec(["zizmor", "--offline", "--min-severity", "low", "."])
      .stdout()
  }

  /**
   * Cisco skill-scanner (static + behavioral, no LLM) over every skill; fails on high or critical.
   * A signal, not proof: its own published recall for rules alone is low.
   */
  @func()
  async skillScanner(source: Directory): Promise<string> {
    return dag
      .container()
      .from("python:3.13-slim")
      .withExec(["pip", "install", "--no-cache-dir", "--root-user-action=ignore", `cisco-ai-skill-scanner==${SKILL_SCANNER}`])
      .withDirectory("/src/skills", source.directory("skills"))
      .withExec(["skill-scanner", "scan-all", "/src/skills", "--recursive", "--use-behavioral", "--fail-on-severity", "high"])
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
