workspace "Bookshop" "Online bookshop." {
    !identifiers hierarchical
    model {
        customer = person "Customer" "Buys books online."
        payments = softwareSystem "Payment Provider" {
            tags "External"
        }
        shop = softwareSystem "Bookshop" "Sells books online." {
            web = container "Web App" "Serves the storefront." "React"
            api = container "API" "Handles orders and payments."
            db = container "Database" "Stores orders and stock." "PostgreSQL" {
                tags "Database"
            }
            search = container "Search Index" "Full-text search over the catalogue." "OpenSearch"
        }
        customer -> shop.web "Browses and buys books using" "HTTPS"
        shop.web -> shop.api "Uses"
        shop.api -> shop.db "Reads from and writes to" "SQL/TCP"
        shop.api -> payments "Takes card payments using" "JSON/HTTPS"
    }
    views {
        container shop "Containers" "The Bookshop's containers." {
            include *
            autolayout tb
        }
        styles {
            element "Element" {
                background #1168bd
            }
            element "Person" {
                shape Person
            }
            element "Database" {
                shape Cylinder
            }
            element "External" {
                background #999999
            }
        }
    }
}
