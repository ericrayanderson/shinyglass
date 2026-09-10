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
    glass_preset_input(
      "preset",
      label = "Theme",
      selected = glass_preset,
      choices = c("Light" = "light", "Dark" = "dark", "Auto" = "auto"),
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
  # Stack beside a 280px sidebar at typical laptop widths (~1280px). A 6/6
  # split there squeezed plotly (overflow:visible leaked a page scrollbar)
  # and clipped gt headers. Side-by-side from Bootstrap xxl (1400px).
  layout_columns(
    col_widths = breakpoints(xs = c(12, 12), xxl = c(6, 6)),
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

  observe_glass_preset_input(input, session, "preset")

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
    plotly_glass(
      plot_ly(
        df,
        x = ~Sepal.Length,
        y = ~Sepal.Width,
        color = ~Species,
        type = "scatter",
        mode = "markers",
        marker = list(size = 9, opacity = 0.85)
      ),
      input = input
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
    gt_theme_glass(
      gt(summary) |>
        tab_header(
          title = "Mean iris measures",
          subtitle = paste(nrow(df), "rows")
        ) |>
        cols_label(
          Species = "Species",
          Sepal.Length = "Sepal Length",
          Sepal.Width = "Sepal Width",
          Petal.Length = "Petal Length"
        ) |>
        cols_align(align = "left", columns = Species) |>
        cols_align(align = "right", columns = where(is.numeric)) |>
        cols_width(
          Species ~ pct(22),
          Sepal.Length ~ pct(26),
          Sepal.Width ~ pct(26),
          Petal.Length ~ pct(26)
        ) |>
        opt_row_striping() |>
        tab_options(
          table.width = pct(100),
          column_labels.padding = "8px",
          data_row.padding = "6px"
        ),
      input = input
    )
  })
}

shinyApp(ui, server)
