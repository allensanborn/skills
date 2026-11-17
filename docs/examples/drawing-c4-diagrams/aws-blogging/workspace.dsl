workspace "Blogging Platform" "A Medium-style blogging platform and its Live deployment on AWS." {

    !impliedRelationships true

    configuration {
        scope softwaresystem
    }

    model {
        reader = person "Reader" "Reads, claps for and responds to stories; follows writers and topics."
        writer = person "Writer" "Drafts, edits and publishes stories; builds a following."

        blog = softwareSystem "Blogging Platform" "Lets writers publish stories and readers discover, read and react to them." {
            !docs docs
            !adrs adrs

            web = container "Web Application" "Server-renders story pages for SEO and fast first paint; delivers the interactive reader UI and the rich-text editor." "TypeScript, Next.js"

            api = container "API" "Stories, drafts, profiles, follows, claps, responses and personalised feeds. Owns all writes." "TypeScript, Node.js (Fastify)"

            worker = container "Background Worker" "Consumes domain events: fans out home feeds, indexes stories for search, resizes images, sends notification and digest emails." "TypeScript, Node.js"

            identity = container "Identity Service" "User pool; federates social sign-in and issues the JWTs the API trusts." "Amazon Cognito user pool"

            queue = container "Event Queue" "Durable buffer of domain events (StoryPublished, UserFollowed, Clapped, ResponsePosted)." "Message queue (SQS)" "Queue"

            db = container "Content Database" "System of record: users, stories and revisions, follows, claps, responses." "PostgreSQL" "Database"

            cache = container "Cache" "Precomputed home feeds, clap counters, hot story pages, rate limits." "Redis" "Database"

            search = container "Search Index" "Full-text and tag search over published stories and writers." "OpenSearch" "Database"

            media = container "Media Store" "Uploaded images and their resized renditions." "Object storage (S3)" "Bucket"
        }

        email = softwareSystem "Email Provider" "Transactional and digest email delivery (e.g. Postmark, SendGrid)." "External"
        social = softwareSystem "Social Sign-in" "Google, Apple and GitHub identity providers." "External"

        # Context-level edges people reach the system through
        reader -> web "Reads stories, follows, claps and responds using" "HTTPS"
        writer -> web "Drafts, edits and publishes stories using" "HTTPS"

        # Container-level edges
        web -> api "Makes API calls to" "JSON/HTTPS"
        web -> identity "Redirects users to sign in through" "OIDC / OAuth 2.0"
        web -> media "Uploads images via pre-signed URLs to" "HTTPS"
        identity -> social "Federates sign-in to" "OIDC"

        api -> identity "Validates access tokens against (JWKS)" "HTTPS"
        api -> db "Reads from and writes to" "SQL/TLS"
        api -> cache "Reads feeds and counters from; caches pages in" "RESP/TLS"
        api -> search "Queries stories and writers in" "HTTPS"
        api -> queue "Publishes domain events to" "HTTPS" "Async"

        worker -> queue "Consumes domain events from" "HTTPS" "Async"
        worker -> db "Reads stories and the follower graph from" "SQL/TLS"
        worker -> cache "Writes fanned-out home feeds to" "RESP/TLS"
        worker -> search "Indexes published stories in" "HTTPS"
        worker -> media "Writes resized image renditions to" "HTTPS"
        worker -> email "Sends notification and digest emails through" "HTTPS API"

        email -> reader "Delivers story digests and follow notifications to" "Email"
        email -> writer "Delivers new-follower and response notifications to" "Email"

        live = deploymentEnvironment "Live" {

            emailNode = deploymentNode "Email Provider SaaS" "Vendor-hosted." "SaaS" {
                softwareSystemInstance email
            }
            socialNode = deploymentNode "Social Identity Providers" "Vendor-hosted." "SaaS" {
                softwareSystemInstance social
            }

            aws = deploymentNode "AWS" "Production account; provisioned with Terraform." "Amazon Web Services" {
                tags "Amazon Web Services - AWS Cloud"

                dns = infrastructureNode "Route 53" "Public hosted zone for the blog's domain." "Amazon Route 53" {
                    tags "Amazon Web Services - Route 53"
                }
                cdn = infrastructureNode "CloudFront" "Edge cache for story pages, static assets and images; TLS via ACM." "Amazon CloudFront" {
                    tags "Amazon Web Services - CloudFront"
                }
                waf = infrastructureNode "WAF" "Managed rule groups, bot control and per-IP rate limiting." "AWS WAF" {
                    tags "Amazon Web Services - WAF"
                }

                region = deploymentNode "us-east-1" "Primary region; every stateful tier spans 2 AZs." "AWS Region" {
                    tags "Amazon Web Services - Region"

                    cognitoNode = deploymentNode "Cognito" "Hosted UI on the auth subdomain." "Amazon Cognito" {
                        tags "Amazon Web Services - Cognito"
                        identityInstance = containerInstance identity
                    }
                    s3Node = deploymentNode "S3" "Private bucket, versioned; read only through CloudFront OAC." "Amazon S3" {
                        tags "Amazon Web Services - Simple Storage Service"
                        mediaInstance = containerInstance media
                    }
                    sqsNode = deploymentNode "SQS" "Standard queue with a dead-letter queue." "Amazon SQS" {
                        tags "Amazon Web Services - Simple Queue Service"
                        containerInstance queue
                    }

                    vpc = deploymentNode "VPC" "10.0.0.0/16 across 2 AZs." "Amazon VPC" {
                        tags "Amazon Web Services - Virtual private cloud VPC"

                        publicSubnet = deploymentNode "Public subnets" "One per AZ; NAT gateways for outbound traffic." "Subnet" {
                            tags "Amazon Web Services - Public subnet"
                            alb = infrastructureNode "Application Load Balancer" "Accepts traffic from CloudFront only; routes /api/* to the API, everything else to the web app." "Elastic Load Balancing" {
                                tags "Amazon Web Services - Load Balancing"
                            }
                        }

                        appSubnet = deploymentNode "Private app subnets" "One per AZ; egress via NAT." "Subnet" {
                            tags "Amazon Web Services - Private subnet"

                            ecs = deploymentNode "ECS cluster" "Images from ECR; secrets from Secrets Manager." "Amazon ECS" {
                                tags "Amazon Web Services - Elastic Container Service"

                                webSvc = deploymentNode "web service" "2-10 tasks, autoscaled on CPU." "AWS Fargate" {
                                    tags "Amazon Web Services - Fargate"
                                    webInstance = containerInstance web
                                }
                                apiSvc = deploymentNode "api service" "3-20 tasks, autoscaled on request count." "AWS Fargate" {
                                    tags "Amazon Web Services - Fargate"
                                    apiInstance = containerInstance api
                                }
                                workerSvc = deploymentNode "worker service" "1-10 tasks, autoscaled on queue depth." "AWS Fargate" {
                                    tags "Amazon Web Services - Fargate"
                                    containerInstance worker
                                }
                            }
                        }

                        dataSubnet = deploymentNode "Private data subnets" "One per AZ; no internet route." "Subnet" {
                            tags "Amazon Web Services - Private subnet"

                            auroraNode = deploymentNode "Aurora PostgreSQL" "Writer + 1 reader replica across 2 AZs; PITR backups." "Amazon Aurora" {
                                tags "Amazon Web Services - Aurora"
                                containerInstance db
                            }
                            redisNode = deploymentNode "ElastiCache for Redis" "Primary + replica, Multi-AZ failover." "Amazon ElastiCache" {
                                tags "Amazon Web Services - ElastiCache"
                                containerInstance cache
                            }
                            osNode = deploymentNode "OpenSearch Service" "3 data nodes across 2 AZs." "Amazon OpenSearch Service" {
                                tags "Amazon Web Services - OpenSearch Service"
                                containerInstance search
                            }
                        }
                    }
                }
            }

            dns -> cdn "Resolves the blog's domain to" "DNS"
            cdn -> waf "Screens every request with" "AWS WAF web ACL"
            cdn -> alb "Forwards uncached page and API requests to" "HTTPS"
            cdn -> mediaInstance "Serves images from (origin access control)" "HTTPS"
            alb -> webInstance "Forwards page requests to" "HTTPS"
            alb -> apiInstance "Forwards /api/* requests to" "HTTPS"
        }
    }

    views {
        systemContext blog "SystemContext" "Who uses the Blogging Platform and what it depends on." {
            include *
            autolayout lr
        }

        container blog "Containers" "The deployable units inside the Blogging Platform." {
            include *
            autolayout lr
        }

        deployment blog live "LiveDeployment" "Production on AWS (us-east-1)." {
            include *
            autolayout tb 300 150
        }

        styles {
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape cylinder
            }
            element "Queue" {
                shape pipe
            }
            element "Bucket" {
                shape folder
            }
            relationship "Relationship" {
                dashed false
            }
            relationship "Async" {
                dashed true
            }
        }

        theme amazon-web-services-2025.07
    }
}
