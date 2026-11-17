# Contributing

Maintainer guide: how this repo is built, checked, and tracked. Outside reports go through the routes in the next section once the repo is public.

## Develop

Skills follow [Anthropic's authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):
lean `SKILL.md` (<500 lines), progressive disclosure via `references/` (one level deep),
third-person "pushy" descriptions, forward-slash paths, evals-first.

Quality checks run in a container via [Dagger](https://dagger.io) (portable, no metered CI
minutes) — see [`.dagger/`](.dagger/). GitHub Actions are added only once a skill is
proven ship-ready.

```bash
# via Dagger: lint, and the drawing-c4-diagrams render test (Docker + network)
dagger call lint --source=.
dagger call render-test --source=.

# local lint (skill-lint + reference link check)
bash ci/check.sh
```

## Issue tracking (beads)

Issues live in a local Dolt database and travel on **`refs/dolt/data`** on this repo's git
remote — **not** in git objects. A plain `git clone` does not fetch them, and a plain
`git push` does not send them.

**On a fresh clone, or a new machine, run both:**

```bash
bd bootstrap                              # fetches the issue database
git config core.hooksPath .beads/hooks    # makes the tracked hooks actually fire
```

Neither implies the other. `bd bootstrap` gets the data; the `git config` is what makes
`git push` carry your subsequent issue changes. The hooks themselves live in
`.beads/hooks/` and **are tracked**, so you never need `pre-commit install` here — but
`core.hooksPath` is git config, which cannot be committed, so that one line is manual per
clone.

Do **not** run `bd hooks install`. It reports success, does not set `core.hooksPath`, and
rewrites `.git/hooks` with a version that has no `bd dolt push` in it.

**Verify rather than assume** — this repo was found on 2026-08-22 with hooks completely
dead and no local database, while 7 real issues sat unreachable on the remote:

```bash
if [ -n "$(git config --get core.hooksPath)" ] || [ -f .git/hooks/pre-push ]
then echo "hooks OK"; else echo "HOOKS DEAD — run git config core.hooksPath .beads/hooks"; fi
bd list >/dev/null 2>&1 && echo "db OK" || echo "NO DATABASE — run bd bootstrap"
```

Or just run the packaged version, which also checks the Dolt remote, `beads.role`, `.beads`
permissions and unpushed commits, and exits non-zero if anything is wrong:

```bash
./ci/beads-audit.sh
```

A green `git push` proves nothing on its own. To confirm sync end to end, make a real issue
change and watch the ref move — note that a push with no issue changes correctly leaves it
untouched:

```bash
git ls-remote origin refs/dolt/data   # before
git push                              # prints "pre-push: syncing issues..."
git ls-remote origin refs/dolt/data   # must differ
```

Full background, including the pre-commit/linter variant used in other repos:
[`BEADS-PROCEDURE.md`](https://github.com/allensanborn/beads-roundtrip-probe/blob/main/BEADS-PROCEDURE.md).

