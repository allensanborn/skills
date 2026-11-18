---
tags: [drawing-c4-diagrams]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Yes to the setup. Answers to your points: the product is called Gigstack. nginx only routes and terminates TLS. postgres and the S3 bucket are ours; Stripe and SendGrid are external. Customers only use the web app, and the web app calls the api. The ops team uses an admin page served by the api. The worker turns paid orders into PDF tickets in S3 and emails them through SendGrid. Go ahead and draw it.
