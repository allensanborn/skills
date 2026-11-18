## System design

A Medium-style blogging platform: writers draft and publish stories; readers discover, read, clap,
comment on and follow. This document goes with the C4 views in `../exports/` and is written for
the engineering team and the AWS design review.

### Requirements

**Functional**

- Writers: rich-text editor with autosave drafts, image upload, publish/unpublish, tags, revision history, basic stats (views, reads, claps).
- Readers: story pages, a home feed (followed writers + tags), tag and writer pages, full-text search, claps, threaded comments, follows.
- Sign-in with Google, Apple or GitHub. No passwords stored by us.
- Email: new-follower and comment notifications, and a daily or weekly digest.

**Non-functional (planning numbers to check in the review)**

| Item | Target |
| --- | --- |
| Monthly active readers | 5M; 50K active writers |
| Peak read traffic | ~5K req/s at the edge, >90% served from CloudFront |
| Writes | ~50 publishes/min peak; ~500 claps+comments/s peak |
| Story page latency | p95 < 300 ms uncached origin, < 50 ms edge hit |
| Availability | 99.9% for reading, 99.5% for writing |
| Durability | RPO ≤ 5 min, RTO ≤ 1 h (single region, see DR) |

The workload is read-heavy (around 100:1), and reads are dominated by a small hot set of stories.
That ratio drives most of the decisions below.

### Containers (see 02-Containers, 02b, 02c)

| Container | Technology | Why it exists |
| --- | --- | --- |
| Web Application | Next.js on Fargate | Server-rendered story HTML for SEO and first paint; also serves the editor. Pages are cacheable at CloudFront (`s-maxage` + stale-while-revalidate). |
| API Application | NestJS on Fargate | The only writer to the database. Stateless; JWT auth. |
| Background Worker | Node.js on Fargate | Everything that must not slow a request down: feed fan-out, search indexing, image resizing, emails. |
| Identity Service | Cognito user pool | Federates social IdPs and issues JWTs, so we never handle third-party tokens or passwords. |
| Database | Aurora PostgreSQL | Relational data with strong consistency; readers take feed/profile reads. |
| Cache | ElastiCache Redis | Feed timelines (sorted sets), clap counters, hot page fragments, rate limits. |
| Search Index | OpenSearch | Full-text and tag search; rebuilt from the database if lost. |
| Event Queue | SQS (+ DLQ) | Decouples the API from slow or failure-prone work; at-least-once delivery. |
| Media Store | S3 behind CloudFront | Images uploaded straight from the browser with pre-signed URLs; the API never proxies bytes. |

### Key flows

**Read a story.** Browser → Route 53 → CloudFront (WAF) → cache hit, done. On a miss → ALB → web
→ API → Redis (page fragment) → Aurora reader on a miss. Images go browser → CloudFront → S3.
Publishing or editing a story purges its CloudFront path.

**Publish.** Writer's editor → API: write the story row and an outbox row in one transaction, then
publish `StoryPublished` to SQS (a relay retries from the outbox if SQS is unavailable). The worker
then (1) pushes the story ID into each follower's Redis feed (fan-out-on-write, capped at 1,000 entries
per feed), (2) indexes it in OpenSearch, (3) queues notification emails.

**Home feed.** API reads the reader's Redis sorted set, hydrates story cards from cache or Aurora.
Writers with very large followings (over ~50K followers) are not fanned out; their recent stories
are merged in at read time (hybrid fan-out, ADR 0003).

**Clap.** API does `INCRBY` in Redis and appends to a clap ledger; a worker flushes counts to Aurora
every few seconds. Counts are eventually consistent, which is fine for this feature.

**Sign in.** Web redirects to the Cognito hosted UI → social IdP → Cognito → web gets tokens (PKCE).
The API verifies JWTs locally with Cognito's cached JWKS; no per-request call to Cognito.

**Image upload.** Editor asks the API for a pre-signed PUT URL (size and type limited), uploads to S3,
then confirms the upload to the API, which publishes `ImageUploaded`; the worker creates resized
WebP variants.

### Data model (core tables)

`users`, `stories` (id, author_id, slug, status, published_at), `story_revisions` (body as JSON
document), `tags`, `story_tags`, `follows` (follower_id, followee_id), `claps` (ledger),
`comments` (story_id, parent_id), `notifications`, `outbox`. Story bodies are stored as structured
JSON (editor format), rendered to HTML at publish time and cached.

### AWS deployment (see 03-Deployment-*)

- **Edge:** Route 53 → CloudFront with AWS WAF (managed rules, bot control, rate limits). ALB accepts
  traffic only from the CloudFront managed prefix list plus a secret origin header.
- **Network:** one VPC, 3 AZs. Public subnets hold only the ALB (and NAT gateways for the
  email-provider and IdP egress). App and data subnets are private. VPC endpoints for S3, SQS,
  Secrets Manager, ECR and CloudWatch Logs keep AWS traffic off the NAT.
- **Compute:** ECS on Fargate, three services, at least one task per AZ. Web/API scale on CPU and
  ALB request count; the worker scales on SQS queue depth.
- **Data:** Aurora PostgreSQL (writer + 2 readers, Multi-AZ, RDS Proxy for connection pooling),
  ElastiCache Redis cluster mode with replicas, OpenSearch 3 data nodes with dedicated masters.
  All encrypted with KMS; credentials in Secrets Manager with rotation.
- **Observability:** CloudWatch logs/metrics/alarms, X-Ray (or OpenTelemetry → CloudWatch) traces,
  dashboards per service; alarms on 5xx rate, p95 latency, queue age, DLQ depth, Aurora replica lag.
- **Delivery:** infrastructure as code (CDK or Terraform); images in ECR; blue/green deploys via
  CodeDeploy for ECS; separate AWS accounts for dev, staging and live under AWS Organizations.

### Resilience and DR

Everything in the region is Multi-AZ, so an AZ loss is absorbed automatically. Region loss is the
accepted risk for v1: Aurora backups and snapshots copied to a second region, S3 cross-region
replication for media, and IaC to rebuild there (RTO ~1 h). Aurora Global Database is the upgrade
path if the read-availability target rises. OpenSearch and Redis are rebuildable from Aurora.

### Security

WAF at the edge; TLS everywhere; least-privilege IAM task roles per service; private subnets for all
compute and data; S3 bucket private with origin access control; pre-signed URLs short-lived and
content-type restricted; server-side HTML sanitization of story bodies (stored XSS is the main
app-level risk for a publishing platform); rate limits on claps, comments and sign-in.

### Cost levers

CloudFront hit ratio is the biggest lever (it shields every tier). Then Fargate Spot for the worker,
Graviton (ARM64) tasks, Aurora reader auto-scaling, and S3 Intelligent-Tiering for old images.

### Open questions for the review

1. Is fan-out-on-write in Redis acceptable at the follower-count threshold, or start with read-time merge only?
2. Single-region v1 with backup-based DR: does the business accept a ~1 h RTO?
3. Email: stay with a third-party provider, or move to Amazon SES once sending reputation is established?
4. Is SSR on Fargate the right call, or should story pages be pre-rendered to S3 at publish time?
