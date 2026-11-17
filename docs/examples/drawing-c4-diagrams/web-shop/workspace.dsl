workspace "Web Shop" "C4 model of the Web Shop, for onboarding new engineers." {

    model {
        !impliedRelationships true

        customer = person "Customer" "Browses products, places orders, pays by card, and receives order emails."

        webShop = softwareSystem "Web Shop" "Lets customers browse products, place orders, and pay online." {
            spa = container "Single-Page App" "Product browsing, cart, checkout, and account screens in the customer's browser." "React"
            api = container "API Application" "Serves the SPA bundle; handles business logic, customer login, orders, and payment confirmation via a JSON API." "Java/Spring Boot"
            db = container "Database" "Stores customer accounts, products, orders, and payment status." "PostgreSQL" {
                tags "Database"
            }
        }

        stripe = softwareSystem "Stripe" "Third-party card payment processor." {
            tags "External"
        }
        ses = softwareSystem "Amazon SES" "Amazon Simple Email Service; delivers transactional email." {
            tags "External"
        }

        # Context-level edges, declared explicitly so the rolled-up labels read well
        customer -> webShop "Browses products, places orders, and pays using" "Web browser"
        webShop -> stripe "Takes card payments through" "HTTPS"
        stripe -> webShop "Notifies of payment events" "Webhooks/HTTPS"
        webShop -> ses "Sends order and account emails using" "SMTP"
        ses -> customer "Delivers emails to" "Email"

        # Container-level edges
        customer -> spa "Browses, checks out, and enters card details in" "Web browser"
        spa -> api "Makes API calls to" "JSON/HTTPS"
        spa -> stripe "Collects card details with Stripe Elements and sends them to" "Stripe.js/HTTPS"
        api -> db "Reads from and writes to" "SQL/JDBC"
        api -> stripe "Creates and confirms payments using" "Stripe API/HTTPS"
        stripe -> api "Sends payment event webhooks to" "Webhooks/HTTPS"
        api -> ses "Sends order and account emails using" "SMTP"
    }

    views {
        systemContext webShop "SystemContext" "Web Shop and the people and systems around it." {
            include *
            autolayout lr
        }

        container webShop "Containers" "The applications and data store that make up Web Shop." {
            include *
            autolayout tb 300 300
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape cylinder
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
