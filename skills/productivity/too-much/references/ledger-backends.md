# Ledger backends

## Choosing

1. If `.beads/` exists and `bd list >/dev/null 2>&1` succeeds, use **beads**.
2. Otherwise, use **markdown**. Don't set up beads just for this skill.

Name the backend and its location in the batch footer the first time.

## beads

One parent epic per triage topic, and one child per item. Labels carry what beads has no
field for: `too-much` on everything, plus the item's type, plus `irreversible` and `parked`
where they apply. Priority carries the rank (0 = blocks other work … 3 = cheap/minor).

```bash
# topic parent
bd create "triage: auth review" -t epic -l too-much \
  -d "Source: code review of feat/auth, 2026-09-24"

# one child per item
bd create "Expired sessions on /api/*: redirect or 401?" \
  --parent <epic-id> -l too-much,decision,irreversible -p 0 \
  -d "<detail: evidence, options, what happens if deferred>" \
  --notes "Default: B (401); the SPA already handles 401."

# D6 can't be settled until Q4 is decided
bd dep add <D6-id> <Q4-id>

# fyi: decided by you, logged, closed at once
bd create "<summary>" --parent <epic-id> -l too-much,fyi -p 3 -d "<detail>"
bd close <id> --reason "fyi: <your decision and why>"
```

| Ledger action | Command |
| --- | --- |
| next batch | `bd ready --parent <epic-id> --exclude-label parked --json` → the top 3 by priority |
| status | `bd list --parent <epic-id> --all --json` → count by status and label |
| decided / done | `bd close <id> --reason "<the user's answer, verbatim>"` |
| deferred | `bd update <id> --status deferred` |
| dropped | `bd close <id> --reason "dropped: <reason>"` |
| park a new item | `bd create … --parent <epic-id> -l too-much,<type>,parked --deps discovered-from:<id>` |
| unpark | `bd update <id> --remove-label parked` |
| find an existing ledger | `bd list -l too-much -t epic --json` |

Closing an item unblocks its dependents in `bd ready`, so blocking order comes for free.
Follow the project's own rules about pushing beads (for example `bd dolt push`).

## markdown

File: `.too-much/<topic-slug>.md`. Ask the user once whether `.too-much/` should be gitignored
or committed.

```markdown
# Triage: auth review
Source: code review of feat/auth · started 2026-09-24

| ID | Type | Status | Blocks | Irrev | Summary | Default | Resolution |
|----|------|--------|--------|-------|---------|---------|------------|
| Q4 | decision | open | D6 | yes | Expired sessions on /api/*: redirect or 401? | B (401) | |
| F5 | finding | done | - | - | `session.ts:88` compares tokens with `==` | fix | "fix it" → fixed in a1b2c3 |
| Y7 | fyi | decided | - | - | Log format for auth failures | JSON | (my call; overridable) |

## Q4: Expired sessions on /api/*
Detail: `middleware/auth.ts:40` redirects every request, including `/api/*` fetches.
Options: A) redirect  B) 401
If deferred: API clients keep getting HTML login pages.
```

- Keep one `## ID: title` detail section per item, so `focus` works after compaction.
- Update the table row and the detail section **in the same edit** as the resolution.
- Find an existing ledger with `ls .too-much/`.
