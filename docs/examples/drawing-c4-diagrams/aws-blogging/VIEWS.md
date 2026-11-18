# Blogging Platform architecture

C4 model of a Medium-style blogging platform on AWS. `workspace.dsl` is the single source of truth;
the images in `exports/` are generated from it. The system design narrative is in
[docs/01-system-design.md](docs/01-system-design.md), decisions in [adrs/](adrs/).

Read in order:

| View | What it answers |
| --- | --- |
| [01-SystemContext](01-SystemContext.svg) | Who uses the platform, and what it depends on |
| [02-Containers](02-Containers.svg) | Request path: how readers and writers reach the apps |
| [02b-Containers-Data](02b-Containers-Data.svg) | How the API and worker use the data stores |
| [02c-Containers-Async](02c-Containers-Async.svg) | Events through the queue to the worker and email |
| [03-Deployment-Edge](03-Deployment-Edge.svg) | Live on AWS: Route 53, CloudFront, WAF, ALB to Fargate |
| [03b-Deployment-Data](03b-Deployment-Data.svg) | Live on AWS: Fargate services to Aurora, ElastiCache, OpenSearch |
| [03c-Deployment-Async](03c-Deployment-Async.svg) | Live on AWS: SQS, S3 and Cognito |

Each view has a `-key.png` legend next to it. AWS icons come from the `amazon-web-services-2025.07`
theme bundled in the Structurizr image; the icons are AWS's, so check AWS's terms before publishing
these images outside the company.

## Regenerate

```bash
cd docs/architecture
img=structurizr/structurizr:2026.10.26-playwright
run() { docker run --rm --ipc=host -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes -v "$PWD:/work" -w /work "$img" "$@"; }
run validate -workspace workspace.dsl
run inspect  -workspace workspace.dsl
run export   -workspace workspace.dsl -format png -output exports
run export   -workspace workspace.dsl -format svg -output exports
```

Interactive layout: `docker run -it --rm -p 8080:8080 -e STRUCTURIZR_THEMES=/usr/local/structurizr-themes -v "$PWD:/usr/local/structurizr" $img local`, then open <http://localhost:8080>.
