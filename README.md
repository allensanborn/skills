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

## License

Private during development. To be released under the **MIT License** when ship-ready.
