---
"allensanborn-skills": patch
---

drawing-c4-diagrams: each Docker image is pinned once, by tag and digest, in SKILL.md's "Pinned images"; every command uses `$IMG`, `$MCP_IMG` or `$PLANTUML_IMG`. Parse errors are explained as the modeling mistake behind them, and the references now say correctly which headless exports write filtered views (PNG/SVG write the filtered view and skip its base).
