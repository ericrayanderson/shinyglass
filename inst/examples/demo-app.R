library(shiny)
library(bslib)
library(ggplot2)
library(shinyglass)

local({
  hits <- file.path(getwd(), "phone-preview", "phone-preview.R")
  root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  for (i in seq_len(8L)) {
    hits <- c(
      hits,
      file.path(root, "inst", "examples", "_shared", "phone-preview.R"),
      file.path(root, "_shared", "phone-preview.R")
    )
    parent <- dirname(root)
    if (identical(parent, root)) break
    root <- parent
  }
  installed <- system.file("examples", "_shared", "phone-preview.R", package = "shinyglass")
  if (nzchar(installed)) hits <- c(hits, installed)
  hit <- hits[file.exists(hits)]
  if (!length(hit)) stop("Missing phone preview helper.", call. = FALSE)
  app_env <- parent.env(environment())
  assign(".phone_preview_dir", dirname(normalizePath(hit[[1L]], winslash = "/")), envir = app_env)
  sys.source(hit[[1L]], envir = app_env)
})

demo_page <- glass_page(
  title = "Liquid Glass",
  persist = TRUE,
  scene = "tahoe",
  layout_column_wrap(
    width = 280,
    gap = "0.75rem",
    card(
      card_header("Form Controls"),
      selectInput("species", "Species", c("setosa", "versicolor", "virginica"), width = "100%"),
      sliderInput("bins", "Bins", 1, 50, 20, width = "100%"),
      checkboxInput("smooth", "Show smooth", TRUE)
    ),
    card(
      card_header("Plot"),
      plotOutput("dist_plot", height = "260px")
    )
  )
)

server <- function(input, output, session) {
  observe_glass(input, session)

  output$dist_plot <- renderPlot({
    req(input$species)
    x <- iris$Sepal.Length[iris$Species == input$species]
    df <- data.frame(x = x)
    pal <- glass_plot_colors(input = input)
    fill <- if (!is.null(input$glass_accent) && nzchar(input$glass_accent)) {
      input$glass_accent
    } else {
      pal$fill
    }
    p <- ggplot(df, aes(x)) +
      geom_histogram(bins = input$bins, fill = fill, color = NA, alpha = 0.88) +
      labs(title = paste("Sepal length:", input$species), x = "Sepal length (cm)", y = NULL) +
      theme_glass(input = input)
    if (isTRUE(input$smooth)) {
      p <- p + geom_density(
        aes(y = after_stat(count)),
        color = "#AF52DE",
        linewidth = 1.15
      )
    }
    p
  }, bg = "transparent", height = 260, res = 96)
}

ui <- function(request) {
  phone_preview(demo_page, app = "demo", request = request)
}

shinyApp(ui, server)
