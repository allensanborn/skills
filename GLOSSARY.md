# allensanborn skills

A collection of agent skills for Claude Code and other Agent Skills harnesses. Terms used across `SKILL.md` files, references, evals, and docs.

## Language

**Grill**:
A Socratic interrogation of the user that makes them engage with and defend a design rather than accept generated output. In `drawing-c4-diagrams`, the *scoping grill* runs before any DSL and is hard to skip; the *review grill* runs after generation and is skippable with "skip the grill".
_Avoid_: interview, questionnaire

**Capability tier**:
What tooling the current environment has, probed bottom-up: Tier 0 (no tools), Tier 1 (Docker, so Structurizr MCP or headless CLI), Tier 2 (Docker plus Structurizr Lite in a browser). A skill degrades by tier instead of failing.

**Render-and-look**:
Rendering a view to an image and actually inspecting it before showing it to the user. Validation proves the DSL parses; render-and-look catches visual defects (empty views, overlapping elements, missing icons). Never skipped, including under "skip the grill".

**Eval case**:
One folder `evals/<skill>-<n>/` holding `prompt.md`, `case.yaml`, and `graders/`, mirrored by an entry in `evals/evals.json`.

**Promoted**:
A skill in `engineering/` or `productivity/`: listed in the README and `plugin.json`, and given a docs page.

## Relationships

- A **Promoted** skill has one or more **Eval cases**
- The **Grill** runs before and after generation; **Render-and-look** runs at every **Capability tier** that can render
