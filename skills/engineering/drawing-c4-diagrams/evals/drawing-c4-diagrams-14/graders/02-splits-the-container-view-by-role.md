---
type: llm
focus: { source: file, path: workspace.dsl }
weight: 1
---

Fixes the structure instead of hand-tuning or widening spacing: the views meant for the README split the container view by role into focused views (for example a request path with the datastores excluded, plus a data view for the services and the stores they own), each saying where the rest of the system is, with no element left disconnected in its view (keeping the original all-in-one view for browsing in the live server is fine)
