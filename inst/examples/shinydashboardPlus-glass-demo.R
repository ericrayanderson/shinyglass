# shinydashboardPlus + glass overlay (AdminLTE denser chrome).
#
# Run:
#   shiny::runApp(system.file("examples", "shinydashboardPlus-glass-demo.R", package = "shinyglass"))
#
# Requires: shinydashboardPlus, shinydashboard

if (!requireNamespace("shinydashboardPlus", quietly = TRUE)) {
  stop("Install shinydashboardPlus: install.packages('shinydashboardPlus')", call. = FALSE)
}
if (!requireNamespace("shinydashboard", quietly = TRUE)) {
  stop("Install shinydashboard: install.packages('shinydashboard')", call. = FALSE)
}
if (!requireNamespace("shinyglass", quietly = TRUE)) {
  stop("Install shinyglass first.", call. = FALSE)
}

library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyglass)
library(htmltools)

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
  # runApp("inst/examples/....R") often sets wd to the examples/ dir
  candidates <- c(
    ".",
    "..",
    file.path("..", ".."),
    if (requireNamespace("shinyglass", quietly = TRUE)) {
      system.file(package = "shinyglass")
    } else {
      character()
    }
  )
  for (cand in candidates) {
    if (!nzchar(cand) || !dir.exists(cand)) next
    utils_path <- file.path(cand, "inst", "scripts", "tier-ab-utils.R")
    # installed package: scripts live under package root without extra inst/
    utils_path2 <- file.path(cand, "scripts", "tier-ab-utils.R")
    if (file.exists(utils_path) || file.exists(utils_path2)) {
      return(normalizePath(cand, winslash = "/"))
    }
  }
  NA_character_
}

pkg_root <- resolve_pkg_root()
if (!is.na(pkg_root)) {
  utils_path <- file.path(pkg_root, "inst", "scripts", "tier-ab-utils.R")
  if (!file.exists(utils_path)) {
    utils_path <- file.path(pkg_root, "scripts", "tier-ab-utils.R")
  }
  if (file.exists(utils_path)) source(utils_path)
}

if (!exists("glass_overlay_dependency", mode = "function")) {
  stop(
    "glass_overlay_dependency() not found. Run from the package source tree:\n",
    "  shiny::runApp('inst/examples/shinydashboardPlus-glass-demo.R')",
    call. = FALSE
  )
}

glass_preset <- match.arg(Sys.getenv("SHINYGLASS_PRESET", "light"), c("light", "dark"))
glass_dep <- glass_overlay_dependency(preset = glass_preset)

glass_head <- tags$head(
  glass_dep,
  tags$script(HTML(sprintf(
    "document.documentElement.dataset.glassPreset=%s;",
    shQuote(glass_preset, type = "cmd")
  ))),
  tags$style(HTML("
    .content-wrapper, .main-footer, .right-side { background: transparent !important; }
    body { min-height: 100vh; }
  "))
)

ui <- dashboardPage(
  title = "shinydashboardPlus + glass",
  header = dashboardHeader(
    title = "Glass + Plus",
    dropdownMenu(
      type = "notifications",
      badgeStatus = "primary",
      notificationItem(text = "Glass overlay active", icon = icon("glass-water"))
    ),
    userOutput("user")
  ),
  sidebar = dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Dashboard", tabName = "dash", icon = icon("gauge"), selected = TRUE),
      menuItem("Widgets", tabName = "widgets", icon = icon("sliders"))
    )
  ),
  body = dashboardBody(
    glass_head,
    tabItems(
      tabItem(
        "dash",
        fluidRow(
          valueBox(150, "Observations", icon = icon("database"), color = "blue", width = 4),
          valueBox(3, "Species", icon = icon("seedling"), color = "green", width = 4),
          valueBox("5.8 cm", "Avg sepal", icon = icon("ruler"), color = "aqua", width = 4)
        ),
        fluidRow(
          box(
            title = "Iris head",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            collapsible = TRUE,
            tableOutput("tbl")
          ),
          box(
            title = "Controls",
            status = "info",
            solidHeader = FALSE,
            width = 6,
            selectInput("n", "Rows", c(5, 10, 15), selected = 5),
            sliderInput("bins", "Demo slider", 1, 20, 8),
            p(class = "text-muted", "Preset: ", strong(glass_preset))
          )
        )
      ),
      tabItem(
        "widgets",
        fluidRow(
          box(
            title = "Description blocks",
            width = 12,
            fluidRow(
              column(4, descriptionBlock(number = "150", header = "n", text = "rows", rightBorder = TRUE)),
              column(4, descriptionBlock(number = "3", header = "k", text = "groups", rightBorder = TRUE)),
              column(4, descriptionBlock(number = "4", header = "p", text = "features", rightBorder = FALSE))
            )
          )
        )
      )
    )
  ),
  controlbar = dashboardControlbar(
    skin = if (identical(glass_preset, "dark")) "dark" else "light",
    controlbarMenu(
      id = "cb_menu",
      controlbarItem(
        "Theme",
        p("Restart with SHINYGLASS_PRESET=dark for the dark glass pack."),
        p(class = "text-muted", "Controlbar uses glass overlay CSS.")
      )
    )
  ),
  footer = dashboardFooter(left = "shinyglass", right = "shinydashboardPlus")
)

server <- function(input, output, session) {
  output$user <- renderUser({
    dashboardUser(
      name = "Glass User",
      image = NULL,
      title = "Demo",
      subtitle = "shinyglass"
    )
  })

  output$tbl <- renderTable({
    head(iris, as.integer(input$n))
  })
}

shinyApp(ui, server)
