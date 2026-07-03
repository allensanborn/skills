# Dagger CI

Quality gates run in a container via [Dagger](https://dagger.io) so they are portable and
consume **no metered CI minutes** during development. GitHub Actions are added only once a
skill is proven ship-ready (to avoid burning Actions budget early).

## Plan (beads `llm-wiki-j1x.12`)

A Dagger module (TypeScript or Go) exposing:

- `lint` — run `ci/check.sh` in a Node container (skill-lint + reference link check).
- `evals` — run the `evals/evals.json` scenarios for a given skill (with-skill vs baseline),
  following Anthropic's skill-creator eval pattern; fixtures from Simon Brown's published
  example diagrams.

Until the module lands, run the checks directly:

```bash
bash ci/check.sh
```

## Later: GitHub Actions

When ship-ready, add a thin `.github/workflows/ci.yml` that just calls the same Dagger
functions, so local and CI runs are identical.
