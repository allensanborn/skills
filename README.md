# Skills

[![CI](https://github.com/allensanborn/skills/actions/workflows/ci.yml/badge.svg)](https://github.com/allensanborn/skills/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/allensanborn/skills/badge)](https://scorecard.dev/viewer/?uri=github.com/allensanborn/skills)

Agent skills for Claude Code and other [Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) harnesses, built on the conventions of [mattpocock/skills](https://github.com/mattpocock/skills): small, composable, and each one makes you think rather than doing the thinking for you.

## Installation

The plugin updates itself on each release. [skills.sh](https://skills.sh) copies editable files into your project, and you update them by hand. Pick one, because installing both gives you every skill twice.

<details>
<summary>Claude Code</summary>

```bash
claude plugin marketplace add allensanborn/skills
claude plugin install allensanborn-skills@allensanborn
```

Updates when a new version is released.

To stay on a release you've reviewed instead, add the marketplace at its tag. Releases are immutable, so the tag can't be moved to other code:

```bash
claude plugin marketplace add allensanborn/skills@v0.2.0
claude plugin install allensanborn-skills@allensanborn
```

To move to a newer release, run `claude plugin marketplace remove allensanborn` and add it again at the new tag. Removing the marketplace also uninstalls the plugin, so reinstall it after.

</details>

<details>
<summary>Every other agent, or editable files (skills.sh)</summary>

```bash
npx skills@latest add allensanborn/skills
```

Manual updates: run `npx skills@latest update`, and re-run `add` to pick up new skills.

</details>

## Available skills

### Engineering

#### Model-invoked

- **[drawing-c4-diagrams](./skills/engineering/drawing-c4-diagrams/SKILL.md)**: Create and refine C4 architecture diagrams as Structurizr DSL, validated and rendered locally, while grilling you so you defend the design instead of accepting generated boxes. [Docs](./docs/engineering/drawing-c4-diagrams.md) · [Sample output](./docs/examples/drawing-c4-diagrams/).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to report a problem, and for the maintainer guide (checks, Dagger, beads). Scope is in [SCOPE.md](./SCOPE.md).

## License

[MIT](./LICENSE)
