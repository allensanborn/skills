---
name: too-much
description: Turns a large set of findings, questions, and decisions into a tracked issue ledger that the user works through in small, terse turns, without losing anything. Use when a task has produced many open questions, findings, or decisions; when the user says "triage", "too much", "one at a time", "status", or "next"; or when a response would contain more than 3 questions.
---

# Too much

A review, audit, or plan often ends with a wall of output that the user can't answer in one
reply. They answer two items and the rest are lost. This skill fixes that. **Write everything
to a ledger first, then show it a few items at a time.**

## The ledger

It has to survive context compaction and new sessions, so it lives in a file, never only in
chat. See [references/ledger-backends.md](references/ledger-backends.md) for the formats:

- **beads**, if the project has `.beads/` and `bd` works;
- **markdown** otherwise, at `.too-much/<topic-slug>.md`.

Each item has:

- **ID**: permanent. Never reuse or renumber.
- **Type**:
  - `decision`: needs the user to choose.
  - `question`: needs information only the user has.
  - `finding`: a problem you found. Needs a fix or a won't-fix.
  - `fyi`: you decided it and logged the decision; the user can override it.
- **Status**: `open` · `parked` · `decided` · `deferred` · `done` · `dropped`.
- **Blocks**: the IDs of items this one blocks.
- **Irreversible**: yes when it involves data loss, a schema, a public contract, security, or cost.
- **Summary**: one line, readable with no other context.
- **Detail**: the evidence (file:line), the options, why it matters, and what happens if
  it's deferred. Store this in the ledger, because after compaction it's the only copy.
- **Default**: your recommendation, with a one-clause reason.
- **Resolution**: the user's answer, **verbatim**.

## Workflow

1. **Intake.** Before showing anything, extract every question, finding, and *implicit*
   decision from the recent work into the ledger, including the minor ones. Merge duplicates;
   drop nothing silently. If a ledger for this topic already exists, add to it instead of
   starting a new one.
2. **Rank.** Order by (a) blocks other work, (b) hard to reverse, (c) cheap to answer. Items
   the user can't meaningfully weigh in on become `fyi`, with your decision recorded.
3. **Present a batch** of at most 3 `open` items, in 2–4 lines each:
   ```
   Q4 · blocks D6 · irreversible
   Expired sessions on /api/*: redirect to /login or return 401?
   A) redirect  B) 401 ← default: the SPA already handles 401
   If deferred: API clients keep getting HTML login pages.
   ```
   End with one line:
   `N more parked · M fyi logged · ledger: <path> · reply "status" for the full list`.
4. **Apply replies.** Parse terse answers like `Q4 B`, `Q5 default`, `Q6 defer`,
   `rest default`. For each one:
   1. write the resolution to the ledger **before** replying;
   2. recheck the items it blocks, and close or update any the answer settles (`D6 now moot → done`);
   3. do the resulting work if there is any, and record the outcome;
   4. present the next batch.
5. **Anything new that comes up** goes into the ledger as `parked`. Don't ask about it inline,
   and don't interrupt the current batch unless the new item blocks it.

## Commands the user may send

- `next`: the next batch.
- `status`: counts by status, plus the open and parked items as one-liners.
- `ledger`: the full table.
- `defaults`: accept the defaults for the items currently shown.
- `defaults all`: accept the defaults for every open and parked item **except irreversible ones**.
- `focus Qn`: discuss one item in depth, using its stored detail, and hold the rest.
- `done`: summarize the decisions made this session, one line each, and list what's still
  open. The ledger stays, so later sessions can pick it up.

If the user sends `status` or `next` and no ledger is in context, look for an existing ledger
before saying there isn't one.

## Rules

- Never present more than 3 items that need input in one response.
- Never accept a default silently on an irreversible item. It needs an explicit answer, even
  under `defaults all`.
- Record what the user actually said, not a paraphrase.
- Don't repeat resolved items in later responses, except in `done`.
- Never show the whole list "for context" before the first batch. That wall of text is the
  problem this skill exists to fix.
