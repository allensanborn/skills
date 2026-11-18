# Security review: what a skill here can do, and what guards it

Reviewed 2026-11-18 by the maintainer. Re-review when a skill gains a new tool, network call, or script, and at least every two years. This page is the project's security review for the OpenSSF Best Practices `security_review` criterion; [SECURITY.md](../../SECURITY.md) is the short public version.

## What ships

The plugin ships Markdown instructions (`SKILL.md`, `references/`) and nothing executable that runs on install. A skill has no privileges of its own: everything it does, it does by asking the user's agent to call a tool, under that agent's permission settings.

`drawing-c4-diagrams` asks the agent to:

- run the pinned `structurizr/structurizr` Docker image against a DSL file in the user's repo (validate, inspect, export);
- optionally fetch a Structurizr icon theme over HTTPS, or use the themes installed in that image;
- optionally use Structurizr MCP: local Docker by default, the public `mcp.structurizr.com` only if the user opts in;
- write `workspace.dsl`, `exports/`, and `.c4-diagrams.json` in the user's repo;
- read an image the user pastes.

The scripts in `ci/`, `scripts/`, and `evals/render/` are maintainer tools and are not in the release archive.

## Trust boundaries and threats

| Boundary | Threat | Guard |
| --- | --- | --- |
| Repo to user's agent (the skill text) | A malicious change to `SKILL.md` steers the agent into running something unsafe or exfiltrating data | Changes reach `main` only through a pull request with required checks; CODEOWNERS; Cisco skill-scanner and skill-lint in CI; the agent's own permission prompts still apply |
| Pasted image or user file to the skill | Prompt injection hidden in a whiteboard photo or an existing DSL file | The skill only produces DSL and diagrams from them; it gives no instruction to run commands taken from input. Residual: the agent's own injection defences |
| Skill to Docker Hub and the theme host | A swapped image or theme | Every `docker` command in the skill names a pinned tag (`structurizr/structurizr`, `structurizr/mcp`, `plantuml/plantuml`), the same versions the render test runs; `ci/check.sh` fails on an unpinned image. Theme URLs name a release tag. Tags can be re-pushed upstream; digests would close that |
| Skill to `mcp.structurizr.com` | The user's architecture leaves the machine | Opt-in only; local Docker is the default |
| GitHub to user (distribution) | A tampered release or a moved tag | Immutable releases, GitHub release attestations, SLSA provenance on the archive, and a tag-pinned install route (README) |
| CI and release (supply chain) | A compromised action or token | Actions pinned by SHA (except the SLSA generator, which must be tag-referenced), least-privilege tokens checked by zizmor, an App token scoped to this repo, secret scanning with push protection, gitleaks, Dependabot with a 7-day cooldown |

## Limits we accept

- **Scanners are signals, not proof.** skill-scanner's own published recall for rules alone is low, and Trail of Bits showed payloads getting past skill scanners ("The sorry state of skill distribution", 2026-06-03). The real guard on skill text is review plus pinning.
- **One maintainer.** No second reviewer exists yet, so a compromised maintainer account is not caught by review. 2FA on that account is the guard; [CONTRIBUTING.md](../../CONTRIBUTING.md) says how a second reviewer is added.
- **Images are pinned by tag, not digest.** An upstream maintainer could re-push a tag. Digests are harder to read and to bump, so tags are the trade-off for now.
- **Marketplace installs use git, not the archive.** Claude Code checks no signatures; tag pinning plus immutable releases is the integrity guarantee for that route.
