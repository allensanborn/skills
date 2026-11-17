# Writing docs pages

Adapted from [mattpocock/skills `.agents/writing-docs.md`](https://github.com/mattpocock/skills/blob/main/.agents/writing-docs.md). Where this file is silent, follow that one.

Every skill in `engineering/` and `productivity/` has a human-facing **docs page** at `docs/<bucket>/<skill-name>.md`. The docs tree mirrors those two bucket folders under `skills/`. The page is not the skill and not a copy of `SKILL.md`. Only these two buckets are promoted; the rest (`misc/`, `in-progress/`, `deprecated/`) ship no docs page.

The job of a docs page is to relieve **cognitive load**: to orient one reader around one skill so they can hold it in their head, know when to reach for it, and see where it sits in the system.

Act whenever a promoted skill is added, renamed, or has its behaviour changed: create or re-sync its docs page. A rename moves the file too (`docs/<bucket>/<old>.md` → `docs/<bucket>/<new>.md`); a skill that moves between `engineering/` and `productivity/` moves its docs file to the matching folder. A skill moving *out* of a promoted bucket loses its page; one moving in gains a page. A promoted skill that is removed outright keeps its page as an **archived** page: leave the body as it was and open it with a blockquote notice (`> **Archived.** ...`) naming the version it was removed in and any replacement.

Pages are read on GitHub and may be copied elsewhere, so **every link is absolute**: a link into the repo points at its full `https://github.com/allensanborn/skills/blob/main/...` URL.

There is no H1. The page takes its title from the filename.

## Page structure

Fill the template below, keeping its order. The **fixed frame** (`## What it does`, `## When to reach for it`, `## Where it fits`) appears on every page. `## Prerequisites` and the free-form substance sections carry only what this particular skill needs; delete the rest.

Four sections make a page worth reading: `What it does`, `When to reach for it`, `Common questions`, `It's working if`. Treat a page that has neither of the last two as unfinished, not as finished-and-short.

**A page carries no install commands.** Install wording lives in [the install block](./install-block.md) and the top-level `README.md`.

<page-template>

## What it does

One or two plain-language paragraphs. Lead with the skill's one-sentence job, then state the **defining constraint**: the single fact that makes this skill behave differently from the obvious default. Write it as a plain declarative sentence, never a labelled aside like "The defining constraint:". This line is the most valuable on the page; never omit it.

## When to reach for it

- **Invocation mode.** A user-invoked skill: "You invoke this by typing `/<name>`, and the agent won't reach for it on its own." A model-invoked skill: "Type `/<name>`, or the agent reaches for it automatically when a task fits."
- **Trigger boundary.** "Reach for this when …". Where the skill is confusable with a sibling, add the other half: "for <X> instead, use <sibling>."

## Prerequisites

Optional: include only when the skill needs something in place: a workspace it writes into, prior setup, or tooling (Docker, a CLI). Omit the heading otherwise.

## <free-form middle>

One to three short sections, in the skill's *own vocabulary*, that make it click. The single non-negotiable: **surface the skill's leading word / defining idea**.

## Common questions

The questions readers really ask, each in bold with the answer beneath it. No sub-headings. Hunt for observed questions before writing any:

- **beads.** `bd list --all` and `bd search <skill-name>`: a bug or decision filed against the skill is a question the page owes an answer to.
- **This repo's issues.** `gh issue list --repo allensanborn/skills --search "<skill-name>" --state all`.
- **Eval findings.** Commits titled "fix gaps found by the eval N run" record where the skill surprised someone.
- **`CHANGELOG.md`.** Anything renamed, moved, or behaviourally changed generates a "where did it go?".

The count stays honest to the evidence. Order by how often each comes up, sharpest first, and say the unflattering thing where it is true. Omit the heading where there is nothing worth answering.

## It's working if

A few bullets naming what the reader sees when the skill is doing its job, each checkable without opening `SKILL.md`. Omit the heading where the tells stay vague.

## Where it fits

Always present. Name the skill's **role** (chain step, run-once setup, periodic maintenance, or reach-for-it-anytime standalone) and its one or two **neighbours**, each with a because-clause.

</page-template>

## Conventions

- Explain the **why**, not the process. Never reproduce the `SKILL.md` steps.
- **Never name the author.** State the substance as a plain claim about the skill. Quoting an anonymous *user* is fine.
- Use the skill's **leading words** so the page and the skill speak one language, and [GLOSSARY.md](../GLOSSARY.md)'s terms where one exists.
- **Branches go in a table or a list, never in a paragraph.**
- Keep the page itself low-load: no spare headings, no restated links.

## Done when

- The page exists at `docs/<bucket>/<name>.md`, and no stale page survives a rename or bucket move.
- It writes no install command and names no author.
- `## What it does` states the defining constraint as plain prose.
- `## When to reach for it` states invocation mode and the trigger boundary.
- `## Where it fits` names the role.
- A prerequisite is stated where one exists, and the section is absent where none does.
- The middle surfaces the leading word.
- Every multi-way branch is a table or a list.
- The hunt for real questions ran, and `## Common questions` is sized to what it found.
- Every `## It's working if` bullet is checkable without opening `SKILL.md`.
- The sections appear in the template's order, and every link is absolute and resolves.
