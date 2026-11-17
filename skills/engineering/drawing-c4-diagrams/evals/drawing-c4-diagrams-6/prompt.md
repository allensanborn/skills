---
tags: [drawing-c4-diagrams, render]
max_turns: 80
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

I have Docker but haven't set up any Structurizr MCP server. Generate the C4 diagrams for my app and give me PNGs I can drop in the repo.

Scope answers up front: it's a Django web app with a Postgres database and a Celery worker on Redis; staff users log in to it; it charges cards through Stripe. Audience: our dev team. One system, one workspace. Draw System Context and Container.
