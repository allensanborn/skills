# Contributing

Every issue is judged against the bar in [`SCOPE.md`](./SCOPE.md). Read it first.

## Where each request goes

| You have | Go to |
| --- | --- |
| A bug in a skill | [Bug issue](https://github.com/allensanborn/skills/issues/new?template=bug.yml) |
| A change to an existing skill | [Idea or feedback issue](https://github.com/allensanborn/skills/issues/new?template=idea.yml) |
| A question, or "how do I...?" | [Question issue](https://github.com/allensanborn/skills/issues/new?template=question.yml) |
| An idea for a new skill | Closed: see [`SCOPE.md`](./SCOPE.md) |

Pull requests are open to collaborators only, so describe the fix in an issue instead.

## Issues written with AI

Agents are welcome to help, but you post the issue, so you own it:

- **One problem per issue.** Several findings from one session are several issues, or none.
- **Short.** If it does not fit on one screen, cut it.
- **Repro first.** The steps that show the problem come before any analysis.
- **No pasted specs.** No full proposals, plans, or rewritten `SKILL.md` files. Describe the problem; the fix is ours to design.

## Maintainers: where work is tracked

GitHub Issues are the intake for outside reports. Maintainer work lives in beads (below). When a GitHub issue is accepted (`ready-for-agent` or `ready-for-human`, see [`docs/agents/triage-labels.md`](./docs/agents/triage-labels.md)), file a bead that links it, and close the issue when the bead closes.

## Reviewing

Every change reaches `main` through a pull request whose six CI checks pass. A review is the part CI can't do: does the change say what it means, and does it still hold together?

### What to check, by kind of change

| The PR changes | Check |
| --- | --- |
| A skill's behaviour (`SKILL.md`, `references/`) | An eval case covers it (added or updated), the docs page in `docs/<bucket>/` still matches, and there's a changeset. Every constraint in the old wording ("hard to skip", tier numbers, command names) survives the new one. |
| A skill's evals | Each case's `case.yaml` expected outcome and its `graders/` bodies say the same thing; graders check behaviour, not wording. |
| Samples (`docs/examples/`) | They are real, unedited runs: the README names the commit and flags, and any edit to model output is disclosed. |
| Workflows (`.github/`) | Actions are pinned to a commit SHA with the version in a comment; permissions are the least the job needs; any `zizmor: ignore` says why. |
| Prose anywhere | Plain words, no em-dashes (Vale enforces it), links resolve. |

### How to approve

Leave the review on GitHub ("Approve", or "Request changes" with what is wrong and why). The author merges once it's approved and green.

### Adding a second reviewer

A second person's approval is what moves OpenSSF Scorecard's Code-Review and Branch-Protection checks; an author can't approve their own PR, and a bot approval would only game them. When someone joins:

1. Give them the **Write** role on the repository.
2. Add them to `.github/CODEOWNERS`, by area if you split the work (for example `/.github/` for workflows, `/skills/` for skill content).
3. In the "Protect main" ruleset, set required approvals to **1** and turn on "Require review from Code Owners" and "Dismiss stale approvals".

Until then approvals stay optional, so a solo maintainer can merge.

## Develop

Skills follow [Anthropic's authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):
lean `SKILL.md` (<500 lines), progressive disclosure via `references/` (one level deep),
third-person "pushy" descriptions, forward-slash paths, evals-first.

Quality checks run in containers via [Dagger](https://dagger.io), so they behave the same locally and
in CI. `.github/workflows/ci.yml` runs every one of them on each pull request and on `main`; see
[`.dagger/src/index.ts`](.dagger/src/index.ts) for the functions and [SECURITY.md](./SECURITY.md) for what else guards the repo.

```bash
# via Dagger: lint, prose lint, and the drawing-c4-diagrams render test (Docker + network)
dagger call lint --source=.
dagger call markdownlint --source=.   # .markdownlint-cli2.jsonc
dagger call vale --source=.           # .vale.ini, House style (no em-dashes)
dagger call gitleaks --source=.       # secrets in the working tree
dagger call zizmor --source=.         # security lint of .github/workflows
dagger call render-test --source=.

# local: plugin manifest + validate, version sync, skill-lint, links
bash ci/check.sh
```

`render-test` renders `evals/render/aws-deployment.dsl` through every export path and runs
`evals/render/test.sh --check` on the output; the image and theme pins are mirrored in
`test.sh` and `.dagger/src/index.ts`, so bump them together. Without Dagger, run `test.sh`
directly (plain Docker).

LLM evals run with Claude Code's own runner, with-skill against a no-skill baseline and an LLM
judge. These are real, billed runs:

```bash
claude plugin eval skills/engineering/drawing-c4-diagrams --no-publish --allow-tools Bash Write Edit \
  --output-dir /tmp/c4-evals --report /tmp/c4-evals/report.html \
  [--case drawing-c4-diagrams-13] [--runs 1] [--max-cost-usd 5]
```

Keep results **outside** the skill folder: reports quote the eval agent's system prompt, which
skill-lint flags as TOXIC, and a packaged skill would ship them. `--allow-tools` is needed for
cases that render; `allowed_tools` in a case's `prompt.md` doesn't grant them by itself.

## Release app

Releases are cut by `.github/workflows/release.yml` (changesets). It opens the "chore: version skills" pull request with a GitHub App token, because a pull request opened with the default `GITHUB_TOKEN` triggers no workflows, so it would never get the CI checks that `main` requires. One-time setup, by the repo owner:

1. Create an app at <https://github.com/settings/apps/new>: any name, homepage `https://github.com/allensanborn/skills`, **Webhook: inactive**. Repository permissions: **Contents: read and write**, **Pull requests: read and write** (Metadata: read is added automatically). Installable "Only on this account".
2. On the app's page, note the **Client ID**, and **Generate a private key** (a `.pem` downloads).
3. **Install App** on `allensanborn/skills` only.
4. Store both on the repo, then delete the local `.pem`:

   ```bash
   gh variable set RELEASE_APP_CLIENT_ID --body "<client id>"
   gh secret set RELEASE_APP_PRIVATE_KEY < path/to/key.pem
   ```

The workflow asks for a token scoped to contents and pull requests only, which expires after an hour.

## Issue tracking (beads)

Issues live in a Dolt database that travels on **`refs/dolt/data`** on this repo's remote, not
in git objects: a plain `git clone` doesn't fetch them and a plain `git push` doesn't send
them. On a fresh clone or a new machine, run both:

```bash
bd bootstrap                              # fetches the issue database
git config core.hooksPath .beads/hooks    # makes the tracked hooks fire, so pushes sync issues
```

Do **not** run `bd hooks install`: it reports success but doesn't set `core.hooksPath`, and it
rewrites `.git/hooks` without the `bd dolt push` step. To check everything (hooks, database,
Dolt remote, permissions, unpushed commits), run `./ci/beads-audit.sh`; it exits non-zero on any
problem. The full procedure is in
[`BEADS-PROCEDURE.md`](https://github.com/allensanborn/beads-roundtrip-probe/blob/main/BEADS-PROCEDURE.md).
