# The canonical install block

One install story, one wording. `README.md`, `.changeset/*`, and every page under `docs/` must say **this** and nothing else. Change it here first, then propagate.

Managed installs come first. skills.sh is the fallback, labelled "manual updates". Only routes someone has actually run against this repo are listed: Codex, Copilot, and Gemini stay off until someone does.

The plugin reinstalls only when the `version` in `.claude-plugin/plugin.json` changes. The Release workflow runs `npm run version`, which copies that field from `package.json`, so users get a release when the "chore: version skills" PR merges.

## Claude Code

<canonical-block name="claude-code">

```bash
claude plugin marketplace add allensanborn/skills
claude plugin install allensanborn-skills@allensanborn
```

Updates when a new version is released.

</canonical-block>

## Every other agent, or editable files (skills.sh)

<canonical-block name="other-agents">

```bash
npx skills@latest add allensanborn/skills
```

Manual updates: run `npx skills@latest update`, and re-run `add` to pick up new skills.

</canonical-block>

Use the single-skill form wherever one skill is named on its own.

<canonical-block name="skills-sh-one-skill">

```bash
npx skills@latest add allensanborn/skills --skill=<name>
```

</canonical-block>

## The two routes are exclusive

The plugin is a managed, read-only bundle you subscribe to. skills.sh writes files you own and edit. Installing both, or installing either alongside `scripts/link-skills.sh`, leaves you with every skill twice: always say "pick one".
