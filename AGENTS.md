Skills are organized into bucket folders under `skills/`:

- `engineering/`: daily code work
- `productivity/`: daily non-code workflow tools
- `misc/`: kept around but rarely used, not promoted
- `in-progress/`: beta: public on purpose, feedback wanted, not shipped in the plugin
- `deprecated/`: no longer used

Every skill in `engineering/` or `productivity/` (the **promoted** buckets) must have a reference in the top-level `README.md` and an entry in `.claude-plugin/plugin.json`'s `skills` array (the Claude Code plugin ships exactly the promoted set). Skills in `misc/`, `in-progress/`, and `deprecated/` must not appear in either. `ci/check.sh` fails if `plugin.json` drifts from disk.

Install commands are copied verbatim from [.agents/install-block.md](./.agents/install-block.md). `.claude-plugin/marketplace.json` is the repo's own marketplace. Run `bash ci/check.sh` after touching either manifest: it runs `claude plugin validate` as strict, tolerating only the warning that root `CLAUDE.md` is not plugin context (mattpocock/skills hits the same one).

Each skill entry in the top-level `README.md` must link the skill name to its `SKILL.md`.

Each bucket folder has a `README.md` that lists every skill in the bucket with a one-line description, with the skill name linked to its `SKILL.md`. The promoted buckets' `README.md`s and the top-level `README.md` group entries into **User-invoked** and **Model-invoked**; non-promoted bucket `README.md`s (`misc/`, `in-progress/`) use a flat list.

Skills in `engineering/` and `productivity/` also have a human-facing docs page at `docs/<bucket>/<skill-name>.md` (the docs tree mirrors those two bucket folders under `skills/`). When you add, rename, or change the behaviour of a skill in `engineering/` or `productivity/`, create or re-sync its docs page following [.agents/writing-docs.md](./.agents/writing-docs.md). A finished page carries four sections: **What it does**, **When to reach for it**, **Common questions**, and **It's working if**. Skills in the non-promoted buckets get **no** docs page.

Every `SKILL.md` is either user-invoked (`disable-model-invocation: true` plus `policy.allow_implicit_invocation: false` in `agents/openai.yaml`, reachable only by the human) or model-invoked (model- or user-reachable). See [.agents/invocation.md](./.agents/invocation.md).

Every user-facing change to a skill gets a changeset (`npx changeset`). The Release workflow turns them into `CHANGELOG.md` entries and a version bump, and `npm run version` copies the version into `plugin.json`.

Decisions that shape a skill or the repo are recorded as ADRs in [.agents/adr/](./.agents/adr/). Domain terms live in [GLOSSARY.md](./GLOSSARY.md).

Every skill keeps its evals in `evals/` (an `evals.json` plus one `<skill>-<n>/` case folder per eval). Add or update a case when you change behaviour the evals cover.

To (re)link every skill outside `deprecated/` and `misc/` into the local harness skill directories (`~/.claude/skills`, `~/.agents/skills`), run `scripts/link-skills.sh`. Each entry is a symlink into this repo, so a `git pull` keeps installed skills current; re-run the script after adding, removing, or renaming a skill.

No em-dashes anywhere in this repo's prose (`SKILL.md` files, references, evals, docs, `README.md`, `CHANGELOG.md`, ADRs, changesets, code comments). Where a sentence reaches for one, rewrite it instead with a comma, colon, period, parentheses, or a conjunction, whichever the sentence actually wants; never do a blind character substitution. Vale enforces this (`dagger call vale --source=.`).

Every skill that dispatches a subagent says to start it with a fresh context window. Some harnesses (Codex, for one) fork the parent conversation by default, and a fork inherits the parent's context, which is what the subagent was meant to escape.

`AGENTS.md` is a byte-identical copy of this file. Edit both, or `ci/check.sh` fails.

## Agent skills

### Issue tracker

Maintainer work lives in beads (`bd`); see [CONTRIBUTING.md](./CONTRIBUTING.md). GitHub Issues are the intake for outside reports.

### Triage labels

Canonical names, unchanged. See `docs/agents/triage-labels.md`. Issues are judged against [`SCOPE.md`](./SCOPE.md).
