# Render-test fixture for test.sh: a blogging app deployed on AWS, every deployment and
# infrastructure node tagged with an AWS 2025.07 theme tag (9 icons on the Deployment view; S3 twice).
workspace "Blog" "AWS icon theme test" {

    model {
        reader = person "Reader"
        blog = softwareSystem "Blog" {
            spa = container "Web App" "Reading and writing UI" "React"
            api = container "API" "Posts, users, comments" "Node.js"
            db = container "Database" "Posts and users" "PostgreSQL" "Database"
            media = container "Media Store" "Images" "Object storage" "Database"
        }
        reader -> spa "Reads and writes posts"
        spa -> api "Calls" "JSON/HTTPS"
        api -> db "Reads/writes" "SQL"
        api -> media "Stores images"

        live = deploymentEnvironment "Live" {
            deploymentNode "AWS" {
                tags "Amazon Web Services - AWS Cloud"
                dns = infrastructureNode "Route 53" {
                    tags "Amazon Web Services - Route 53"
                }
                cdn = infrastructureNode "CloudFront" {
                    tags "Amazon Web Services - CloudFront"
                }
                deploymentNode "S3 (static site)" {
                    tags "Amazon Web Services - Simple Storage Service"
                    containerInstance spa
                }
                deploymentNode "us-east-1" {
                    tags "Amazon Web Services - Region"
                    alb = infrastructureNode "ALB" {
                        tags "Amazon Web Services - Load Balancing"
                    }
                    deploymentNode "ECS on Fargate" {
                        tags "Amazon Web Services - Fargate"
                        containerInstance api
                    }
                    deploymentNode "Aurora PostgreSQL" {
                        tags "Amazon Web Services - Aurora"
                        containerInstance db
                    }
                    deploymentNode "S3 (media)" {
                        tags "Amazon Web Services - Simple Storage Service"
                        containerInstance media
                    }
                }
                dns -> cdn "Routes to"
                cdn -> alb "Forwards /api to"
                alb -> api "Forwards to"
            }
        }
    }

    views {
        container blog "Containers" {
            include *
            autolayout lr
        }
        deployment blog live "Deployment" {
            include *
            autolayout lr
        }
        theme amazon-web-services-2025.07
        properties {
            # Mermaid only emits icons when asked, and only for http(s) icon URLs
            "mermaid.icons" "true"
        }
        styles {
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape cylinder
            }
        }
    }
}
