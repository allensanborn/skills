---
tags: [drawing-c4-diagrams]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Our container view is going in the README. Make it work there. Here's the workspace; save it as `workspace.dsl` in this folder and edit it there:

```text
workspace "Ticketing" "Concert ticket sales." {
    !identifiers hierarchical
    model {
        fan = person "Fan" "Buys concert tickets."
        promoter = person "Promoter" "Lists events and seats."
        stripe = softwareSystem "Stripe" "Card payments." {
            tags "External"
        }
        email = softwareSystem "SendGrid" "Transactional email." {
            tags "External"
        }
        tix = softwareSystem "Ticketing" "Sells concert tickets." {
            web = container "Web App" "Storefront and checkout." "Next.js"
            admin = container "Admin App" "Event and seat setup." "React"
            gateway = container "API Gateway" "Routes and authenticates requests." "Envoy"
            catalog = container "Catalog Service" "Events, venues and seat maps." "Go"
            booking = container "Booking Service" "Holds and confirms seats." "Go"
            payment = container "Payment Service" "Takes payments for bookings." "Node.js"
            notify = container "Notification Service" "Sends tickets and receipts." "Node.js"
            catalogDb = container "Catalog DB" "Events and seat maps." "PostgreSQL" {
                tags "Database"
            }
            bookingDb = container "Booking DB" "Holds and bookings." "PostgreSQL" {
                tags "Database"
            }
            cache = container "Seat Cache" "Live seat availability." "Redis" {
                tags "Database"
            }
            bus = container "Event Bus" "Booking and payment events." "Kafka" {
                tags "Queue"
            }
        }
        fan -> tix.web "Browses events and buys tickets using" "HTTPS"
        promoter -> tix.admin "Lists events using" "HTTPS"
        tix.web -> tix.gateway "Makes API calls to" "JSON/HTTPS"
        tix.admin -> tix.gateway "Makes API calls to" "JSON/HTTPS"
        tix.gateway -> tix.catalog "Routes catalog requests to" "gRPC"
        tix.gateway -> tix.booking "Routes booking requests to" "gRPC"
        tix.gateway -> tix.payment "Routes payment requests to" "gRPC"
        tix.catalog -> tix.catalogDb "Reads from and writes to" "SQL"
        tix.catalog -> tix.cache "Publishes seat availability to" "RESP"
        tix.booking -> tix.bookingDb "Reads from and writes to" "SQL"
        tix.booking -> tix.cache "Reads and updates seat holds in" "RESP"
        tix.booking -> tix.bus "Publishes BookingConfirmed to" "Kafka"
        tix.payment -> stripe "Charges cards using" "JSON/HTTPS"
        tix.payment -> tix.bus "Publishes PaymentSucceeded to" "Kafka"
        tix.bus -> tix.booking "Delivers PaymentSucceeded to" "Kafka"
        tix.bus -> tix.notify "Delivers BookingConfirmed to" "Kafka"
        tix.notify -> email "Sends tickets and receipts using" "JSON/HTTPS"
    }
    views {
        container tix "Containers" "Everything in Ticketing." {
            include *
            autolayout lr
        }
        styles {
            element "Person" {
                shape Person
            }
            element "Database" {
                shape Cylinder
            }
            element "Queue" {
                shape Pipe
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }
}
```
