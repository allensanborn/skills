# skills

A personal, shareable collection of [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
for Claude Code and compatible agents. Structured like
[`mattpocock/skills`](https://github.com/mattpocock/skills): one skill per directory under
`skills/<category>/<skill-name>/`, each with a `SKILL.md` plus optional `references/`,
`evals/`, and scripts.

## Skills

### Engineering

- **[drawing-c4-diagrams](skills/engineering/drawing-c4-diagrams/)** — create and refine
  C4-model software architecture diagrams as Structurizr DSL, validated and rendered
  locally (Structurizr MCP + Lite), and *grill* the user Socratically so they engage with
  and defend the design instead of passively accepting generated output. Bootstraps from a
  pasted whiteboard/hand-drawn/existing-diagram image.

## Install

```bash
npx skills@latest add allensanborn/skills
```

Or copy a skill directory into your project's `.claude/skills/`.

## Develop

Skills follow [Anthropic's authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):
lean `SKILL.md` (<500 lines), progressive disclosure via `references/` (one level deep),
third-person "pushy" descriptions, forward-slash paths, evals-first.

Quality checks run in a container via [Dagger](https://dagger.io) (portable, no metered CI
minutes) — see [`.dagger/`](.dagger/). GitHub Actions are added only once a skill is
proven ship-ready.

```bash
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
git config --get core.hooksPath     # must print .beads/hooks
bd list                             # must show issues, not "no beads database found"
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

## License

Private during development. To be released under the **MIT License** when ship-ready.
