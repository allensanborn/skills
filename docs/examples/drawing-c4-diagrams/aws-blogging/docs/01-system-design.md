## System design

### Product scope

Writers draft, edit and publish stories with images and tags. Readers read stories, follow writers and
topics, clap, post responses, and get a personalised home feed plus email digests. Both sign in with a
social account (Google, Apple, GitHub) through Cognito.

### Workload assumptions (sizing for v1)

| Metric | Assumption |
| --- | --- |
| Monthly active readers | 5M |
| Peak reads | ~3,000 page views/s, >90% anonymous or cacheable |
| Writes | ~50 stories published/min peak; claps and responses ~500/s peak |
| Read:write ratio | ~100:1 |
| Story size | ~10 KB text, 1–10 images |

The design follows from the ratio: **optimise the read path at the edge, keep writes simple and durable,
push everything slow onto a queue.**

### Read path

1. Route 53 resolves the domain to CloudFront; WAF screens the request.
2. CloudFront serves cached story pages (anonymous readers) and images from S3. A published story page is
   cached at the edge for 60 s with stale-while-revalidate; publishing or editing a story issues an
   invalidation for that path.
3. On a miss, the ALB routes to the Next.js web service, which server-renders the page by calling the API.
4. The API serves home feeds and clap counters from Redis and falls back to Aurora reader replicas.

### Write path

1. The writer's editor saves drafts to the API (autosave every few seconds; each save is a revision row).
2. Images upload straight from the browser to S3 with a pre-signed URL from the API, so large files never
   pass through Fargate.
3. Publishing commits the story in Aurora, then publishes `StoryPublished` to SQS (transactional outbox
   table relayed by the API, so an event is never lost if SQS is briefly unavailable).
4. The worker fans the story into followers' feeds in Redis (push for writers with < 10k followers; pull
   at read time for larger accounts), indexes it in OpenSearch, renders image sizes, and queues
   notification emails through the email provider.

### Data model (Aurora PostgreSQL)

`users`, `stories`, `story_revisions`, `tags`, `story_tags`, `follows (follower_id, followee_id)`,
`claps (story_id, user_id, count)`, `responses` (a response is itself a story with `parent_id`),
`outbox`. Clap totals are counted in Redis and flushed to Aurora in batches.

### Reliability and operations

- **Availability:** every tier is Multi-AZ (Fargate tasks spread across 2 AZs, Aurora writer + reader,
  ElastiCache replica, 3-node OpenSearch). Target 99.9% for reads, 99.5% for publishing.
- **Recovery:** Aurora point-in-time restore (RPO ≤ 5 min), S3 versioning; Redis and OpenSearch are
  rebuildable from Aurora. Single region for v1; cross-region is a later decision (see ADR 0003).
- **Security:** only CloudFront can reach the ALB (managed prefix list + secret header); data subnets have
  no internet route; secrets in Secrets Manager; least-privilege task roles per service.
- **Observability:** CloudWatch logs and metrics, X-Ray traces, alarms on SQS age and DLQ depth.
- **Delivery:** Terraform for infrastructure; container images built in CI, pushed to ECR, rolled out by
  ECS rolling deploys with circuit breaker.
