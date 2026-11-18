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

## Develop

Skills follow [Anthropic's authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):
lean `SKILL.md` (<500 lines), progressive disclosure via `references/` (one level deep),
third-person "pushy" descriptions, forward-slash paths, evals-first.

Quality checks run in containers via [Dagger](https://dagger.io), so they behave the same locally and
in CI. `.github/workflows/ci.yml` runs every one of them on each pull request and on `main`; see
[`.dagger/`](.dagger/) for the functions and [SECURITY.md](./SECURITY.md) for what else guards the repo.

```bash
# via Dagger: lint, prose lint, and the drawing-c4-diagrams render test (Docker + network)
dagger call lint --source=.
dagger call markdownlint --source=.   # .markdownlint-cli2.jsonc
dagger call vale --source=.           # .vale.ini, House style (no em-dashes)
dagger call gitleaks --source=.       # secrets in the working tree
dagger call zizmor --source=.         # security lint of .github/workflows
dagger call render-test --source=.

# local: AGENTS/CLAUDE parity, plugin manifest + validate, version sync, skill-lint, links
bash ci/check.sh
```

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

Issues live in a local Dolt database and travel on **`refs/dolt/data`** on this repo's git
remote, **not** in git objects. A plain `git clone` does not fetch them, and a plain
`git push` does not send them.

**On a fresh clone, or a new machine, run both:**

```bash
bd bootstrap                              # fetches the issue database
git config core.hooksPath .beads/hooks    # makes the tracked hooks actually fire
```

Neither implies the other. `bd bootstrap` gets the data; the `git config` is what makes
`git push` carry your subsequent issue changes. The hooks themselves live in
`.beads/hooks/` and **are tracked**, so you never need `pre-commit install` here, but
`core.hooksPath` is git config, which cannot be committed, so that one line is manual per
clone.

Do **not** run `bd hooks install`. It reports success, does not set `core.hooksPath`, and
rewrites `.git/hooks` with a version that has no `bd dolt push` in it.

**Verify rather than assume.** This repo was found on 2026-08-22 with hooks completely
dead and no local database, while 7 real issues sat unreachable on the remote:

```bash
if [ -n "$(git config --get core.hooksPath)" ] || [ -f .git/hooks/pre-push ]
then echo "hooks OK"; else echo "HOOKS DEAD: run git config core.hooksPath .beads/hooks"; fi
bd list >/dev/null 2>&1 && echo "db OK" || echo "NO DATABASE: run bd bootstrap"
```

Or just run the packaged version, which also checks the Dolt remote, `beads.role`, `.beads`
permissions and unpushed commits, and exits non-zero if anything is wrong:

```bash
./ci/beads-audit.sh
```

A green `git push` proves nothing on its own. To confirm sync end to end, make a real issue
change and watch the ref move. Note that a push with no issue changes correctly leaves it
untouched:

```bash
git ls-remote origin refs/dolt/data   # before
git push                              # prints "pre-push: syncing issues..."
git ls-remote origin refs/dolt/data   # must differ
```

Full background, including the pre-commit/linter variant used in other repos:
[`BEADS-PROCEDURE.md`](https://github.com/allensanborn/beads-roundtrip-probe/blob/main/BEADS-PROCEDURE.md).
