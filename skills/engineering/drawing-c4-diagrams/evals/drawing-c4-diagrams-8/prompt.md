---
tags: [drawing-c4-diagrams, render]
max_turns: 80
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Two of our services share one Postgres instance (separate schemas), and the OTel collector runs as a gateway. Show where things actually run.

Scope answers up front: the audience is our SREs reviewing production; the system is our orders platform (Orders and Billing services, plus the OTel collector), one system in one workspace; no people needed; no external systems; draw the container view and a production deployment view.
