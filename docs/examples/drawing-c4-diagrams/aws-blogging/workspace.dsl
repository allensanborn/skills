workspace "Blogging Platform" "A Medium-style publishing platform for readers and writers, running on AWS." {

    model {
        !impliedRelationships true

        reader = person "Reader" "Reads stories, follows writers, claps and comments. Mostly anonymous; some signed in."
        writer = person "Writer" "Drafts, edits and publishes stories, and watches how they perform."

        social = softwareSystem "Social Identity Providers" "Google, Apple and GitHub accounts used for sign-in." "External"
        email = softwareSystem "Email Provider" "Third-party transactional and bulk email delivery (e.g. SendGrid)." "External"

        blog = softwareSystem "Blogging Platform" "Lets writers publish stories and readers discover, read and respond to them." {
            !docs docs
            !adrs adrs

            web = container "Web Application" "Server-renders story pages for SEO and fast first paint; hydrates into the reader UI and the story editor." "Next.js, TypeScript"
            api = container "API Application" "Stories, drafts, comments, claps, follows, feeds and profiles behind one REST API." "Node.js, NestJS, TypeScript"
            worker = container "Background Worker" "Consumes domain events: fans stories into follower feeds, indexes search, resizes images, sends notifications." "Node.js, TypeScript"
            identity = container "Identity Service" "User pool and hosted sign-in; federates social logins and issues JWTs." "Amazon Cognito" "Identity"
            db = container "Database" "System of record: users, stories and revisions, comments, claps, follows." "PostgreSQL" "Database"
            cache = container "Cache" "Hot story pages, per-reader feed timelines and clap counters." "Redis" "Database"
            search = container "Search Index" "Full-text search over published stories, tags and writers." "OpenSearch" "Database"
            queue = container "Event Queue" "Durable queue of domain events (StoryPublished, CommentAdded, UserFollowed)." "Amazon SQS" "Queue"
            media = container "Media Store" "Uploaded images and their resized variants." "Amazon S3" "Bucket"
        }

        # System-level edges first, so the context view gets these labels rather than a child's
        reader -> blog "Reads stories, follows writers, claps and comments using" "HTTPS"
        writer -> blog "Drafts and publishes stories using" "HTTPS"
        blog -> social "Federates sign-in to" "OIDC/HTTPS"
        blog -> email "Sends notification and digest emails through" "JSON/HTTPS"
        email -> reader "Delivers notification and digest emails to" "SMTP"
        email -> writer "Delivers comment and follower notifications to" "SMTP"

        # Containers
        reader -> web "Reads stories, claps and comments using" "HTTPS"
        writer -> web "Writes and publishes stories using" "HTTPS"
        reader -> media "Loads story images from (via CDN)" "HTTPS"
        writer -> media "Uploads images to (pre-signed URL)" "HTTPS"

        web -> api "Makes API calls to" "JSON/HTTPS"
        web -> identity "Redirects users to sign in through" "OAuth 2.0/OIDC"
        identity -> social "Federates sign-in to" "OIDC/HTTPS"
        api -> identity "Verifies JWT signatures against keys from" "JWKS/HTTPS"

        api -> db "Reads from and writes to" "SQL/TLS"
        api -> cache "Reads feeds and cached pages from, updates counters in" "RESP/TLS"
        api -> search "Runs full-text queries against" "JSON/HTTPS"
        api -> queue "Publishes domain events to" "SQS API"
        api -> media "Signs upload URLs for" "S3 API"

        worker -> queue "Consumes domain events from" "SQS API"
        worker -> db "Reads followers and writes notifications to" "SQL/TLS"
        worker -> cache "Fans new stories into follower feeds in" "RESP/TLS"
        worker -> search "Indexes published stories into" "JSON/HTTPS"
        worker -> media "Writes resized image variants to" "S3 API"
        worker -> email "Sends notification and digest emails through" "JSON/HTTPS"

        live = deploymentEnvironment "Live" {
            aws = deploymentNode "Amazon Web Services" "Production account." "AWS" {
                tags "Amazon Web Services - AWS Cloud"

                dns = infrastructureNode "Route 53" "Hosted zone; alias records for the blog domain." "Amazon Route 53" {
                    tags "Amazon Web Services - Route 53"
                }
                cdn = infrastructureNode "CloudFront" "Edge cache for pages, assets and images; TLS termination." "Amazon CloudFront" {
                    tags "Amazon Web Services - CloudFront"
                }
                waf = infrastructureNode "AWS WAF" "Managed rules, bot control and per-IP rate limits." "AWS WAF" {
                    tags "Amazon Web Services - WAF"
                }

                region = deploymentNode "us-east-1" "Primary region, 3 Availability Zones." "AWS Region" {
                    tags "Amazon Web Services - Region"

                    cognito = deploymentNode "Cognito" "User pool with hosted UI." "Amazon Cognito" {
                        tags "Amazon Web Services - Cognito"
                        identityInstance = containerInstance identity
                    }
                    s3 = deploymentNode "S3" "Private bucket; read only through CloudFront origin access control." "Amazon S3" {
                        tags "Amazon Web Services - Simple Storage Service"
                        mediaInstance = containerInstance media
                    }
                    sqs = deploymentNode "SQS" "Standard queue with a dead-letter queue." "Amazon SQS" {
                        tags "Amazon Web Services - Simple Queue Service"
                        queueInstance = containerInstance queue
                    }

                    vpc = deploymentNode "VPC" "10.0.0.0/16 across 3 AZs; VPC endpoints for S3, SQS and Secrets Manager." "Amazon VPC" {
                        tags "Amazon Web Services - Virtual private cloud VPC"

                        publicSubnet = deploymentNode "Public subnets" "One per AZ." "Subnet" {
                            tags "Amazon Web Services - Public subnet"
                            alb = infrastructureNode "Application Load Balancer" "Accepts traffic only from CloudFront; routes /api/* to the API, everything else to the web app." "Elastic Load Balancing" {
                                tags "Amazon Web Services - Load Balancing"
                            }
                        }

                        appSubnet = deploymentNode "Private app subnets" "One per AZ; no inbound from the internet." "Subnet" {
                            tags "Amazon Web Services - Private subnet"
                            ecs = deploymentNode "ECS cluster" "Services auto-scale on CPU and request count." "Amazon ECS on AWS Fargate" {
                                tags "Amazon Web Services - Fargate"
                                webService = deploymentNode "web service" "3-12 tasks" "Fargate service" {
                                    webInstance = containerInstance web
                                }
                                apiService = deploymentNode "api service" "3-20 tasks" "Fargate service" {
                                    apiInstance = containerInstance api
                                }
                                workerService = deploymentNode "worker service" "2-10 tasks, scales on queue depth" "Fargate service" {
                                    workerInstance = containerInstance worker
                                }
                            }
                        }

                        dataSubnet = deploymentNode "Private data subnets" "One per AZ; reachable only from the app subnets." "Subnet" {
                            tags "Amazon Web Services - Private subnet"
                            aurora = deploymentNode "Aurora PostgreSQL" "Writer plus 2 readers across AZs; automatic failover." "Amazon Aurora" {
                                tags "Amazon Web Services - Aurora"
                                dbInstance = containerInstance db
                            }
                            redis = deploymentNode "ElastiCache" "Redis OSS, cluster mode, Multi-AZ replicas." "Amazon ElastiCache" {
                                tags "Amazon Web Services - ElastiCache"
                                cacheInstance = containerInstance cache
                            }
                            opensearch = deploymentNode "OpenSearch" "3 data nodes across AZs, dedicated masters." "Amazon OpenSearch Service" {
                                tags "Amazon Web Services - OpenSearch Service"
                                searchInstance = containerInstance search
                            }
                        }
                    }
                }

                dns -> cdn "Resolves the blog domain to" "DNS alias"
                waf -> cdn "Filters requests reaching" "Web ACL"
                cdn -> alb "Forwards page and API requests to" "HTTPS"
                cdn -> mediaInstance "Fetches uncached images from" "HTTPS, origin access control"
                alb -> webInstance "Routes page requests to" "HTTPS"
                alb -> apiInstance "Routes /api/* requests to" "HTTPS"
            }
        }
    }

    views {
        systemContext blog "01-SystemContext" "System Context: the Blogging Platform, its two kinds of user and the two external systems it relies on. Read first." {
            include *
            autolayout tb
        }

        container blog "02-Containers" "Container view, request path: how readers and writers reach the apps. Data stores in 02b; the queue, worker and email in 02c." {
            include reader writer web api identity social media
            autolayout tb
        }

        container blog "02b-Containers-Data" "Container view, data: how the API and worker use the database, cache, search index and media store." {
            include api worker db cache search media
            autolayout tb
        }

        container blog "02c-Containers-Async" "Container view, async: domain events through the queue to the worker and on to email." {
            include api queue worker email reader writer
            autolayout lr
        }

        deployment blog live "03-Deployment-Edge" "Live deployment on AWS, edge: how a request reaches the apps. Data in 03b, async in 03c." {
            include dns cdn waf alb webInstance apiInstance mediaInstance
            exclude "apiInstance -> mediaInstance"
            autolayout tb
        }

        deployment blog live "03b-Deployment-Data" "Live deployment on AWS, data: the app services and their managed stores." {
            include apiInstance workerInstance dbInstance cacheInstance searchInstance
            autolayout tb
        }

        deployment blog live "03c-Deployment-Async" "Live deployment on AWS, regional managed services: events, media and identity. Email and social sign-in are third-party SaaS outside AWS (see 02-Containers and 02c)." {
            include apiInstance queueInstance workerInstance mediaInstance identityInstance
            autolayout lr 200 100
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
                background #8a8a8a
                color #ffffff
                border dashed
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
            element "Identity" {
                shape hexagon
            }
        }

        theme amazon-web-services-2025.07
    }

    configuration {
        scope softwaresystem
    }

}
