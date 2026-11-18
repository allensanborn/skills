# drawing-c4-diagrams architecture

C4 model of the skill's toolchain: what runs where, every render path, and how cloud icons reach
each output. Audience: skill maintainers. Source of truth: [workspace.dsl](workspace.dsl).

| View | Shows |
| --- | --- |
| [Context](exports/Context.svg) | Engineer, the toolchain, Docker Hub, GitHub raw, the dead theme host, icon owners |
| [Containers](exports/Containers.svg) | Claude, the skill, workspace.dsl, the Structurizr/PlantUML/Mermaid containers, exports |
| [IconFlow](exports/IconFlow.svg) | Installed theme vs URL theme, and what each export format keeps (from `evals/render/test.sh`) |
| [Deployment](exports/Deployment.svg) | The Mac, OrbStack, one Docker container per tool, the internet |

Re-render (SVGs carry a timestamp footer, so every render changes them; delete the `*-key.svg` legends afterwards):

```bash
cd docs/architecture
docker run --rm --ipc=host -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes \
  -v "$PWD:/work" -w /work structurizr/structurizr:2026.10.26-playwright \
  export -workspace workspace.dsl -format svg -output exports
```

## Icon licensing (not legal advice; checked 2026-11-14 to 2026-11-16)

**Bottom line:** every vendor *invites* diagram use on its icon page, but only Kubernetes gives an
actual licence. AWS and Oracle site terms bar redistributing or modifying their content, and AWS
explicitly grants nothing for third-party publications. Structurizr redistributes the PNGs anyway
(its `theme.json` files are Apache-2.0; the PNGs "are copyright of their respective copyright
holders"; no NOTICE). The skill repo ships **no** icon files.

| Owner | Diagram use | Publishing | Redistribute icon files | Modify | Attribution | Key restriction |
| --- | --- | --- | --- | --- | --- | --- |
| AWS | Invited: "to create architecture diagrams" (icons page) | Trademark Guidelines §15: "AWS does not provide licenses or other authorization for use of AWS content in third party publications"; doesn't object to "limited fair use … for educational or non-profit purposes" | Site Terms: no download/copy/reproduce for commercial purposes without written consent | §9: "You will not alter the logo images in any manner, including … changing the proportion"; icon toolkit: "For diagrams, use icons at their predefined size and do not resize" | Not required | §5: nothing implying "sponsorship or endorsement by AWS"; §13: fair use of marks is "plain text only (no logos)" |
| Microsoft Azure | Licensed: "architectural diagrams, training materials, or documentation" | Allowed for those uses | "only for the permitted use" | No crop, flip, rotate or distort | Product name near icon recommended | Not for your own product |
| Google Cloud | Invited: "for your diagrams, technical documentation" | Brand guidance: "Include a legal attribution line when using any of Google's trademarks – such as our names, icons" | Not addressed | Google ToS: don't "alter any of our branding, logos" | **Required** | Cloud Terms §9: Brand Features only "in accordance with the Branding Guidelines"; the co-branding guide puts "The use of our Google Cloud logo, icon, and branded bylines" under "Ask first"; the Brand Resource Center says product icons need a permission request. All of this conflicts with the Cloud icons page |
| Oracle OCI † | Invited: "draw custom architecture diagrams for your OCI implementation" | Terms of Use §3: "personal, informational, noncommercial purposes" | §3(c): "may not be redistributed" | §3(b): not "modified or altered"; icon deck: "never alter, rotate or embellish" | Icon deck: "Always include identification labels" | No implied sponsorship or affiliation |
| Kubernetes | Licensed | Licensed | Apache-2.0 or CC-BY-4.0 | Allowed | CC-BY option requires it | The logo is a Linux Foundation trademark |

† Reported by a research agent from oracle.com/legal/terms.html and the OCI icon PPTX. Oracle's
terms page refused my fetch (403), so I haven't confirmed the quotes myself or that the page
governs docs.oracle.com assets.

Implications:

- **Skill repo:** fine as is. Never commit vendor icon PNGs here or into a user's repo; reference a
  theme.
- **Users' diagrams:** internal or customer-facing diagrams of the vendor's own services are what
  the icon pages invite. For anything published commercially, check the vendor's terms; for Google
  Cloud, add an attribution line (e.g. "Google Cloud and related marks are trademarks of Google LLC").
- **Don't distort icons.** Mermaid stretches icons to node width, which conflicts with AWS §9, Azure
  and Oracle. One more reason to prefer PNG/SVG export.
- **Size:** AWS's toolkit says not to resize icons in diagrams. Structurizr and PlantUML scale them
  proportionally to fit nodes, and Structurizr has no setting to stop it. That breaks AWS's style
  guidance (not a licence term), and nothing in this toolchain can avoid it.
- **Google Cloud:** its terms and co-branding guide say to "ask first" for icon use. For anything
  public beyond the icons page's "diagrams, technical documentation", treat permission as needed.
- **URL-theme workaround:** it fetches Structurizr's redistributed copies from GitHub, a use AWS
  and Oracle terms don't license. Keep it for when PlantUML output is unavoidable.
- Read 2026-11-16: the AWS PowerPoint toolkit (156 slides, style rules but no legal or licence slide),
  Google's product-icons guidance (now on partnermarketinghub.withgoogle.com) and Cloud Terms. Product
  Terms say nothing about brand. Still unread: Oracle's logo usage guidelines.

Sources: aws.amazon.com/architecture/icons (and its PowerPoint toolkit, slides 5 and 15), aws.amazon.com/trademark-guidelines,
aws.amazon.com/terms, learn.microsoft.com/azure/architecture/icons, cloud.google.com/icons,
about.google/brand-resource-center/guidance/media, policies.google.com/terms, cloud.google.com/terms,
services.google.com/fh/files/misc/external_customer_co_branding_eligibility.pdf,
docs.oracle.com/iaas/Content/General/Reference/graphicsfordiagrams.htm, oracle.com/legal/terms.html,
oracle.com/legal/trademarks.html, github.com/kubernetes/community/tree/master/icons.
