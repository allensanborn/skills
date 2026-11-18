workspace "Web Shop" "C4 System Context and Container diagrams for Web Shop, for onboarding new engineers." {

    model {
        !impliedRelationships true

        customer = person "Customer" "Someone who browses products and buys from the shop."

        webShop = softwareSystem "Web Shop" "Lets customers browse products, place orders, and pay by card." {
            spa = container "Single-Page Application" "The storefront UI: product browsing, cart, checkout, and account pages." "React" {
                tags "Browser"
            }
            api = container "API Application" "Serves the SPA bundle; handles business logic, customer login, orders, and payments behind a JSON API." "Java, Spring Boot"
            db = container "Database" "Stores customers and their credentials, products, carts, and orders." "PostgreSQL" {
                tags "Database"
            }
        }

        stripe = softwareSystem "Stripe" "Payment processor that handles card details and charges." "External"
        ses = softwareSystem "Amazon SES" "Amazon Simple Email Service: delivers transactional email." "External"

        # System-level edge declared first so the context view gets a clear label
        # instead of whichever container-level edge would otherwise be rolled up.
        webShop -> stripe "Takes card payments through" "HTTPS"

        customer -> spa "Browses products and places orders using" "Web browser"
        api -> spa "Delivers the SPA's static bundle to the customer's browser" "HTTPS"
        spa -> api "Makes API calls to" "JSON/HTTPS"
        spa -> stripe "Sends card details to, via Stripe Elements" "HTTPS"
        api -> stripe "Confirms payments using" "JSON/HTTPS"
        stripe -> api "Sends payment event webhooks to" "HTTPS"
        api -> db "Reads from and writes to" "SQL/JDBC"
        api -> ses "Sends order and account emails using" "SMTP"
        ses -> customer "Delivers emails to" "Email"
    }

    views {
        systemContext webShop "SystemContext" "System Context: Web Shop, the people who use it, and the systems it depends on." {
            include *
            autolayout tb 200 50
        }

        container webShop "Containers" "Containers: the applications and data store inside Web Shop." {
            include *
            autolayout tb 200 50
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Database" {
                shape cylinder
            }
            element "Browser" {
                shape webbrowser
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
