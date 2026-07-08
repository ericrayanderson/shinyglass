# Minimal bs4Dash dashboard with shinyglass overlay CSS (no Bootstrap 5 reboot).
# Stress-tests AdminLTE3 boxes, value boxes, and sidebar under glass rules.
#
# Run:
#   shiny::runApp(system.file("examples", "bs4dash-glass-demo.R", package = "shinyglass"))
#
# Requires: bs4Dash

if (!requireNamespace("bs4Dash", quietly = TRUE)) {
  stop("Install bs4Dash: install.packages(\"bs4Dash\")", call. = FALSE)
}
if (!requireNamespace("shinyglass", quietly = TRUE)) {
  stop("Install shinyglass first.", call. = FALSE)
}

library(shiny)
library(bs4Dash)
library(shinyglass)
library(htmltools)

# Resolve package scripts when running from a source checkout or staged wrapper
resolve_pkg_root <- function() {
  env_root <- Sys.getenv("SHINYGLASS_PKG_ROOT", unset = "")
  if (nzchar(env_root) && dir.exists(env_root)) {
    return(normalizePath(env_root, winslash = "/"))
  }
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    this_file <- sub("^--file=", "", file_arg[1])
    return(normalizePath(file.path(dirname(this_file), "..", ".."), winslash = "/"))
  }
  if (file.exists("inst/scripts/tier-ab-utils.R")) {
    return(normalizePath(".", winslash = "/"))
  }
  NA_character_
}

pkg_root <- resolve_pkg_root()
if (!is.na(pkg_root)) {
  utils_path <- file.path(pkg_root, "inst", "scripts", "tier-ab-utils.R")
  if (file.exists(utils_path)) source(utils_path)
}

if (!exists("glass_overlay_dependency", mode = "function")) {
  stop(
    "glass_overlay_dependency() not found. Run from the package source tree:\n",
    "  shiny::runApp('inst/examples/bs4dash-glass-demo.R')",
    call. = FALSE
  )
}

glass_preset <- match.arg(Sys.getenv("SHINYGLASS_PRESET", "light"), c("light", "dark"))
use_dark <- identical(glass_preset, "dark")

glass_dep <- glass_overlay_dependency(preset = glass_preset)

glass_head <- tags$head(
  tags$script(HTML(sprintf(
    "document.documentElement.dataset.glassPreset=%s;",
    shQuote(glass_preset, type = "cmd")
  ))),
  tags$style(HTML("
    /* Keep AdminLTE layout; only restyle chrome, not structure */
    body.hold-transition {
      min-height: 100vh;
    }
    .content-wrapper, .main-footer {
      background: transparent !important;
    }
    .main-sidebar, .main-header.navbar {
      backdrop-filter: blur(20px) saturate(180%);
      -webkit-backdrop-filter: blur(20px) saturate(180%);
    }
  "))
)

ui <- dashboardPage(
  title = "bs4Dash + shinyglass",
  dark = use_dark,
  help = NULL,
  fullscreen = TRUE,
  scrollToTop = TRUE,
  header = dashboardHeader(
    title = dashboardBrand(
      title = "Glass + bs4Dash",
      color = "primary"
    )
  ),
  sidebar = dashboardSidebar(
    skin = if (use_dark) "dark" else "light",
    sidebarMenu(
      id = "sidebar_menu",
      menuItem("Dashboard", tabName = "dash", icon = icon("chart-line")),
      menuItem("Boxes", tabName = "boxes", icon = icon("box"))
    )
  ),
  body = dashboardBody(
    glass_head,
    tabItems(
      tabItem(
        tabName = "dash",
        fluidRow(
          valueBox(
            value = 128,
            subtitle = "Active users",
            color = "primary",
            icon = icon("users"),
            width = 4
          ),
          valueBox(
            value = "98%",
            subtitle = "Uptime",
            color = "success",
            icon = icon("server"),
            width = 4
          ),
          valueBox(
            value = 7,
            subtitle = "Open issues",
            color = "warning",
            icon = icon("bug"),
            width = 4
          )
        ),
        fluidRow(
          box(
            title = "Histogram",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 8,
            sliderInput("n", "Observations", 50, 500, 150, width = "100%"),
            plotOutput("hist", height = 280)
          ),
          box(
            title = "Notes",
            status = "info",
            width = 4,
            collapsible = TRUE,
            p(
              "Overlay CSS from ",
              code("glass.scss"),
              " (without Bootstrap 5 reboot) so AdminLTE3 layout stays intact",
              " while .box / value boxes pick up glass surfaces."
            ),
            actionButton("notify", "Show notification", class = "btn-primary")
          )
        )
      ),
      tabItem(
        tabName = "boxes",
        fluidRow(
          box(
            title = "Closable box",
            width = 6,
            status = "danger",
            closable = TRUE,
            collapsible = TRUE,
            "Card body content sits under glass overrides for .box."
          ),
          box(
            title = "Solid header",
            width = 6,
            status = "success",
            solidHeader = TRUE,
            collapsible = TRUE,
            "Second box to check multi-column gap and overflow."
          )
        )
      )
    )
  ),
  controlbar = dashboardControlbar(
    skin = if (use_dark) "dark" else "light",
    controlbarMenu(
      id = "controlbar_menu",
      controlbarItem(
        title = "Theme",
        p(paste("Preset env: SHINYGLASS_PRESET =", glass_preset))
      )
    )
  ),
  footer = dashboardFooter(
    left = "shinyglass tier-B demo",
    right = "bs4Dash"
  )
)

ui <- attachDependencies(ui, glass_dep, append = TRUE)

server <- function(input, output, session) {
  output$hist <- renderPlot({
    hist(
      rnorm(input$n),
      col = "#007AFF",
      border = NA,
      main = paste(input$n, "draws"),
      xlab = NULL
    )
  })

  observeEvent(input$notify, {
    showNotification("Glass + bs4Dash notification", type = "message")
  })
}

shinyApp(ui, server)
