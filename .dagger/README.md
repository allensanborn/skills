# Dagger CI

Quality gates run in a container via [Dagger](https://dagger.io) so they are portable and
consume **no metered CI minutes** during development. GitHub Actions are added only once a
skill is proven ship-ready (to avoid burning Actions budget early).

## Functions

TypeScript module (`.dagger/src/index.ts`, `dagger.json` at the repo root). Needs Docker and network.

```bash
dagger call lint --source=.          # ci/check.sh: skill-lint + reference link check
dagger call render-test --source=.   # drawing-c4-diagrams: AWS icons through every export path
```

`render-test` renders `evals/render/aws-deployment.dsl` with the pinned Structurizr, PlantUML and
mermaid-cli images as Dagger containers, then runs `evals/render/test.sh --check` on the output.
The assertions live only in `test.sh`; the image and theme pins are mirrored in both files, so bump
them together. Cold run ~2 min, cached runs are fast.

LLM evals don't go through Dagger: each skill's `evals/<case>/` folders run with Claude Code's own
runner, with-skill vs no-skill baseline and an LLM judge (real, billed runs; ~$0.22 for one grill-only
case, one run, both arms):

```bash
claude plugin eval skills/engineering/drawing-c4-diagrams --no-publish --allow-tools Bash Write Edit \
  --output-dir /tmp/c4-evals --report /tmp/c4-evals/report.html \
  [--case drawing-c4-diagrams-13] [--runs 1] [--max-cost-usd 5]
```

Keep results **outside** the skill folder (`--output-dir`, `--report`). By default they land in
`evals/results/` inside the skill, where `ci/check.sh`'s scanner reads them. The reports quote the eval
agent's system prompt, which trips its agent-state-tamper rule (TOXIC), and a packaged skill could ship them.

`--allow-tools` is needed for cases that render (Docker); `allowed_tools` in a case's `prompt.md`
doesn't grant them by itself. `evals.json` is the older format, kept as is; the case folders were
generated from it and take precedence.

Without Dagger: `bash ci/check.sh` and
`bash skills/engineering/drawing-c4-diagrams/evals/render/test.sh` (plain Docker).

## Later: GitHub Actions

When ship-ready, add a thin `.github/workflows/ci.yml` that just calls the same Dagger
functions, so local and CI runs are identical.
