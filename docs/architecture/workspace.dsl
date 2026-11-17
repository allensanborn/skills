workspace "drawing-c4-diagrams" "The skill's toolchain, its render paths, and how cloud icons flow into each output. Audience: skill maintainers." {

    !identifiers hierarchical

    model {
        engineer = person "Engineer" "Asks Claude for architecture diagrams; maintains the skill."

        toolchain = softwareSystem "C4 diagramming toolchain" "The skill plus the Docker tools it drives on the engineer's machine." {
            claude = container "Claude Code agent" "Follows the skill: scope grill, writes DSL, runs validate/export/render, reviews renders." "Claude Code"
            skill = container "drawing-c4-diagrams skill" "SKILL.md, references/, evals/render/test.sh." "Markdown, bash" "Files"
            dsl = container "workspace.dsl" "One model, many views; names a theme and tags deployment nodes with icon tags." "Structurizr DSL" "Files"
            cli = container "Structurizr CLI" "validate, inspect, export png|svg|plantuml|mermaid. Resolves themes; inlines installed-theme icons as data: URIs." "Docker: structurizr/structurizr:2026.10.26-playwright"
            themes = container "Bundled themes" "16 provider themes (theme.json + vendor PNGs) at /usr/local/structurizr-themes." "Files in the image" "Files"
            local = container "Structurizr local" "Interactive render and layout editing at :8080." "Docker: structurizr/structurizr local"
            mcp = container "Structurizr MCP" "In-chat validate and Mermaid/PlantUML preview." "Docker: structurizr/mcp"
            plantuml = container "PlantUML renderer" "Renders .puml; fetches https icons and embeds them." "Docker: plantuml/plantuml:1.2026.10"
            mermaid = container "mermaid-cli" "Renders .mmd; SVG keeps icons as remote <img> URLs." "Docker: minlag/mermaid-cli:12.0.0"
            exports = container "exports/" "PNG, SVG, .puml, .mmd, legend keys." "Files" "Files"
        }

        github = softwareSystem "GitHub raw content" "raw.githubusercontent.com/structurizr/structurizr: theme.json + icon PNGs (the URL-theme source)." "External"
        dockerhub = softwareSystem "Docker Hub" "Publishes the pinned Structurizr, PlantUML and mermaid-cli images." "External"
        vendors = softwareSystem "Icon owners" "AWS, Microsoft, Google, Oracle, CNCF: publish icon sets under their own terms." "External,Licensing"
        oldHost = softwareSystem "static.structurizr.com" "Old theme host; gone since the cloud service EOL (30 Sep 2026)." "External,Dead"

        engineer -> toolchain.claude "Asks for diagrams; answers the grill" "Chat"
        toolchain.claude -> toolchain.skill "Reads instructions from" "File read"
        toolchain.claude -> toolchain.dsl "Writes" "File write"
        toolchain.claude -> toolchain.cli "Runs validate/export via" "docker run"
        toolchain.claude -> toolchain.local "Starts for layout tweaks" "docker run"
        toolchain.claude -> toolchain.mcp "Validates and previews via" "MCP"
        toolchain.claude -> toolchain.plantuml "Renders .puml with" "docker run"
        toolchain.claude -> toolchain.mermaid "Renders .mmd with" "docker run"
        toolchain.claude -> dockerhub "Pulls pinned images from" "HTTPS"

        toolchain.cli -> toolchain.dsl "Parses" "Bind mount"
        toolchain.cli -> toolchain.themes "Loads installed theme" "STRUCTURIZR_THEMES"
        toolchain.cli -> github "Loads URL theme" "HTTPS"
        toolchain.cli -> toolchain.exports "Writes PNG/SVG and .puml/.mmd" "Bind mount"
        toolchain.cli -> oldHost "theme default resolves to (fails; renders unstyled)" "HTTPS" "Dead"
        toolchain.local -> toolchain.dsl "Reads; saves layout to" "Bind mount"
        toolchain.local -> toolchain.themes "Loads installed theme" "File read"
        toolchain.mcp -> toolchain.dsl "Parses" "MCP tool input"
        toolchain.plantuml -> toolchain.exports "Reads .puml; writes PNG/SVG" "Bind mount"
        toolchain.plantuml -> github "Fetches icon PNGs at render time" "HTTPS"
        toolchain.mermaid -> toolchain.exports "Reads .mmd; writes SVG/PNG" "Bind mount"
        toolchain.mermaid -> github "Loads <img> icon URLs while rendering" "HTTPS"

        toolchain.themes -> vendors "Contains copies of icons owned by" "Vendor icon terms" "Licensing"
        github -> vendors "Serves copies of icons owned by" "Vendor icon terms" "Licensing"

        live = deploymentEnvironment "Engineer's machine" {
            deploymentNode "Mac" "" "macOS" {
                deploymentNode "Claude Code" "" "CLI" {
                    containerInstance toolchain.claude
                }
                deploymentNode "skills repo checkout" "" "git" {
                    containerInstance toolchain.skill
                    containerInstance toolchain.dsl
                    containerInstance toolchain.exports
                }
                deploymentNode "OrbStack" "" "Docker" {
                    deploymentNode "structurizr/structurizr:2026.10.26-playwright" "" "Docker container" {
                        containerInstance toolchain.cli
                        containerInstance toolchain.themes
                    }
                    deploymentNode "structurizr/structurizr local" "" "Docker container, :8080" {
                        containerInstance toolchain.local
                    }
                    deploymentNode "structurizr/mcp" "" "Docker container" {
                        containerInstance toolchain.mcp
                    }
                    deploymentNode "plantuml/plantuml:1.2026.10" "" "Docker container" {
                        containerInstance toolchain.plantuml
                    }
                    deploymentNode "minlag/mermaid-cli:12.0.0" "" "Docker container" {
                        containerInstance toolchain.mermaid
                    }
                }
            }
            deploymentNode "Internet" {
                softwareSystemInstance github
                softwareSystemInstance dockerhub
            }
        }
    }

    views {
        systemContext toolchain "Context" "Who drives the toolchain and what it reaches outside the machine." {
            include *
            autolayout lr
        }

        container toolchain "Containers" "The skill, the Docker tools it runs, and every render path. Dead host and icon owners: see Context." {
            include *
            exclude oldHost vendors
            autolayout lr
        }

        dynamic toolchain "IconFlow" "How an AWS icon reaches each output (verified by evals/render/test.sh)." {
            toolchain.claude -> toolchain.dsl "Writes theme + AWS tags on deployment nodes"
            toolchain.cli -> toolchain.dsl "Parses"
            toolchain.cli -> toolchain.themes "Installed theme: icons inlined as data: URIs"
            toolchain.cli -> toolchain.exports "Installed theme -> PNG/SVG: 9/9 icons embedded. PlantUML/Mermaid: 0 (exporters want http* icons)"
            toolchain.cli -> github "URL theme: icon names become https URLs"
            toolchain.cli -> toolchain.exports "URL theme -> .puml 9/9 refs; C4-PlantUML 0; .mmd 3/9 (infrastructure nodes, mermaid.icons=true)"
            toolchain.plantuml -> github "Fetches the 9 icon PNGs"
            toolchain.plantuml -> toolchain.exports "URL theme -> PlantUML PNG/SVG with 9 icons embedded"
            toolchain.mermaid -> toolchain.exports "URL theme -> Mermaid SVG with 3 remote <img> icons (blank offline)"
            autolayout lr
        }

        deployment toolchain live "Deployment" "Where each piece runs." {
            include *
            autolayout tb
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
            element "Files" {
                shape folder
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Licensing" {
                background #b8860b
            }
            element "Dead" {
                background #cc3333
                border dashed
            }
            relationship "Dead" {
                color #cc3333
                dashed true
            }
            relationship "Licensing" {
                color #b8860b
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
