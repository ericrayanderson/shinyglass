# plotly + gt + optional waiter under glass_theme().
#
# Run:
#   shiny::runApp(system.file("examples", "plotly-gt-demo.R", package = "shinyglass"))
#
# Dark:
#   Sys.setenv(SHINYGLASS_PRESET = "dark")
#   shiny::runApp(system.file("examples", "plotly-gt-demo.R", package = "shinyglass"))
#
# Requires: plotly, gt  (optional: waiter)

library(shiny)
library(bslib)
library(shinyglass)

if (!requireNamespace("plotly", quietly = TRUE)) {
  stop("Install plotly: install.packages('plotly')", call. = FALSE)
}
if (!requireNamespace("gt", quietly = TRUE)) {
  stop("Install gt: install.packages('gt')", call. = FALSE)
}
library(plotly)
library(gt)

# Screenshots / CI can set SHINYGLASS_NO_WAITER=1 to skip the full-page overlay.
has_waiter <- requireNamespace("waiter", quietly = TRUE) &&
  !identical(Sys.getenv("SHINYGLASS_NO_WAITER", ""), "1")
if (has_waiter) {
  library(waiter)
}

glass_preset <- match.arg(
  Sys.getenv("SHINYGLASS_PRESET", "auto"),
  c("light", "dark", "auto")
)

ui <- page_sidebar(
  title = "plotly + gt + glass",
  theme = glass_theme(preset = glass_preset),
  fillable = TRUE,
  if (has_waiter) use_waiter() else NULL,
  if (has_waiter) waiter_show_on_load(spin_fading_circles(), color = "rgba(0,0,0,0.35)") else NULL,
  sidebar = sidebar(
    title = "Controls",
    width = 280,
    open = "desktop",
    selectInput(
      "preset",
      "Theme",
      c("Light" = "light", "Dark" = "dark", "Auto" = "auto"),
      selected = glass_preset,
      width = "100%"
    ),
    selectInput(
      "species",
      "Species",
      c("All", levels(iris$Species)),
      selected = "All",
      width = "100%"
    ),
    actionButton("reload", "Refresh plot", class = "btn-primary", width = "100%"),
    tags$hr(),
    tags$small(
      class = "text-muted",
      if (has_waiter) {
        "waiter is loaded — a glass-tinted overlay runs on first paint and refresh."
      } else {
        "Optional: install.packages('waiter') for loading overlays."
      }
    )
  ),
  layout_columns(
    col_widths = breakpoints(xs = c(12, 12), md = c(7, 5)),
    gap = "0.75rem",
    card(
      full_screen = TRUE,
      card_header("plotly"),
      # Tall enough that plotly bottom margin + x-axis title fit inside the card
      plotlyOutput("scatter", height = "400px")
    ),
    card(
      full_screen = TRUE,
      card_header("gt"),
      gt_output("iris_gt")
    )
  )
)

server <- function(input, output, session) {
  if (has_waiter) {
    waiter_hide()
  }

  observeEvent(input$preset, {
    update_glass_theme(session, preset = input$preset)
  }, ignoreInit = TRUE)

  filtered <- reactive({
    input$reload
    df <- iris
    if (!identical(input$species, "All")) {
      df <- df[df$Species == input$species, , drop = FALSE]
    }
    df
  })

  output$scatter <- renderPlotly({
    if (has_waiter) {
      waiter_show(html = spin_fading_circles(), color = "rgba(0,0,0,0.25)")
      on.exit(waiter_hide(), add = TRUE)
    }
    df <- filtered()
    dark <- identical(input$preset, "dark")
    paper <- if (dark) "rgba(0,0,0,0)" else "rgba(255,255,255,0)"
    font_col <- if (dark) "#f5f5f7" else "#1d1d1f"
    grid_col <- if (dark) "rgba(255,255,255,0.12)" else "rgba(0,0,0,0.08)"

    plot_ly(
      df,
      x = ~Sepal.Length,
      y = ~Sepal.Width,
      color = ~Species,
      type = "scatter",
      mode = "markers",
      marker = list(size = 9, opacity = 0.85)
    ) |>
      layout(
        paper_bgcolor = paper,
        plot_bgcolor = paper,
        font = list(color = font_col, family = "system-ui, sans-serif"),
        xaxis = list(gridcolor = grid_col, zerolinecolor = grid_col, color = font_col),
        yaxis = list(gridcolor = grid_col, zerolinecolor = grid_col, color = font_col),
        legend = list(bgcolor = "rgba(0,0,0,0)", font = list(color = font_col)),
        # Room for axis titles (b especially) — tight margins clip under glass
        margin = list(l = 56, r = 24, t = 36, b = 64)
      ) |>
      config(displaylogo = FALSE, modeBarButtonsToRemove = c("lasso2d", "select2d"), responsive = TRUE)
  })

  output$iris_gt <- render_gt({
    df <- filtered()
    summary <- aggregate(
      cbind(Sepal.Length, Sepal.Width, Petal.Length) ~ Species,
      data = df,
      FUN = function(x) round(mean(x), 2)
    )
    # Leave font color unset so glass CSS can apply --glass-body-color
    # (gt rejects CSS keyword "inherit" as a color name).
    gt(summary) |>
      tab_header(
        title = "Mean iris measures",
        subtitle = paste(nrow(df), "rows")
      ) |>
      cols_label(
        Species = "Species",
        Sepal.Length = "Sepal L",
        Sepal.Width = "Sepal W",
        Petal.Length = "Petal L"
      ) |>
      opt_row_striping() |>
      tab_options(
        table.background.color = "transparent",
        heading.background.color = "transparent",
        column_labels.background.color = "transparent",
        row.striping.background_color = "transparent",
        table.border.top.color = "transparent",
        table.border.bottom.color = "transparent",
        table.border.left.color = "transparent",
        table.border.right.color = "transparent"
      )
  })
}

shinyApp(ui, server)
