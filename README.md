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

### Productivity

- **[too-much](skills/productivity/too-much/)** — turn a sprawling pile of findings,
  questions, and decisions into a tracked ledger (beads if the project has it, markdown
  otherwise) and work through it in terse batches of at most 3, so nothing gets lost.
  Low-stakes calls are logged as `fyi`; irreversible ones always need an explicit answer.
  Triggers on "triage", "too much", "one at a time", "status", "next", or any response that
  would ask more than 3 questions.

## Install

Pick **one** of these. Installing more than one gives you every skill twice.

**Claude Code plugin**: a read-only bundle that updates when a new `version` ships.

```text
/plugin marketplace add allensanborn/skills
/plugin install allensanborn-skills@allensanborn
```

**[skills.sh](https://skills.sh)**: copies skill files you can edit into your project. Works
with Codex and other Agent Skills harnesses too.

```bash
npx skills@latest add allensanborn/skills
```

**Working on this repo**: symlink every skill into `~/.claude/skills` and `~/.agents/skills`,
so your edits are live in the next session and `git pull` updates them:

```bash
./scripts/link-skills.sh
```

## Develop

Skills live in category folders. `engineering/` and `productivity/` are **shipped**: each
skill in them must be listed in [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json)
(`ci/check.sh` enforces this). Drafts go in [`skills/in-progress/`](skills/in-progress/),
which the plugin doesn't ship but the link script still links. To release, bump `version` in
`plugin.json`. Claude Code uses it to decide when installed users get an update.

Skills follow [Anthropic's authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):
lean `SKILL.md` (<500 lines), progressive disclosure via `references/` (one level deep),
third-person "pushy" descriptions, forward-slash paths, evals-first.

Quality checks run in a container via [Dagger](https://dagger.io) (portable, no metered CI
minutes) — see [`.dagger/`](.dagger/). GitHub Actions are added only once a skill is
proven ship-ready.

```bash
# local lint (plugin manifest + skill-lint + reference link check)
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

## License

Private during development. To be released under the **MIT License** when ship-ready.
