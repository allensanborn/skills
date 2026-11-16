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

Still planned: an `evals` function running `evals/evals.json` (with-skill vs baseline), following
Anthropic's skill-creator eval pattern.

Without Dagger: `bash ci/check.sh` and
`bash skills/engineering/drawing-c4-diagrams/evals/render/test.sh` (plain Docker).

## Later: GitHub Actions

When ship-ready, add a thin `.github/workflows/ci.yml` that just calls the same Dagger
functions, so local and CI runs are identical.
