# drawing-c4-diagrams architecture

C4 model of the skill's toolchain: what runs where, every render path, and how cloud icons reach
each output. Audience: skill maintainers. Source of truth: [workspace.dsl](workspace.dsl).

| View | Shows |
| --- | --- |
| [Context](exports/Context.png) | Engineer, the toolchain, Docker Hub, GitHub raw, the dead theme host, icon owners |
| [Containers](exports/Containers.png) | Claude, the skill, workspace.dsl, the Structurizr/PlantUML/Mermaid containers, exports |
| [IconFlow](exports/IconFlow.png) | Installed theme vs URL theme, and what each export format keeps (from `evals/render/test.sh`) |
| [Deployment](exports/Deployment.png) | The Mac, OrbStack, one Docker container per tool, the internet |

Re-render (PNGs carry a timestamp footer, so every render changes them):

```bash
cd docs/architecture
docker run --rm --ipc=host -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes \
  -v "$PWD:/work" -w /work structurizr/structurizr:2026.10.26-playwright \
  export -workspace workspace.dsl -format png -output exports
```

## Icon licensing (not legal advice; checked 2026-11-14)

The skill repo ships **no** icon files. Icons arrive at render time from the Structurizr image or
GitHub, and end up inside *users'* rendered diagrams. Structurizr licenses its `theme.json` files
Apache-2.0 but says the PNGs "are copyright of their respective copyright holders"; the repo has no
NOTICE covering them.

| Owner | Diagram use | Redistribute icon files | Modify | Source |
| --- | --- | --- | --- | --- |
| AWS | Allowed ("to create architecture diagrams"; whitepapers, presentations, posters) | Not stated | Not stated | aws.amazon.com/architecture/icons |
| Microsoft Azure | Allowed (diagrams, training, docs) | Only "for the permitted use" | No crop, flip, rotate or distort; don't use them for your own product | learn.microsoft.com/azure/architecture/icons |
| Google Cloud | Implied ("for your diagrams, technical documentation") | Not stated | Not stated | cloud.google.com/icons |
| Oracle OCI | Allowed ("for your OCI implementation") | Not stated | Not stated | docs.oracle.com, Graphics for Diagrams |
| Kubernetes | Allowed | Allowed (Apache-2.0 or CC-BY-4.0) | Allowed; the logo is a Linux Foundation trademark | kubernetes/community icons/README.md |

What follows for the skill:
- Rendering and publishing diagrams of the vendor's own services is the use every vendor intends.
- Don't add icon PNGs to this repo; reference installed themes or the URL theme instead.
- Structurizr's renderer only scales icons, which fits Azure's no-crop/no-distort rule. Mermaid
  stretches them to node width, which arguably doesn't.
- Not confirmed: AWS, Google and OCI terms beyond the landing pages (site terms, legal notices, and
  the licence files inside their download ZIPs were not read).
